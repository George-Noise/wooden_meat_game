local K = require("kompot:kompot")
local UI = require("kompot:ui")
local M = K.M
local S = K.Shape

local theme = UI.theme({
	colors = {
		primary = "#8B5CF6",
		on_primary = "#FFFFFF",
		surface = "#2A2A2A",
	},
})

local BUTTON_WIDTH = 350
local PILL_SHAPE = S.rounded(S.percent(50))
local TEXT_PADDING_H = 40

local function CustomButton(props)
	local hovered = K.state(false)
	local pressed = K.state(false)

	local bg_color = pressed.value and "#6B4CD6" or (hovered.value and "#9B6CF6" or "#8B5CF6")

	K.Box({
		modifier = M:width(BUTTON_WIDTH)
			:background(bg_color, PILL_SHAPE)
			:clip(PILL_SHAPE)
			:clickable(props.on_click, {
				on_focus = function()
					pressed.value = true
				end,
				on_defocus = function()
					pressed.value = false
				end,
			})
			:hoverable(hovered)
			:padding(TEXT_PADDING_H, 12, TEXT_PADDING_H, 12)
			:then_(props.modifier),
	}, function()
		K.Text(props.text or "", {
			style = "label",
			color = "#FFFFFF",
			wrap = true,
			modifier = M:align("center"),
		})
	end)
end

local Screen = K.component(function()
	K.Box({ modifier = M:fill_max_size() }, function()
		K.Column({
			modifier = M:fill_max_size(),
			arrangement = "center",
			spacing = 20,
		}, function()
			CustomButton({
				text = "Кнопка-капсула",
				on_click = function()
					print("Клик по первой кнопке!")
				end,
				modifier = M:align("center"),
			})

			CustomButton({
				text = "Длинный текст с пробелами между словами который переносится на несколько строк",
				on_click = function()
					print("Клик по второй кнопке!")
				end,
				modifier = M:align("center"),
			})

			CustomButton({
				text = "Длинный текст с пробелами между словами ",
				on_click = function()
					print("Клик по второй кнопке!")
				end,
				modifier = M:align("center"),
			})
		end)
	end)
end)

local handle

function on_open()
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
