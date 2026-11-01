local wave = require("vd_tower_defence:wave")

local function prev_wave()
	local n = wave.set_current(wave.get_current() - 1)
	print("[TD] " .. wave.describe(n))
end

function on_use(pid)
	prev_wave()
end

function on_use_on_block(x, y, z, pid, normal)
	prev_wave()
	return true
end
