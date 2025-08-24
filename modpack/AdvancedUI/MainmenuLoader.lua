Script.Load("Data\\Script\\Common\\MapList.lua")
Script.Load("Data\\Script\\Common\\SaveList.lua")

MainmenuMaps = {}
MainmenuSaves = {}

---@type CPPLAutoScroll<MapListMap>
MainmenuMaps.StartMapScroll = AutoScroll.Init("SPM20_Scoll", "SPM20_MapNameUp", "SPM20_MapNameDown", "SPM20_ScrollBar", true)
---@type CPPLAutoScroll<MapListSave>
MainmenuSaves.LoadSaveScroll = AutoScroll.Init("SPM30_Scoll", "SPM30_MapNameUp", "SPM30_MapNameDown", "SPM30_ScrollBar", true)

---@param m MapListMap
---@return string
function MainmenuMaps.StartMapScroll.StringExtract(m)
	return m.MapNameString ~= "" and m.MapNameString or m.Name
end

---@param old MapListMap?
---@param new MapListMap?
function MainmenuMaps.StartMapScroll.OnSelectedChanged(old, new)
	local tex = ""
	local tit = ""
	local des = ""
	if new then
		tex = Framework.GetMapPreviewMapTextureName(new.Name, new.Type, new.CampaignIndex)
		tit = new.MapNameString
		des = new.MapDescString
	end
	if tex == "" then
		tex = "data\\graphics\\textures\\gui\\mainmenu\\pergamentmap.png"
	end
	XGUIEng.SetMaterialTexture("SPM20_MapPreview", 1, tex)
	XGUIEng.SetText("SPM20_MapDescription", des)
	XGUIEng.SetText("SPM20_MapTitle", tit)
end

---@param m MapListSave
---@return string
function MainmenuSaves.LoadSaveScroll.StringExtract(m)
	return m.Desc ~= "" and m.Desc or m.Save
end

---@param old MapListSave?
---@param new MapListSave?
function MainmenuSaves.LoadSaveScroll.OnSelectedChanged(old, new)
	local tex = ""
	local tit = ""
	local des = ""
	if new then
		tex = Framework.GetMapPreviewMapTextureName(new.Name, new.Type, new.CampaignIndex)
		tit = new.Desc ~= "" and new.Desc or new.MapNameString
		des = new.MapDescString
	end
	if tex == "" then
		tex = "data\\graphics\\textures\\gui\\mainmenu\\pergamentmap.png"
	end
	XGUIEng.SetMaterialTexture("SPM30_MapPreview", 1, tex)
	XGUIEng.SetText("SPM30_MapDescription", des)
	XGUIEng.SetText("SPM30_MapTitle", tit)
end

