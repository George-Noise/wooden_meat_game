local belt_interact = {}

local DEBUG_TOPFACE = false

local DEBUG_CYCLE = true

local BELT_ITEMS = {
	["vd_belt_system:transport_belt.item"] = true,
	["vd_belt_system:junction.item"] = true,
	["vd_belt_system:splitter.item"] = true,
}

local CYCLE_NAMES = {
	"vd_belt_system:transport_belt",
	"vd_belt_system:junction",
	"vd_belt_system:splitter",
}

local function log(...)
	if DEBUG_CYCLE then
		print("[cycle]", ...)
	end
end

local function key_of(x, y, z)
	return x .. "," .. y .. "," .. z
end

local function read_belt_dir(x, y, z)
	local belt = require("vd_belt_system:belt")
	local dx, dz = belt.get_belt_direction(x, y, z)
	if not dx then
		return nil
	end
	return belt.dir_code_of_vec(dx, dz), dx, dz
end

local function is_top_face(x, y, z, pid)
	return true
end

function belt_interact.cycle(x, y, z)
	local belt = require("vd_belt_system:belt")
	local key = key_of(x, y, z)

	local btype = belt.get_belt_type(x, y, z)
	local idx = btype == "belt" and 1 or btype == "junction" and 2 or btype == "splitter" and 3
	if not idx then
		return false
	end

	local code = belt.get_stored_dir(x, y, z)
	local src = "bits"
	if code == nil then
		code = read_belt_dir(x, y, z)
		src = code ~= nil and "engine" or "none"
	end
	log("read dir:", key, "was:", btype, "src:", src, "code:", code)

	local next_idx = idx % 3 + 1
	local next_name = CYCLE_NAMES[next_idx]

	local states = block.get_states(x, y, z)
	block.set(x, y, z, block.index(next_name), states)
	log("set block:", key, "->", next_name, "carried states:", states)

	if code ~= nil then
		belt.set_stored_dir(x, y, z, code)
		local back = belt.get_stored_dir(x, y, z)
		log("save dir:", key, "code:", code, "readback bits:", back)
	end

	if next_idx == 1 and code ~= nil then
		belt.sync_engine_rotation(x, y, z, code)
		local got = read_belt_dir(x, y, z)
		log("restore:", key, "want code:", code, "got code:", got, "rotation:", block.get_rotation(x, y, z))
	end

	return true
end

function belt_interact.on_interact(x, y, z, pid)
	local belt = require("vd_belt_system:belt")

	if not pid or pid < 0 then
		return false
	end

	local btype = belt.get_belt_type(x, y, z)
	if btype then
		local held_name
		local inv_id, slot
		local ok0, inv_id_v, slot_v = pcall(player.get_inventory, pid)
		if ok0 and inv_id_v and slot_v then
			inv_id, slot = inv_id_v, slot_v
			local ok1, item_id = pcall(inventory.get, inv_id, slot)
			if ok1 and item_id and item_id > 0 then
				held_name = item.name(item_id)
			end
		end

		if held_name and BELT_ITEMS[held_name] then
			if is_top_face(x, y, z, pid) then
				return belt_interact.cycle(x, y, z)
			end
			return false
		end

		if not inv_id or not slot then
			return false
		end
		local ok2, item_id, count, data = pcall(inventory.get, inv_id, slot)
		if not ok2 or not item_id or item_id == 0 or item_id == -1 then
			return false
		end

		if belt.place_item(x, y, z, item_id, 1, data) then
			if not player.is_infinite_items(pid) then
				inventory.use(inv_id)
			end
			return true
		end
		return false
	end

	return false
end

return belt_interact
