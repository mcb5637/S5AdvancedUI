Script.Load("Data\\Script\\Common\\MapList.lua")
Script.Load("Data\\Script\\Common\\SaveList.lua")
if not AutoScroll then
	Script.Load("Data\\Script\\InterfaceTools\\AutoScroll.lua")
end

AdvancedUI = {}

---@type CPPLAutoScroll<MapListSave>
AdvancedUI.DoSaveScroll = AutoScroll.Init("MainMenuSave_Scoll", "MainMenuSave_MapNameUp", "MainMenuSave_MapNameDown", "MainMenuSave_ScrollBar", true)
---@type CPPLAutoScroll<MapListSave>
AdvancedUI.LoadSaveScroll = AutoScroll.Init("MainMenuLoad_Scoll", "MainMenuLoad_MapNameUp", "MainMenuLoad_MapNameDown", "MainMenuLoad_ScrollBar", true)
---@type CPPLAutoScroll<number>
AdvancedUI.MultiselectionScroll = AutoScroll.Init("MultiSelectionScroll", nil, nil, nil, true)

---@param m MapListSave
---@return string
function AdvancedUI.DoSaveScroll.StringExtract(m)
	local r = m.Desc ~= "" and m.Desc or m.Save
	if m.SlotNumber then
		r = m.SlotNumber.." - "..r
	end
	return r
end

---@param m MapListSave
---@return string
function AdvancedUI.LoadSaveScroll.StringExtract(m)
	return m.Desc ~= "" and m.Desc or m.Save
end

---@diagnostic disable-next-line: duplicate-set-field
function AdvancedUI.CanNotSave()
	return XNetwork ~= nil and XNetwork.Manager_DoesExist() == 1
end

function AdvancedUI.InitSave()
	SaveList.InitCreate(5)
	AdvancedUI.DoSaveScroll:SetDataToScrollOver(SaveList.SaveGameCreateTable)
	CppLogic.UI.TextInputCustomWidgetSetText("MainMenuSave_NameInput", "")
	CppLogic.UI.InputCustomWidgetSetFocus("MainMenuSave_NameInput", true)
end

function AdvancedUI.InitLoad()
	SaveList.Init()
	AdvancedUI.LoadSaveScroll:SetDataToScrollOver(SaveList.SaveGameTable)
end

function AdvancedUI.OnNameInputChanged()

end

function AdvancedUI.CreateSaveName()
	local name = Framework.GetCurrentMapName()
	local t, cn = Framework.GetCurrentMapTypeAndCampaignName()
	local title = Framework.GetMapNameAndDescription(name, t, cn)
	local d = title
	if d == nil or d == "" then
		d = name
	end
	local extra = CppLogic.UI.TextInputCustomWidgetGetText("MainMenuSave_NameInput")
	if extra == "" then
		d = d.." - "..Framework.GetSystemTimeDateString()
	else
		d = extra.." - "..d.." - "..Framework.GetSystemTimeDateString()
	end
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

function AdvancedUI.LoadSave()
	---@type MapListSave?
	local s = AdvancedUI.LoadSaveScroll:GetElementOf(XGUIEng.GetCurrentWidgetID())
	if not s or not Framework.IsSaveGameValid(s.Save) then
		return
	end
	---@diagnostic disable-next-line: undefined-global
	if FrameworkWrapper then
		---@diagnostic disable-next-line: undefined-global
		FrameworkWrapper.Savegame.LoadSave(s.Save)
	else
		Framework.LoadGame(s.Save)
	end
	GUIAction_ToggleMenu(XGUIEng.GetWidgetID("MainMenuWindow"), 0)
end

---@param filter string?
function AdvancedUI.FilterLoad(filter)
	local l = SaveList.ApplyFilter(filter)
	AdvancedUI.LoadSaveScroll:SetDataToScrollOver(l)
	XGUIEng.ShowWidget("MainMenuLoad_FilterClear", filter == "" and 0 or 1)
end

function AdvancedUI.OnMarketInputChanged(txt, widget)
	local rt = XGUIEng.GetBaseWidgetUserVariable(widget, 0)
	local num = tonumber(txt)
	if not num then
		return
	end
	if rt == ResourceType.Gold then
		gvGUI.MarketMoneyToBuy = num
	elseif rt == ResourceType.Wood then
		gvGUI.MarketWoodToBuy = num
	elseif rt == ResourceType.Clay then
		gvGUI.MarketClayToBuy = num
	elseif rt == ResourceType.Stone then
		gvGUI.MarketStoneToBuy = num
	elseif rt == ResourceType.Iron then
		gvGUI.MarketIronToBuy = num
	elseif rt == ResourceType.Sulfur then
		gvGUI.MarketSulfurToBuy = num
	end
end

function AdvancedUI.RewriteInputs()
	CppLogic.UI.TextInputCustomWidgetSetText("Trade_Market_MoneyAmount", tostring(gvGUI.MarketMoneyToBuy))
	CppLogic.UI.TextInputCustomWidgetSetText("Trade_Market_WoodAmount", tostring(gvGUI.MarketWoodToBuy))
	CppLogic.UI.TextInputCustomWidgetSetText("Trade_Market_ClayAmount", tostring(gvGUI.MarketClayToBuy))
	CppLogic.UI.TextInputCustomWidgetSetText("Trade_Market_StoneAmount", tostring(gvGUI.MarketStoneToBuy))
	CppLogic.UI.TextInputCustomWidgetSetText("Trade_Market_IronAmount", tostring(gvGUI.MarketIronToBuy))
	CppLogic.UI.TextInputCustomWidgetSetText("Trade_Market_SulfurAmount", tostring(gvGUI.MarketSulfurToBuy))
end

function AdvancedUI.InitMarketUI()
	for _, d in ipairs{
		{
			Name = "Trade_Market_MoneyAmount",
			ResourceType = ResourceType.Gold,
			Parent = "Trade_Market_BuyMoney",
			Before = "Trade_BG_Money",
			Add = "Trade_Market_IncreaseMoney",
			Sub = "Trade_Market_DecreaseMoney",
		},
		{
			Name = "Trade_Market_ClayAmount",
			ResourceType = ResourceType.Clay,
			Parent = "Trade_Market_BuyClay",
			Before = "Trade_BG_Clay",
			Add = "Trade_Market_IncreaseClay",
			Sub = "Trade_Market_DecreaseClay",
		},
		{
			Name = "Trade_Market_WoodAmount",
			ResourceType = ResourceType.Wood,
			Parent = "Trade_Market_BuyWood",
			Before = "Trade_BG_Wood",
			Add = "Trade_Market_IncreaseWood",
			Sub = "Trade_Market_DecreaseWood",
		},
		{
			Name = "Trade_Market_StoneAmount",
			ResourceType = ResourceType.Stone,
			Parent = "Trade_Market_BuyStone",
			Before = "Trade_BG_Stone",
			Add = "Trade_Market_IncreaseStone",
			Sub = "Trade_Market_DecreaseStone",
		},
		{
			Name = "Trade_Market_IronAmount",
			ResourceType = ResourceType.Iron,
			Parent = "Trade_Market_BuyIron",
			Before = "Trade_BG_Iron",
			Add = "Trade_Market_IncreaseIron",
			Sub = "Trade_Market_DecreaseIron",
		},
		{
			Name = "Trade_Market_SulfurAmount",
			ResourceType = ResourceType.Sulfur,
			Parent = "Trade_Market_BuySulfur",
			Before = "Trade_BG_Sulfur",
			Add = "Trade_Market_IncreaseSulfur",
			Sub = "Trade_Market_DecreaseSulfur",
		},
	} do
		local x, y, w, h = CppLogic.UI.WidgetGetPositionAndSize(d.Name)
		CppLogic.UI.RemoveWidget(d.Name)

		assert(XGUIEng.GetWidgetID(d.Name) == 0, "Trade_Market_MoneyAmount already exists")
		CppLogic.UI.ContainerWidgetCreateCustomWidgetChild(d.Parent, d.Name, "CppLogic::Mod::UI::TextInputCustomWidget", d.Before, 4, 0, -1, 0, 0, 100,
														   "AdvancedUI.OnMarketInputChanged", "data\\menu\\fonts\\standard10.met")
		CppLogic.UI.WidgetSetPositionAndSize(d.Name, x, y, w, h)
		XGUIEng.ShowWidget(d.Name, 1)
		CppLogic.UI.WidgetSetBaseData(d.Name, 0, false, false)

		XGUIEng.SetBaseWidgetUserVariable(d.Name, 0, d.ResourceType)

		local stra = CppLogic.UI.ButtonGetActionFunc(d.Add)
		local fadd = CppLogic.API.Eval(stra)
		CppLogic.UI.ButtonOverrideActionFunc(d.Add, function()
			fadd()
			AdvancedUI.RewriteInputs()
		end)
		local strs = CppLogic.UI.ButtonGetActionFunc(d.Sub)
		local fsub = CppLogic.API.Eval(strs)
		CppLogic.UI.ButtonOverrideActionFunc(d.Sub, function()
			fsub()
			AdvancedUI.RewriteInputs()
		end)
	end
