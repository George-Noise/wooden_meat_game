local belt_interact = require("vd_belt_system:belt_interact")

function on_interact(x, y, z, pid)
	return belt_interact.on_interact(x, y, z, pid)
end

function on_placed(x, y, z)
	local belt = require("vd_belt_system:belt")
	if belt.get_belt_type(x, y, z) == "belt" then
		belt.sync_stored_dir(x, y, z)
	end
end
