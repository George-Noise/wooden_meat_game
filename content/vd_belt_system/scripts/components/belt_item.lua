local belt = require("vd_belt_system:belt")

local speed = belt.get_speed()
local item_height = belt.get_item_height()
local initialized = false

-- Режим визуальной отладки
local DEBUG_MODE = false
-- Константы цветов для визуальной отладки
local MOVING_COLOR = { 0.2, 0.9, 0.9 }
local WAITING_COLOR = { 1.0, 0.8, 0.0 }
local NO_PATH_COLOR = { 0.9, 0.2, 0.2 }
local DEFAULT_COLOR = { 1.0, 1.0, 1.0 }

local base_matrix = nil

local function get_state()
	if not SAVED_DATA.belt_x then
		SAVED_DATA.belt_x = 0
		SAVED_DATA.belt_y = 0
		SAVED_DATA.belt_z = 0
		SAVED_DATA.item_id = 0
		SAVED_DATA.count = 1
		SAVED_DATA.data = nil
		SAVED_DATA.phase = "centered"
		SAVED_DATA.progress = 0
		SAVED_DATA.direction = { 0, 0 }
		SAVED_DATA.target_direction = { 0, 0 }
		SAVED_DATA.moving_to_x = 0
		SAVED_DATA.moving_to_z = 0
		SAVED_DATA.can_move = false
		SAVED_DATA.creator_cooldown = 0
		SAVED_DATA.size_flip = false
		SAVED_DATA.current_scale = 1.0
		SAVED_DATA.owner_x = 0
		SAVED_DATA.owner_y = 0
		SAVED_DATA.owner_z = 0
		SAVED_DATA.ownership_transferred = false
	end
	return SAVED_DATA
end

function apply_scale(scale)
	if not DEBUG_MODE then return end
	local rig = entity.skeleton
	if not rig then return end
	if not base_matrix then
		base_matrix = rig:get_matrix(0)
	end
	if not base_matrix then return end

	local matrix = {}
	for i = 1, 16 do
		matrix[i] = base_matrix[i]
	end
	matrix[1] = base_matrix[1] * scale
	matrix[6] = base_matrix[6] * scale
	matrix[11] = base_matrix[11] * scale
	rig:set_matrix(0, matrix)
end

function update_visual_state()
	if not DEBUG_MODE then return end
	local state = get_state()
	local rig = entity.skeleton
	if not rig then return end

	local color = DEFAULT_COLOR

	if belt.is_creator(state.owner_x, state.owner_y, state.owner_z) then
		color = DEFAULT_COLOR
	elseif belt.is_destroyer(state.owner_x, state.owner_y, state.owner_z) then
		color = DEFAULT_COLOR
	elseif state.phase == "moving_forward" then
		color = MOVING_COLOR
	elseif state.phase == "centered" then
		local dx, dz = state.direction[1], state.direction[2]
		local nx, ny, nz = state.owner_x + dx, state.owner_y, state.owner_z + dz
		if not belt.is_belt(nx, ny, nz) then
			color = NO_PATH_COLOR
		else
			color = WAITING_COLOR
		end
	end

	rig:set_color(color)
	apply_scale(state.current_scale)
end

function init(item_id, count, data, bx, by, bz)
	local state = get_state()
	state.item_id = item_id
	state.count = count
	state.data = data
	state.belt_x = bx
	state.belt_y = by
	state.belt_z = bz
	state.owner_x = bx
	state.owner_y = by
	state.owner_z = bz
	state.phase = "centered"
	state.progress = 0
	state.can_move = false
	state.size_flip = false
	state.current_scale = 1.0
	state.ownership_transferred = false

	local dx, dz = belt.get_belt_direction(bx, by, bz)
	if dx then
		state.direction = { dx, dz }
	end

	initialized = true

	local rig = entity.skeleton
	if rig then
		rig:set_model(0, item.model_name(item_id))
		if DEBUG_MODE then
			base_matrix = rig:get_matrix(0)
		end
	end

	update_position()
	update_visual_state()
end

function on_save()
end

function is_on_belt(x, y, z)
	local state = get_state()
	return state.belt_x == x and state.belt_y == y and state.belt_z == z
end

function is_moving_to(x, y, z)
	local state = get_state()
	if state.phase ~= "moving_forward" then
		return false
	end
	return state.moving_to_x == x and state.belt_y == y and state.moving_to_z == z
end

function is_leaving_belt(x, y, z)
	local state = get_state()
	if state.phase ~= "moving_forward" then
		return false
	end
	return state.belt_x == x and state.belt_y == y and state.belt_z == z
end

-- Получить логического владельца (для считывателей в будующем)
function get_owner()
	local state = get_state()
	return state.owner_x, state.owner_y, state.owner_z
end

