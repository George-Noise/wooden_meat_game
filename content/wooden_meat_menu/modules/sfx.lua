local sfx = {}

local CLICK_SOUNDS = {
	-- "sharpie-on-wood-106784/2",
	-- "sharpie-on-wood-106784/3",
	-- "sharpie-on-wood-106784/4",
	-- "sharpie-on-wood-106784/6",
	-- "sharpie-on-wood-106784/7",
	"sharpie-on-wood-106784/8",
	-- "sharpie-on-wood-106784/9",
}

local HOVER_SOUNDS = {
	"sharpie-on-wood-106784/1",
}

local function random_sound(sounds)
	return sounds[math.random(#sounds)]
end

function sfx.main_menu_btn_click(volume, pitch)
  -- print("function sfx.main_menu_btn_click(volume, pitch)")
	volume = volume or 1.0
	pitch = pitch or 1.0
	audio.play_sound_2d(random_sound(CLICK_SOUNDS), volume, pitch)
end

function sfx.main_menu_btn_hover(volume, pitch)
	volume = volume or 0.6
	pitch = pitch or 1.0
	audio.play_sound_2d(random_sound(HOVER_SOUNDS), volume, pitch)
end

return sfx
