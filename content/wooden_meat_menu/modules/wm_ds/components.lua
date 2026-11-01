local C = {}

local function merge(mod)
	for k, v in pairs(mod) do
		C[k] = v
	end
end

merge(require("wooden_meat_menu:wm_ds/components/button"))
merge(require("wooden_meat_menu:wm_ds/components/scrollbar"))
merge(require("wooden_meat_menu:wm_ds/components/recipe_card"))

return C
