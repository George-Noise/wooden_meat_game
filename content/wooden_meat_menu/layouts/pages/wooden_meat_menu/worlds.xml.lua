local K = require("kompot:kompot")
local DS = require("wooden_meat_menu:wm_ds")
local M = K.M
local sfx = require("wooden_meat_menu:sfx")

local theme = DS.theme({
	metrics = {
		shadow_direction = DS.SHADOW.bottom_left,
	},
})

local PANEL_WIDTH = 500
local WORLD_CARD_W = 380
local WORLD_CARD_H = 66

local c = theme.colors
local mt = theme.metrics

local WorldCard = K.component(function(props)
	local inter = K.interaction()
	local hovered = inter.hovered.value
	local bg = hovered and c.surface_raised or c.surface

	K.Box({
		modifier = M:size(WORLD_CARD_W, WORLD_CARD_H)
			:background(bg)
			:border(mt.border, c.ink, 0)
			:clip()
			:clickable(function()
				app.open_world(props.name)
			end, {
				interaction = inter,
				focus_color = c.focus_ring,
				focus_radius = 0,
			}),
	}, function()
		K.Box({ modifier = M:offset(1, 1):size(96, 64) }, function()
			K.Image(props.icon or "gui/no_world_icon", {
				source_size = { 96, 64 },
				fit = "cover",
				modifier = M:fill_max_size(),
			})
		end)

		K.Box({ modifier = M:offset(104, 8) }, function()
			K.Text(props.name, {
				style = "strong",
				color = c.text,
			})
		end)

		local del = K.interaction()
		K.Box({
			modifier = M:offset(WORLD_CARD_W - 40, 0):size(36, WORLD_CARD_H):clickable(function()
				gui.ask("Удалить мир " .. props.name .. "?", function()
					app.delete_world(props.name)
				end, nil, "Удалить", "Отмена")
			end, {
				interaction = del,
				focus_color = c.focus_ring,
				focus_radius = 0,
			}),
			align = "center",
		}, function()
			K.Text("×", {
				style = "strong",
				color = del.hovered.value and c.error or c.muted,
			})
		end)

		K.Box({ modifier = M:offset(317, 44) }, function()
			K.Text(props.versionString, {
				style = "caption",
				color = props.versionColor,
			})
		end)
	end)
end)

local Screen = K.component(function()
	local worlds_state = K.state(world.get_list() or {})
	local scroll = K.scroll_state()

	K.Box({
		modifier = M:fill_max_size():block_pointer():padding(32, 24),
	}, function()
		K.Column({
			modifier = M:width(PANEL_WIDTH):fill_max_height():align("center"),
			arrangement = "start",
			spacing = 12,
		}, function()
			DS.Button({
				text = "НОВЫЙ МИР",
				size = "lg",
				fill_width = true,
				on_click = function()
					sfx.main_menu_btn_click()
					menu.page = "new_world"
				end,
			})

			K.Row({
				modifier = M:fill_max_width():weight(1),
				spacing = 8,
			}, function()
				K.Box({
					modifier = M:fill_max_width()
						:weight(1)
						:padding(5)
						:background(c.surface)
						:border(mt.border, c.ink, 0),
				}, function()
					K.Column({
						modifier = M:fill_max_size():vertical_scroll(scroll),
						spacing = 8,
						align = "center",
					}, function()
						for _, info in ipairs(worlds_state.value) do
							local major, minor = app.get_version()
							local versionColor = c.muted
							if info.version[1] > major or info.version[2] > minor then
								versionColor = c.error
							end

							WorldCard({
								name = info.name,
								icon = info.icon,
								version = info.version,
								versionString = string.format("%s.%s", unpack(info.version)),
								versionColor = versionColor,
							})
						end

						if #worlds_state.value == 0 then
							K.Text("Нет сохранённых миров", {
								style = "body",
								color = c.muted,
								modifier = M:padding(16),
							})
						end
					end)
				end)

				DS.Scrollbar({ state = scroll })
			end)

			DS.Button({
				text = "ОТКРЫТЬ ПАПКУ МИРОВ",
				variant = "secondary",
				size = "md",
				fill_width = true,
				on_click = function()
					sfx.main_menu_btn_click()
					app.open_folder("user:worlds")
				end,
			})

			DS.Button({
				text = "НАЗАД",
				variant = "secondary",
				size = "md",
				fill_width = true,
				on_click = function()
					sfx.main_menu_btn_click()
					menu:back()
				end,
			})
		end)
	end)
end)

local handle
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
