---@diagnostic disable: inject-field
---@type ModPack
ModLoader.AdvancedUI = {
	Manifest = {
		StringTableTexts = {
			AdvancedUI = true,
		},
	},
}

---gets called on loading your ModPack.
---@param mp ModpackDesc
function ModLoader.AdvancedUI.Init(mp)
	--- merge own manifest into the main mods one
	ModLoader.MergeManifest(ModLoader.Manifest, ModLoader.AdvancedUI.Manifest)
end