end

function AdvancedUI.InitMarketOverrides()
	AdvancedUI.GUIAction_MarketClearDeals = GUIAction_MarketClearDeals
	function GUIAction_MarketClearDeals()
		AdvancedUI.GUIAction_MarketClearDeals()
		AdvancedUI.RewriteInputs()
		CppLogic.UI.InputCustomWidgetSetFocus("Trade_Market_MoneyAmount", false)
		CppLogic.UI.InputCustomWidgetSetFocus("Trade_Market_WoodAmount", false)
		CppLogic.UI.InputCustomWidgetSetFocus("Trade_Market_ClayAmount", false)
		CppLogic.UI.InputCustomWidgetSetFocus("Trade_Market_StoneAmount", false)
		CppLogic.UI.InputCustomWidgetSetFocus("Trade_Market_IronAmount", false)
		CppLogic.UI.InputCustomWidgetSetFocus("Trade_Market_SulfurAmount", false)
	end

	AdvancedUI.GUAction_MarketAcceptDeal = GUAction_MarketAcceptDeal
	function GUAction_MarketAcceptDeal(selltype)
		if XGUIEng.IsModifierPressed(Keys.ModifierControl) == 1 then
			local markets = {}
			for id in CppLogic.Entity.PlayerEntityIterator(CppLogic.Entity.Predicates.OfType(Entities.PB_Market2), GUI.GetPlayerID()) do
				if Logic.GetTransactionProgress(id) == 100 then
					table.insert(markets, id)
				end
			end
			local sellam = InterfaceTool_MarketGetSellAmount(selltype)
			local c = {}

			c[selltype] = sellam * table.getn(markets)

			if InterfaceTool_HasPlayerEnoughResources_Feedback(c) == 1 then
				local buyty, buyam = InterfaceTool_MarketGetBuyResourceTypeAndAmount()
				for _, id in ipairs(markets) do
					---@diagnostic disable-next-line: param-type-mismatch
					GUI.StartTransaction(id, selltype, buyty, buyam)
				end
				XGUIEng.ShowWidget(gvGUI_WidgetID.TradeInProgress, 1)
			end
		else
			AdvancedUI.GUAction_MarketAcceptDeal(selltype)
		end
	end

	AdvancedUI.GUIUpdate_CannonProgress = GUIUpdate_CannonProgress
	function GUIUpdate_CannonProgress()
		AdvancedUI.GUIUpdate_CannonProgress()
		local id = GUI.GetSelectedEntity()
		if IsValid(id) then
			local ty = CppLogic.Entity.Building.FoundryGetCannonTypeInConstruction(id)
			if ty == Entities.PV_Cannon1 then
				CppLogic.UI.WidgetMaterialSetTextureCoordinates("CannonProgressType", 0, 0, 0, 0.25, 0.125)
			elseif ty == Entities.PV_Cannon2 then
				CppLogic.UI.WidgetMaterialSetTextureCoordinates("CannonProgressType", 0, 0, 0.125, 0.25, 0.125)
			elseif ty == Entities.PV_Cannon3 then
				CppLogic.UI.WidgetMaterialSetTextureCoordinates("CannonProgressType", 0, 0, 0.25, 0.25, 0.125)
			elseif ty == Entities.PV_Cannon4 then
				CppLogic.UI.WidgetMaterialSetTextureCoordinates("CannonProgressType", 0, 0, 0.375, 0.25, 0.125)
			end
		end
	end
end

function AdvancedUI.GUIAction_UpdateMultiSelectionContainer()
	local s = {GUI.GetSelectedEntities()}
	AdvancedUI.MultiselectionScroll:SetDataToScrollOver(s)
end

function AdvancedUI.GetResIconString(rt)
	if rt == ResourceType.Gold or rt == ResourceType.GoldRaw then
		return "@icon:graphics\\textures\\gui\\i_res_gold_large,0.0625,0,0.875,0.71875,2,2,255,255,255,a|"
	elseif rt == ResourceType.Wood or rt == ResourceType.WoodRaw then
		return "@icon:graphics\\textures\\gui\\i_res_wood_large,0.0625,0,0.875,0.875,2,2,255,255,255,a|"
	elseif rt == ResourceType.Clay or rt == ResourceType.ClayRaw then
		return "@icon:graphics\\textures\\gui\\i_res_mud_large,0.0625,0,0.875,0.71875,2,2,255,255,255,a|"
	elseif rt == ResourceType.Stone or rt == ResourceType.StoneRaw then
		return "@icon:graphics\\textures\\gui\\i_res_stone_large,0.0625,0,0.875,0.8125,2,2,255,255,255,a|"
	elseif rt == ResourceType.Iron or rt == ResourceType.IronRaw then
		return "@icon:graphics\\textures\\gui\\i_res_iron_large,0.0625,0,0.875,0.71875,2,2,255,255,255,a|"
	elseif rt == ResourceType.Sulfur or rt == ResourceType.SulfurRaw then
		return "@icon:graphics\\textures\\gui\\i_res_sulfur_large,0.0625,0,0.875,0.71875,2,2,255,255,255,a|"
	else
		return ""
	end
end

function AdvancedUI.GUIUpdate_MarketTradeStatus()
	local id = GUI.GetSelectedEntity()
	local txt = ""
	if IsValid(id) and Logic.GetEntityType(id) == Entities.PB_Market2 then
		local bt, st, ba, sa = CppLogic.Entity.Building.MarketGetCurrentTradeData(id)
		txt = AdvancedUI.GetResIconString(st).." "..sa.." -> "..AdvancedUI.GetResIconString(bt).." "..ba
	end
	XGUIEng.SetText(XGUIEng.GetCurrentWidgetID(), txt)
end

---@param button number
---@param entity number
function AdvancedUI.UpdateMultiselectionButton(button, entity)
	local hero = HeroSelection_GetCurrentSelectedHeroID()

	local src

	if Logic.IsEntityInCategory(entity, EntityCategories.Hero1) == 1 then
		src = "MultiSelectionSource_Hero1"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.Hero2) == 1 then
		src = "MultiSelectionSource_Hero2"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.Hero3) == 1 then
		src = "MultiSelectionSource_Hero3"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.Hero4) == 1 then
		src = "MultiSelectionSource_Hero4"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.Hero5) == 1 then
		src = "MultiSelectionSource_Hero5"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.Hero6) == 1 then
		src = "MultiSelectionSource_Hero6"
	elseif Logic.GetEntityType(entity) == Entities.CU_BlackKnight then
		src = "MultiSelectionSource_Hero7"
	elseif Logic.GetEntityType(entity) == Entities.CU_Mary_de_Mortfichet then
		src = "MultiSelectionSource_Hero8"
	elseif Logic.GetEntityType(entity) == Entities.CU_Barbarian_Hero then
		src = "MultiSelectionSource_Hero9"
	elseif Logic.GetEntityType(entity) == Entities.PU_Serf then
		src = "MultiSelectionSource_Serf"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.Sword) == 1 then
		src = "MultiSelectionSource_Sword"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.Bow) == 1 then
		src = "MultiSelectionSource_Bow"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.Spear) == 1 then
		src = "MultiSelectionSource_Spear"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.Cannon) == 1 then
		src = "MultiSelectionSource_Cannon"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.CavalryHeavy) == 1 then
		src = "MultiSelectionSource_HeavyCav"
	elseif Logic.IsEntityInCategory(entity, EntityCategories.CavalryLight) == 1 then
		src = "MultiSelectionSource_LightCav"
	elseif EntityCategories.Rifle and Logic.IsEntityInCategory(entity, EntityCategories.Rifle) == 1
		and Logic.IsEntityInCategory(entity, EntityCategories.Hero10) == 0 then
		src = "MultiSelectionSource_Rifle"
	elseif Logic.GetEntityType(entity) == Entities.PU_Scout then
		src = "MultiSelectionSource_Scout"
	elseif Logic.GetEntityType(entity) == Entities.PU_Thief then
		src = "MultiSelectionSource_Thief"
	elseif EntityCategories.Hero10 and Logic.IsEntityInCategory(entity, EntityCategories.Hero10) == 1 then
		src = "MultiSelectionSource_Hero10"
	elseif EntityCategories.Hero11 and Logic.IsEntityInCategory(entity, EntityCategories.Hero11) == 1 then
		src = "MultiSelectionSource_Hero11"
	elseif Logic.GetEntityType(entity) == Entities.CU_Evil_Queen then
		src = "MultiSelectionSource_Hero12"
	else
		src = "MultiSelectionSource_Sword"
	end

	XGUIEng.TransferMaterials(src, button)

	if hero == entity then
		for i = 0, 4 do
			XGUIEng.SetMaterialColor(button, i, 255, 177, 0, 255)
		end
	else
		for i = 0, 4 do
			XGUIEng.SetMaterialColor(button, i, 255, 255, 255, 255)
		end
	end
