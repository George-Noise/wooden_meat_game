local TPS = 20

local belt = require("vd_belt_system:belt")
local factory = require("vd_belt_system:factory")
local recipes = require("vd_belt_system:recipes")

local FACTORY_BLOCK = "vd_belt_system:factory_1"
local BELT_ITEM_ENTITY = "vd_belt_system:belt_item"
local COMPONENT = "vd_belt_system:belt_item"

local RECIPES = { "stone_sand", "glass_metal" }

local FACTORY_SIZE = { 3, 2, 3 }
local DEBUG = true

local function log(...)
	if DEBUG then
		print("[factory_1]", ...)
	end
end

local function find_origin(x, y, z)
	local factory_id = block.index(FACTORY_BLOCK)
	local w, h, d = FACTORY_SIZE[1], FACTORY_SIZE[2], FACTORY_SIZE[3]

	for ox = x - (w - 1), x do
		for oy = y - (h - 1), y do
			for oz = z - (d - 1), z do
				local is_origin = true
				for dx = 0, w - 1 do
					for dy = 0, h - 1 do
						for dz = 0, d - 1 do
							if block.get(ox + dx, oy + dy, oz + dz) ~= factory_id then
								is_origin = false
								break
							end
						end
						if not is_origin then
							break
						end
					end
					if not is_origin then
						break
					end
				end
				if is_origin then
					return ox, oy, oz
				end
			end
		end
	end
	return x, y, z
end

local function find_item_on_cell(cx, cy, cz)
	local center = { cx + 0.5, cy + belt.get_item_height(), cz + 0.5 }
	for _, uid in ipairs(entities.get_all_in_radius(center, 0.8)) do
		local ent = entities.get(uid)
		if ent and ent:def_name() == BELT_ITEM_ENTITY then
			local component = ent:get_component(COMPONENT)
			if component and component.is_on_belt and component.is_on_belt(cx, cy, cz) then
				return uid
			end
		end
	end
	return nil
end

local function collect_item_from_belt(bx, by, bz, ox, oy, oz)
	local center = { bx + 0.5, by + belt.get_item_height(), bz + 0.5 }
	local nearby = entities.get_all_in_radius(center, 0.8)

	for _, uid in ipairs(nearby) do
		local ent = entities.get(uid)
		if ent and ent:def_name() == BELT_ITEM_ENTITY then
			local component = ent:get_component(COMPONENT)
			if component and component.is_on_belt and component.is_on_belt(bx, by, bz) then
				local state = component.SAVED_DATA or {}
				local item_name = item.name(state.item_id or 0)
				local count = state.count or 1

				if item_name and item_name ~= "" and state.item_id > 0 then
					if factory.can_add(ox, oy, oz, item_name, count) then
						ent:despawn()
						return item_name, count
					end
				end
			end
		end
	end
	return nil, 0
end

local function find_all_output_belts(ox, oy, oz)
	local w, h, d = FACTORY_SIZE[1], FACTORY_SIZE[2], FACTORY_SIZE[3]
	local outputs = {}

	local directions = {
		{ dx = 1, dz = 0, name = "+X" },
		{ dx = -1, dz = 0, name = "-X" },
		{ dx = 0, dz = 1, name = "+Z" },
		{ dx = 0, dz = -1, name = "-Z" },
	}

	for _, dir in ipairs(directions) do
		for dy = 0, h - 1 do
			for along = 0, (dir.dx ~= 0 and d - 1 or w - 1) do
				local bx, by, bz
				if dir.dx ~= 0 then
					bx = dir.dx > 0 and (ox + w) or (ox - 1)
					by = oy + dy
					bz = oz + along
				else
					bx = ox + along
					by = oy + dy
					bz = dir.dz > 0 and (oz + d) or (oz - 1)
				end

				if belt.is_belt(bx, by, bz) and not belt.is_creator(bx, by, bz) then
					local bdx, bdz = belt.get_belt_direction(bx, by, bz)
					if bdx == dir.dx and bdz == dir.dz then
						table.insert(outputs, {
							x = bx,
							y = by,
							z = bz,
							dx = dir.dx,
							dz = dir.dz,
							name = dir.name,
						})
					end
				end
			end
		end
	end

	return outputs
