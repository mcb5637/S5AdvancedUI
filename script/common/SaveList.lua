SaveList = {}

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

function SaveList.Init()
	SaveList.SaveGameTable = {}
	local index = 0
	while true do
		local num, SaveGameName = Framework.GetSaveGameNames(index, 1)
		if num == 0 then
			break
		end
		index = index + 1
		if Framework.IsSaveGameValid(SaveGameName) then
			table.insert(SaveList.SaveGameTable, SaveList.MakeSave(SaveGameName))
		end
	end
	table.sort(LoadSaveGame.SaveGameTable, LoadSaveGame.Sort)
end

---@param slot string
---@return MapListSave
function SaveList.MakeSave(slot)
	local mapname, typ, cname, guid = CppLogic.API.SaveGetMapInfo(slot)
	local MapNameString, MapDescString = Framework.GetMapNameAndDescription(mapname, typ, cname)
	local mp = Framework.GetMapMultiplayerInformation(mapname, typ, cname) == 1
	local desc = Framework.GetSaveGameString(slot) or "invalid"
	---@class MapListSave : MapListMap
	---@field Save string
	---@field Desc string
	---@field GUID string
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
	}
	return s
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
