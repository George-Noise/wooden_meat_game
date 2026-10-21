local enemy_type = (ARGS and ARGS.enemy_type) or "ground"

function get_type()
	return enemy_type
end

function on_spawn()
	print("[EnemyType] Инициализация врага типа: " .. enemy_type)

	-- TODO если враг летающий
	-- if enemy_type == "flying" and entity.rigidbody then
	--     entity.rigidbody:set_gravity_scale(0.0)
	-- end
end
