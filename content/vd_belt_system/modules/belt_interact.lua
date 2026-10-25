local belt_interact = {}

function belt_interact.on_interact(x, y, z, pid)
	local belt = require("vd_belt_system:belt")
	
	if not pid or pid < 0 then
		return false
	end

	local ok, inv_id, slot = pcall(player.get_inventory, pid)
	if not ok or not inv_id or not slot then
		return false
	end

	local ok2, item_id, count, data = pcall(inventory.get, inv_id, slot)
	if not ok2 or not item_id or item_id == 0 or item_id == -1 then
		return false
	end

	local ok3, item_name = pcall(item.name, item_id)
	if ok3 then
		if item_name == "vd_belt_system:transport_belt.item" or
		   item_name == "vd_belt_system:destroyer_belt.item" or
		   item_name == "vd_belt_system:creator_belt.item" then
			return false
		end
	end

	if belt.place_item(x, y, z, item_id, 1, data) then
		if not player.is_infinite_items(pid) then
			inventory.use(inv_id)
		end
		return true
	end
	return false
end

return belt_interact