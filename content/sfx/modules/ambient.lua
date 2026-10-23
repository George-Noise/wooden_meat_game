--[[
  gust - порыв
  rising - подъём
  falling - спад
--]]

local BROWN = "sounds/pixabay.com_brown_noise___themediaguy-soft-soothing-deep-white-noise-378857.ogg"
local PINK = "sounds/pixabay.com_pink_noise___danevaer-low-pink-noise-434732.ogg"
-- local CAVE = "sounds/cave.ogg"

local ambient = {}

local field_stream
local wind_stream
local cave_stream

local wind_volume = 0.0
local peak_volume = 0.0
local gust_phase = "idle" -- "idle" | "rising" | "falling"
local gust_timer = 0.0
local next_gust_time = 3.0
local NEXT_GUST_MIN = 4.0
local NEXT_GUST_MAX = 16.0
local RISE_SPEED = 0.2
local FALL_SPEED = 0.05
local DELTA_TIME = 0.05

function ambient.on_hud_open()
	field_stream = audio.play_stream_2d(BROWN, 0.05, 1.0, "ambient", true)
	wind_stream = audio.play_stream_2d(PINK, 0.0, 1.0, "ambient", true)
	-- cave_stream = audio.play_stream_2d(CAVE, 1.0, 1.0, "ambient", true)
end

function ambient.on_world_tick()
	-- print(wind_volume)

	if gust_phase == "idle" then
		idle()
	elseif gust_phase == "rising" then
		rising()
	elseif gust_phase == "falling" then
		falling()
	end

	audio.set_volume(wind_stream, wind_volume)
end

function idle()
	gust_timer = gust_timer + DELTA_TIME
	if gust_timer >= next_gust_time then
		gust_timer = 0.0
		peak_volume = 0.15 + math.random() * 0.25
		gust_phase = "rising"
	end
end

function rising()
	wind_volume = math.min(peak_volume, wind_volume + RISE_SPEED * DELTA_TIME)
	if wind_volume >= peak_volume then
		gust_phase = "falling"
	end
end

function falling()
	wind_volume = math.max(0.0, wind_volume - FALL_SPEED * DELTA_TIME)
	if wind_volume <= 0.0 then
		gust_phase = "idle"
		gust_timer = 0.0
		next_gust_time = NEXT_GUST_MIN + (NEXT_GUST_MAX - NEXT_GUST_MIN) * math.random()
	end
end

return ambient
