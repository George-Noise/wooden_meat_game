local K = require("kompot:kompot")
local T = require("wooden_meat_menu:wm_ds/tokens")
local M = K.M

local C = {}

C.RecipeCard = K.component(function(p)
	p = T.props("RecipeCard", p)
	local t = T.current()
	local c, mt, mo = t.colors, t.metrics, t.motion

	local inter = K.interaction()
	local enabled = p.enabled ~= false
	local hovered = enabled and (inter.hovered.value or inter.focused.value) or false
	local down = enabled and inter.pressed.value or false
	local selected = p.selected or false

	local card_border = 5
	local shadow_offset = 8

	local fill = c.surface
	local edge = c.ink
	local text_color = c.on_surface

	if not enabled then
		fill = c.disabled_bg
		edge = c.disabled_edge
		text_color = c.disabled_fg
	elseif selected then
		fill = c.primary
		edge = c.ink
		text_color = c.on_primary
	elseif down then
		fill = c.surface_raised
		edge = c.ink
	elseif hovered then
		fill = c.surface_raised
		edge = c.primary
	end

	local fill_animated = K.animate(fill, mo.color)
	local edge_animated = K.animate(edge, mo.color)

	local offset_x = 0
	local offset_y = 0
	if down then
		offset_x = 2
		offset_y = 2
	elseif hovered and not selected then
		offset_x = -2
		offset_y = -2
	end

	local face = M:width(p.width or 200)
		:height(p.height or 240)
		:offset(offset_x, offset_y)
		:background(fill_animated, K.Shape.rectangle())
		:border(card_border, edge_animated, K.Shape.rectangle())
		:clickable(p.on_click, {
			interaction = inter,
			enabled = enabled,
			focus_color = c.focus_ring,
			focus_shape = K.Shape.rectangle(),
		})
		:padding(mt.pad_md)

	local outer = p.modifier or M

	K.Box({ modifier = outer }, function()
		if not down and enabled then
			K.Box({
				modifier = M:match_parent_size()
					:offset(shadow_offset, shadow_offset)
					:background(c.ink, K.Shape.rectangle()),
			})
		end

		K.Box({ modifier = face }, function()
			K.Column({ modifier = M:fill_max_size(), spacing = mt.gap }, function()
				if p.icon then
					K.Box({
						modifier = M:width(80)
							:height(80)
							:background(c.ink, K.Shape.rectangle())
							:border(3, c.primary, K.Shape.rectangle())
							:align("center"),
					}, function()
						K.Icon(p.icon, { size = 64 })
					end)
				end

				if p.title then
					K.Text(p.title, {
						style = "strong",
						color = text_color,
						wrap = false,
					})
				end

				if p.description then
					K.Text(p.description, {
						style = "body",
						color = c.muted,
						wrap = true,
					})
				end

				if selected then
					K.Box({
						modifier = M:fill_max_width()
							:height(4)
							:background(c.primary, K.Shape.rectangle())
							:margin_top("auto"),
					})
				end
			end)
		end)
	end)
end)

return C
