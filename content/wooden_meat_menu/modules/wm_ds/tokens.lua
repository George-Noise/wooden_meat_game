local K = require("kompot:kompot")
local color = K.color
local hex = K.hex
local S = K.Shape

local T = {}

T.PALETTE = {
	ink = hex("#0B2B26"),
	paper = hex("#0E1715"),
	surface = hex("#182A26"),
	text = hex("#EAF6F1"),
	muted = hex("#8FAFA6"),
	turquoise = hex("#2EC4B6"),
	coral = hex("#FF6B57"),
}
local P = T.PALETTE

local function lighten(c, a)
	return color.mix(c, hex("#FFFFFF"), a)
end
local function deepen(c, a)
	return color.mix(c, P.ink, a)
end

T.METRICS = {
	height_sm = 34,
	height_md = 44,
	height_lg = 56,
	pad_sm = 16,
	pad_md = 22,
	pad_lg = 30,
	border = 3,
	shadow_direction = { -5, 5 },
	shadow_hover_lift = 2,
	icon = 18,
	gap = 8,
	scroll_w = 32,
	scroll_thumb_min_ratio = 0.10,
	scroll_thumb_max_ratio = 0.75,
}

T.MOTION = {
	color = K.tween(0.12),
	shadow = K.tween(0.18, "out_quad"),
	press = K.tween(0.07, "out_quad"),
	release = K.tween(0.22, "out_back"),
}

T.SHADOW_DIRECTIONS = {
	bottom_left = { -5, 5 },
	bottom_right = { 5, 5 },
	top_left = { -5, -5 },
	top_right = { 5, -5 },
	bottom = { 0, 5 },
	top = { 0, -5 },
}

local function variants()
	local sec = color.mix(P.surface, P.turquoise, 0.16)
	return {
		primary = {
			fill = P.turquoise,
			hover = lighten(P.turquoise, 0.16),
			pressed = deepen(P.turquoise, 0.14),
			edge = P.ink,
			text = P.ink,
		},
		secondary = {
			fill = sec,
			hover = color.mix(sec, P.turquoise, 0.16),
			pressed = deepen(sec, 0.35),
			edge = P.ink,
			text = color.mix(P.text, P.turquoise, 0.35),
		},
		danger = {
			fill = P.coral,
			hover = lighten(P.coral, 0.14),
			pressed = deepen(P.coral, 0.16),
			edge = P.ink,
			text = P.ink,
		},
		ghost = {
			fill = color.with_alpha(P.turquoise, 0),
			hover = color.with_alpha(P.turquoise, 0.14),
			pressed = color.with_alpha(P.turquoise, 0.22),
			edge = color.with_alpha(P.ink, 0),
			text = P.turquoise,
			shadow = false,
		},
	}
end

function T.theme(opts)
	local colors = {
		background = P.paper,
		on_background = P.text,
		surface = P.surface,
		surface_raised = color.mix(P.surface, P.turquoise, 0.08),
		on_surface = P.text,
		muted = P.muted,
		primary = P.turquoise,
		on_primary = P.ink,
		outline = color.mix(P.surface, P.text, 0.25),
		error = P.coral,
		success = hex("#7DBF5A"),
		warning = hex("#F2B84B"),
		ink = P.ink,
		focus_ring = hex("#EAFFF8"),
		disabled_bg = color.mix(P.surface, P.paper, 0.55),
		disabled_fg = color.mix(P.muted, P.surface, 0.5),
		disabled_edge = color.mix(P.ink, P.surface, 0.45),
		variants = variants(),
	}

	local base = {
		name = "wooden-meat",
		dark = true,
		wooden_meat = true,
		colors = colors,
		type = {
			-- 1.5rem = 24px: движок масштабирует kompot_sb_20 до size
			caption = { font = "kompot_12", bold = "kompot_sb_12", size = 12 },
			body = { font = "kompot_14", bold = "kompot_sb_14", size = 14 },
			label = { font = "kompot_sb_14", size = 14 },
			button = { font = "kompot_sb_20", bold = "kompot_sb_20", size = 24 },
			strong = { font = "kompot_sb_20", bold = "kompot_sb_20", size = 24 },
			title = { font = "kompot_sb_20", size = 20 },
			heading = { font = "kompot_sb_20", size = 20 },
			display = { font = "kompot_32", size = 32 },
			mono = { font = "kompot_mono_13", size = 13 },
		},
		default_style = "body",
		icons = "kompot_ui_icons",
		metrics = T.METRICS,
		motion = T.MOTION,
		shapes = { pill = S.rounded(S.percent(50)) },
		components = {},
		ui = T.ui,
	}
	return K.extend_theme(base, opts or {})
end

T.DEFAULT = T.theme()

function T.current()
	local t = K.theme()
	return t.wooden_meat and t or T.DEFAULT
end

function T.props(name, props)
	local defaults = T.current().components[name]
	if not defaults then
		return props or {}
	end
	local out = {}
	for k, v in pairs(defaults) do
		out[k] = v
	end
	for k, v in pairs(props or {}) do
		out[k] = v
	end
	return out
end

function T.variant(t, name)
	local v = t.colors.variants or T.DEFAULT.colors.variants
	return v[name or "primary"] or v.primary
end

function T.resolve_shadow(dir)
	if type(dir) == "string" then
		return T.SHADOW_DIRECTIONS[dir] or T.SHADOW_DIRECTIONS.bottom_left
	end
	if type(dir) == "table" then
		return { dir[1] or 0, dir[2] or 0 }
	end
	return T.SHADOW_DIRECTIONS.bottom_left
end

return T
