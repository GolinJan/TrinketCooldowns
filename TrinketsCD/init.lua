local DB =  {
	["size"] = 35,			-- тут понятно
	["space"] = 2,			-- отступ
	["border"] = 4,			-- толщина бортиков
	["target"] = {-120,0},	-- значения по осям x,y относительно центра экрана
	["focus"] = {120,0},
	["party1"] = {-605,250},
	["party2"] = {-605,200},
	["arena1"] = {410,40},
	["arena2"] = {410,3},
	["arena3"] = {410,-35},
}





local array,QUESTION,tmp,plate,units = select(2,...).a,"Interface\\Icons\\INV_Misc_QuestionMark",{},{},{"target","focus","party1","party2","arena1","arena2","arena3"}
local function SetCD(s,x,y) if not y then s:SetAlpha(0) else s:SetAlpha(1) s:SetCooldown(x,y) end end
local function SetInfo(s,cd,x,r,g) SetCD(s.cd,GetTime(),cd) s.cd.cd = x s:SetBackdropBorderColor(r,g)end

local function CD_OnHide(s)
	local cd = s.cd
	if cd then
		if cd > 0 then
			s.cd = -1
			SetCD(s,GetTime(),cd)
			s.p:SetBackdropBorderColor(.8,0,0)
		elseif cd == -1 then
			s.cd = nil
			s.p:SetBackdropBorderColor(0,.8,0)
		end
	end
end

local function UpdatePlate(s)
	local guid = s.guid
	if tmp[guid] then
		for i = 1,2 do
			if tmp[guid][i] then
				local t,x,y = unpack(tmp[guid][i])
				local d,r = x-GetTime(), y-GetTime()
				
				s[i].i:SetTexture(select(10,GetItemInfo(t)))
				if d > 0 then
					SetInfo(s[i],d,y-x,0,.8)
				elseif r > 0 then
					SetInfo(s[i],r,-1,.8,0)
				else
					SetInfo(s[i],nil,nil,0,.8)
				end
			else
				s[i].i:SetTexture(QUESTION)
				SetInfo(s[i],nil,nil,0,0)
			end
		end
	else
		for i=1,2 do
			s[i].i:SetTexture(QUESTION)
			SetInfo(s[i],nil,nil,0,0)
		end
	end
end

local function CreateTracker(p)
	local f = CreateFrame("frame",nil,p)
	f:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = DB.border/2,bgFile = "Interface\\Buttons\\WHITE8x8",
				   insets = { left = -DB.border/2, right = -DB.border/2, top = -DB.border/2, bottom = -DB.border/2}})
	f:SetBackdropColor(0,0,0)
	f:SetBackdropBorderColor(0,0,0)
	f:SetSize(DB.size,DB.size)

	f.i = f:CreateTexture(nil, "BORDER")
	f.i:SetTexture(QUESTION)
	f.i:SetTexCoord(.07,.93,.07,.93)
	f.i:SetPoint("TOPLEFT",DB.border,-DB.border)
	f.i:SetPoint("BOTTOMRIGHT",-DB.border,DB.border)

	local cd = CreateFrame("Cooldown", nil, f)
	cd:SetFrameLevel(f:GetFrameLevel()+1)
	cd:SetPoint("TOPLEFT",DB.border,-DB.border)
	cd:SetPoint("BOTTOMRIGHT",-DB.border,DB.border)
	cd.p = f
	cd:SetScript("OnHide",CD_OnHide)
	f.cd = cd
	return f
end

local function CreateLayer(u)
	local l = CreateFrame("frame",nil,UIParent)
	l:Hide()
	l:SetSize(1,1)
	l:SetPoint("CENTER",unpack(DB[u]))
	local f,s = CreateTracker(l),CreateTracker(l)
	f:SetPoint("CENTER",(-DB.size/2)-(DB.space/2),0)
	s:SetPoint("CENTER",(DB.size/2)+(DB.space/2),0)
	l[1],l[2] = f,s
	return l
end

local function AuraHandler(i,p)
	if array[p] then
		if not tmp[i]then tmp[i] = {} end
		local r,d,c = unpack(array[p])
		local p = {r,GetTime()+d,GetTime()+c}
		if not tmp[i][1] or tmp[i][1][1] == r then
			tmp[i][1] = p
		elseif not tmp[i][2] or tmp[i][2][1] == r then
			tmp[i][2] = p
		else
			tmp[i][1] = {unpack(tmp[i][2])}
			tmp[i][2] = p
		end
		for _,v in pairs(plate) do
			if v.guid and v.guid == i then
				UpdatePlate(v)
			end
		end	
	end	
end

for _,v in pairs(units) do plate[v] = CreateLayer(v) end

local function UnitHandler(u)
	local plate = plate[u]
	if UnitIsPlayer(u) then
		plate:Show()
		plate.guid = UnitGUID(u)
		UpdatePlate(plate)
	else
		plate:Hide()
		plate.guid = nil
	end
end

local function PartyHandler() for i = 1,2 do UnitHandler("party"..i) end end
PartyHandler()

local function ArenaHandler() for i = 1,3 do UnitHandler("arena"..i) end end
ArenaHandler()

local f = CreateFrame"frame"
--f:RegisterEvent("PLAYER_TARGET_CHANGED")
--f:RegisterEvent("PLAYER_FOCUS_CHANGED")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:RegisterEvent("ARENA_OPPONENT_UPDATE")
f:SetScript("OnEvent",function(s,e,...)
	if e == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _,s,g,_,_,_,_,_,i = ...
		if s == "SPELL_AURA_APPLIED" or s == "SPELL_CAST_SUCCESS" then
			AuraHandler(g,i)
		end
	elseif e == "PARTY_MEMBERS_CHANGED" then
		PartyHandler()
	elseif e == "ARENA_OPPONENT_UPDATE" then
		ArenaHandler()
	else
		UnitHandler(select(2,strsplit("_",e)):lower())
	end
end)