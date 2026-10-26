local T = require("wooden_meat_menu:wm_ds/tokens")
local C = require("wooden_meat_menu:wm_ds/components")
local UI = require("wooden_meat_menu:wm_ds/ui")

T.ui = UI
T.DEFAULT = T.theme()

local DS = {
	tokens = T,
	ui = UI,
	theme = T.theme,
	SHADOW = T.SHADOW_DIRECTIONS,
}
for name, fn in pairs(C) do
	DS[name] = fn
end
return DS