end

function AdvancedUI.GUIUpdate_MultiSelectionButton()
	local w = XGUIEng.GetCurrentWidgetID()
	local id = AdvancedUI.MultiselectionScroll:GetElementOf(w, 1)
	if not id then
		return
	end
	AdvancedUI.UpdateMultiselectionButton(w, id)
end

function AdvancedUI.GUIAction_MultiSelectionSelectUnit()
	local w = XGUIEng.GetCurrentWidgetID()
	local id = AdvancedUI.MultiselectionScroll:GetElementOf(w, 1)
	if not id then
		return
	end
	if XGUIEng.IsModifierPressed(Keys.ModifierControl) == 1 then
		Camera.ScrollSetLookAt(Logic.EntityGetPos(id))
	elseif XGUIEng.IsModifierPressed(Keys.ModifierShift) == 1 then
		GUI.DeselectEntity(id)
	else
		Camera.ScrollSetLookAt(Logic.EntityGetPos(id))
		GUI.SetSelectedEntity(id)
	end
end

function AdvancedUI.ShowExtendedInfo()
	return XGUIEng.IsModifierPressed(Keys.ModifierControl) == 1
end

---@param id number
---@return number thp
---@return number tmax
---@return number hp
---@return number max
---@return boolean leader
function AdvancedUI.GetHealthBar(id)
	local hp = Logic.GetEntityHealth(id)
	local max = Logic.GetEntityMaxHealth(id)

	local thp = hp
	local tmax = max
	local l = false

	if Logic.IsEntityInCategory(id, EntityCategories.Leader) == 1 then
		local maxSol = Logic.LeaderGetMaxNumberOfSoldiers(id)
		if maxSol > 0 then
			local shp = CppLogic.Entity.Leader.GetTroopHealth(id)
			local perSol = CppLogic.EntityType.GetMaxHealth(Logic.LeaderGetSoldiersType(id))
			if shp < 0 then
				shp = Logic.LeaderGetNumberOfSoldiers(id) * perSol
			end

			thp = thp + shp
			tmax = tmax + (maxSol * perSol)
			l = true
		end
	end

	return thp, tmax, hp, max, l
end

function AdvancedUI.GUIUpate_MultiSelectionHealthBar()
	local w = XGUIEng.GetCurrentWidgetID()
	local id = AdvancedUI.MultiselectionScroll:GetElementOf(w, 1)
	if not id then
		return
	end

	local hp, max = AdvancedUI.GetHealthBar(id)

	local r, g, b = GUI.GetPlayerColor(Logic.EntityGetPlayer(id))
	XGUIEng.SetMaterialColor(w, 0, r, g, b, 255)

	XGUIEng.SetProgressBarValues(w, hp, max)
end

function AdvancedUI.GUIUpate_DetailsHealthBar()
	local w = XGUIEng.GetCurrentWidgetID()
	local id = GUI.GetSelectedEntity()
	if id == nil then
		return
	end
	local r, g, b = GUI.GetPlayerColor(GUI.GetPlayerID())
	XGUIEng.SetMaterialColor(w, 0, r, g, b, 170)
	local thp, tmax, hp, max = AdvancedUI.GetHealthBar(id)
	if AdvancedUI.ShowExtendedInfo() then
		hp = thp
		max = tmax
	end
	XGUIEng.SetProgressBarValues(w, hp, max)
end

function AdvancedUI.GUIUpdate_DetailsHealthPoints()
	local w = XGUIEng.GetCurrentWidgetID()
	local id = GUI.GetSelectedEntity()
	if id == nil then
		return
	end
	local thp, tmax, hp, max = AdvancedUI.GetHealthBar(id)
	if AdvancedUI.ShowExtendedInfo() then
		hp = thp
		max = tmax
	end
	local s = "@center "..hp.."/"..max
	XGUIEng.SetText(w, s)
end

AdvancedUI.ExtractTitleBuffer = {}
---@param s string
---@return string
function AdvancedUI.ExtractTitle(s)
	if AdvancedUI.ExtractTitleBuffer[s] then
		return AdvancedUI.ExtractTitleBuffer[s]
	end
	local _, _, title = string.find(XGUIEng.GetStringTableText(s), "(@color:180,180,180.*@color:255,255,255)")
	title = title.." "
	AdvancedUI.ExtractTitleBuffer[s] = title
	return title
end

function AdvancedUI.GUITooltip_DetailsHealthBar()
	if AdvancedUI.ShowExtendedInfo() then
		XGUIEng.SetText("TooltipBottomShortCut", "")
		XGUIEng.SetText("TooltipBottomCosts", "")
		local txt = AdvancedUI.ExtractTitle("MenuSelectionGeneric/health")
		local id = GUI.GetSelectedEntity()
		if id then
			local thp, tmax, hp, max, l = AdvancedUI.GetHealthBar(id)
			txt = txt..XGUIEng.GetStringTableText("AdvancedUI/hp")..hp.."/"..max
			if l then
				txt = txt.."@cr|"..XGUIEng.GetStringTableText("AdvancedUI/hp_troop")..thp.."/"..tmax
			end
		end
		XGUIEng.SetText("TooltipBottomText", txt)
	else
		GUITooltip_Generic("MenuSelectionGeneric/health")
	end
end

function AdvancedUI.GetName(id, t)
	local n = ""
	for k, v in pairs(t) do
		if v == id then
			n = k
			break
		end
	end
	local x = XGUIEng.GetStringTableText("Names/"..n)
	return x or n
end

function AdvancedUI.GUITooltip_Armor()
	local id = GUI.GetSelectedEntity()
	if AdvancedUI.ShowExtendedInfo() and id and (Logic.IsBuilding(id) == 1 or Logic.IsSettler(id) == 1) then
		XGUIEng.SetText("TooltipBottomShortCut", "")
		XGUIEng.SetText("TooltipBottomCosts", "")
		local txt = AdvancedUI.ExtractTitle("MenuSelectionGeneric/armor")
		local pl = Logic.EntityGetPlayer(id)
		local ty = Logic.GetEntityType(id)
		local base, class = CppLogic.EntityType.GetArmor(ty)
		local techs = CppLogic.EntityType.GetArmorModifierTechs(ty)
		txt = txt..XGUIEng.GetStringTableText("AdvancedUI/ac")..AdvancedUI.GetName(class, ArmorClasses).."@cr|"..XGUIEng.GetStringTableText("AdvancedUI/armor")..base
		for _, t in ipairs(techs) do
			local op, num = CppLogic.Technology.GetArmorModifier(t)
			local c = "@color:180,180,180"
			if Logic.IsTechnologyResearched(pl, t) == 1 then
				c = "@color:255,255,255"
			end
			txt = txt..c.."|@cr|"..AdvancedUI.GetName(t, Technologies)..": "..string.char(op)..num
		end
		XGUIEng.SetText("TooltipBottomText", txt)
	else
		GUITooltip_Generic("MenuSelectionGeneric/armor")
	end
end

function AdvancedUI.GetConditionColor(c)
	return c and "@color:255,255,255|" or "@color:180,180,180|"
end

function AdvancedUI.GetColoredTechBoni(pl, t, op, num)
	return AdvancedUI.GetConditionColor(Logic.IsTechnologyResearched(pl, t) == 1)..AdvancedUI.GetName(t, Technologies)..": "..string.char(op)..num
end

