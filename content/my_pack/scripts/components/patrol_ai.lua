local patrol_size = (ARGS and ARGS.patrol_size) or 5.0
local move_speed = (ARGS and ARGS.move_speed) or 5.0
local wait_time = (ARGS and ARGS.wait_time) or 0.5

local spawn_pos = nil
local current_corner = 1
local target_pos = nil
local wait_timer = 0.0
local state = "moving"

local function get_corners()
	local half = patrol_size / 2.0
	return {
		{ spawn_pos[1] - half, spawn_pos[2], spawn_pos[3] - half },
		{ spawn_pos[1] + half, spawn_pos[2], spawn_pos[3] - half },
		{ spawn_pos[1] + half, spawn_pos[2], spawn_pos[3] + half },
		{ spawn_pos[1] - half, spawn_pos[2], spawn_pos[3] + half },
	}
end

function on_update(tps)
	if not target_pos then
		return
	end

	local pos = entity.transform:get_pos()
	local vel = entity.rigidbody and entity.rigidbody:get_vel() or { 0, 0, 0 }

	if state == "waiting" then
		wait_timer = wait_timer - 1.0 / tps
		if wait_timer <= 0 then
			current_corner = (current_corner % 4) + 1
			target_pos = get_corners()[current_corner]
			state = "moving"
		end

		if entity.rigidbody then
			entity.rigidbody:set_vel({ 0, vel[2], 0 })
		end
		return
	end

	local dx = target_pos[1] - pos[1]
	local dy = target_pos[2] - pos[2]
	local dz = target_pos[3] - pos[3]
	local dist_2d = math.sqrt(dx * dx + dz * dz)

	if dist_2d < 0.2 then
		state = "waiting"
		wait_timer = wait_time
	else
		local len_2d = dist_2d
		local dir_x = dx / len_2d
		local dir_z = dz / len_2d

		if entity.rigidbody then
			-- local type_comp = entity:get_component("my_pack:enemy_type")
			-- local enemy_type = "ground"
			-- if type_comp and type(type_comp) == "table" and type_comp.get_type then
			-- 	enemy_type = type_comp:get_type()
			-- end

			-- if enemy_type == "flying" then
			-- local dist_3d = math.sqrt(dx * dx + dy * dy + dz * dz)
			-- if dist_3d > 0 then
			-- 	local dir_y = dy / dist_3d
			-- 	vel = {
			-- 		dir_x * move_speed,
			-- 		dir_y * move_speed,
			-- 		dir_z * move_speed,
			-- 	}
			-- end
			-- else
			vel[1] = dir_x * move_speed
			vel[3] = dir_z * move_speed
			-- end
			entity.rigidbody:set_vel(vel)
		end
	end
end

local function on_spawn()
	spawn_pos = entity.transform:get_pos()
	target_pos = get_corners()[current_corner]
end

on_spawn()