function MainmenuMaps.OverrideFuncs()
	if MainmenuMaps.S00_ToCustomMapOrig then
		return
	end
	---@diagnostic disable-next-line: duplicate-set-field
	function LoadMap.Done()
		---@type MapListMap?
		local sel = MainmenuMaps.StartMapScroll:GetSelected()
		if not sel then
			return
		end
		GDB.SetStringNoSave("AdvUI\\LastMap\\Name", sel.Name)
		GDB.SetStringNoSave("AdvUI\\LastMap\\CampaignIndex", sel.CampaignIndex)
		GDB.SetValue("AdvUI\\LastMap\\Type", sel.Type)
		Framework.StartMap(sel.Name, sel.Type, sel.CampaignIndex)
		LoadScreen_Init(0, sel.Name, sel.Type, sel.CampaignIndex)
	end

	MainmenuMaps.S00_ToCustomMapOrig = SPMenu.S00_ToCustomMap
	---@diagnostic disable-next-line: duplicate-set-field
	function SPMenu.S00_ToCustomMap()
		MainmenuMaps.S00_ToCustomMapOrig()
		CppLogic.API.ReloadExternalmaps()
		MapList.Init()
		MainmenuMaps.StartMapScroll:SetDataToScrollOver(MapList.MapTable)
		MainmenuMaps.StartMapScroll.OnSelectedChanged(nil, nil)
		CppLogic.UI.TextInputCustomWidgetSetText("SPM20_FilterInput", "")
		CppLogic.UI.InputCustomWidgetSetFocus("SPM20_FilterInput", true)
		if GDB.IsKeyValid("AdvUI\\LastMap\\Name") then
			local n = GDB.GetString("AdvUI\\LastMap\\Name")
			local t = GDB.GetValue("AdvUI\\LastMap\\Type")
			local c = GDB.GetString("AdvUI\\LastMap\\CampaignIndex")
			for _,m in ipairs(MapList.MapTable) do
				if m.Name == n and m.Type == t and m.CampaignIndex == c then
					MainmenuMaps.StartMapScroll:SetSelected(m, true)
					break
				end
			end
		end
	end

	MainmenuSaves.S00_ToLoadSaveGame = SPMenu.S00_ToLoadSaveGame
	---@diagnostic disable-next-line: duplicate-set-field
	function SPMenu.S00_ToLoadSaveGame()
		MainmenuSaves.S00_ToLoadSaveGame()
		XGUIEng.ShowWidget("SPM30_MapDetailsScreen", 1)
		SaveList.Init()
		MainmenuSaves.LoadSaveScroll:SetDataToScrollOver(SaveList.SaveGameTable)
		MainmenuSaves.LoadSaveScroll.OnSelectedChanged(nil, nil)
		CppLogic.UI.TextInputCustomWidgetSetText("SPM30_FilterInput", "")
		CppLogic.UI.InputCustomWidgetSetFocus("SPM30_FilterInput", true)
		local year, month, day, hour, min, sec = 0, 0, 0, 0, 0, 0
		local save = nil
		for _, s in ipairs(SaveList.SaveGameTable) do
			local y, mo, d, h, m, se = SaveList.ParseSaveDate(s)
			local n = false
			if y ~= year then
				n = y > year
			elseif mo ~= month then
				n = mo > month
			elseif d ~= day then
				n = d > day
			elseif h ~= hour then
				n = h > hour
			elseif m ~= min then
				n = m > min
			else
				n = se > sec
			end
			if n then
				year = y
				month = mo
				day = d
				hour = h
				min = m
				sec = s
				save = s
			end
		end
		if save then
			MainmenuSaves.LoadSaveScroll:SetSelected(save, true)
		end
	end

	---@diagnostic disable-next-line: duplicate-set-field
	function LoadSaveGame.Done()
		---@type MapListSave?
		local sel = MainmenuSaves.LoadSaveScroll:GetSelected()
		if not sel then
			return
		end
		Framework.LoadGame(sel.Save)
		LoadScreen_Init(1, sel.Save)
	end
end

function MainmenuMaps.Filter(filter)
	---@type MapListMap?
	local sel = MainmenuMaps.StartMapScroll:GetSelected()
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

	local selnew = nil
	for _,m in ipairs(l) do
		if m == sel then
			selnew = sel
		end
	end
	MainmenuMaps.StartMapScroll:SetDataToScrollOver(l)
	MainmenuMaps.StartMapScroll:SetSelected(selnew, true)
	XGUIEng.ShowWidget("SPM20_FilterClear", filter == "" and 0 or 1)
end

function MainmenuSaves.Filter(filter)
	---@type MapListSave?
	local sel = MainmenuSaves.LoadSaveScroll:GetSelected()
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

	local selnew = nil
	for _,m in ipairs(l) do
		if m == sel then
			selnew = sel
		end
	end
	MainmenuSaves.LoadSaveScroll:SetDataToScrollOver(l)
	MainmenuSaves.LoadSaveScroll:SetSelected(selnew, true)
	XGUIEng.ShowWidget("SPM30_FilterClear", filter == "" and 0 or 1)
end