function plan()
	local state = get_state()

	if not initialized then
		local rig = entity.skeleton
		if rig then
			rig:set_model(0, item.model_name(state.item_id))
			if DEBUG_MODE then
				base_matrix = rig:get_matrix(0)
			end
		end
		initialized = true
	end

	if state.phase ~= "centered" then
		return
	end

	if not belt.is_belt(state.belt_x, state.belt_y, state.belt_z) then
		return
	end

	if belt.is_creator(state.belt_x, state.belt_y, state.belt_z) then
		return
	end

	local dx, dz = state.direction[1], state.direction[2]
	local nx, nz = state.belt_x + dx, state.belt_z + dz

	if belt.is_belt_free(nx, state.belt_y, nz, dx, dz, entity) then
		state.moving_to_x = nx
		state.moving_to_z = nz
		state.target_direction = { belt.get_belt_direction(nx, state.belt_y, nz) }
		state.phase = "moving_forward"
		state.progress = 0
		state.can_move = true
		state.ownership_transferred = false
	end
end

function execute(delta)
	local state = get_state()

	if not initialized then
		local rig = entity.skeleton
		if rig then
			rig:set_model(0, item.model_name(state.item_id))
			if DEBUG_MODE then
				base_matrix = rig:get_matrix(0)
			end
		end
		initialized = true
	end

	if not belt.is_belt(state.belt_x, state.belt_y, state.belt_z) then
		drop_item()
		entity:despawn()
		return
	end

	if state.phase == "centered" then
		if belt.is_destroyer(state.belt_x, state.belt_y, state.belt_z) then
			entity:despawn()
			return
		end
	end

	if state.phase == "centered" and belt.is_creator(state.belt_x, state.belt_y, state.belt_z) then
		if not state.creator_cooldown then state.creator_cooldown = 0 end
		state.creator_cooldown = state.creator_cooldown - delta

		if state.creator_cooldown <= 0 then
			local dx, dz = state.direction[1], state.direction[2]
			local nx, ny, nz = state.belt_x + dx, state.belt_y, state.belt_z + dz
			if belt.is_belt(nx, ny, nz) and not belt.is_creator(nx, ny, nz) then
				if belt.place_item(nx, ny, nz, state.item_id, state.count, state.data) then
					state.creator_cooldown = 1.0 / speed
				else
					state.creator_cooldown = 0.1
				end
			else
				state.creator_cooldown = 0.5
			end
		end

		update_position()
		update_visual_state()
		return
	end

	if state.phase == "moving_forward" and state.can_move then
		if
			not belt.is_belt_free(
				state.moving_to_x,
				state.belt_y,
				state.moving_to_z,
				state.direction[1],
				state.direction[2],
				entity
			)
		then
			state.phase = "centered"
			state.progress = 0
			state.can_move = false
			state.ownership_transferred = false
			update_position()
			update_visual_state()
			return
		end

		state.progress = state.progress + speed * delta

		if state.progress >= 0.5 and not state.ownership_transferred then
			state.owner_x = state.moving_to_x
			state.owner_y = state.belt_y
			state.owner_z = state.moving_to_z
			state.ownership_transferred = true

			if DEBUG_MODE then
				state.size_flip = not state.size_flip
				if state.size_flip then
					state.current_scale = 2.0
				else
					state.current_scale = 1.0
				end
			end
		end

		if state.progress >= 1.0 then
			if belt.is_destroyer(state.moving_to_x, state.belt_y, state.moving_to_z) then
				entity:despawn()
				return
			end

			state.belt_x = state.moving_to_x
			state.belt_z = state.moving_to_z
			state.direction = state.target_direction
			state.phase = "centered"
			state.progress = 0
			state.can_move = false
			state.ownership_transferred = false

			-- Планирование следующего движения
			local dx, dz = state.direction[1], state.direction[2]
			local nx, nz = state.belt_x + dx, state.belt_z + dz

			if not belt.is_creator(state.belt_x, state.belt_y, state.belt_z) then
				if belt.is_belt_free(nx, state.belt_y, nz, dx, dz, entity) then
					state.moving_to_x = nx
					state.moving_to_z = nz
					state.target_direction = { belt.get_belt_direction(nx, state.belt_y, nz) }
					state.phase = "moving_forward"
					state.progress = 0
					state.can_move = true
					state.ownership_transferred = false
				end
			end
		end
	end

	update_position()
	update_visual_state()
end

function update_position()
	local state = get_state()
	local tsf = entity.transform

	local x = state.belt_x + 0.5
	local y = state.belt_y + item_height
	local z = state.belt_z + 0.5

	if state.phase == "moving_forward" then
		x = x + state.direction[1] * state.progress
		z = z + state.direction[2] * state.progress
	end

	tsf:set_pos({ x, y, z })
end

function drop_item()
	local state = get_state()
	if not state.item_id or state.item_id <= 0 then return end
	local pos = entity.transform:get_pos()
	entities.spawn("base:drop", pos, {
		["base:drop"] = {
			item = item.name(state.item_id),
			count = state.count,
			data = state.data,
		},
	})
end

function get_plan_priority()
	local state = get_state()
	if state.phase ~= "centered" then return 0 end
	local dx, dz = state.direction[1], state.direction[2]
	if not dx then return 0 end
	local nx, ny, nz = state.belt_x + dx, state.belt_y, state.belt_z + dz
	local ndx, ndz = belt.get_belt_direction(nx, ny, nz)
	if not ndx then return 0 end
	if dx == ndx and dz == ndz then
		return 1
	end
	return 0
end