local cooldown = 1.0
local search_radius = 50.0

local skeleton = entity.skeleton
local gun_hand_idx = skeleton and skeleton:index("gun_hand")
local last_target_uid = nil

local MUZZLE_FLASH = {
	texture = "gfx/muzzle_flash",
	lifetime = 0.05,
	spawn_interval = 0,
	count = 10,
	size = { 0.1, 0.1, 0.1 },
	velocity = { 0, 0, 0 },
	explosion = { 3, 3, 3 },
	spawn_shape = "sphere",
	lighting = false,
	acceleration = { 0, 0, 0 },
}

local TRACER = {
	texture = "gfx/tracer",
	lifetime = 1.08,
	spawn_interval = 0,
	count = 1,
	size = { 0.1, 0.1, 0.1 },
	spawn_shape = "box",
	spawn_spread = { 0, 0, 0 },
	lighting = false,
	acceleration = { 0, 0, 0 },
}

function on_update(tps)
	cooldown = cooldown - 1.0 / tps

	local target = find_target()

	if target then
		if last_target_uid ~= target.uid then
			print("[Turret] Цель обнаружена: UID " .. target.uid)
			last_target_uid = target.uid
		end

		aim_gun_at(target.pos)

		if cooldown <= 0 then
			fire(target)
			cooldown = 1.0
		end
	else
		if last_target_uid then
			print("[Turret] Цель потеряна")
			last_target_uid = nil
		end
	end
end

function find_target()
	local pos = entity.transform:get_pos()
	local all_entities = entities.get_all()

	if not all_entities then
		return nil
	end

	local closest_target = nil
	local closest_dist = search_radius

	for uid, target in pairs(all_entities) do
		if uid ~= entity:get_uid() then
			local has_health = target.has_component and target:has_component("my_pack:health")
			if has_health then
				local t_pos = target.transform:get_pos()
				local dx = t_pos[1] - pos[1]
				local dy = t_pos[2] - pos[2]
				local dz = t_pos[3] - pos[3]
				local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

				if dist < closest_dist then
					closest_dist = dist
					closest_target = { uid = uid, pos = t_pos }
				end
			end
		end
	end

	return closest_target
end

-- muzzle - дуло, но позиция не совсем верная, это центр ружъя, TODO переименовать может быть когда нибудь
function get_muzzle_pos()
	local pos = entity.transform:get_pos()
	return {
		pos[1],
		pos[2] + 0.5,
		pos[3],
	}
end

function fire(target)
	local muzzle = get_muzzle_pos()

	local dir = {
		target.pos[1] - muzzle[1],
		target.pos[2] - muzzle[2],
		target.pos[3] - muzzle[3],
	}

	local len = math.sqrt(dir[1] * dir[1] + dir[2] * dir[2] + dir[3] * dir[3])
	if len == 0 then
		print("[Turret] Ошибка: цель в точке выстрела")
		return
	end
	dir[1] = dir[1] / len
	dir[2] = dir[2] / len
	dir[3] = dir[3] / len

	local start_pos = {
		muzzle[1] + dir[1] * 0.3,
		muzzle[2] + dir[2] * 0.3,
		muzzle[3] + dir[3] * 0.3,
	}

	local muzzle_pos = {
		muzzle[1] + dir[1] * 0.6,
		muzzle[2] + dir[2] * 0.6,
		muzzle[3] + dir[3] * 0.6,
	}

	audio.play_sound("shotgun", start_pos[1], start_pos[2], start_pos[3], 0.6, 0.6)
	audio.play_sound("shotgun", start_pos[1], start_pos[2], start_pos[3], 0.6, 0.4)
	gfx.particles.emit(muzzle_pos, 8, MUZZLE_FLASH)
	gfx.particles.emit(muzzle_pos, 1, TRACER, { velocity = { dir[1] * 100, dir[2] * 100, dir[3] * 100 } })

	local ray = world.raycast({
		start = start_pos,
		dir = dir,
		distance = search_radius + 2.0,
		entities = true,
		ignore_uid = entity:get_uid(),
	})

	if ray and ray.entity then
		local hit_target = entities.get(ray.entity)
		if hit_target and hit_target:has_component("my_pack:health") then
			local health_comp = hit_target:get_component("my_pack:health")
			health_comp.take_damage(25)
			print("[Turret] Попадание по цели UID: " .. ray.entity)
		else
			print("[Turret] Луч задел сущность без здоровья: " .. ray.entity)
		end
	else
		print("[Turret] Промах")
	end
end

function aim_gun_at(target_world_pos)
	if not gun_hand_idx then
		return
	end

	local muzzle = get_muzzle_pos()

	local dir = {
		target_world_pos[1] - muzzle[1],
		target_world_pos[2] - muzzle[2],
		target_world_pos[3] - muzzle[3],
	}

	local len = math.sqrt(dir[1] * dir[1] + dir[2] * dir[2] + dir[3] * dir[3])
	if len == 0 then
		return
	end
	dir[1] = dir[1] / len
	dir[2] = dir[2] / len
	dir[3] = dir[3] / len

	local entity_rot = entity.transform:get_rot()
	local inv_rot = mat4.inverse(entity_rot)
	local local_dir = mat4.mul(inv_rot, dir)

	local look_matrix = mat4.inverse(mat4.look_at({ 0, 0, 0 }, local_dir, { 0, 1, 0 }))
	local rotation_fix = mat4.rotate({ 0, 1, 0 }, -90)
	look_matrix = mat4.mul(look_matrix, rotation_fix)

	local current_matrix = skeleton:get_matrix(gun_hand_idx)
	look_matrix[13] = current_matrix[13]
	look_matrix[14] = current_matrix[14]
	look_matrix[15] = current_matrix[15]

	skeleton:set_matrix(gun_hand_idx, look_matrix)
end