function AdvancedUI.GUITooltip_Damage()
	local id = GUI.GetSelectedEntity()
	local top = Logic.GetFoundationTop(id)
	if IsValid(top) then
		id = top
	end
	if AdvancedUI.ShowExtendedInfo() and id and (Logic.IsBuilding(id) == 1 or Logic.IsSettler(id) == 1) then
		XGUIEng.SetText("TooltipBottomShortCut", "")
		XGUIEng.SetText("TooltipBottomCosts", "")
		local txt = AdvancedUI.ExtractTitle("MenuSelectionGeneric/damage")
		local pl = Logic.EntityGetPlayer(id)
		local ty = Logic.GetEntityType(id)
		local base, class, rand = CppLogic.EntityType.GetAutoAttackDamage(ty)
		txt = txt..XGUIEng.GetStringTableText("AdvancedUI/dc")..AdvancedUI.GetName(class, DamageClasses)
			.."@cr|"..XGUIEng.GetStringTableText("AdvancedUI/damage")..base.."@tab:0.5|"..XGUIEng.GetStringTableText("AdvancedUI/damageRand")..rand
		if Logic.IsSettler(id) == 1 then
			local b, r = CppLogic.Entity.Leader.GetLeveledDamageBonus(id)
			if b and r then
				if b < 0 then
					b = 0
				end
				txt = txt.."@color:255,255,255|@cr|"..XGUIEng.GetStringTableText("AdvancedUI/level")..(Logic.GetLeaderExperienceLevel(id) + 1)..": +"..b.."@tab:0.5|+"..r
			end
			local techs, randomTechs = CppLogic.EntityType.Settler.GetDamageModifierTechs(ty)
			for i = 1, math.max(table.getn(techs), table.getn(randomTechs)) do
				local t = techs[i]
				local rt = randomTechs[i]
				txt = txt.."@cr|"
				if t then
					local op, num = CppLogic.Technology.GetDamageModifier(t)
					txt = txt..AdvancedUI.GetColoredTechBoni(pl, t, op, num)
				end
				if rt then
					local op, num = CppLogic.Technology.GetDamageBonusModifier(rt)
					txt = txt.."@tab:0.5|"..AdvancedUI.GetColoredTechBoni(pl, rt, op, num)
				end
			end
		end
		XGUIEng.SetText("TooltipBottomText", txt)
	else
		GUITooltip_Generic("MenuSelectionGeneric/damage")
	end
end

function AdvancedUI.GUIUpdate_Damage()
	local id = GUI.GetSelectedEntity()
	local top = Logic.GetFoundationTop(id)
	if IsValid(top) then
		id = top
	end
	if AdvancedUI.ShowExtendedInfo() and id and Logic.IsSettler(id) == 1 then
		local d = Logic.GetEntityDamage(id)
		if not d then
			d = 0
		end
		local r = CppLogic.Entity.Settler.GetRandomDamageBonus(id)
		XGUIEng.SetText(XGUIEng.GetCurrentWidgetID(), "@ra|"..d.."+"..r)
	else
		GUIUpdate_Damage()
	end
end

AdvancedUI.ExperienceBorders = CppLogic.Logic.CalculateExperienceBorders()
function AdvancedUI.CheckExperienceLevelText(l_v, v, stt, txt)
	if v == l_v then
		return txt
	end
	return txt.." "..XGUIEng.GetStringTableText(stt).." +"..(v - l_v)
end

function AdvancedUI.GUITooltip_Experience()
	local id = GUI.GetSelectedEntity()
	local top = Logic.GetFoundationTop(id)
	if IsValid(top) then
		id = top
	end
	if AdvancedUI.ShowExtendedInfo() and id and Logic.IsLeader(id) == 1 then
		XGUIEng.SetText("TooltipBottomShortCut", "")
		XGUIEng.SetText("TooltipBottomCosts", "")
		local lvl = Logic.GetLeaderExperienceLevel(id)
		local txt = AdvancedUI.ExtractTitle("MenuSelectionGeneric/Experience")..XGUIEng.GetStringTableText("AdvancedUI/xp")..CppLogic.Entity.Leader.GetExperience(id)
		if AdvancedUI.ExperienceBorders[lvl + 1] then
			txt = txt.."/"..AdvancedUI.ExperienceBorders[lvl + 1]
		end
		local ec = CppLogic.Entity.Settler.GetExperienceClass(id)
		local l_rd, l_auto, l_d, l_dod, l_expl, l_reg, l_rang, l_miss, l_speed = 0, 0, 0, 0, 0, 0, 0, 0, 0
		for i = 0, 4 do
			local rd, auto, d, dod, expl, reg, rang, miss, speed = CppLogic.Logic.GetExperienceLevelData(ec, i)
			txt = txt.."@cr|"..AdvancedUI.GetConditionColor(lvl >= i)..XGUIEng.GetStringTableText("AdvancedUI/level")..(i + 1)
			txt = AdvancedUI.CheckExperienceLevelText(l_d, d, "AdvancedUI/dmg", txt)
			txt = AdvancedUI.CheckExperienceLevelText(l_rd, rd, "AdvancedUI/rdmg", txt)
			txt = AdvancedUI.CheckExperienceLevelText(l_rang, rang, "AdvancedUI/rang", txt)
			txt = AdvancedUI.CheckExperienceLevelText(l_expl, expl, "AdvancedUI/expl", txt)
			txt = AdvancedUI.CheckExperienceLevelText(l_auto, auto, "AdvancedUI/auto", txt)
			txt = AdvancedUI.CheckExperienceLevelText(l_reg, reg, "AdvancedUI/reg", txt)
			txt = AdvancedUI.CheckExperienceLevelText(l_dod, dod, "AdvancedUI/dod", txt)
			txt = AdvancedUI.CheckExperienceLevelText(-l_miss, -miss, "AdvancedUI/miss", txt)
			txt = AdvancedUI.CheckExperienceLevelText(l_speed, speed, "AdvancedUI/speed", txt)
			l_rd, l_auto, l_d, l_dod, l_expl, l_reg, l_rang, l_miss, l_speed = rd, auto, d, dod, expl, reg, rang, miss, speed
		end
		XGUIEng.SetText("TooltipBottomText", txt)
	else
		GUITooltip_Generic("MenuSelectionGeneric/Experience")
	end
end

AdvancedUI.RangeMarker = {}

---@type AdvUIRangeMarker
AdvancedUI.RangeMarker.AutoAttack = {Range = 0}
---@type AdvUIRangeMarker
AdvancedUI.RangeMarker.AoE = {Range = 0}

---@class AdvUIRangeMarker
---@field Decal TerrainDecalAccess?
---@field Range number
---@field Models nil|LogicModel[]

---@param m AdvUIRangeMarker
---@param p Position
---@param r number
---@param coneOpen number?
---@param coneDir number?
function AdvancedUI.RangeMarker.Update(m, p, r, coneOpen, coneDir)
	if m.Range ~= r then
		if m.Decal then
			m.Decal:Destroy()
		end
		m.Decal = nil
	end
	if r > 1500 or coneOpen then
		if not m.Models then
			m.Models = {}
		end
		local min, max = nil, nil
		local i = 1
		if coneOpen then
			min = coneDir - coneOpen
			max = coneDir + coneOpen
		end
		local make = function(p)
			if not m.Models[i] then
				m.Models[i] = CppLogic.Logic.CreateFreeModel()
				m.Models[i]:SetModel(Models.XD_CoordinateEntity)
			end
			m.Models[i]:ResetTransform()
			m.Models[i]:Translate(p, nil, nil, nil, true)
			m.Models[i]:Rotate(p.r)
			i = i + 1
		end

		AdvancedUI.RangeMarker.CallFuncWithCirclePositions(p, r, 150, make, min, max)
		if coneOpen then
			local e = {}
			e.X, e.Y = AdvancedUI.RangeMarker.ModifyCirclePos(p, min, r)
			e.r = min
			AdvancedUI.RangeMarker.CallFuncWithLinePositions(p, e, make, 150)
			e.X, e.Y = AdvancedUI.RangeMarker.ModifyCirclePos(p, max, r)
			e.r = max
			AdvancedUI.RangeMarker.CallFuncWithLinePositions(p, e, make, 150)
		end
		while m.Models[i] do
			m.Models[i]:Clear()
			m.Models[i] = nil
			i = i + 1
		end
	else
		if not m.Decal then
			m.Decal = CppLogic.UI.CreateSelectionDecal("Selection_Building", p, r, r)
		else
			m.Decal:SetPos(p)
		end
		if m.Models then
			for _, e in ipairs(m.Models) do
				e:Clear()
			end
			m.Models = nil
		end
	end
end

function AdvancedUI.RangeMarker.ModifyCirclePos(_pos, angle, _range)
	local nSin = math.sin(math.rad(angle))
	local nCos = math.cos(math.rad(angle))
	return _pos.X - nCos * _range, _pos.Y - nSin * _range
end

