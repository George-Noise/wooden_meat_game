local belt = require("vd_belt_system:belt")

local DRILL_BLOCK = "vd_belt_system:drill"
local BELT_ITEM_ENTITY = "vd_belt_system:belt_item"
local COMPONENT = "vd_belt_system:belt_item"

local DRILL_SIZE = { 2, 2, 2 }

local ORE_ITEMS = {
	["vd_belt_system:coal_ore"] = "vd_belt_system:coal_ore.item",
	["vd_belt_system:copper_ore"] = "vd_belt_system:copper_ore.item",
}

local DEBUG = true

local function log(...)
	if DEBUG then
		print("[drill]", ...)
	end
end

local function find_origin(x, y, z)
	local drill_id = block.index(DRILL_BLOCK)
	local w, h, d = DRILL_SIZE[1], DRILL_SIZE[2], DRILL_SIZE[3]

	for ox = x - (w - 1), x do
		for oy = y - (h - 1), y do
			for oz = z - (d - 1), z do
				local is_origin = true
				for dx = 0, w - 1 do
					for dy = 0, h - 1 do
						for dz = 0, d - 1 do
							if block.get(ox + dx, oy + dy, oz + dz) ~= drill_id then
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

local function cell_has_item(bx, by, bz)
	local center = { bx + 0.5, by + belt.get_item_height(), bz + 0.5 }
	for _, uid in ipairs(entities.get_all_in_radius(center, 0.8)) do
		local ent = entities.get(uid)
		if ent and ent:def_name() == BELT_ITEM_ENTITY then
			local component = ent:get_component(COMPONENT)
			if component then
				if component.is_on_belt and component.is_on_belt(bx, by, bz) then
					return true
				end
				if component.is_moving_to and component.is_moving_to(bx, by, bz) then
					return true
				end
			end
		end
	end
	return false
end

local function find_output_belts(ox, oy, oz)
	local w, h, d = DRILL_SIZE[1], DRILL_SIZE[2], DRILL_SIZE[3]
	local cells = {}

	local side_dirs = {
		{ dx = 1, dz = 0 },
		{ dx = -1, dz = 0 },
		{ dx = 0, dz = 1 },
		{ dx = 0, dz = -1 },
	}

	for _, dir in ipairs(side_dirs) do
		for dy = 0, h - 1 do
			for along = 0, 1 do
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
				table.insert(cells, { bx, by, bz })
			end
		end
	end

	for dx = 0, w - 1 do
		for dz = 0, d - 1 do
			table.insert(cells, { ox + dx, oy + h, oz + dz })
		end
	end

	local belts = {}
	for _, cell in ipairs(cells) do
		local bx, by, bz = cell[1], cell[2], cell[3]
		if belt.get_belt_type(bx, by, bz) == "belt" and not cell_has_item(bx, by, bz) then
			table.insert(belts, cell)
		end
	end
	return belts
end

local function roll_item_name(ox, oy, oz)
	local ores = {}
	for dx = 0, DRILL_SIZE[1] - 1 do
		for dz = 0, DRILL_SIZE[3] - 1 do
			local id = block.get(ox + dx, oy - 1, oz + dz)
			if id and id > 0 then
				local ore_item = ORE_ITEMS[block.name(id)]
				if ore_item then
					table.insert(ores, ore_item)
				end
			end
		end
	end
	if #ores == 0 then
		return nil
	end
	return ores[math.random(#ores)]
end

function on_block_tick(x, y, z)
	local ox, oy, oz = find_origin(x, y, z)

	if ox ~= x or oy ~= y or oz ~= z then
		return
	end

	local item_name = roll_item_name(ox, oy, oz)
	if not item_name then
		return
	end

	local belts = find_output_belts(ox, oy, oz)
	if #belts == 0 then
		return
	end

	local out_id = item.index(item_name)
	if not out_id or out_id <= 0 then
		log("ERROR: item not found:", item_name)
		return
	end

	local choice = belts[math.random(#belts)]
	if belt.place_item(choice[1], choice[2], choice[3], out_id, 1) then
		log("Выдано:", item_name, "->", choice[1], choice[2], choice[3])
	end
end

function on_placed(x, y, z)
	local ox, oy, oz = find_origin(x, y, z)
	log("Бур поставлен, опорный угол:", ox, oy, oz)
end
