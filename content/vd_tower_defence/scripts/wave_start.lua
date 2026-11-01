local wave = require("vd_tower_defence:wave")

function on_use(pid)
	wave.start()
end

function on_use_on_block(x, y, z, pid, normal)
	wave.start()
	return true
end
