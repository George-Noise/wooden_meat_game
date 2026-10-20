local spawn_entity_name = "my_pack:turret"

function on_use_on_block(x, y, z, playerid, normal)
	entities.spawn(spawn_entity_name, { x + 0.5 + normal[1], y + 0.5 + normal[2], z + 0.5 + normal[3] })
end
