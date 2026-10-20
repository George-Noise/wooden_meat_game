function on_used(pid)

	print("[turret] Активирована игроком " .. pid)
	local pos = entity.transform:get_pos()
	local player_dir = player.get_dir(pid)

	local start = {
		pos[1],
		pos[2] + 0.5,
		pos[3],
	}

	local dir = {
		player_dir[1],
		0,
		player_dir[3],
	}
	
	-- audio.play_sound_2d("shotgun", 1.0, 1.0)
	-- audio.play_sound_2d("shotgun", 1.0, 0.8)
	audio.play_sound("shotgun", start[1], start[2], start[3], 1.0, 1.0)
	audio.play_sound("shotgun", start[1], start[2], start[3], 1.0, 0.8)

	local ray = world.raycast({
		start = start,
		dir = dir,
		distance = 50.0,
		entities = true,
		ignore_uid = entity:get_uid(),
	})

	if ray and ray.entity then
		local target = entities.get(ray.entity)
		if target and target:has_component("my_pack:health") then
			local health_comp = target:get_component("my_pack:health")
			health_comp.take_damage(25)
			print("[turret] Стойка попала в цель UID: " .. ray.entity)
		else
			print("[turret] Цель не имеет компонента здоровья")
		end
	else
		print("[turret] Стойка промахнулась!")
	end
end


