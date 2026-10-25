local app_bridge = require("wooden_meat_menu:app_bridge")

function on_start_game()
	-- print("Запускаем мир...")
	app_bridge.app.new_world("my_world", "42", "core:default")
end

function on_quit()
	-- print("Выходим...")
	app_bridge.app.quit(true)
end

function on_close_world()
	-- print("Закрываем мир...")
	app_bridge.app.close_world(true)
end