table.insert(ModLoaderMainmenu.InitUICallbacks, function()
	MainmenuMaps.OverrideFuncs()
	local function rem(w)
		if CppLogic.UI.IsContainerWidget(w) then
			for _, c in ipairs(CppLogic.UI.ContainerWidgetGetAllChildren(w)) do
				rem(c)
			end
		end
		CppLogic.UI.RemoveWidget(w)
	end

	rem("SPM20_MapDetailsHeadline")
	rem("SPM20_MapList")
	rem("SPM20_DemoMapList")
	rem("SPM20_Headline")
	rem("SPM20_DemoLoadMap")

	rem("SPM30_MapDetailsHeadline")
	rem("SPM30_SaveGameList")
	rem("SPM30_Headline_old")


	if not CppLogic.UI.TextButtonSetCenterText then
		function CppLogic.UI.TextButtonSetCenterText() end
	end
	assert(XGUIEng.GetWidgetID("SPM20_Filter")==0, "SPM20_Filter already exists")
	assert(XGUIEng.GetWidgetID("SPM20_FilterInput")==0, "SPM20_FilterInput already exists")
	assert(XGUIEng.GetWidgetID("SPM20_FilterClear")==0, "SPM20_FilterClear already exists")
	assert(XGUIEng.GetWidgetID("SPM20_FilterInputBG")==0, "SPM20_FilterInputBG already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPMenu20", "SPM20_Filter", "SPM20_MapDetailsScreen")
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_Filter", 716, 79, 263, 28)
	XGUIEng.ShowWidget("SPM20_Filter", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_Filter", 100, false, false)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("SPM20_Filter", "SPM20_FilterInput", "CppLogic::Mod::UI::TextInputCustomWidget", nil, 0, 0, 0, 1, 1000, 0, "MainmenuMaps.Filter", "")
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_FilterInput", 0, 0, 220, 17)
	XGUIEng.ShowWidget("SPM20_FilterInput", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_FilterInput", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("SPM20_Filter", "SPM20_FilterClear", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_FilterClear", 234, 0, 17, 17)
	XGUIEng.ShowWidget("SPM20_FilterClear", 0)
	CppLogic.UI.WidgetSetBaseData("SPM20_FilterClear", 0, false, false)
	XGUIEng.DisableButton("SPM20_FilterClear", 0)
	XGUIEng.HighLightButton("SPM20_FilterClear", 0)
	CppLogic.UI.ButtonOverrideActionFunc("SPM20_FilterClear", function() MainmenuMaps.Filter(nil); CppLogic.UI.TextInputCustomWidgetSetText("SPM20_FilterInput", ""); end)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_FilterClear", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_FilterClear", 0, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM20_FilterClear", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_FilterClear", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_FilterClear", 1, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM20_FilterClear", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_FilterClear", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_FilterClear", 2, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM20_FilterClear", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_FilterClear", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_FilterClear", 3, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM20_FilterClear", 3, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_FilterClear", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_FilterClear", 4, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM20_FilterClear", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("SPM20_FilterClear", nil, false, false)
	CppLogic.UI.WidgetSetUpdateManualFlag("SPM20_FilterClear", true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_FilterClear", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_FilterClear", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("SPM20_Filter", "SPM20_FilterInputBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_FilterInputBG", 0, 0, 220, 17)
	XGUIEng.ShowWidget("SPM20_FilterInputBG", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_FilterInputBG", 0, false, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_FilterInputBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_FilterInputBG", 0, 0, 7, 12, 96)





	if not CppLogic.UI.TextButtonSetCenterText then
		function CppLogic.UI.TextButtonSetCenterText() end
	end
	assert(XGUIEng.GetWidgetID("SPM20_MapList")==0, "SPM20_MapList already exists")
	assert(XGUIEng.GetWidgetID("SPM20_MapSelectors")==0, "SPM20_MapSelectors already exists")
	assert(XGUIEng.GetWidgetID("SPM20_MapSelector")==0, "SPM20_MapSelector already exists")
	assert(XGUIEng.GetWidgetID("SPM20_Scoll")==0, "SPM20_Scoll already exists")
	assert(XGUIEng.GetWidgetID("SPM20_SliderTravel")==0, "SPM20_SliderTravel already exists")
	assert(XGUIEng.GetWidgetID("SPM20_SliderGfx")==0, "SPM20_SliderGfx already exists")
	assert(XGUIEng.GetWidgetID("SPM20_ScrollBar")==0, "SPM20_ScrollBar already exists")
	assert(XGUIEng.GetWidgetID("SPM20_MapNameUp")==0, "SPM20_MapNameUp already exists")
	assert(XGUIEng.GetWidgetID("SPM20_MapNameDown")==0, "SPM20_MapNameDown already exists")
	assert(XGUIEng.GetWidgetID("SPM20_SliderBG")==0, "SPM20_SliderBG already exists")
	assert(XGUIEng.GetWidgetID("SPM20_MapNameBG")==0, "SPM20_MapNameBG already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPMenu20", "SPM20_MapList", "SPM20_RightBG")
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_MapList", 0, 0, 1024, 768)
	XGUIEng.ShowWidget("SPM20_MapList", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_MapList", 10, false, false)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPM20_MapList", "SPM20_MapSelectors", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_MapSelectors", 717, 117, 256, 322)
	XGUIEng.ShowWidget("SPM20_MapSelectors", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_MapSelectors", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateTextButtonWidgetChild("SPM20_MapSelectors", "SPM20_MapSelector", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_MapSelector", 4, 4, 214, 20)
	XGUIEng.ShowWidget("SPM20_MapSelector", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_MapSelector", 0, false, false)
	CppLogic.UI.WidgetSetGroup("SPM20_MapSelector", "MapNames")
	XGUIEng.DisableButton("SPM20_MapSelector", 0)
	XGUIEng.HighLightButton("SPM20_MapSelector", 0)
	CppLogic.UI.ButtonOverrideActionFunc("SPM20_MapSelector", function() MainmenuMaps.StartMapScroll:GUIAction_DefaultSelect() end)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapSelector", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_MapSelector", 0, 151, 150, 151, 68)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapSelector", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_MapSelector", 1, 250, 214, 121, 128)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapSelector", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_MapSelector", 2, 150, 100, 50, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapSelector", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_MapSelector", 3, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapSelector", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_MapSelector", 4, 220, 170, 120, 255)
	CppLogic.UI.WidgetSetTooltipData("SPM20_MapSelector", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("SPM20_MapSelector", false)
	CppLogic.UI.WidgetOverrideUpdateFunc("SPM20_MapSelector", function() MainmenuMaps.StartMapScroll:GUIUpdate_DefaultSelect(true) end)
	CppLogic.UI.WidgetSetFont("SPM20_MapSelector", "data\\menu\\fonts\\standard10.met")
	CppLogic.UI.WidgetSetStringFrameDistance("SPM20_MapSelector", 0)
	XGUIEng.SetText("SPM20_MapSelector", "", 1)
	XGUIEng.SetTextColor("SPM20_MapSelector", 255, 255, 255, 255)
	CppLogic.UI.TextButtonSetCenterText("SPM20_MapSelector", true)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("SPM20_MapList", "SPM20_Scoll", "CppLogic::Mod::UI::AutoScrollCustomWidget", nil, 4, 0, 0, 0, 0, 0, "SPM20_SliderGfx", "SPM20_MapSelector")
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_Scoll", 0, 0, 1024, 768)
	XGUIEng.ShowWidget("SPM20_Scoll", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_Scoll", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPM20_MapList", "SPM20_SliderTravel", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_SliderTravel", 942, 154, 31, 242)
	XGUIEng.ShowWidget("SPM20_SliderTravel", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_SliderTravel", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("SPM20_SliderTravel", "SPM20_SliderGfx", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_SliderGfx", 5, 100, 23, 23)
	XGUIEng.ShowWidget("SPM20_SliderGfx", 0)
	CppLogic.UI.WidgetSetBaseData("SPM20_SliderGfx", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_SliderGfx", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_SliderGfx", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_handle.png")
	XGUIEng.SetMaterialColor("SPM20_SliderGfx", 0, 255, 255, 255, 255)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPM20_MapList", "SPM20_ScrollBar", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_ScrollBar", 942, 117, 51, 352)
	XGUIEng.ShowWidget("SPM20_ScrollBar", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_ScrollBar", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("SPM20_ScrollBar", "SPM20_MapNameUp", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_MapNameUp", 3, 3, 31, 42)
	XGUIEng.ShowWidget("SPM20_MapNameUp", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_MapNameUp", 1, false, false)
	XGUIEng.DisableButton("SPM20_MapNameUp", 0)
	XGUIEng.HighLightButton("SPM20_MapNameUp", 0)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameUp", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameUp", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameUp", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameUp", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameUp", 1, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up_hi.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameUp", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameUp", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameUp", 2, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up_sel.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameUp", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameUp", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameUp", 3, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameUp", 3, 128, 128, 128, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameUp", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameUp", 4, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameUp", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("SPM20_MapNameUp", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("SPM20_MapNameUp", false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameUp", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_MapNameUp", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("SPM20_ScrollBar", "SPM20_MapNameDown", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_MapNameDown", 3, 278, 31, 45)
	XGUIEng.ShowWidget("SPM20_MapNameDown", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_MapNameDown", 1, false, false)
	XGUIEng.DisableButton("SPM20_MapNameDown", 0)
	XGUIEng.HighLightButton("SPM20_MapNameDown", 0)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameDown", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameDown", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameDown", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameDown", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameDown", 1, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down_hi.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameDown", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameDown", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameDown", 2, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down_sel.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameDown", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameDown", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameDown", 3, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameDown", 3, 128, 128, 128, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameDown", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_MapNameDown", 4, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("SPM20_MapNameDown", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("SPM20_MapNameDown", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("SPM20_MapNameDown", false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameDown", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_MapNameDown", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("SPM20_ScrollBar", "SPM20_SliderBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_SliderBG", 1, 0, 31, 321)
	XGUIEng.ShowWidget("SPM20_SliderBG", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_SliderBG", 10, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_SliderBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM20_SliderBG", 0, "graphics\\textures\\gui\\mainmenu\\center_scroll_bg.png")
	XGUIEng.SetMaterialColor("SPM20_SliderBG", 0, 255, 255, 255, 255)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("SPM20_MapList", "SPM20_MapNameBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM20_MapNameBG", 717, 117, 256, 322)
	XGUIEng.ShowWidget("SPM20_MapNameBG", 1)
	CppLogic.UI.WidgetSetBaseData("SPM20_MapNameBG", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM20_MapNameBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM20_MapNameBG", 0, 0, 7, 12, 96)


	if not CppLogic.UI.TextButtonSetCenterText then
		function CppLogic.UI.TextButtonSetCenterText() end
	end
	assert(XGUIEng.GetWidgetID("SPM30_Filter")==0, "SPM30_Filter already exists")
	assert(XGUIEng.GetWidgetID("SPM30_FilterInput")==0, "SPM30_FilterInput already exists")
	assert(XGUIEng.GetWidgetID("SPM30_FilterClear")==0, "SPM30_FilterClear already exists")
	assert(XGUIEng.GetWidgetID("SPM30_FilterInputBG")==0, "SPM30_FilterInputBG already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPMenu30", "SPM30_Filter", "SPM30_MapDetailsScreen")
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_Filter", 716, 79, 263, 28)
	XGUIEng.ShowWidget("SPM30_Filter", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_Filter", 100, false, false)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("SPM30_Filter", "SPM30_FilterInput", "CppLogic::Mod::UI::TextInputCustomWidget", nil, 0, 0, 0, 1, 1000, 0, "MainmenuSaves.Filter", "")
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_FilterInput", 0, 0, 220, 17)
	XGUIEng.ShowWidget("SPM30_FilterInput", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_FilterInput", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("SPM30_Filter", "SPM30_FilterClear", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_FilterClear", 234, 0, 17, 17)
	XGUIEng.ShowWidget("SPM30_FilterClear", 0)
	CppLogic.UI.WidgetSetBaseData("SPM30_FilterClear", 0, false, false)
	XGUIEng.DisableButton("SPM30_FilterClear", 0)
	XGUIEng.HighLightButton("SPM30_FilterClear", 0)
	CppLogic.UI.ButtonOverrideActionFunc("SPM30_FilterClear", function() MainmenuSaves.Filter(nil); CppLogic.UI.TextInputCustomWidgetSetText("SPM30_FilterInput", ""); end)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_FilterClear", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_FilterClear", 0, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM30_FilterClear", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_FilterClear", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_FilterClear", 1, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM30_FilterClear", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_FilterClear", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_FilterClear", 2, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM30_FilterClear", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_FilterClear", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_FilterClear", 3, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM30_FilterClear", 3, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_FilterClear", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_FilterClear", 4, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("SPM30_FilterClear", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("SPM30_FilterClear", nil, false, false)
	CppLogic.UI.WidgetSetUpdateManualFlag("SPM30_FilterClear", true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_FilterClear", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_FilterClear", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("SPM30_Filter", "SPM30_FilterInputBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_FilterInputBG", 0, 0, 220, 17)
	XGUIEng.ShowWidget("SPM30_FilterInputBG", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_FilterInputBG", 0, false, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_FilterInputBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_FilterInputBG", 0, 0, 7, 12, 96)

	if not CppLogic.UI.TextButtonSetCenterText then
		function CppLogic.UI.TextButtonSetCenterText() end
	end
	assert(XGUIEng.GetWidgetID("SPM30_MapList")==0, "SPM30_MapList already exists")
	assert(XGUIEng.GetWidgetID("SPM30_MapSelectors")==0, "SPM30_MapSelectors already exists")
	assert(XGUIEng.GetWidgetID("SPM30_MapSelector")==0, "SPM30_MapSelector already exists")
	assert(XGUIEng.GetWidgetID("SPM30_Scoll")==0, "SPM30_Scoll already exists")
	assert(XGUIEng.GetWidgetID("SPM30_SliderTravel")==0, "SPM30_SliderTravel already exists")
	assert(XGUIEng.GetWidgetID("SPM30_SliderGfx")==0, "SPM30_SliderGfx already exists")
	assert(XGUIEng.GetWidgetID("SPM30_ScrollBar")==0, "SPM30_ScrollBar already exists")
	assert(XGUIEng.GetWidgetID("SPM30_MapNameUp")==0, "SPM30_MapNameUp already exists")
	assert(XGUIEng.GetWidgetID("SPM30_MapNameDown")==0, "SPM30_MapNameDown already exists")
	assert(XGUIEng.GetWidgetID("SPM30_SliderBG")==0, "SPM30_SliderBG already exists")
	assert(XGUIEng.GetWidgetID("SPM30_MapNameBG")==0, "SPM30_MapNameBG already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPMenu30", "SPM30_MapList", "SPM30_RightBG")
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_MapList", 0, 0, 1024, 768)
	XGUIEng.ShowWidget("SPM30_MapList", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_MapList", 10, false, false)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPM30_MapList", "SPM30_MapSelectors", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_MapSelectors", 717, 117, 256, 322)
	XGUIEng.ShowWidget("SPM30_MapSelectors", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_MapSelectors", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateTextButtonWidgetChild("SPM30_MapSelectors", "SPM30_MapSelector", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_MapSelector", 4, 4, 214, 20)
	XGUIEng.ShowWidget("SPM30_MapSelector", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_MapSelector", 0, false, false)
	CppLogic.UI.WidgetSetGroup("SPM30_MapSelector", "MapNames")
	XGUIEng.DisableButton("SPM30_MapSelector", 0)
	XGUIEng.HighLightButton("SPM30_MapSelector", 0)
	CppLogic.UI.ButtonOverrideActionFunc("SPM30_MapSelector", function() MainmenuSaves.LoadSaveScroll:GUIAction_DefaultSelect() end)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapSelector", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_MapSelector", 0, 151, 150, 151, 68)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapSelector", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_MapSelector", 1, 250, 214, 121, 128)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapSelector", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_MapSelector", 2, 150, 100, 50, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapSelector", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_MapSelector", 3, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapSelector", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_MapSelector", 4, 220, 170, 120, 255)
	CppLogic.UI.WidgetSetTooltipData("SPM30_MapSelector", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("SPM30_MapSelector", false)
	CppLogic.UI.WidgetOverrideUpdateFunc("SPM30_MapSelector", function() MainmenuSaves.LoadSaveScroll:GUIUpdate_DefaultSelect(true) end)
	CppLogic.UI.WidgetSetFont("SPM30_MapSelector", "data\\menu\\fonts\\standard10.met")
	CppLogic.UI.WidgetSetStringFrameDistance("SPM30_MapSelector", 0)
	XGUIEng.SetText("SPM30_MapSelector", "", 1)
	XGUIEng.SetTextColor("SPM30_MapSelector", 255, 255, 255, 255)
	CppLogic.UI.TextButtonSetCenterText("SPM30_MapSelector", true)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("SPM30_MapList", "SPM30_Scoll", "CppLogic::Mod::UI::AutoScrollCustomWidget", nil, 4, 0, 0, 0, 0, 0, "SPM30_SliderGfx", "SPM30_MapSelector")
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_Scoll", 0, 0, 1024, 768)
	XGUIEng.ShowWidget("SPM30_Scoll", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_Scoll", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPM30_MapList", "SPM30_SliderTravel", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_SliderTravel", 942, 154, 31, 242)
	XGUIEng.ShowWidget("SPM30_SliderTravel", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_SliderTravel", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("SPM30_SliderTravel", "SPM30_SliderGfx", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_SliderGfx", 5, 100, 23, 23)
	XGUIEng.ShowWidget("SPM30_SliderGfx", 0)
	CppLogic.UI.WidgetSetBaseData("SPM30_SliderGfx", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_SliderGfx", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_SliderGfx", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_handle.png")
	XGUIEng.SetMaterialColor("SPM30_SliderGfx", 0, 255, 255, 255, 255)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("SPM30_MapList", "SPM30_ScrollBar", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_ScrollBar", 942, 117, 51, 352)
	XGUIEng.ShowWidget("SPM30_ScrollBar", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_ScrollBar", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("SPM30_ScrollBar", "SPM30_MapNameUp", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_MapNameUp", 3, 3, 31, 42)
	XGUIEng.ShowWidget("SPM30_MapNameUp", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_MapNameUp", 1, false, false)
	XGUIEng.DisableButton("SPM30_MapNameUp", 0)
	XGUIEng.HighLightButton("SPM30_MapNameUp", 0)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameUp", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameUp", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameUp", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameUp", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameUp", 1, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up_hi.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameUp", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameUp", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameUp", 2, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up_sel.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameUp", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameUp", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameUp", 3, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameUp", 3, 128, 128, 128, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameUp", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameUp", 4, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameUp", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("SPM30_MapNameUp", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("SPM30_MapNameUp", false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameUp", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_MapNameUp", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("SPM30_ScrollBar", "SPM30_MapNameDown", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_MapNameDown", 3, 278, 31, 45)
	XGUIEng.ShowWidget("SPM30_MapNameDown", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_MapNameDown", 1, false, false)
	XGUIEng.DisableButton("SPM30_MapNameDown", 0)
	XGUIEng.HighLightButton("SPM30_MapNameDown", 0)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameDown", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameDown", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameDown", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameDown", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameDown", 1, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down_hi.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameDown", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameDown", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameDown", 2, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down_sel.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameDown", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameDown", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameDown", 3, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameDown", 3, 128, 128, 128, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameDown", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_MapNameDown", 4, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("SPM30_MapNameDown", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("SPM30_MapNameDown", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("SPM30_MapNameDown", false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameDown", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_MapNameDown", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("SPM30_ScrollBar", "SPM30_SliderBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_SliderBG", 1, 0, 31, 321)
	XGUIEng.ShowWidget("SPM30_SliderBG", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_SliderBG", 10, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_SliderBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("SPM30_SliderBG", 0, "graphics\\textures\\gui\\mainmenu\\center_scroll_bg.png")
	XGUIEng.SetMaterialColor("SPM30_SliderBG", 0, 255, 255, 255, 255)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("SPM30_MapList", "SPM30_MapNameBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("SPM30_MapNameBG", 717, 117, 256, 322)
	XGUIEng.ShowWidget("SPM30_MapNameBG", 1)
	CppLogic.UI.WidgetSetBaseData("SPM30_MapNameBG", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("SPM30_MapNameBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("SPM30_MapNameBG", 0, 0, 7, 12, 96)


	MainmenuMaps.StartMapScroll:Setup()
	MainmenuSaves.LoadSaveScroll:Setup()
end)
