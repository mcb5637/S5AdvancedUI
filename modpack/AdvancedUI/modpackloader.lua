---@diagnostic disable: inject-field
---@type ModPack
ModLoader.AdvancedUI = {
	Manifest = {
		StringTableTexts = {
			AdvancedUI = true,
		},
		GUITextures = {
			"data\\graphics\\textures\\gui\\dropdown\\dropmenudown187x32.png",
			"data\\graphics\\textures\\gui\\dropdown\\dropmenudown187x32_hi.png",
			"data\\graphics\\textures\\gui\\dropdown\\dropmenudown187x32_sel.png",
			"data\\graphics\\textures\\gui\\dropdown\\dropmenudown187x32_in.png",
			"data\\graphics\\textures\\gui\\dropdown\\dropmenudown187x32_akt.png",
			"data\\graphics\\textures\\gui\\dropdown\\dropmenuup187x32.png",
			"data\\graphics\\textures\\gui\\dropdown\\dropmenuup187x32_hi.png",
			"data\\graphics\\textures\\gui\\dropdown\\dropmenuup187x32_sel.png",
			"data\\graphics\\textures\\gui\\dropdown\\dropmenuup187x32_in.png",
			"data\\graphics\\textures\\gui\\dropdown\\dropmenuup187x32_akt.png",
		},
	},
	Settings = {}
}

---gets called on loading your ModPack.
---@param mp ModpackDesc
function ModLoader.AdvancedUI.Init(mp)
	--- merge own manifest into the main mods one
	ModLoader.MergeManifest(ModLoader.Manifest, ModLoader.AdvancedUI.Manifest)
end
