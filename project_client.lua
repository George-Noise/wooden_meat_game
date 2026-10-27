local menubg

function on_menu_clear()
	if menubg then
		menubg:destruct()
		menubg = nil
	end
end

local function setup_background()
	local controller = {}

	function controller.resize_menu_bg()
		local vw, vh = unpack(gui.get_viewport())
		local bw, bh = 1920, 1080

		local scale = math.max(vw / bw, vh / bh)
		return bw * scale, bh * scale
	end

	local bgid = random.uuid()
	gui.root.root:add(
		string.format(
			"<image id='%s' src='gui/menu_background' size-func='DATA.resize_menu_bg' "
				.. "gravity='center-center' z-index='-1' interactive='true'/>",
			bgid
		),
		controller
	)
	menubg = gui.root[bgid]
end

function on_menu_setup()
	time.post_runnable(function()
		-- app.config_packs({"base", "kompot", "wooden_meat_menu"})
		app.load_content()
		
		setup_background()
		-- local app_bridge = require("wooden_meat_menu:app_bridge")
		-- app_bridge.init(app)
		menu.page = "wooden_meat_menu/main_menu"
		menu.visible = true
	end)
end
