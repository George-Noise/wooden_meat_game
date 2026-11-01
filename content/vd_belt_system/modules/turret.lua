local turret = {}

local MAG_SIZE = 32
local DEFAULT_DAMAGE = 1

local AMMO_DAMAGE = {
	["vd_belt_system:coal_ore.item"] = 2,
	["vd_belt_system:copper_ore.item"] = 4,
	["vd_belt_system:bullet_1"] = 10,
	["vd_belt_system:bullet_2"] = 25,
}

turret.TARGET_COMPONENTS = {
	"my_pack:health",
}

turret.RAY_EXCLUDE = {
	"vd_belt_system:belt_item",
	"base:drop",
}

turret.SEARCH_RADIUS = 50.0
turret.FIRE_COOLDOWN = 1.0

turret.GUN_ENTITY = "vd_belt_system:turret_gun"
local GUN_COMPONENT_KEY = "vd_belt_system__turret_gun"

local GUN_OFFSET = { 0.5, 1.0, 0.5 }

local GUNS = {}

local function key_of(x, y, z)
	return x .. "," .. y .. "," .. z
end

local function get_int_field(x, y, z, name)
	local ok, v = pcall(block.get_field, x, y, z, name)
	if ok and type(v) == "number" then
		return v
	end
	return 0
end

function turret.get_ammo_count(x, y, z)
	return get_int_field(x, y, z, "mag_count")
end

function turret.is_whitelisted(item_name)
	return AMMO_DAMAGE[item_name] ~= nil
end

function turret.ammo_damage(item_name)
	return AMMO_DAMAGE[item_name] or DEFAULT_DAMAGE
end

function turret.damage_of_item_id(item_id)
	local ok, name = pcall(item.name, item_id)
	if ok and name then
		return turret.ammo_damage(name)
	end
	return DEFAULT_DAMAGE
end

function turret.can_accept(x, y, z, item_id)
	if not item_id or item_id <= 0 then
		return false
	end
	if turret.get_ammo_count(x, y, z) >= MAG_SIZE then
		return false
	end
	local ok, name = pcall(item.name, item_id)
	if not ok or not name then
		return false
	end
	return turret.is_whitelisted(name)
end

function turret.load(x, y, z, item_id, count)
	if not item_id or item_id <= 0 then
		return 0
	end
	local want = count or 1
	local loaded = 0
	while loaded < want and turret.get_ammo_count(x, y, z) < MAG_SIZE do
		local count_now = turret.get_ammo_count(x, y, z)
		local head = get_int_field(x, y, z, "mag_head")
		local slot = (head + count_now) % MAG_SIZE
		pcall(block.set_field, x, y, z, "mag", item_id, slot)
		pcall(block.set_field, x, y, z, "mag_count", count_now + 1)
		loaded = loaded + 1
	end
	return loaded
end

function turret.take_ammo(x, y, z)
	local count = turret.get_ammo_count(x, y, z)
	if count <= 0 then
		return nil
	end
	local head = get_int_field(x, y, z, "mag_head")
	local ok, item_id = pcall(block.get_field, x, y, z, "mag", head)
	if not ok or type(item_id) ~= "number" then
		item_id = 0
	end
	pcall(block.set_field, x, y, z, "mag", 0, head)
	pcall(block.set_field, x, y, z, "mag_head", (head + 1) % MAG_SIZE)
	pcall(block.set_field, x, y, z, "mag_count", count - 1)
	if item_id <= 0 then
		return nil
	end
	return item_id
end

function turret.is_turret_block(x, y, z)
	local ok, block_id = pcall(block.get, x, y, z)
	if not ok or not block_id or block_id <= 0 then
		return false
	end
	local ok2, name = pcall(block.name, block_id)
	return ok2 and name == "vd_belt_system:turret"
end

local function gun_alive(uid)
	if not uid then
		return false
	end
	local ok, ent = pcall(entities.get, uid)
	return ok and ent ~= nil
end

function turret.spawn_gun(x, y, z)
	local key = key_of(x, y, z)
	if gun_alive(GUNS[key]) then
		return
	end
	GUNS[key] = nil

	local expected = {
		x + GUN_OFFSET[1],
		y + GUN_OFFSET[2],
		z + GUN_OFFSET[3],
	}
	local ok, uids = pcall(entities.get_all_in_radius, expected, 0.75)
	if ok and uids then
		for _, uid in ipairs(uids) do
			local ok2, ent = pcall(entities.get, uid)
			if ok2 and ent then
				local ok3, defname = pcall(function()
					return ent:def_name()
				end)
				if ok3 and defname == turret.GUN_ENTITY then
					local ok4, pos = pcall(function()
						return ent.transform:get_pos()
					end)
					local on_place = ok4
						and pos
						and math.abs(pos[1] - expected[1]) < 0.05
						and math.abs(pos[2] - expected[2]) < 0.05
						and math.abs(pos[3] - expected[3]) < 0.05
					if on_place then
						GUNS[key] = uid
						return
					end
					pcall(function()
						ent:despawn()
					end)
				end
			end
		end
	end

	local ok4, ent = pcall(entities.spawn, turret.GUN_ENTITY, {
		x + GUN_OFFSET[1],
		y + GUN_OFFSET[2],
		z + GUN_OFFSET[3],
	}, {
		[GUN_COMPONENT_KEY] = { x = x, y = y, z = z },
	})
	if ok4 and ent then
		local ok5, uid = pcall(function()
			return ent:get_uid()
		end)
		if ok5 then
			GUNS[key] = uid
		end
	end
end

function turret.despawn_gun(x, y, z)
	local key = key_of(x, y, z)
	local uid = GUNS[key]
	GUNS[key] = nil
	if uid then
		local ok, ent = pcall(entities.get, uid)
		if ok and ent then
			pcall(function()
				ent:despawn()
			end)
		end
	end
end

function turret.ensure_gun(x, y, z)
	local key = key_of(x, y, z)
	if gun_alive(GUNS[key]) then
		return
	end
	turret.spawn_gun(x, y, z)
end

function turret.tick(x, y, z, tps)
	turret.ensure_gun(x, y, z)
end

function turret.on_interact(x, y, z, pid)
	if not pid or pid < 0 then
		return false
	end

	local held_name
	local inv_id, slot
	local ok0, inv_id_v, slot_v = pcall(player.get_inventory, pid)
	if ok0 and inv_id_v and slot_v then
		inv_id, slot = inv_id_v, slot_v
		local ok1, item_id = pcall(inventory.get, inv_id, slot)
		if ok1 and item_id and item_id > 0 then
			local ok2, name = pcall(item.name, item_id)
			if ok2 then
				held_name = name
			end

			if turret.can_accept(x, y, z, item_id) then
				if turret.load(x, y, z, item_id, 1) > 0 then
					if not player.is_infinite_items(pid) then
						inventory.use(inv_id)
					end
					return true
				end
			elseif held_name then
				return false
			end
		end
	end

	print(
		"[turret] боезапас: "
			.. turret.get_ammo_count(x, y, z)
			.. "/"
			.. MAG_SIZE
			.. " ("
			.. x
			.. ","
			.. y
			.. ","
			.. z
			.. ")"
	)
	return false
end

return turret