function AdvancedUI.RangeMarker.CallFuncWithCirclePositions(_pos, _range, _spacing, _func, minAngle, maxAngle)
	-- Determine angle step size
	if not minAngle then
		minAngle = 0
	end
	if not maxAngle then
		maxAngle = 360
	end
	local perimeter = 2 * _range * math.pi / 360 * (maxAngle-minAngle)
	local n = math.floor(perimeter / _spacing)
	local angleStep = (maxAngle-minAngle) / n

	-- Go!
	local p = {}
	for i = 0, (n - 1) do
		local angle = i * angleStep + minAngle
		p.X, p.Y = AdvancedUI.RangeMarker.ModifyCirclePos(_pos, angle, _range)
		p.r = angle
		if AdvancedUI.RangeMarker.IsValidPosition(p) then
			_func(p)
		end
	end
end

function AdvancedUI.RangeMarker.IsValidPosition(_position)
	if (type(_position) == "table") then
		if (type(_position.X) == "number") and (type(_position.Y) == "number") then
			local x, y = Logic.WorldGetSize()
			if ((_position.X <= x + 100) and (_position.X >= 0)) and ((_position.Y <= y + 100) and (_position.Y >= 0)) then
				return true
			end
		end
	end
	return false
end

function AdvancedUI.RangeMarker.CallFuncWithLinePositions(a, b, func, periode)
    local ax = a.X
	local ay = a.Y
	local bx = b.X
	local by = b.Y

	-- vector a->b
	local dx = bx - ax
	local dy = by - ay

	-- number of points
	local d = math.sqrt(dx*dx + dy*dy)
	local n = math.floor(d/periode + 0.5)

	-- "normalize"
	dx = dx / n
	dy = dy / n

	local p = {}
	if b.r then
		p.r = b.r
	end
	for i=1, n do
		p.X, p.Y = ax+dx*i, ay+dy*i
		func(p)
	end
end

function AdvancedUI.RangeMarker.AngleDifference(a, b)
	local c = a - b
	if c == 0 then
		return 0
	end
	if c < 0 then
		while c < -180 do
			c = c + 360
		end
		return c
	else
		while c > 180 do
			c = c - 360
		end
		return c
	end
end

function AdvancedUI.RangeMarker.GetAngleBetween(_Pos1,_Pos2)
	local delta_X = 0;
	local delta_Y = 0;
	local alpha   = 0
	if type (_Pos1) == "string" or type (_Pos1) == "number" then
		_Pos1 = GetPosition(GetEntityId(_Pos1));
	end
	if type (_Pos2) == "string" or type (_Pos2) == "number" then
		_Pos2 = GetPosition(GetEntityId(_Pos2));
	end
	delta_X = _Pos1.X - _Pos2.X
	delta_Y = _Pos1.Y - _Pos2.Y
	if delta_X == 0 and delta_Y == 0 then -- Gleicher Punkt
		return 0
	end
	alpha = math.deg(math.asin(math.abs(delta_X)/(math.sqrt(__pow(delta_X, 2)+__pow(delta_Y, 2)))))
	if delta_X >= 0 and delta_Y > 0 then
		alpha = 270 - alpha 
	elseif delta_X < 0 and delta_Y > 0 then
		alpha = 270 + alpha
	elseif delta_X < 0 and delta_Y <= 0 then
		alpha = 90  - alpha
	elseif delta_X >= 0 and delta_Y <= 0 then
		alpha = 90  + alpha
	end
	return alpha
end

---@param m AdvUIRangeMarker
function AdvancedUI.RangeMarker.Clear(m)
	if m.Decal then
		m.Decal:Destroy()
	end
	m.Decal = nil
	if m.Models then
		for _, e in ipairs(m.Models) do
			e:Clear()
		end
		m.Models = nil
	end
end

AdvancedUI.RangeMarker.StateMapping = {}
function AdvancedUI.RangeMarker.StateMapping.SnipeCommand(p, tp, id)
	local _,r = CppLogic.EntityType.Settler.GetAbilityDataSniper(Logic.GetEntityType(id))
	return r
end
function AdvancedUI.RangeMarker.StateMapping.ShurikenCommand(p, tp, id)
	local _,_,_,r,a = CppLogic.EntityType.Settler.GetAbilityDataShuriken(Logic.GetEntityType(id))
	return r, nil, a
end
function AdvancedUI.RangeMarker.StateMapping.PlaceBombCommand(p, tp, id)
	local _,_,r = CppLogic.EntityType.GetBombData(Entities.XD_Bomb1)
	return nil, r
end
function AdvancedUI.RangeMarker.StateMapping.ConvertSettlerCommand(p, tp, id)
	local s,m = CppLogic.EntityType.Settler.GetAbilityDataConvertSettler(Logic.GetEntityType(id))
	tp.X, tp.Y = p.X, p.Y
	return s, m
end
function AdvancedUI.RangeMarker.StateMapping.PlaceCannon(p, tp, id)
	local _,t = CppLogic.UI.GetPlaceBuildingUCat()
	if t == Entities.PU_Hero2_Cannon1 then
		local a = CppLogic.EntityType.GetAutoAttackRange(Entities.PU_Hero2_Cannon1)
		if a > 0 then
			return nil, a
		end
	elseif t == Entities.PU_Hero3_TrapCannon then
		local _,_,a = CppLogic.EntityType.GetAutoAttackRange(Entities.PU_Hero3_TrapCannon)
		if a > 0 then
			return nil, a
		end
	end
end

AdvancedUI.RangeMarker.WidgetMapping = {}
function AdvancedUI.RangeMarker.WidgetMapping.Hero1_ProtectUnits(p, tp, id)
	local r = CppLogic.EntityType.Settler.GetAbilityDataFear(Logic.GetEntityType(id))
	return r
end
AdvancedUI.RangeMarker.WidgetMapping.Hero7_InflictFear = AdvancedUI.RangeMarker.WidgetMapping.Hero1_ProtectUnits
AdvancedUI.RangeMarker.WidgetMapping.Hero11_FireworksFear = AdvancedUI.RangeMarker.WidgetMapping.Hero1_ProtectUnits
function AdvancedUI.RangeMarker.WidgetMapping.Hero4_CircularAttack(p, tp, id)
	local _,_, r = CppLogic.EntityType.Settler.GetAbilityDataCircularAttack(Logic.GetEntityType(id))
	return r
end
AdvancedUI.RangeMarker.WidgetMapping.Hero8_Poison = AdvancedUI.RangeMarker.WidgetMapping.Hero4_CircularAttack
AdvancedUI.RangeMarker.WidgetMapping.Hero12_PoisonRange = AdvancedUI.RangeMarker.WidgetMapping.Hero4_CircularAttack
function AdvancedUI.RangeMarker.WidgetMapping.Hero4_AuraOfWar(p, tp, id)
	local _,_,_, r = CppLogic.EntityType.Settler.GetAbilityDataRangedEffect(Logic.GetEntityType(id))
	return r
end
AdvancedUI.RangeMarker.WidgetMapping.Hero3_Heal = AdvancedUI.RangeMarker.WidgetMapping.Hero4_AuraOfWar
AdvancedUI.RangeMarker.WidgetMapping.Hero6_Bless = AdvancedUI.RangeMarker.WidgetMapping.Hero4_AuraOfWar
AdvancedUI.RangeMarker.WidgetMapping.Hero7_Madness = AdvancedUI.RangeMarker.WidgetMapping.Hero4_AuraOfWar
AdvancedUI.RangeMarker.WidgetMapping.Hero8_MoraleDamage = AdvancedUI.RangeMarker.WidgetMapping.Hero4_AuraOfWar
AdvancedUI.RangeMarker.WidgetMapping.Hero9_Berserk = AdvancedUI.RangeMarker.WidgetMapping.Hero4_AuraOfWar
AdvancedUI.RangeMarker.WidgetMapping.Hero10_LongRangeAura = AdvancedUI.RangeMarker.WidgetMapping.Hero4_AuraOfWar
function AdvancedUI.RangeMarker.WidgetMapping.Hero11_FireworksMotivate(p, tp, id)
	local r = CppLogic.EntityType.Settler.GetAbilityDataMotivate(Logic.GetEntityType(id))
	return r
end

