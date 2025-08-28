SaveList = {}

---@param _left MapListSave
---@param _right MapListSave
---@return boolean
function SaveList.Sort(_left, _right)
	if _right.Save == "quicksave" then --quicksave top
		return false
	end
	if _left.Save == "quicksave" then
		return true
	end
	local leftnorm = string.find(_left.Save, "save_") == 1
	local rightnorm = string.find(_right.Save, "save_") == 1
	local leftauto = string.find(_left.Save, "autosave") == 1
	local rightauto = string.find(_right.Save, "autosave") == 1
	if leftauto ~= rightauto then
		return leftauto
	end
	if leftauto then
		return tonumber(string.gsub(_left.Save, "autosave", ""), 10) < tonumber(string.gsub(_right.Save, "autosave", ""), 10)
	end
	if leftnorm ~= rightnorm then
		return leftnorm
	end
	if leftnorm then
		return tonumber(string.gsub(_left.Save, "save_", ""), 10) < tonumber(string.gsub(_right.Save, "save_", ""), 10)
	end
	return _left.Save < _right.Save
end

---@param _string string
---@return string
function SaveList.MinimizeName(_string)
	_string = string.gsub(
		string.gsub(string.gsub(string.gsub(_string, "@color:%d+,%d+,%d+,%d+", ""), "@color:%d+,%d+,%d+", ""), " +", " "),
		"\"", "")
	while string.sub(_string, 1, 1) == " " do
		_string = string.sub(_string, 2)
	end
	while string.sub(_string, string.len(_string)) == " " do
		_string = string.sub(_string, 1, string.len(_string) - 1)
	end
	return _string
end

---@return MapListSave[] invalid
function SaveList.Init()
	---@type MapListSave[]
	SaveList.SaveGameTable = {}
	---@type MapListSave[]
	local invalid = {}
	local index = 0
	while true do
		local num, slot = Framework.GetSaveGameNames(index, 1)
		if num == 0 then
			break
		end
		index = index + 1
		if Framework.IsSaveGameValid(slot) then
			table.insert(SaveList.SaveGameTable, SaveList.MakeSave(slot))
		else
			table.insert(invalid, SaveList.MakeInvalidSave(slot))
		end
	end
	table.sort(SaveList.SaveGameTable, SaveList.Sort)
	return invalid
end

---@param minNum number
function SaveList.InitCreate(minNum)
	local invalid = SaveList.Init()
	---@type MapListSave[]
	SaveList.SaveGameCreateTable = {}
	local maxSlot = 0
	for _,s in ipairs(SaveList.SaveGameTable) do
		if s.SlotNumber then
			SaveList.SaveGameCreateTable[s.SlotNumber] = s
			maxSlot = math.max(s.SlotNumber, maxSlot) or 0
		end
	end
	for _,s in ipairs(invalid) do
		if s.SlotNumber then
			SaveList.SaveGameCreateTable[s.SlotNumber] = s
			maxSlot = math.max(s.SlotNumber, maxSlot) or 0
		end
	end
	maxSlot = math.max(maxSlot + 5, minNum)
	for i=1,maxSlot do
		if not SaveList.SaveGameCreateTable[i] then
			SaveList.SaveGameCreateTable[i] = {
				Name = "",
				Type = -5,
				CampaignIndex = "",
				MapNameString = "",
				MapDescString = "",
				IsMP = false,
				Save = "save_"..i,
				Desc = XGUIEng.GetStringTableText("IngameMenu/SaveGame_EmptySlot"),
				GUID = "",
				MinimizedName = "",
				SlotNumber = i,
			}
		end
	end
end

---@param slot string
---@return MapListSave
function SaveList.MakeSave(slot)
	local mapname, typ, cname, guid = CppLogic.API.SaveGetMapInfo(slot)
	local MapNameString, MapDescString = Framework.GetMapNameAndDescription(mapname, typ, cname)
	local mp = Framework.GetMapMultiplayerInformation(mapname, typ, cname) == 1
	local desc = Framework.GetSaveGameString(slot) or "invalid"
	local sn = SaveList.TryParseSlotNum(slot)
	---@class MapListSave : MapListMap
	---@field Save string
	---@field Desc string
	---@field GUID string
	---@field SlotNumber number?
	local s = {
		Name = mapname,
		Type = typ,
		CampaignIndex = cname,
		MapNameString = MapNameString,
		MapDescString = MapDescString,
		IsMP = mp,
		Save = slot,
		Desc = desc,
		GUID = guid,
		MinimizedName = SaveList.MinimizeName(string.lower(desc)),
		SlotNumber = sn,
	}
	return s
end

---@param slot string
---@return MapListSave
function SaveList.MakeInvalidSave(slot)
	local sn = SaveList.TryParseSlotNum(slot)
	local n = Framework.GetSaveGameString(slot)
	if not n or n == "" then
		n = XGUIEng.GetStringTableText("AdvancedUI/invalid_saveslot_empty")
	else
		n = XGUIEng.GetStringTableText("AdvancedUI/invalid_saveslot_name").." - "..n
	end
	---@type MapListSave
	local s = {
		Name = "",
		Type = -5,
		CampaignIndex = "",
		MapNameString = "",
		MapDescString = "",
		IsMP = false,
		Save = slot,
		Desc = n,
		GUID = "",
		MinimizedName = "",
		SlotNumber = sn,
	}
	return s
end

---@param slot string
---@return number?
function SaveList.TryParseSlotNum(slot)
	local _, _, slotnum = string.find(slot, "save_(%d+)$")
	local sn = nil
	if slotnum then
		sn = tonumber(slotnum)
	end
	return sn
end

---@param save MapListSave
---@return number year
---@return number month
---@return number day
---@return number hour
---@return number min
---@return number sec
function SaveList.ParseSaveDate(save)
	local f, _, year, month, day, hour, min, sec = string.find(save.Desc, "(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)$")
	if f then
		return tonumber(year) or 0, tonumber(month) or 0, tonumber(day) or 0, tonumber(hour) or 0, tonumber(min) or 0, tonumber(sec) or 0
	else
		return 0, 0, 0, 0, 0, 0
	end
end

---@param filter string?
---@return MapListSave[]
function SaveList.ApplyFilter(filter)
	if not filter then
		filter = ""
	end
	---@type MapListSave[]
	local l
	if filter ~= "" then
		filter = string.lower(filter)
		l = {}
		for _, m in ipairs(SaveList.SaveGameTable) do
			if string.find(m.MinimizedName, filter, 1, true) then
				table.insert(l, m)
			end
		end
	else
		l = SaveList.SaveGameTable
	end
	return l
end
