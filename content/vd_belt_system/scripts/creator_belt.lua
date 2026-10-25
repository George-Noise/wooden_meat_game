local belt_interact = require("vd_belt_system:belt_interact")

function on_interact(x, y, z, pid)
	return belt_interact.on_interact(x, y, z, pid)
end