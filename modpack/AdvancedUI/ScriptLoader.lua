Script.Load("Data\\Script\\Common\\MapList.lua")
Script.Load("Data\\Script\\Common\\SaveList.lua")
Script.Load("Data\\Script\\InterfaceTools\\AutoScroll.lua")

AdvancedUI = {}

---@type CPPLAutoScroll<MapListSave>
AdvancedUI.DoSaveScroll = AutoScroll.Init("MainMenuSave_Scoll", "MainMenuSave_MapNameUp", "MainMenuSave_MapNameDown", "MainMenuSave_ScrollBar", true)

---@param m MapListSave
---@return string
function AdvancedUI.DoSaveScroll.StringExtract(m)
	local r = m.Desc ~= "" and m.Desc or m.Save
	if m.SlotNumber then
		r = m.SlotNumber .. " - " .. r
	end
	return r
end

function AdvancedUI.CanNotSave()
	return XNetwork ~= nil and XNetwork.Manager_DoesExist() == 1
end

function AdvancedUI.InitSave()
	SaveList.InitCreate(5)
	AdvancedUI.DoSaveScroll:SetDataToScrollOver(SaveList.SaveGameCreateTable)
	CppLogic.UI.TextInputCustomWidgetSetText("MainMenuSave_NameInput", "")
	CppLogic.UI.InputCustomWidgetSetFocus("MainMenuSave_NameInput", true)
end

function AdvancedUI.OnNameInputChanged()

end

function AdvancedUI.CreateSaveName()
	local name = Framework.GetCurrentMapName()
	local t, cn = Framework.GetCurrentMapTypeAndCampaignName()
	local title = Framework.GetMapNameAndDescription( name, t, cn )
	local d = title
	if d == nil or d == "" then
		d = name
	end
	local extra = CppLogic.UI.TextInputCustomWidgetGetText("MainMenuSave_NameInput")
	d = d .. " - " .. extra .. " - " .. Framework.GetSystemTimeDateString()
	return d
end

function AdvancedUI.DoSaveGame()
	if AdvancedUI.CanNotSave() then
		return
	end
	---@type MapListSave?
	local s = AdvancedUI.DoSaveScroll:GetElementOf(XGUIEng.GetCurrentWidgetID())
	if not s then
		return
	end
	local saveName = AdvancedUI.CreateSaveName()

	if s.Name == "" then
		---@diagnostic disable-next-line: undefined-global
		if FrameworkWrapper then
			---@diagnostic disable-next-line: undefined-global
			FrameworkWrapper.Savegame.DoSave(s.Save, saveName)
		else
			Framework.SaveGame(s.Save, saveName)
		end
		GUI.AddNote(XGUIEng.GetStringTableText("InGameMessages/GUI_GameSaved"))
		GUIAction_ToggleMenu(XGUIEng.GetWidgetID("MainMenuWindow"), 0)
	else
		MainWindow_SaveGame_SaveGameName = s.Save
		MainWindow_SaveGame_SaveGameDescOld = s.Desc
		MainWindow_SaveGame_SaveGameDescNew = saveName
		GUIAction_ToggleMenu("MainMenuBoxOverwriteWindow", 1)
	end
end

