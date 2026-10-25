local belt = {}

local BELT_BLOCK = "vd_belt_system:transport_belt"
local CREATOR_BLOCK = "vd_belt_system:creator_belt"
local DESTROYER_BLOCK = "vd_belt_system:destroyer_belt"
local BELT_ITEM_ENTITY = "vd_belt_system:belt_item"
local COMPONENT = "vd_belt_system:belt_item"
local SPEED = 2.0
local ITEM_HEIGHT = 0.6

function belt.get_belt_type(x, y, z)
	local block_id = block.get(x, y, z)
	if block_id == block.index(BELT_BLOCK) then
		return "belt"
	elseif block_id == block.index(CREATOR_BLOCK) then
		return "creator"
	elseif block_id == block.index(DESTROYER_BLOCK) then
		return "destroyer"
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

function belt.get_belt_direction(x, y, z)
	if not belt.is_belt(x, y, z) then
		return nil, nil
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

function belt.is_belt_free(x, y, z, from_dx, from_dz, requesting_ent)
	if not belt.is_belt(x, y, z) then
		return false
	end

	if belt.is_creator(x, y, z) then
		return false
	end

	local dx, dz = belt.get_belt_direction(x, y, z)
	if not dx then
		return false
	end

	if dx == -from_dx and dz == -from_dz then
		return false
	end

	local center = { x + 0.5, y + ITEM_HEIGHT, z + 0.5 }
	local nearby = entities.get_all_in_radius(center, 1.5)

	for _, uid in ipairs(nearby) do
		if not (requesting_ent and uid == requesting_ent:get_uid()) then
			local ent = entities.get(uid)
			if ent and ent:def_name() == BELT_ITEM_ENTITY then
				local component = ent:get_component(COMPONENT)
				if component then
					if component.is_on_belt and component.is_on_belt(x, y, z) then
						if component.is_leaving_belt and component.is_leaving_belt(x, y, z) then
							-- Предмет в фазе moving_forward, скоро уйдёт — не блокируем
						else
							return false
						end
					end
					if component.is_moving_to and component.is_moving_to(x, y, z) then
						return false
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
	-- Детерминированный порядок при слиянии потоков, TODO придумать потом как это сделать лучше
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

	-- Планирование
	-- Кто первый зарезервировал клетку, тот и едет
	for _, ent in ipairs(items) do
		local component = ent:get_component(COMPONENT)
		if component and component.plan then
			component.plan()
		end
	end

	-- Исполнение
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

return belt
