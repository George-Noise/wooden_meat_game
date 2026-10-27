local K = require("kompot:kompot")
local T = require("wooden_meat_menu:wm_ds/tokens")
local M = K.M

local C = {}

C.Scrollbar = K.component(function(p)
	local t = T.current()
	local c, mt = t.colors, t.metrics
	local state = p.state
	assert(state, "Scrollbar: props.state required (K.scroll_state())")

	local inter = K.interaction()
	local track_h = K.state(0)

	local fraction, visible = state:fraction()

	local h = track_h.value
	local thumb_h = 0
	if h > 0 and state.max > 0 then
		thumb_h = visible * h
		local min_h = h * (mt.scroll_thumb_min_ratio or 0.10)
		local max_h = h * (mt.scroll_thumb_max_ratio or 0.75)
		if thumb_h < min_h then
			thumb_h = min_h
		end
		if thumb_h > max_h then
			thumb_h = max_h
		end
	end
	local travel = h - thumb_h
	local y = travel > 0 and fraction * travel or 0

	local v = T.variant(t, "primary")
	local thumb_fill = c.primary
	if inter.pressed.value then
		thumb_fill = v.pressed
	elseif inter.hovered.value then
		thumb_fill = v.hover
	end

	K.Box({
		modifier = (p.modifier or M)
			:width(mt.scroll_w)
			:fill_max_height()
			:on_size(function(_, hh)
				track_h.value = hh
			end)
			:background(c.ink)
			:on_wheel(function(delta)
				return state:scroll_by(-delta * state.step) ~= 0
			end),
	}, function()
		if thumb_h > 0 then
			K.Box({
				modifier = M:fill_max_width():height(thumb_h):offset(0, y):background(thumb_fill):draggable({
					axis = 2,
					interaction = inter,
					on_event = function(e)
						if e.type == "move" and travel > 0 then
							state:scroll_by(e.parent_dy * (state.max / travel))
						end
					end,
				}),
			})
		end
	end)
end)

return C
