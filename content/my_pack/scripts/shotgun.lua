function on_use(pid)
	audio.play_sound_2d("shotgun", 1.0, 1.0)
	audio.play_sound_2d("shotgun", 1.0, 0.8)

	-- local pos = { player.get_pos(pid) }
	local dir = player.get_dir(pid)
	local cam_index = player.get_camera(pid)
	local cam = cameras.get(cam_index)
	local cam_pos = cam:get_pos()

	local ray = world.raycast({
		start = cam_pos,
		dir = dir,
		distance = 50.0,
		entities = true,
		ignore_uid = player.get_entity(pid),
	})

	if ray and ray.entity then
		local target = entities.get(ray.entity)
		if target and target:has_component("my_pack:health") then
			local health_comp = target:get_component("my_pack:health")
			health_comp.take_damage(25)
			print("[Shotgun Игрок]  " .. pid .. " попал в цель UID: " .. ray.entity)
		else
			print("[Shotgun Игрок] - Цель не имеет компонента здоровья")
		end
	else
		print("[Shotgun Игрок] Промах")
	end
end