end

local function find_free_output_belts(ox, oy, oz)
	local free = {}
	for _, out in ipairs(find_all_output_belts(ox, oy, oz)) do
		if belt.is_belt_free(out.x, out.y, out.z, out.dx, out.dz, nil) then
			table.insert(free, out)
		end
	end
	return free
end

local function try_place_output(ox, oy, oz, data)
	local craft = data.craft
	local outputs = find_free_output_belts(ox, oy, oz)
	if #outputs == 0 then
		log("Craft", craft.id, "done, waiting for free output belt")
		return false
	end

	local choice = outputs[math.random(#outputs)]
	local out_id = item.index(craft.output.item)
	if not out_id or out_id <= 0 then
		log("ERROR: output item not found:", craft.output.item)
		return false
	end

	if not belt.place_item(choice.x, choice.y, choice.z, out_id, craft.output.count or 1) then
		log("place_item failed on", choice.name)
		return false
	end

	craft.placed_cell = { choice.x, choice.y, choice.z }
	log("Output", craft.output.item, "placed on", choice.name, "- factory busy until it leaves")
	return true
end

function on_block_tick(x, y, z)
	local ox, oy, oz = find_origin(x, y, z)
	local data = factory.get(ox, oy, oz)
	local w, h, d = FACTORY_SIZE[1], FACTORY_SIZE[2], FACTORY_SIZE[3]

	local directions = {
		{ dx = 1, dz = 0 },
		{ dx = -1, dz = 0 },
		{ dx = 0, dz = 1 },
		{ dx = 0, dz = -1 },
	}

	for _, dir in ipairs(directions) do
		for dy = 0, h - 1 do
			for along = 0, (dir.dx ~= 0 and d - 1 or w - 1) do
				local bx, by, bz
				if dir.dx ~= 0 then
					bx = dir.dx > 0 and (ox + w) or (ox - 1)
					by = oy + dy
					bz = oz + along
				else
					bx = ox + along
					by = oy + dy
					bz = dir.dz > 0 and (oz + d) or (oz - 1)
				end

				if belt.is_belt(bx, by, bz) and not belt.is_creator(bx, by, bz) then
					local bdx, bdz = belt.get_belt_direction(bx, by, bz)
					if bdx == -dir.dx and bdz == -dir.dz then
						local item_name, count = collect_item_from_belt(bx, by, bz, ox, oy, oz)
						if item_name then
							log("Collected:", item_name, "x", count)
							factory.add(ox, oy, oz, item_name, count)
						end
					end
				end
			end
		end
	end

	local craft = data.craft

	if craft and craft.placed_cell then
		if find_item_on_cell(craft.placed_cell[1], craft.placed_cell[2], craft.placed_cell[3]) == nil then
			log("Factory freed:", craft.id)
			data.craft = nil
		end
		return
	end

	if craft then
		craft.ticks_left = craft.ticks_left - 1
		if craft.ticks_left <= 0 then
			try_place_output(ox, oy, oz, data)
		end
		return
	end

	local recipe = recipes.find_craftable(data.items, RECIPES)
	if not recipe then
		return
	end

	recipes.consume(data.items, recipe)
	local seconds = recipe.time or 1
	data.craft = {
		id = recipe.id,
		ticks_left = math.floor(seconds * TPS),
		output = recipe.output,
		placed_cell = nil,
	}
	log("Started craft:", recipe.id, "-", seconds, "s =", data.craft.ticks_left, "ticks")
end

function on_placed(x, y, z)
	local ox, oy, oz = find_origin(x, y, z)
	factory.get(ox, oy, oz)
	log("Factory placed at", ox, oy, oz)
end

function on_remove(x, y, z)
	local ox, oy, oz = find_origin(x, y, z)
	factory.storage[factory.key(ox, oy, oz)] = nil
end
