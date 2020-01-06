local SETTINGS = {
	{unit = "player", points = {"CENTER",-400,-300}, size = 36, inArena = false, },
	--{unit = "target", points = {"CENTER"}, size = 72,},
	{unit = "party1", points = {"CENTER",-605,250}, size = 36, inArena = true, },
	{unit = "party2", points = {"CENTER",-605,200}, size = 36, inArena = true, },
	{unit = "arena1", points = {"CENTER",410,40}, size = 36, inArena = true, },
	{unit = "arena2", points = {"CENTER",410,3}, size = 36, inArena = true, },
	{unit = "arena3", points = {"CENTER",410,-35}, size = 36, inArena = true, },
}

local CreateFrame = CreateFrame
local setmetatable = setmetatable
local select,unpack,wipe = select,unpack,wipe
local IsInInstance = IsInInstance
local UnitAura,UnitExists,UnitGUID = UnitAura,UnitExists,UnitGUID
local GetItemIcon = GetItemIcon
local GetTime = GetTime
local math = math
local UIParent = UIParent


local spell2trinket,trinket2cooldown = unpack(select(2,...))
local addon = CreateFrame("frame")
local objects,tmpData = {},{}
local trinket2uptime = {}


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

	local data = tmpData[self.guid]
	if data then
		local unit = self.unit

		local icon,data_i,trinket
		local texture,duration,expirationTime,_
		for i = 1,math.max(#data,#icons) do
			icon,data_i = icons[i],data[i]

			if data_i then
				_,_,texture,_,_,duration,expirationTime = UnitAuraBySpellID(unit,data_i.spell)
				trinket = spell2trinket[data_i.spell]

				if duration and duration ~= 0 then
					icon.texture:SetTexture(texture)
					icon.cooldown:SetCooldown(expirationTime-duration,duration)
					icon.bg:SetTexture(0,0.8,0)
					trinket2uptime[trinket] = duration
				else
					duration = trinket2cooldown[trinket]

					icon.texture:SetTexture(GetItemIcon(trinket))
					if duration ~= 0 and data_i.timestamp+duration > GetTime() then
						local uptime = trinket2uptime[trinket] or 0
						icon.cooldown:SetCooldown(data_i.timestamp+uptime,duration-uptime)
						icon.bg:SetTexture(0.8,0,0)
					else
						icon.cooldown:Hide()
						icon.bg:SetTexture(0,0.8,0)
					end
				end
			else
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				icon.cooldown:Hide()
				icon.bg:SetTexture(0,0,0)
			end

			icon:Show()
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

function framePrototype:UpdateGUID()
	self.guid = UnitGUID(self.unit)
end

function framePrototype:PLAYER_ENTERING_WORLD()
	if self.inArena_event then
		if select(2,IsInInstance()) == "arena" then
			self:RegisterEvent(self.inArena_event)
		else
			self:UnregisterEvent(self.inArena_event)
			self:Hide()
			return
		end
	end
	self:CheckUnitExists()
end

function framePrototype:UNIT_INVENTORY_CHANGED(unit,slot)
	if unit ~= self.unit then
		return
	end

	-- todo
end

function framePrototype:CheckUnitExists()
	if UnitExists(self.unit) then
		self:UpdateGUID()
		self:Update()
		self:Show()
	else
		self:Hide()
	end
end


function addon:CreateFrame()
	local frame = setmetatable(CreateFrame("frame",nil,UIParent),frameMT)
	frame:SetSize(12,12)
	frame:SetScript("OnEvent",addon.OnEvent)

	frame.icons = setmetatable({parent = frame},iconsMT)


	objects[#objects+1] = frame
	return frame
end

function addon:SetupFrame(frame,data)
	frame.size = data.size or 36
	if data.points then
		frame:SetPoint(unpack(data.points))
	else
		frame:SetPoint("CENTER")
	end

	local unit = data.unit or "player"
	frame.unit = unit

	local event
	if unit == "player" then
		frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	elseif unit == "target" then
		event = "PLAYER_TARGET_CHANGED"
	elseif unit == "focus" then
		event = "PLAYER_FOCUS_CHANGED"
	elseif unit:find("^party%d$") then
		event = "PARTY_MEMBERS_CHANGED"
	elseif unit:find("^arena%d$") then
		event = "ARENA_OPPONENT_UPDATE"
	end

	if event then
		if data.inArena then
			frame.inArena_event = event
		else
			frame:RegisterEvent(event)
		end
		frame[event] = frame.CheckUnitExists
	end
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

function addon:AddTrinket(guid,spell,timestamp)
	local data = tmpData[guid]
	if data then
		local added = false
		local trinket = spell2trinket[spell]
		local data_i
		for i = 1,#data do
			data_i = data[i]

			if spell2trinket[data_i.spell] == trinket then
				data_i.spell = spell
				data_i.timestamp = timestamp

				added = true
				break
			end
		end

		if not added then
			if #data >= 2 then
				local olderTimestamp,olderTimestamp_i = 0xFFFFFFFF
				local timestamp
				for i = 1,#data do
					timestamp = data[i].timestamp
					if olderTimestamp > timestamp then
						olderTimestamp = timestamp
						olderTimestamp_i = i
					end
				end

				data[olderTimestamp_i].spell = spell
				data[olderTimestamp_i].timestamp = timestamp
			else
				data[#data+1] = {spell = spell, timestamp = timestamp}
			end
		end
	else
		tmpData[guid] = {{spell = spell, timestamp = timestamp}}
	end

	self:UpdateObjectByGUID(guid)
end

local watchedSubEvents = {
	["SPELL_CAST_SUCCESS"] = true,
	["SPELL_AURA_APPLIED"] = true,
	["SPELL_AURA_REFRESH"] = true,
	["SPELL_AURA_APPLIED_DOSE"] = true,
}

function addon:COMBAT_LOG_EVENT_UNFILTERED(_,subEvent,...)
	if watchedSubEvents[subEvent] then
		local srcGUID,spellId
		srcGUID,_,_,_,_,_,spellId = ...
		if spell2trinket[spellId] then
			self:AddTrinket(srcGUID,spellId,GetTime())
		end
	end
end

function addon:PLAYER_ENTERING_WORLD()
	for i = 1,#objects do
		objects[i]:CheckUnitExists()
	end
	wipe(tmpData)
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