function AdvancedUI.RangeMarker.Show()
	local id = GUI.GetSelectedEntity()
	local is_top = false
	if IsValid(id) then
		local top = Logic.GetFoundationTop(id)
		if IsValid(top) then
			id = top
			is_top = true
		end
	end
	if IsDestroyed(id) or not (Logic.IsLeader(id) == 1 or is_top) then
		AdvancedUI.RangeMarker.Clear(AdvancedUI.RangeMarker.AutoAttack)
		AdvancedUI.RangeMarker.Clear(AdvancedUI.RangeMarker.AoE)
		return
	end

	local autoattack, aoe, coneOpen = nil, nil, nil
	local p = GetPosition(id)
	local tx, ty = GUI.Debug_GetMapPositionUnderMouse()
	local guiState = GUI.GetCurrentStateName()
	local t = {X=tx,Y=ty}

	if AdvancedUI.RangeMarker.StateMapping[guiState] then
		autoattack, aoe, coneOpen = AdvancedUI.RangeMarker.StateMapping[guiState](p, t, id)
	else
		local x,y = GUI.GetMousePosition()
		local dx,dy = GUI.GetScreenSize()
		x = x / dx * 1024
		y = y / dy * 768
		local wid = CppLogic.UI.GetWidgetAtPosition("root", x, y)
		local done = false
		if wid ~= 0 then
			local widn = CppLogic.UI.GetWidgetName(wid)
			if AdvancedUI.RangeMarker.WidgetMapping[widn] then
				autoattack, aoe = AdvancedUI.RangeMarker.WidgetMapping[widn](p, t, id)
				done = true
			end
		end
		if not done then
			if Logic.IsEntityInCategory(id, EntityCategories.Melee) == 0 then
				autoattack = CppLogic.Entity.GetAutoAttackMaxRange(id)
			end
			local _,_,a = CppLogic.EntityType.GetAutoAttackRange(Logic.GetEntityType(id))
			if a > 0 then
				aoe = a
			end
		end
	end

	if autoattack and coneOpen then
		AdvancedUI.RangeMarker.Update(AdvancedUI.RangeMarker.AutoAttack, p, autoattack, coneOpen, AdvancedUI.RangeMarker.GetAngleBetween(t, p))
	elseif autoattack then
		AdvancedUI.RangeMarker.Update(AdvancedUI.RangeMarker.AutoAttack, p, autoattack)
	else
		AdvancedUI.RangeMarker.Clear(AdvancedUI.RangeMarker.AutoAttack)
	end
	if aoe then
		AdvancedUI.RangeMarker.Update(AdvancedUI.RangeMarker.AoE, t, aoe)
	else
		AdvancedUI.RangeMarker.Clear(AdvancedUI.RangeMarker.AoE)
	end
end

function AdvancedUI.Init()
	GUIAction_UpdateMultiSelectionContainer = AdvancedUI.GUIAction_UpdateMultiSelectionContainer
	GUIUpate_DetailsHealthBar = AdvancedUI.GUIUpate_DetailsHealthBar
	GUIUpdate_DetailsHealthPoints = AdvancedUI.GUIUpdate_DetailsHealthPoints
	AdvancedUI.InitMarketOverrides()
	AdvancedUI.GUIUpdate_AverageMotivation = GUIUpdate_AverageMotivation
	function GUIUpdate_AverageMotivation()
		AdvancedUI.GUIUpdate_AverageMotivation()
		AdvancedUI.RangeMarker.Show()
	end

	AdvancedUI.InitUI()
	return true
end

