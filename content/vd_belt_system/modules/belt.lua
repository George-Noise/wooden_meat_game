local belt = {}

local BELT_BLOCK = "vd_belt_system:transport_belt"
local CREATOR_BLOCK = "vd_belt_system:creator_belt"
local DESTROYER_BLOCK = "vd_belt_system:destroyer_belt"
local JUNCTION_BLOCK = "vd_belt_system:junction"
local SPLITTER_BLOCK = "vd_belt_system:splitter"
local TURRET_BLOCK = "vd_belt_system:turret"
local BELT_ITEM_ENTITY = "vd_belt_system:belt_item"
local COMPONENT = "vd_belt_system:belt_item"
local SPEED = 2.0
local ITEM_HEIGHT = 0.6
local DIR_BITS_OFFSET = 4
local DIR_BITS_WIDTH = 3
local DIRS = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }

function belt.dir_code_of_vec(dx, dz)
	if dx == 1 then
		return 0
	end
	if dz == 1 then
		return 1
	end
	if dx == -1 then
		return 2
	end
	return 3
end

function belt.get_stored_dir(x, y, z)
	local ok, v = pcall(block.get_user_bits, x, y, z, DIR_BITS_OFFSET, DIR_BITS_WIDTH)
	if ok and type(v) == "number" and v > 0 then
		return v - 1
	end
	return nil
end

function belt.set_stored_dir(x, y, z, code)
	pcall(block.set_user_bits, x, y, z, DIR_BITS_OFFSET, DIR_BITS_WIDTH, (code or 0) + 1)
end

function belt.dir_rotation_of_code(code)
	return (3 - code) % 4
end

function belt.sync_engine_rotation(x, y, z, code)
	if not code or not block.set_rotation then
		return
	end
	block.set_rotation(x, y, z, belt.dir_rotation_of_code(code))
end

function belt.sync_stored_dir(x, y, z)
	local dx, _, dz = block.get_Z(x, y, z)
	if not dx then
		return
	end
	dx = -math.floor(dx + 0.5)
	dz = -math.floor(dz + 0.5)
	if dx == 0 and dz == 0 then
		return
	end
	belt.set_stored_dir(x, y, z, belt.dir_code_of_vec(dx, dz))
end

function belt.get_belt_type(x, y, z)
	local block_id = block.get(x, y, z)
	if block_id == block.index(BELT_BLOCK) then
		return "belt"
	elseif block_id == block.index(CREATOR_BLOCK) then
		return "creator"
	elseif block_id == block.index(DESTROYER_BLOCK) then
		return "destroyer"
	elseif block_id == block.index(JUNCTION_BLOCK) then
		return "junction"
	elseif block_id == block.index(SPLITTER_BLOCK) then
		return "splitter"
	elseif block_id == block.index(TURRET_BLOCK) then
		return "turret"
	end
	return nil
end

function belt.is_belt(x, y, z)
	return belt.get_belt_type(x, y, z) ~= nil
end

function belt.is_creator(x, y, z)
	return belt.get_belt_type(x, y, z) == "creator"
end

function belt.is_destroyer(x, y, z)
	return belt.get_belt_type(x, y, z) == "destroyer"
end

function belt.is_junction(x, y, z)
	return belt.get_belt_type(x, y, z) == "junction"
end

function belt.is_splitter(x, y, z)
	return belt.get_belt_type(x, y, z) == "splitter"
end

function belt.is_turret(x, y, z)
	return belt.get_belt_type(x, y, z) == "turret"
end

function belt.get_belt_direction(x, y, z)
	local btype = belt.get_belt_type(x, y, z)
	if btype ~= "belt" and btype ~= "creator" and btype ~= "destroyer" then
		return nil, nil
	end

	if btype == "belt" then
		local code = belt.get_stored_dir(x, y, z)
		if code then
			local d = DIRS[code + 1]
			return d[1], d[2]
		end
	end
	local dx, _, dz = block.get_Z(x, y, z)
	if not dx then
		return nil, nil
	end

	dx = -math.floor(dx + 0.5)
	dz = -math.floor(dz + 0.5)
	if dx == 0 and dz == 0 then
		return nil, nil
	end
	return dx, dz
end

local function axis_of(dx, dz)
	return (dx ~= 0) and "x" or "z"
end

