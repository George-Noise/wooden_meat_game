local turret = require("vd_belt_system:turret")

function on_placed(x, y, z, pid)
	turret.ensure_gun(x, y, z)
end

function on_block_present(x, y, z)
	turret.ensure_gun(x, y, z)
end

function on_broken(x, y, z, pid)
	turret.despawn_gun(x, y, z)
end

function on_block_removed(x, y, z)
	turret.despawn_gun(x, y, z)
end

function on_block_tick(x, y, z, tps)
	turret.tick(x, y, z, tps)
end

function on_interact(x, y, z, pid)
	return turret.on_interact(x, y, z, pid)
end