function AdvancedUI.InitUI()
	MainWindow_SaveGame_GenerateList = AdvancedUI.InitSave
	MainWindow_LoadGame_GenerateList = AdvancedUI.InitLoad
	local function rem(w)
		if CppLogic.UI.IsContainerWidget(w) then
			for _, c in ipairs(CppLogic.UI.ContainerWidgetGetAllChildren(w)) do
				rem(c)
			end
		end
		CppLogic.UI.RemoveWidget(w)
	end

	rem("MainMenuSaveGameFileRequester")
	rem("MainMenuLoadGameFileRequester")
	for _, id in ipairs(CppLogic.UI.ContainerWidgetGetAllChildren("MultiSelectionContainer")) do
		rem(id)
	end

	if not CppLogic.UI.TextButtonSetCenterText then
		function CppLogic.UI.TextButtonSetCenterText() end
	end
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapList") == 0, "MainMenuSave_MapList already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapSelectors") == 0, "MainMenuSave_MapSelectors already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapSelector") == 0, "MainMenuSave_MapSelector already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_Scoll") == 0, "MainMenuSave_Scoll already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_SliderTravel") == 0, "MainMenuSave_SliderTravel already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_SliderGfx") == 0, "MainMenuSave_SliderGfx already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_ScrollBar") == 0, "MainMenuSave_ScrollBar already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapNameUp") == 0, "MainMenuSave_MapNameUp already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapNameDown") == 0, "MainMenuSave_MapNameDown already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_ScrollBGInterior") == 0, "MainMenuSave_ScrollBGInterior already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_ScrollBG") == 0, "MainMenuSave_ScrollBG already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_MapNameBG") == 0, "MainMenuSave_MapNameBG already exists")
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
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("MainMenuSave_MapList", "MainMenuSave_Scoll", "CppLogic::Mod::UI::AutoScrollCustomWidget", nil, 4, 0, 0, 0, 0, 0,
													   "MainMenuSave_SliderGfx", "MainMenuSave_MapSelector")
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
	assert(XGUIEng.GetWidgetID("MainMenuSave_Name") == 0, "MainMenuSave_Name already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_NameInput") == 0, "MainMenuSave_NameInput already exists")
	assert(XGUIEng.GetWidgetID("MainMenuSave_NameBG") == 0, "MainMenuSave_NameBG already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuSaveWindow", "MainMenuSave_Name", "MainMenuSaveBG")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_Name", 178.5, 325, 420, 28)
	XGUIEng.ShowWidget("MainMenuSave_Name", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_Name", 100, false, false)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("MainMenuSave_Name", "MainMenuSave_NameInput", "CppLogic::Mod::UI::TextInputCustomWidget", nil, 0, 0, 0, 1, 1000, 0,
													   "AdvancedUI.OnNameInputChanged", "")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_NameInput", 0, 0, 420, 17)
	XGUIEng.ShowWidget("MainMenuSave_NameInput", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_NameInput", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuSave_Name", "MainMenuSave_NameBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuSave_NameBG", 0, 0, 420, 17)
	XGUIEng.ShowWidget("MainMenuSave_NameBG", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuSave_NameBG", 0, false, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuSave_NameBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuSave_NameBG", 0, 0, 0, 0, 192)


	if not CppLogic.UI.TextButtonSetCenterText then
		function CppLogic.UI.TextButtonSetCenterText() end
	end
	assert(XGUIEng.GetWidgetID("MainMenuLoad_MapList") == 0, "MainMenuLoad_MapList already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_MapSelectors") == 0, "MainMenuLoad_MapSelectors already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_MapSelector") == 0, "MainMenuLoad_MapSelector already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_Scoll") == 0, "MainMenuLoad_Scoll already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_SliderTravel") == 0, "MainMenuLoad_SliderTravel already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_SliderGfx") == 0, "MainMenuLoad_SliderGfx already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_ScrollBar") == 0, "MainMenuLoad_ScrollBar already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_MapNameUp") == 0, "MainMenuLoad_MapNameUp already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_MapNameDown") == 0, "MainMenuLoad_MapNameDown already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_ScrollBGInterior") == 0, "MainMenuLoad_ScrollBGInterior already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_ScrollBG") == 0, "MainMenuLoad_ScrollBG already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_MapNameBG") == 0, "MainMenuLoad_MapNameBG already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuLoadWindow", "MainMenuLoad_MapList", "MainMenuLoadWindowBG")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_MapList", 174.5, 38, 475, 272)
	XGUIEng.ShowWidget("MainMenuLoad_MapList", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_MapList", 10, false, false)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuLoad_MapList", "MainMenuLoad_MapSelectors", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_MapSelectors", 4, 6, 420, 259)
	XGUIEng.ShowWidget("MainMenuLoad_MapSelectors", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_MapSelectors", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateTextButtonWidgetChild("MainMenuLoad_MapSelectors", "MainMenuLoad_MapSelector", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_MapSelector", 4, 4, 412, 20)
	XGUIEng.ShowWidget("MainMenuLoad_MapSelector", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_MapSelector", 0, false, false)
	CppLogic.UI.WidgetSetGroup("MainMenuLoad_MapSelector", "MapNames")
	XGUIEng.DisableButton("MainMenuLoad_MapSelector", 0)
	XGUIEng.HighLightButton("MainMenuLoad_MapSelector", 0)
	CppLogic.UI.ButtonOverrideActionFunc("MainMenuLoad_MapSelector", function() AdvancedUI.LoadSave() end)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapSelector", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_MapSelector", 0, 151, 150, 151, 68)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapSelector", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_MapSelector", 1, 250, 214, 121, 128)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapSelector", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_MapSelector", 2, 150, 100, 50, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapSelector", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_MapSelector", 3, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapSelector", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_MapSelector", 4, 220, 170, 120, 255)
	CppLogic.UI.WidgetSetTooltipData("MainMenuLoad_MapSelector", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("MainMenuLoad_MapSelector", false)
	CppLogic.UI.WidgetOverrideUpdateFunc("MainMenuLoad_MapSelector", function() AdvancedUI.LoadSaveScroll:GUIUpdate_DefaultSelect(true) end)
	CppLogic.UI.WidgetSetFont("MainMenuLoad_MapSelector", "data\\menu\\fonts\\standard10.met")
	CppLogic.UI.WidgetSetStringFrameDistance("MainMenuLoad_MapSelector", 0)
	XGUIEng.SetText("MainMenuLoad_MapSelector", "", 1)
	XGUIEng.SetTextColor("MainMenuLoad_MapSelector", 255, 255, 255, 255)
	CppLogic.UI.TextButtonSetCenterText("MainMenuLoad_MapSelector", true)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("MainMenuLoad_MapList", "MainMenuLoad_Scoll", "CppLogic::Mod::UI::AutoScrollCustomWidget", nil, 4, 0, 0, 0, 0, 0,
													   "MainMenuLoad_SliderGfx", "MainMenuLoad_MapSelector")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_Scoll", 0, 0, 461, 261)
	XGUIEng.ShowWidget("MainMenuLoad_Scoll", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_Scoll", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuLoad_MapList", "MainMenuLoad_SliderTravel", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_SliderTravel", 427, 42, 37, 180)
	XGUIEng.ShowWidget("MainMenuLoad_SliderTravel", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_SliderTravel", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuLoad_SliderTravel", "MainMenuLoad_SliderGfx", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_SliderGfx", 5, 100, 23, 23)
	XGUIEng.ShowWidget("MainMenuLoad_SliderGfx", 0)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_SliderGfx", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_SliderGfx", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_SliderGfx", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_handle.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_SliderGfx", 0, 255, 255, 255, 255)
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuLoad_MapList", "MainMenuLoad_ScrollBar", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_ScrollBar", 425, 6, 41, 259)
	XGUIEng.ShowWidget("MainMenuLoad_ScrollBar", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_ScrollBar", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("MainMenuLoad_ScrollBar", "MainMenuLoad_MapNameUp", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_MapNameUp", 5, 0, 36, 42)
	XGUIEng.ShowWidget("MainMenuLoad_MapNameUp", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_MapNameUp", 0, false, false)
	XGUIEng.DisableButton("MainMenuLoad_MapNameUp", 0)
	XGUIEng.HighLightButton("MainMenuLoad_MapNameUp", 0)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameUp", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameUp", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameUp", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameUp", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameUp", 1, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up_hi.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameUp", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameUp", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameUp", 2, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up_sel.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameUp", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameUp", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameUp", 3, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameUp", 3, 128, 128, 128, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameUp", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameUp", 4, "data\\graphics\\textures\\gui\\mainmenu\\scroll_up.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameUp", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("MainMenuLoad_MapNameUp", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("MainMenuLoad_MapNameUp", false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameUp", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameUp", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("MainMenuLoad_ScrollBar", "MainMenuLoad_MapNameDown", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_MapNameDown", 5, 217, 36, 42)
	XGUIEng.ShowWidget("MainMenuLoad_MapNameDown", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_MapNameDown", 0, false, false)
	XGUIEng.DisableButton("MainMenuLoad_MapNameDown", 0)
	XGUIEng.HighLightButton("MainMenuLoad_MapNameDown", 0)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameDown", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameDown", 0, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameDown", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameDown", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameDown", 1, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down_hi.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameDown", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameDown", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameDown", 2, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down_sel.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameDown", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameDown", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameDown", 3, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameDown", 3, 128, 128, 128, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameDown", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_MapNameDown", 4, "data\\graphics\\textures\\gui\\mainmenu\\scroll_down.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameDown", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("MainMenuLoad_MapNameDown", nil, false, true)
	CppLogic.UI.WidgetSetUpdateManualFlag("MainMenuLoad_MapNameDown", false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameDown", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameDown", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuLoad_ScrollBar", "MainMenuLoad_ScrollBGInterior", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_ScrollBGInterior", 7, 9, 23, 239)
	XGUIEng.ShowWidget("MainMenuLoad_ScrollBGInterior", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_ScrollBGInterior", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_ScrollBGInterior", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_ScrollBGInterior", 0, 255, 255, 255, 64)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuLoad_ScrollBar", "MainMenuLoad_ScrollBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_ScrollBG", 0, 0, 37, 259)
	XGUIEng.ShowWidget("MainMenuLoad_ScrollBG", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_ScrollBG", 0, false, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_ScrollBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_ScrollBG", 0, 0, 0, 0, 192)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuLoad_MapList", "MainMenuLoad_MapNameBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_MapNameBG", 4, 6, 420, 259)
	XGUIEng.ShowWidget("MainMenuLoad_MapNameBG", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_MapNameBG", 0, false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_MapNameBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_MapNameBG", 0, 0, 0, 0, 192)

	if not CppLogic.UI.TextButtonSetCenterText then
		function CppLogic.UI.TextButtonSetCenterText() end
	end
	assert(XGUIEng.GetWidgetID("MainMenuLoad_Filter") == 0, "MainMenuLoad_Filter already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_FilterInput") == 0, "MainMenuLoad_FilterInput already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_FilterClear") == 0, "MainMenuLoad_FilterClear already exists")
	assert(XGUIEng.GetWidgetID("MainMenuLoad_NameBG") == 0, "MainMenuLoad_NameBG already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MainMenuLoadWindow", "MainMenuLoad_Filter", "MainMenuLoadWindowBG")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_Filter", 178.5, 325, 450, 28)
	XGUIEng.ShowWidget("MainMenuLoad_Filter", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_Filter", 100, false, false)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("MainMenuLoad_Filter", "MainMenuLoad_FilterInput", "CppLogic::Mod::UI::TextInputCustomWidget", nil, 0, 0, 0, 1, 1000, 0,
													   "AdvancedUI.FilterLoad", "")
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_FilterInput", 0, 0, 420, 17)
	XGUIEng.ShowWidget("MainMenuLoad_FilterInput", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_FilterInput", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("MainMenuLoad_Filter", "MainMenuLoad_FilterClear", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_FilterClear", 425, 0, 17, 17)
	XGUIEng.ShowWidget("MainMenuLoad_FilterClear", 0)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_FilterClear", 0, false, false)
	XGUIEng.DisableButton("MainMenuLoad_FilterClear", 0)
	XGUIEng.HighLightButton("MainMenuLoad_FilterClear", 0)
	CppLogic.UI.ButtonOverrideActionFunc("MainMenuLoad_FilterClear",
										 function()
											 AdvancedUI.FilterLoad(nil); CppLogic.UI.TextInputCustomWidgetSetText("MainMenuLoad_FilterInput", "")
										 end)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_FilterClear", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_FilterClear", 0, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_FilterClear", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_FilterClear", 1, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_FilterClear", 1, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_FilterClear", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_FilterClear", 2, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_FilterClear", 2, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_FilterClear", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_FilterClear", 3, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_FilterClear", 3, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_FilterClear", 3, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_FilterClear", 4, 0, 0, 1, 1)
	XGUIEng.SetMaterialTexture("MainMenuLoad_FilterClear", 4, "graphics\\textures\\gui\\trade_cancel.png")
	XGUIEng.SetMaterialColor("MainMenuLoad_FilterClear", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("MainMenuLoad_FilterClear", nil, false, false)
	CppLogic.UI.WidgetSetUpdateManualFlag("MainMenuLoad_FilterClear", true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_FilterClear", 10, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_FilterClear", 10, 255, 255, 255, 0)
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("MainMenuLoad_Filter", "MainMenuLoad_NameBG", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MainMenuLoad_NameBG", 0, 0, 420, 17)
	XGUIEng.ShowWidget("MainMenuLoad_NameBG", 1)
	CppLogic.UI.WidgetSetBaseData("MainMenuLoad_NameBG", 0, false, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MainMenuLoad_NameBG", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MainMenuLoad_NameBG", 0, 0, 0, 0, 192)

	assert(XGUIEng.GetWidgetID("MultiSelectionEntity") == 0, "MultiSelectionEntity already exists")
	assert(XGUIEng.GetWidgetID("MultiSelection_health") == 0, "MultiSelection_health already exists")
	assert(XGUIEng.GetWidgetID("MultiSelection_button") == 0, "MultiSelection_button already exists")
	assert(XGUIEng.GetWidgetID("MultiSelectionScroll") == 0, "MultiSelectionScroll already exists")
	CppLogic.UI.ContainerWidgetCreateContainerWidgetChild("MultiSelectionContainer", "MultiSelectionEntity", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MultiSelectionEntity", 4, 4, 32, 32)
	XGUIEng.ShowWidget("MultiSelectionEntity", 1)
	CppLogic.UI.WidgetSetBaseData("MultiSelectionEntity", 0, false, false)
	CppLogic.UI.ContainerWidgetCreateProgressBarWidgetChild("MultiSelectionEntity", "MultiSelection_health", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MultiSelection_health", 1, 27, 30, 4)
	XGUIEng.ShowWidget("MultiSelection_health", 1)
	CppLogic.UI.WidgetSetBaseData("MultiSelection_health", 1, false, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MultiSelection_health", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("MultiSelection_health", 0, 50, 200, 50, 255)
	XGUIEng.SetProgressBarValues("MultiSelection_health", 100, 100)
	CppLogic.UI.WidgetSetUpdateManualFlag("MultiSelection_health", false)
	CppLogic.UI.WidgetOverrideUpdateFunc("MultiSelection_health", function() AdvancedUI.GUIUpate_MultiSelectionHealthBar() end)
	CppLogic.UI.ContainerWidgetCreateGFXButtonWidgetChild("MultiSelectionEntity", "MultiSelection_button", nil)
	CppLogic.UI.WidgetSetPositionAndSize("MultiSelection_button", 0, 0, 32, 32)
	XGUIEng.ShowWidget("MultiSelection_button", 1)
	CppLogic.UI.WidgetSetBaseData("MultiSelection_button", 0, false, false)
	CppLogic.UI.WidgetSetGroup("MultiSelection_button", "Command_group")
	XGUIEng.DisableButton("MultiSelection_button", 0)
	XGUIEng.HighLightButton("MultiSelection_button", 0)
	CppLogic.UI.ButtonOverrideActionFunc("MultiSelection_button", function() AdvancedUI.GUIAction_MultiSelectionSelectUnit() end)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MultiSelection_button", 0, 0, 0, 0.25, 0.0625)
	XGUIEng.SetMaterialTexture("MultiSelection_button", 0, "data\\graphics\\textures\\gui\\b_units_military.png")
	XGUIEng.SetMaterialColor("MultiSelection_button", 0, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MultiSelection_button", 1, 0.25, 0, 0.25, 0.0625)
	XGUIEng.SetMaterialTexture("MultiSelection_button", 1, "data\\graphics\\textures\\gui\\b_units_military.png")
	XGUIEng.SetMaterialColor("MultiSelection_button", 1, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MultiSelection_button", 2, 0.5, 0, 0.25, 0.0625)
	XGUIEng.SetMaterialTexture("MultiSelection_button", 2, "data\\graphics\\textures\\gui\\b_units_military.png")
	XGUIEng.SetMaterialColor("MultiSelection_button", 2, 255, 255, 255, 255)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MultiSelection_button", 3, 0, 0, 0.25, 0.0625)
	XGUIEng.SetMaterialTexture("MultiSelection_button", 3, "data\\graphics\\textures\\gui\\b_units_military.png")
	XGUIEng.SetMaterialColor("MultiSelection_button", 3, 128, 128, 128, 128)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MultiSelection_button", 4, 0.75, 0, 0.25, 0.0625)
	XGUIEng.SetMaterialTexture("MultiSelection_button", 4, "data\\graphics\\textures\\gui\\b_units_military.png")
	XGUIEng.SetMaterialColor("MultiSelection_button", 4, 255, 255, 255, 255)
	CppLogic.UI.WidgetSetTooltipData("MultiSelection_button", "TooltipBottom", false, true)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("MultiSelection_button", 10, 0, 0, 0.25, 0.25)
	XGUIEng.SetMaterialColor("MultiSelection_button", 10, 255, 255, 255, 0)
	CppLogic.UI.WidgetSetUpdateManualFlag("MultiSelection_button", false)
	CppLogic.UI.WidgetOverrideUpdateFunc("MultiSelection_button", function() AdvancedUI.GUIUpdate_MultiSelectionButton() end)
	CppLogic.UI.ContainerWidgetCreateCustomWidgetChild("MultiSelectionContainer", "MultiSelectionScroll", "CppLogic::Mod::UI::AutoScrollCustomWidget", nil, 4, 0, 0, 0, 0, 0, "",
													   "MultiSelectionEntity")
	CppLogic.UI.WidgetSetPositionAndSize("MultiSelectionScroll", 0, 0, 40, 450)
	XGUIEng.ShowWidget("MultiSelectionScroll", 1)
	CppLogic.UI.WidgetSetBaseData("MultiSelectionScroll", 0, false, false)

	CppLogic.UI.WidgetSetBaseData("MultiSelectionContainer", 0, true, false)
	CppLogic.UI.WidgetSetPositionAndSize("MultiSelectionContainer", 984, 99, 40, 450)

	assert(XGUIEng.GetWidgetID("TradeProgressText") == 0, "TradeProgressText already exists")
	CppLogic.UI.ContainerWidgetCreateStaticTextWidgetChild("TradeInProgress", "TradeProgressText", "CancelTrade")
	CppLogic.UI.WidgetSetPositionAndSize("TradeProgressText", 185, 20, 100, 15)
	XGUIEng.ShowWidget("TradeProgressText", 1)
	CppLogic.UI.WidgetSetBaseData("TradeProgressText", 0, true, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("TradeProgressText", 0, 0, 0, 1, 1)
	XGUIEng.SetMaterialColor("TradeProgressText", 0, 255, 255, 255, 0)
	CppLogic.UI.WidgetSetFont("TradeProgressText", "data\\menu\\fonts\\standard10.met")
	CppLogic.UI.WidgetSetStringFrameDistance("TradeProgressText", -4)
	XGUIEng.SetText("TradeProgressText", "0", 1)
	XGUIEng.SetTextColor("TradeProgressText", 255, 255, 255, 255)
	CppLogic.UI.WidgetSetUpdateManualFlag("TradeProgressText", false)
	CppLogic.UI.WidgetOverrideUpdateFunc("TradeProgressText", function() AdvancedUI.GUIUpdate_MarketTradeStatus() end)
	XGUIEng.SetLinesToPrint("TradeProgressText", 0, 0)
	CppLogic.UI.StaticTextWidgetSetLineDistanceFactor("TradeProgressText", 0)

	assert(XGUIEng.GetWidgetID("CannonProgressType") == 0, "CannonProgressType already exists")
	CppLogic.UI.ContainerWidgetCreateStaticWidgetChild("CannonInProgress", "CannonProgressType", "CannonInProgressBackground")
	CppLogic.UI.WidgetSetPositionAndSize("CannonProgressType", 51, 47, 32, 32)
	XGUIEng.ShowWidget("CannonProgressType", 1)
	CppLogic.UI.WidgetSetBaseData("CannonProgressType", 0, false, false)
	CppLogic.UI.WidgetMaterialSetTextureCoordinates("CannonProgressType", 0, 0, 0, 0.25, 0.125)
	XGUIEng.SetMaterialTexture("CannonProgressType", 0, "data\\graphics\\textures\\gui\\b_foundry.png")
	XGUIEng.SetMaterialColor("CannonProgressType", 0, 255, 255, 255, 255)

	CppLogic.UI.WidgetOverrideTooltipFunc("DetailsHealth_Tooltip", AdvancedUI.GUITooltip_DetailsHealthBar)
	CppLogic.UI.WidgetOverrideTooltipFunc("DetailsArmor_Tooltip", AdvancedUI.GUITooltip_Armor)
	CppLogic.UI.WidgetOverrideTooltipFunc("DetailsDamage_Tooltip", AdvancedUI.GUITooltip_Damage)
	CppLogic.UI.WidgetOverrideUpdateFunc("DetailsDamage_Amount", AdvancedUI.GUIUpdate_Damage)
	CppLogic.UI.WidgetOverrideTooltipFunc("DetailsExperience_Tooltip", AdvancedUI.GUITooltip_Experience)

	AdvancedUI.DoSaveScroll:Setup()
	AdvancedUI.LoadSaveScroll:Setup()
	AdvancedUI.MultiselectionScroll:Init()

	AdvancedUI.InitMarketUI()

	AdvancedUI.ExtractTitleBuffer = {}
end

CppLogic.API.EnableScriptTriggerEval(true)
Trigger.RequestTrigger(Events.CPPLOGIC_EVENT_ON_MAP_STARTED, nil, "AdvancedUI.Init", 1)
Trigger.RequestTrigger(Events.CPPLOGIC_EVENT_ON_SAVEGAME_LOADED, nil, "AdvancedUI.InitUI", 1)
