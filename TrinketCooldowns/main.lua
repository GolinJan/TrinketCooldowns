local SETTINGS = {
	{unit = "player", points = {"CENTER",-400,-300}, size = 36, onlyInArena = false, },
	{unit = "party1", points = {"CENTER",-400,200}, size = 36, onlyInArena = true, },
	{unit = "party2", points = {"CENTER",-400,150}, size = 36, onlyInArena = true, },
	{unit = "arena1", points = {"CENTER",400,200}, size = 36, onlyInArena = true, onlyTrinkets = true, },
	{unit = "arena2", points = {"CENTER",400,150}, size = 36, onlyInArena = true, onlyTrinkets = true, },
	{unit = "arena3", points = {"CENTER",400,100}, size = 36, onlyInArena = true, onlyTrinkets = true, },

	--{unit = "target", points = {"TOPLEFT",0,-50}},
	--{unit = "focus", points = {"TOPLEFT",0,-90}},
}

local math,table = math,table
local setmetatable = setmetatable
local tonumber,select,unpack,wipe = tonumber,select,unpack,wipe
local CreateFrame = CreateFrame
local IsInInstance = IsInInstance
local UnitAura,UnitExists,UnitGUID = UnitAura,UnitExists,UnitGUID
local GetTime = GetTime
local UIParent = UIParent
local GetInventoryItemID = GetInventoryItemID
local GetItemGem,GetItemInfo,GetItemIcon = GetItemGem,GetItemInfo,GetItemIcon
local NotifyInspect = NotifyInspect
local CanInspect = CanInspect
local UnitCanAssist = UnitCanAssist

local INVSLOT_BACK = INVSLOT_BACK
local INVSLOT_HEAD = INVSLOT_HEAD

local SLOT_TRINKET = 0x1
local SLOT_RING = 0x2
local SLOT_METAGEM = 0x3
local SLOT_BACK = 0x4


local addon = CreateFrame("frame")
local objects,cache = {},{}
local spell2item,item2uptime,item2cooldown,item2slot = {},{},{},{}
do
	local namespace = select(2,...)

	local item
	for spell,data in pairs(namespace[1]) do
		item = data[1]

		if type(item) == "table" then
			for i = 1,#item do
				spell2item[spell] = item[i]
			end
		else
			spell2item[spell] = item
		end

		item2cooldown[item] = data[2]
		item2slot[item] = data[3]
	end

	namespace[1] = nil
end


local generateTrinketSlotHandler = function(slot)
	return function(unit)
		local id = GetInventoryItemID(unit,slot)
		if id then
			return id,GetItemIcon(id)
		end
	end
end

local generateRingSlotHandler = function(slot)
	return function(unit)
		local id = GetInventoryItemID(unit,slot)
		if item2cooldown[id] then
			return id,GetItemIcon(id)
		end
	end
end

local SLOTS = {
	[1] = generateTrinketSlotHandler(INVSLOT_TRINKET1),
	[2] = generateTrinketSlotHandler(INVSLOT_TRINKET2),
	[3] = generateRingSlotHandler(INVSLOT_FINGER1),
	[4] = generateRingSlotHandler(INVSLOT_FINGER2),
	[5] = function(unit) -- helm meta
		local id = GetInventoryItemID(unit,INVSLOT_HEAD)
		if id then
			local _,link = GetItemInfo(id)
			if link then
				_,link = GetItemGem(link,1)
				if link then
					id = tonumber(link:match("|Hitem:(%d+):"))
					if item2cooldown[id] then
						return id,GetItemIcon(id)
					end
				end
			end
		end
	end,
	[6] = function(unit) -- back enchant
		local link = GetInventoryItemLink(unit,INVSLOT_BACK)
		if link then
			local id = tonumber(link:match("|Hitem:%d+:(%d+):"))
			if item2cooldown[id] then
				return id,GetItemIcon(link)
			end
		end
	end,
}

local function UnitAuraBySpellID(unit,_spellId,filter)
	local ret1,ret2,ret3,ret4,ret5,ret6,ret7,ret8,ret9,ret10,spellId
	for i = 1,40 do
		ret1,ret2,ret3,ret4,ret5,ret6,ret7,ret8,ret9,ret10,spellId = UnitAura(unit,i,filter)

		if ret1 then
			if spellId == _spellId then
				return ret1,ret2,ret3,ret4,ret5,ret6,ret7,ret8,ret9,ret10,spellId
			end
		else
			break
		end
	end
end


local framePrototype = setmetatable({},getmetatable(FriendsMicroButton))
local frameMT = {__index = framePrototype}

local function cooldown_OnHide(self)
	self:GetParent():GetParent():Update()
end

