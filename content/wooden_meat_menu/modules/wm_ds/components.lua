local K = require("kompot:kompot")
local T = require("wooden_meat_menu:wm_ds/tokens")
local M = K.M

local C = {}

local SIZES = {
	sm = { h = "height_sm", pad = "pad_sm", style = "label" },
	md = { h = "height_md", pad = "pad_md", style = "button" },
	lg = { h = "height_lg", pad = "pad_lg", style = "button" },
}

-- Возвращает смещение при hover против направления тени - если тень влево (dx<0), двигается вправо, и наоборот.
local function hover_lift_xy(dir, lift)
	local dx, dy = dir[1] or 0, dir[2] or 0
	local sx = dx ~= 0 and (dx > 0 and -1 or 1) or 0
	return sx * lift, -lift
end

C.Button = K.component(function(p, content)
	p = T.props("Button", p)
	local t = T.current()
	local c, mt, mo = t.colors, t.metrics, t.motion
	local pill = t.shapes.pill

	local inter = K.interaction()
	local enabled = p.enabled ~= false
	local hovered = enabled and (inter.hovered.value or inter.focused.value) or false
	local down = enabled and inter.pressed.value or false

	local v = T.variant(t, p.variant)
	local size = SIZES[p.size or "md"] or SIZES.md

	local dir = T.resolve_shadow(mt.shadow_direction)
	local sdx, sdy = dir[1], dir[2]
	local hx, hy = hover_lift_xy(dir, mt.shadow_hover_lift or 2)

	local face_tx, face_ty = 0, 0
	if enabled and v.shadow ~= false then
		if down then
			face_tx, face_ty = sdx, sdy
		elseif hovered then
			face_tx, face_ty = hx, hy
		end
	end
	local pos_spec = down and mo.press or mo.release
	local fx = K.animate(face_tx, pos_spec)
	local fy = K.animate(face_ty, pos_spec)

	local fill_target = v.fill
	if not enabled then
		fill_target = c.disabled_bg
	elseif down then
		fill_target = v.pressed
	elseif hovered then
		fill_target = v.hover
	end
	local fill = K.animate(fill_target, mo.color)

	local edge = enabled and v.edge or c.disabled_edge
	local fg = enabled and v.text or c.disabled_fg

	local face = M:height(mt[size.h])
	if p.width then
		face = face:width(p.width)
	elseif p.min_width then
		face = face:width_in(p.min_width, 100000)
	end
	if p.fill_width then
		face = face:fill_max_width()
	end
	face = face:offset(fx, fy):background(fill, pill):border(mt.border, edge, pill)
	if p.clip_input ~= false then
		face = face:clip(pill)
	end
	face = face:clickable(p.on_click, {
		interaction = inter,
		enabled = enabled,
		on_right_click = p.on_right_click,
		focus_color = c.focus_ring,
		focus_shape = pill,
	}):padding(mt[size.pad], 0)

	local outer = p.modifier or M
	if p.fill_width then
		outer = outer:fill_max_width()
	end

	K.Box({ modifier = outer }, function()
		if v.shadow ~= false and enabled then
			K.Box({
				modifier = M:match_parent_size():offset(sdx, sdy):background(edge, pill),
			})
		end
		K.Box({ modifier = face, align = "center" }, function()
			K.Row({ modifier = M, spacing = mt.gap, align = "center" }, function()
				K.ContentColor(fg, function()
					if p.icon then
						K.Icon(p.icon, { size = mt.icon })
					end
					if content then
						content()
					elseif p.text then
						K.Text(p.text, {
							style = p.text_style or size.style,
							color = fg,
							wrap = false,
						})
					end
				end)
			end)
		end)
	end)
end)

return C
