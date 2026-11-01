local turret = require("vd_belt_system:turret")

local cooldown = 0.0
local last_target_uid = nil

local bx = ARGS and ARGS.x
local by = ARGS and ARGS.y
local bz = ARGS and ARGS.z
if not bx then
	local pos = entity.transform:get_pos()
	bx = math.floor(pos[1])
	by = math.floor(pos[2] - 1.0)
	bz = math.floor(pos[3])
end

local skeleton = entity.skeleton
local gun_hand_idx = skeleton and skeleton:index("gun_hand")

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

local function norm3(v)
	local len = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
	if len == 0 then
		return nil
	end
	return { v[1] / len, v[2] / len, v[3] / len }
end

local function dist3(a, b)
	local dx = b[1] - a[1]
	local dy = b[2] - a[2]
	local dz = b[3] - a[3]
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function get_muzzle_pos()
	local pos = entity.transform:get_pos()
	return { pos[1], pos[2] + 0.5, pos[3] }
end

local function find_target()
	local pos = entity.transform:get_pos()
	local all_entities = entities.get_all()
	if not all_entities then
		return nil
	end

	local closest_target = nil
	local closest_dist = turret.SEARCH_RADIUS

	for uid, target in pairs(all_entities) do
		if uid ~= entity:get_uid() then
			for _, comp_name in ipairs(turret.TARGET_COMPONENTS) do
				local has_health = target.has_component and target:has_component(comp_name)
				if has_health then
					local t_pos = target.transform:get_pos()
					local d = dist3(pos, t_pos)
					if d < closest_dist then
						closest_dist = d
						closest_target = {
							uid = uid,
							pos = t_pos,
							comp = comp_name,
						}
					end
					break
				end
			end
		end
	end

	return closest_target
end

function aim_gun_at(target_world_pos)
	if not gun_hand_idx or not skeleton then
		return
	end

	local muzzle = get_muzzle_pos()
	local dir = norm3({
		target_world_pos[1] - muzzle[1],
		target_world_pos[2] - muzzle[2],
		target_world_pos[3] - muzzle[3],
	})
	if not dir then
		return
	end

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

local function fire(target)
	local item_id = turret.take_ammo(bx, by, bz)
	if not item_id then
		return false
	end

	local damage = turret.damage_of_item_id(item_id)
	local muzzle = get_muzzle_pos()
	local dir = norm3({
		target.pos[1] - muzzle[1],
		target.pos[2] - muzzle[2],
		target.pos[3] - muzzle[3],
	})
	if not dir then
		return false
	end

	local start_pos = {
		muzzle[1] + dir[1] * 0.3,
		muzzle[2] + dir[2] * 0.3,
		muzzle[3] + dir[3] * 0.3,
	}

	local flash_pos = {
		muzzle[1] + dir[1] * 0.6,
		muzzle[2] + dir[2] * 0.6,
		muzzle[3] + dir[3] * 0.6,
	}

	pcall(audio.play_sound, "shotgun", start_pos[1], start_pos[2], start_pos[3], 0.6, 0.6)
	pcall(audio.play_sound, "shotgun", start_pos[1], start_pos[2], start_pos[3], 0.6, 0.4)
	pcall(gfx.particles.emit, flash_pos, 8, MUZZLE_FLASH)
	pcall(gfx.particles.emit, flash_pos, 1, TRACER, {
		velocity = { dir[1] * 100, dir[2] * 100, dir[3] * 100 },
	})

	local ray = world.raycast({
		start = start_pos,
		dir = dir,
		distance = turret.SEARCH_RADIUS + 2.0,
		entities = true,
		ignore_uid = entity:get_uid(),
		filter_entities = turret.RAY_EXCLUDE,
		entities_exclusion = true,
	})

	if ray and ray.entity then
		local hit_target = entities.get(ray.entity)
		if hit_target then
			for _, comp_name in ipairs(turret.TARGET_COMPONENTS) do
				if hit_target:has_component(comp_name) then
					local health_comp = hit_target:get_component(comp_name)
					health_comp.take_damage(damage)
					return true
				end
			end
		end
		print("[turret] луч задел сущность без здоровья: " .. tostring(ray.entity))
		return true
	end

	return true
end

function on_update(tps)
	if not turret.is_turret_block(bx, by, bz) then
		entity:despawn()
		return
	end

	cooldown = cooldown - 1.0 / tps
	if cooldown < 0 then
		cooldown = 0
	end

	if turret.get_ammo_count(bx, by, bz) <= 0 then
		return
	end

	local target = find_target()
	if not target then
		last_target_uid = nil
		return
	end

	if last_target_uid ~= target.uid then
		print(
			"[turret] цель обнаружена: UID "
				.. target.uid
				.. " (блок "
				.. bx
				.. ","
				.. by
				.. ","
				.. bz
				.. ")"
		)
		last_target_uid = target.uid
	end

	aim_gun_at(target.pos)

	if cooldown <= 0 then
		if fire(target) then
			cooldown = turret.FIRE_COOLDOWN
		end
	end
end