local iconsMT = {
	__index = function(self,key)
		local parent = self.parent
		local offset = math.ceil(parent.size/18)*(2-UIParent:GetEffectiveScale())
		local n = parent:GetNumChildren()

		local frame = CreateFrame("frame",nil,parent)
		frame:SetPoint("BOTTOMLEFT",n*(parent.size+offset),0)
		frame:SetSize(parent.size,parent.size)

		local bg = frame:CreateTexture(nil,"BACKGROUND")
		bg:SetAllPoints()

		local cooldown = CreateFrame("Cooldown",nil,frame)
		cooldown:SetPoint("TOPRIGHT",-offset,-offset)
		cooldown:SetPoint("BOTTOMLEFT",offset,offset)
		cooldown:SetScript("OnHide",cooldown_OnHide)
		cooldown:SetDrawEdge(true)

		local texture = frame:CreateTexture(nil,"BORDER")
		texture:SetTexCoord(0.07,0.93,0.07,0.93)
		texture:SetAllPoints(cooldown)


		frame.bg = bg
		frame.texture = texture
		frame.cooldown = cooldown

		self[key] = frame
		return frame
	end,
}

function framePrototype:Update()
	local icons = self.icons

	local data = cache[self.guid]
	if data then
		local unit = self.unit
		local onlyTrinkets = self.onlyTrinkets

		local icon,data_i
		local texture,duration,expirationTime,_
		for i = 1,(onlyTrinkets and 2 or math.max(#data,#icons)) do
			icon = icons[i]

			if onlyTrinkets then
				data_i = nil
				for j = 1,#data do
					if item2slot[data[j].item] == SLOT_TRINKET then
						i = i - 1
						if i == 0 then
							data_i = data[j]
						end
					end
				end
			else
				data_i = data[i]
			end

			if data_i then
				if data_i.spell then
					_,_,texture,_,_,duration,expirationTime = UnitAuraBySpellID(unit,data_i.spell)
				else
					duration = nil
				end

				if duration and duration ~= 0 then -- uptime
					icon.texture:SetTexture(texture)
					icon.cooldown:SetCooldown(expirationTime-duration,duration)
					icon.bg:SetTexture(0,0.8,0)
					item2uptime[data_i.item] = duration
				else
					icon.texture:SetTexture(data_i.texture)

					duration = item2cooldown[data_i.item]
					if duration and duration ~= 0 and data_i.timestamp and data_i.timestamp+duration > GetTime() then -- cooldown
						local uptime = item2uptime[data_i.item]
						if uptime and GetTime() > data_i.timestamp + uptime then
							icon.cooldown:SetCooldown(data_i.timestamp+uptime,duration-uptime)
						else
							icon.cooldown:SetCooldown(data_i.timestamp,duration)
						end
						icon.bg:SetTexture(0.8,0,0)
					else -- ready
						icon.cooldown:Hide()
						icon.bg:SetTexture(0,0.8,0)
					end
				end

				icon:Show()
			else
				icon:Hide()
			end
		end
	else
		local icon
		for i = 1,#icons do
			icon = icons[i]

			if icon:IsShown() then
				icon:Hide()
			else
				break
			end
		end
	end
end

function framePrototype:PLAYER_ENTERING_WORLD()
	if self.onlyInArena_event then
		if select(2,IsInInstance()) == "arena" then
			self:RegisterEvent(self.onlyInArena_event)
		else
			self:UnregisterEvent(self.onlyInArena_event)
			self:Hide()
			return
		end
	end

	self:UpdateUnit()
end

function framePrototype:UpdateUnit()
	if not UnitIsPlayer(self.unit) then
		self:Hide()
		return
	end

	local guid = UnitGUID(self.unit)
	if guid then
		self.guid = guid
		if not cache[guid] then
			cache[guid] = {}
		end

		self:Update()
		self:Inspect()
		self:Show()
	else
		self:Hide()
	end
end

function framePrototype:Inspect()
	self.toUpd = -1
	self:SetScript("OnUpdate",self.OnUpdate_Inspect)
end

function framePrototype:OnHide()
	self:SetScript("OnUpdate",nil)
end

function framePrototype:InspectInner()
	local unit = self.unit
	if not CanInspect(unit) then
		return
	end

	NotifyInspect(unit)

	local tbl = {}
	local item,texture
	for i = 1,#SLOTS do
		item,texture = SLOTS[i](unit)
		if item then
			tbl[#tbl+1] = {item = item, texture = texture}
		end
	end
	addon:SetCacheInfo(self.guid,tbl)
	
	self:SetScript("OnUpdate",nil)
	self:Update()
end

function framePrototype:OnUpdate_Inspect(elapsed)
	self.toUpd = self.toUpd - elapsed
	if self.toUpd < 0 then
		self.toUpd = 0.2

		self:InspectInner()
	end
end

function framePrototype:UNIT_INVENTORY_CHANGED(unit)
	if unit ~= self.unit or not UnitCanAssist("player",unit) then
		return
	end

	self:Inspect()	
end


function addon:CreateFrame()
	local frame = setmetatable(CreateFrame("frame",nil,UIParent),frameMT)
	frame:SetSize(12,12)
	frame:SetScript("OnHide",frame.OnHide)
	frame:SetScript("OnEvent",addon.OnEvent)

	frame.icons = setmetatable({parent = frame},iconsMT)


	objects[#objects+1] = frame
	return frame
end

function addon:SetupFrame(frame,data)
	frame.size = data.size or 36
	frame.onlyTrinkets = data.onlyTrinkets

	if data.points then
		frame:SetPoint(unpack(data.points))
	else
		frame:SetPoint("CENTER")
	end

	local unit = data.unit or "player"
	frame.unit = unit

	local event
	if unit == "target" then
		event = "PLAYER_TARGET_CHANGED"
	elseif unit == "focus" then
		event = "PLAYER_FOCUS_CHANGED"
	elseif unit:find("^party%d$") then
		event = "PARTY_MEMBERS_CHANGED"
	elseif unit:find("^arena%d$") then
		event = "ARENA_OPPONENT_UPDATE"
	end

	if event then
		if data.onlyInArena then
			frame.onlyInArena_event = event
		else
			frame:RegisterEvent(event)
		end
		frame[event] = frame.UpdateUnit
	end

	frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function addon:UpdateObjectByGUID(guid)
	local object
	for i = 1,#objects do
		object = objects[i]

		if object.guid == guid and object:IsShown() then
			object:Update()
		end
	end
end

function addon:SetCacheInfo(guid,data)
	local oldData = cache[guid]
	
	local data_i
	for i = 1,#data do
		data_i = data[i]

		if oldData then
			local oldData_i
			for i = 1,#oldData do
				oldData_i = oldData[i]

				if data_i.item == oldData_i.item then
					data_i.spell = oldData_i.spell or data_i.spell
					data_i.timestamp = oldData_i.timestamp or data_i.timestamp
					break
				end
			end
		end
	end

	cache[guid] = data
end

function addon:AlignGuidCache(guidCache,slot)
	local alignTo = slot == SLOT_TRINKET and 2 or 1

	local count = 0
	local oldestTimestamp,oldestTimestamp_index = 0xFFFFFFFF
	local guidCache_i,timestamp
	for i = 1,#guidCache do
		guidCache_i = guidCache[i]

		if item2slot[guidCache_i.item] == slot then
			count = count + 1

			timestamp = guidCache_i.timestamp
			if not timestamp or oldestTimestamp > timestamp then
				oldestTimestamp = timestamp or 0xFFFFFFFF
				oldestTimestamp_index = i
			end
		end
	end

	if count > alignTo then
		table.remove(guidCache,oldestTimestamp_index)
	end
end

function addon:SaveItemToCache(guid,spell,timestamp)
 	local item = spell2item[spell]
 	local tbl = {spell = spell, item = item, timestamp = timestamp, texture = GetItemIcon(item)}

	local guidCache = cache[guid]
	if guidCache then
		local added = false
		for i = 1,#guidCache do
			if guidCache[i].item == item then
				guidCache[i] = tbl

				added = true
				break
			end
		end

		if not added then
			guidCache[#guidCache+1] = tbl
		end

		self:AlignGuidCache(guidCache,item2slot[item])
		self:UpdateObjectByGUID(guid) -- object:UpdateUnit() creates cache[guid] field
	else
		cache[guid] = {tbl}
	end
end

local watchedSubEvents = {
	["SPELL_CAST_SUCCESS"] = true,
	["SPELL_AURA_APPLIED"] = true,
	["SPELL_AURA_REFRESH"] = true,
	["SPELL_AURA_APPLIED_DOSE"] = true,
}

function addon:COMBAT_LOG_EVENT_UNFILTERED(_,subEvent,...)
	if not watchedSubEvents[subEvent] then
		return
	end

	local srcGUID,spellId
	srcGUID,_,_,_,_,_,spellId = ...

	if spell2item[spellId] then
		self:SaveItemToCache(srcGUID,spellId,GetTime())
	end
end

function addon:PLAYER_ENTERING_WORLD()
	wipe(cache)
end

function addon:OnEvent(event,...)
	self[event](self,...)
end

function addon:Initialize()
	for i = 1,#SETTINGS do
		self:SetupFrame(self:CreateFrame(),SETTINGS[i])
	end
	self.SetupFrame,self.CreateFrame = nil

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end


addon:SetScript("OnEvent",addon.OnEvent)
addon:Initialize()
addon.Initialize = nil

collectgarbage()