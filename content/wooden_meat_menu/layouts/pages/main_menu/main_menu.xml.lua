local K = require("kompot:kompot")
local DS = require("wooden_meat_menu:wm_ds")
local M = K.M
local sfx = require("wooden_meat_menu:sfx")

local BUTTON_WIDTH = 350

local theme = DS.theme({
	metrics = {
		shadow_direction = DS.SHADOW.bottom_left,
	},
})

local Screen = K.component(function()
	K.Box({
		modifier = M:fill_max_size():block_pointer(),
	}, function()

		-- K.Image("gui/menu_background", {
		-- 		source_size = { 1920, 1080 },
		-- 		fit = "cover",
		-- 		modifier = M:fill_max_size(),
		-- 	})

		K.Column({
			modifier = M:padding(48):match_parent_size(), -- :background(K.color.with_alpha(theme.colors.background, 0.4))
			arrangement = "end",
			width = BUTTON_WIDTH,
			spacing = 20,
		}, function()

			K.Text("WOODEN MEAT", {
				style = "display",
				color = theme.colors.primary,
				modifier = M:padding(0, 0, 0, 24),
			})

			DS.Button({
				text = "ИГРАТЬ",
				size = "lg",
				width = BUTTON_WIDTH,
				modifier = M:align("start"),
				on_click = function()
					sfx.main_menu_btn_click()
					-- menu.page = "main_menu/main_menu2"
					menu.page = "main"
					-- TODO: bridge.app... (запуск мира)
				end,
			})

			DS.Button({
				text = "СОХРАНЕНИЯ",
				size = "lg",
				width = BUTTON_WIDTH,
				modifier = M:align("start"),
				on_click = function()
					sfx.main_menu_btn_click()
				end,
			})

			DS.Button({
				text = "ВЫЙТИ",
				size = "lg",
				width = BUTTON_WIDTH,
				modifier = M:align("start"),
				on_click = function()
					sfx.main_menu_btn_click()
					app.quit(true)
				end,
			})
		end)
	end)
end)

local handle -- из-за того что приходится использовать кастыль для показа меню - приходится делать кастыль тут, иначе 2 клика по одному нажатию lmb
function on_open()
	if handle then
		print("WARNING: handle already exists, disposing old one")
		handle:dispose()
	end
	handle = K.mount({
		target = document.root,
		theme = theme,
		content = Screen,
	})
end

function on_close()
	if handle then
		handle:dispose()
		handle = nil
	end
end
