local wave = require("vd_tower_defence:wave")

local function next_wave()
	local n = wave.set_current(wave.get_current() + 1)
	print("[TD] " .. wave.describe(n))
end

function on_use(pid)
	next_wave()
end

function on_use_on_block(x, y, z, pid, normal)
	next_wave()
	return true
end