function belt.is_belt_free(x, y, z, from_dx, from_dz, requesting_ent)
	local btype = belt.get_belt_type(x, y, z)
	if not btype or btype == "creator" then
		return false
	end

	if btype == "junction" then
	elseif btype == "splitter" or btype == "turret" then
	else
		local dx, dz = belt.get_belt_direction(x, y, z)
		if not dx then
			return false
		end
		if dx == -from_dx and dz == -from_dz then
			return false
		end
	end

	if btype == "turret" then
		local turret = require("vd_belt_system:turret")
		local item_id
		if requesting_ent then
			local comp = requesting_ent:get_component(COMPONENT)
			if comp and comp.get_item_id then
				item_id = comp.get_item_id()
			end
		end
		if not turret.can_accept(x, y, z, item_id) then
			return false
		end
	end

	local axis = axis_of(from_dx, from_dz)
	local center = { x + 0.5, y + ITEM_HEIGHT, z + 0.5 }
	local nearby = entities.get_all_in_radius(center, 1.5)

	for _, uid in ipairs(nearby) do
		if not (requesting_ent and uid == requesting_ent:get_uid()) then
			local ent = entities.get(uid)
			if ent and ent:def_name() == BELT_ITEM_ENTITY then
				local component = ent:get_component(COMPONENT)
				if component then
					if component.is_on_belt and component.is_on_belt(x, y, z) then
						if not (component.is_leaving_belt and component.is_leaving_belt(x, y, z)) then
							if btype ~= "junction" then
								return false
							end
							if component.get_axis and component.get_axis() == axis then
								return false
							end
						end
					end
					if component.is_moving_to and component.is_moving_to(x, y, z) then
						if btype ~= "junction" then
							return false
						end
						if component.get_target_axis and component.get_target_axis() == axis then
							return false
						end
					end
				end
			end
		end
	end

	return true
end

function belt.place_item(x, y, z, item_id, count, data)
	if not item_id or item_id <= 0 then
		return false
	end
	if not belt.is_belt(x, y, z) then
		return false
	end

	if belt.is_turret(x, y, z) then
		local turret = require("vd_belt_system:turret")
		return turret.load(x, y, z, item_id, 1) > 0
	end

	local center = { x + 0.5, y + ITEM_HEIGHT, z + 0.5 }
	for _, uid in ipairs(entities.get_all_in_radius(center, 0.8)) do
		local ent = entities.get(uid)
		if ent and ent:def_name() == BELT_ITEM_ENTITY then
			local component = ent:get_component(COMPONENT)
			if component and component.is_on_belt and component.is_on_belt(x, y, z) then
				return false
			end
		end
	end

	local ent = entities.spawn(BELT_ITEM_ENTITY, center)
	if not ent then
		print("[belt] failed to spawn " .. BELT_ITEM_ENTITY)
		return false
	end

	local rig = ent.skeleton
	if rig then
		rig:set_model(0, item.model_name(item_id))
	end

	local component = ent:get_component(COMPONENT)
	if not component then
		print("[belt] component not found: " .. COMPONENT)
		ent:despawn()
		return false
	end

	component.init(item_id, count or 1, data, x, y, z)
	return true
end

function belt.get_all_belt_items()
	local result = {}
	for _, ent in pairs(entities.get_all()) do
		if ent:def_name() == BELT_ITEM_ENTITY then
			table.insert(result, ent)
		end
	end
	table.sort(result, function(a, b)
		return a:get_uid() < b:get_uid()
	end)
	return result
end

function belt.tick(tps)
	local items = belt.get_all_belt_items()
	local delta = 1.0 / tps

	table.sort(items, function(a, b)
		local componentA = a:get_component(COMPONENT)
		local componentB = b:get_component(COMPONENT)

		local priorityA = componentA and componentA.get_plan_priority and componentA.get_plan_priority() or 0
		local priorityB = componentB and componentB.get_plan_priority and componentB.get_plan_priority() or 0

		if priorityA ~= priorityB then
			return priorityA > priorityB
		end
		return a:get_uid() < b:get_uid()
	end)

	for _, ent in ipairs(items) do
		local component = ent:get_component(COMPONENT)
		if component and component.plan then
			component.plan()
		end
	end

	for _, ent in ipairs(items) do
		local component = ent:get_component(COMPONENT)
		if component and component.execute then
			component.execute(delta)
		end
	end
end

function belt.get_speed()
	return SPEED
end

function belt.get_item_height()
	return ITEM_HEIGHT
end

local splitter_counter = {}

function belt.splitter_peek(x, y, z, n)
	if n <= 0 then
		return 1
	end
	local key = x .. "," .. y .. "," .. z
	return (splitter_counter[key] or 0) % n + 1
end

function belt.splitter_commit(x, y, z)
	local key = x .. "," .. y .. "," .. z
	splitter_counter[key] = (splitter_counter[key] or 0) + 1
end

return belt