function AdvancedUI.InitUI()
	MainWindow_SaveGame_GenerateList = AdvancedUI.InitSave
	local function rem(w)
		if CppLogic.UI.IsContainerWidget(w) then
			for _, c in ipairs(CppLogic.UI.ContainerWidgetGetAllChildren(w)) do
				rem(c)
			end
		end
		CppLogic.UI.RemoveWidget(w)
	end

	rem("MainMenuSaveGameFileRequester")

	if not CppLogic.UI.TextButtonSetCenterText then
		function CppLogic.UI.TextButtonSetCenterText() end
	end
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapList")==0, "MainMenuSave_MapList already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapSelectors")==0, "MainMenuSave_MapSelectors already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapSelector")==0, "MainMenuSave_MapSelector already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_Scoll")==0, "MainMenuSave_Scoll already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_SliderTravel")==0, "MainMenuSave_SliderTravel already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_SliderGfx")==0, "MainMenuSave_SliderGfx already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_ScrollBar")==0, "MainMenuSave_ScrollBar already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapNameUp")==0, "MainMenuSave_MapNameUp already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapNameDown")==0, "MainMenuSave_MapNameDown already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_ScrollBGInterior")==0, "MainMenuSave_ScrollBGInterior already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_ScrollBG")==0, "MainMenuSave_ScrollBG already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapNameBG")==0, "MainMenuSave_MapNameBG already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuSaveWindow", "MainMenuSave_MapList", "MainMenuSaveBG")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_MapList", 174.5, 38, 475, 272)
	XGUIEng.ShowWidget("MainMenuSave_MapList", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_MapList", 10, false, false)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuSave_MapList", "MainMenuSave_MapSelectors", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_MapSelectors", 4, 6, 420, 259)
	XGUIEng.ShowWidget("MainMenuSave_MapSelectors", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_MapSelectors", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateTextButtonWidgetChild("MainMenuSave_MapSelectors", "MainMenuSave_MapSelector", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_MapSelector", 4, 4, 412, 20)
	XGUIEng.ShowWidget("MainMenuSave_MapSelector", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_MapSelector", 0, false, false)
	CppLogic.UI.WidgetSetGroup("MainMenuSave_MapSelector", "MapNames")
	XGUIEng.DisableButton("MainMenuSave_MapSelector", 0)
	XGUIEng.HighLightButton("MainMenuSave_MapSelector", 0)
	CppLogic.UI.ButtonOverrideActionFunc("MainMenuSave_MapSelector", function() AdvancedUI.DoSaveGame() end)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapSelector", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_MapSelector", 0, 151, 150, 151, 68)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapSelector", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_MapSelector", 1, 250, 214, 121, 128)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapSelector", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_MapSelector", 2, 150, 100, 50, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapSelector", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_MapSelector", 3, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapSelector", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_MapSelector", 4, 220, 170, 120, 255)
	CppLogic.UI.WidgetSetTooltipData("MainMenuSave_MapSelector", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("MainMenuSave_MapSelector", false)
	CppLogic.UI.WidgetOverrideUpdateFunc("MainMenuSave_MapSelector", function() AdvancedUI.DoSaveScroll:GUIUpdate_DefaultSelect(true) end)
	CppLogic.UI.WidgetSetFont("MainMenuSave_MapSelector", "data\\menu\\fonts\\standard10.met")
	CppLogic.UI.WidgetSetStringFrameDistance("MainMenuSave_MapSelector", 0)
	XGUIEng.SetText("MainMenuSave_MapSelector", "", 1)
	XGUIEng.SetTextColor("MainMenuSave_MapSelector", 255, 255, 255, 255)
	CppLogic.UI.TextButtonSetCenterText("MainMenuSave_MapSelector", true)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("MainMenuSave_MapList", "MainMenuSave_Scoll", "CppLogic::Mod::UI::AutoScrollCustomWidget", nil, 4, 0, 0, 0, 0, 0, "MainMenuSave_SliderGfx", "MainMenuSave_MapSelector")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_Scoll", 0, 0, 461, 261)
	XGUIEng.ShowWidget("MainMenuSave_Scoll", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_Scoll", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuSave_MapList", "MainMenuSave_SliderTravel", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_SliderTravel", 427, 42, 37, 180)
	XGUIEng.ShowWidget("MainMenuSave_SliderTravel", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_SliderTravel", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuSave_SliderTravel", "MainMenuSave_SliderGfx", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_SliderGfx", 5, 100, 23, 23)
	XGUIEng.ShowWidget("MainMenuSave_SliderGfx", 0)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_SliderGfx", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_SliderGfx", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_SliderGfx", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_handle.png")
	XGUIEng.SetMaterialColor("MainMenuSave_SliderGfx", 0, 255, 255, 255, 255)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuSave_MapList", "MainMenuSave_ScrollBar", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_ScrollBar", 425, 6, 41, 259)
	XGUIEng.ShowWidget("MainMenuSave_ScrollBar", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_ScrollBar", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("MainMenuSave_ScrollBar", "MainMenuSave_MapNameUp", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_MapNameUp", 5, 0, 36, 42)
	XGUIEng.ShowWidget("MainMenuSave_MapNameUp", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_MapNameUp", 0, false, false)
	XGUIEng.DisableButton("MainMenuSave_MapNameUp", 0)
	XGUIEng.HighLightButton("MainMenuSave_MapNameUp", 0)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameUp", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameUp", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameUp", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameUp", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameUp", 1, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up_hi.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameUp", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameUp", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameUp", 2, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up_sel.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameUp", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameUp", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameUp", 3, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameUp", 3, 128, 128, 128, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameUp", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameUp", 4, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameUp", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("MainMenuSave_MapNameUp", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("MainMenuSave_MapNameUp", false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameUp", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameUp", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("MainMenuSave_ScrollBar", "MainMenuSave_MapNameDown", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_MapNameDown", 5, 217, 36, 42)
	XGUIEng.ShowWidget("MainMenuSave_MapNameDown", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_MapNameDown", 0, false, false)
	XGUIEng.DisableButton("MainMenuSave_MapNameDown", 0)
	XGUIEng.HighLightButton("MainMenuSave_MapNameDown", 0)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameDown", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameDown", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameDown", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameDown", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameDown", 1, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down_hi.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameDown", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameDown", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameDown", 2, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down_sel.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameDown", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameDown", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameDown", 3, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameDown", 3, 128, 128, 128, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameDown", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuSave_MapNameDown", 4, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameDown", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("MainMenuSave_MapNameDown", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("MainMenuSave_MapNameDown", false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameDown", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameDown", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuSave_ScrollBar", "MainMenuSave_ScrollBGInterior", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_ScrollBGInterior", 7, 9, 23, 239)
	XGUIEng.ShowWidget("MainMenuSave_ScrollBGInterior", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_ScrollBGInterior", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_ScrollBGInterior", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_ScrollBGInterior", 0, 255, 255, 255, 64)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuSave_ScrollBar", "MainMenuSave_ScrollBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_ScrollBG", 0, 0, 37, 259)
	XGUIEng.ShowWidget("MainMenuSave_ScrollBG", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_ScrollBG", 0, false, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_ScrollBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_ScrollBG", 0, 0, 0, 0, 192)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuSave_MapList", "MainMenuSave_MapNameBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_MapNameBG", 4, 6, 420, 259)
	XGUIEng.ShowWidget("MainMenuSave_MapNameBG", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_MapNameBG", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_MapNameBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_MapNameBG", 0, 0, 0, 0, 192)

	if not CppLogic.UI.TextButtonSetCenterText then
		function CppLogic.UI.TextButtonSetCenterText() end
	end
	assert(XGUIEng.GetWidgetID("MainMenuSave_Name")==0, "MainMenuSave_Name already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_NameInput")==0, "MainMenuSave_NameInput already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_NameBG")==0, "MainMenuSave_NameBG already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuSaveWindow", "MainMenuSave_Name", "MainMenuSaveBG")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_Name", 178.5, 325, 420, 28)
	XGUIEng.ShowWidget("MainMenuSave_Name", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_Name", 100, false, false)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("MainMenuSave_Name", "MainMenuSave_NameInput", "CppLogic::Mod::UI::TextInputCustomWidget", nil, 0, 0, 0, 1, 1000, 0, "AdvancedUI.OnNameInputChanged", "")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_NameInput", 0, 0, 420, 17)
	XGUIEng.ShowWidget("MainMenuSave_NameInput", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_NameInput", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuSave_Name", "MainMenuSave_NameBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_NameBG", 0, 0, 420, 17)
	XGUIEng.ShowWidget("MainMenuSave_NameBG", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_NameBG", 0, false, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_NameBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_NameBG", 0, 0, 0, 0, 192)




	AdvancedUI.DoSaveScroll:Setup()
end

CppLogic.API.EnableScriptTriggerEval(true)
Trigger.RequestTrigger(Events.CPPLOGIC_EVENT_ON_MAP_STARTED, nil, "AdvancedUI.InitUI", 1)
Trigger.RequestTrigger(Events.CPPLOGIC_EVENT_ON_SAVEGAME_LOADED, nil, "AdvancedUI.InitUI", 1)
