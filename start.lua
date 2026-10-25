-- app.tick()
-- app.config_packs({"base", "wooden_meat_menu"})
-- app.load_content()

app.load_content()

-- app bridge for main menu ui
local app_bridge = require "wooden_meat_menu:app_bridge"
app_bridge.init(app)

-- main menu ui
gui.load_document("wooden_meat_menu:layouts/pages/main_menu.xml", "wooden_meat_menu:main_menu")
gui.root.root:add("<iframe id='menu_frame' src='wooden_meat_menu:main_menu' size-func='unpack(gui.get_viewport())'/>")