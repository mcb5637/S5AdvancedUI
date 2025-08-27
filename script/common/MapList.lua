MapList = {}

---@param _left MapListMap
---@param _right MapListMap
---@return boolean
function MapList.Sort(_left, _right)
	if _left.IsMP and not _right.IsMP then
		return false
	end
	if not _left.IsMP and _right.IsMP then
		return true
	end
	return _left.MinimizedName < _right.MinimizedName
end

function MapList.Init()
	---@type MapListMap[]
	MapList.MapTable = {}
	MapList.AddMaps(MapList.MapTable, 0) -- Add singleplayer maps
	MapList.AddMaps(MapList.MapTable, 3) -- usermaps
	MapList.AddMaps(MapList.MapTable, 2) -- Add multi player maps
	table.sort(MapList.MapTable, MapList.Sort)
end

---@param _MapHandler MapListMap[]
---@param _MapType number
---@param _CampaignName string?
function MapList.AddMaps(_MapHandler, _MapType, _CampaignName)
	if _CampaignName == nil then
		_CampaignName = ""
	end
	local NumberOfMaps = Framework.GetNumberOfMaps(_MapType, _CampaignName)
	if NumberOfMaps == 0 then
		return
	end
	for i = 0, NumberOfMaps - 1 do
		local MapNameNumber, MapName = Framework.GetMapNames(i, 1, _MapType, _CampaignName)
		local MultiplayerMap = Framework.GetMapMultiplayerInformation(MapName, _MapType, _CampaignName) == 1
		local MapNameString, MapDescString = Framework.GetMapNameAndDescription(MapName, _MapType, _CampaignName)
		local mini = MapNameString
		if not mini or mini == "" then
			mini = MapName
		end
		mini = MapList.MinimizeName(string.lower(MapNameString))
		---@class MapListMap
		---@field Name string
		---@field Type number
		---@field CampaignIndex string
		---@field MapNameString string
		---@field MapDescString string
		---@field IsMP boolean
		---@field MinimizedName string
		local map = {
			Name = MapName,
			Type = _MapType,
			CampaignIndex = _CampaignName,
			MapNameString = MapNameString,
			MapDescString = MapDescString,
			IsMP = MultiplayerMap,
			MinimizedName = mini
		}
		table.insert(_MapHandler, map)
	end
end

---@param _string string
---@return string
function MapList.MinimizeName(_string)
	_string = string.gsub(
		string.gsub(string.gsub(string.gsub(_string, "@color:%d+,%d+,%d+,%d+", ""), "@color:%d+,%d+,%d+", ""), "  ",
			" "), "\"", "")
	while string.sub(_string, 1, 1) == " " do
		_string = string.sub(_string, 2)
	end
	while string.sub(_string, string.len(_string)) == " " do
		_string = string.sub(_string, 1, string.len(_string) - 1)
	end
	return _string
end

---@param filter string?
---@return MapListMap[]
function MapList.ApplyFilter(filter)
	if not filter then
		filter = ""
	end
	---@type MapListMap[]
	local l
	if filter ~= "" then
		filter = string.lower(filter)
		l = {}
		for _, m in ipairs(MapList.MapTable) do
			if string.find(m.MinimizedName, filter, 1, true) then
				table.insert(l, m)
			end
		end
	else
		l = MapList.MapTable
	end
	return l
end
