local recipes = {}

recipes.list = {
	{
		id = "stone_sand",
		time = 10,
		inputs = { ["vd_belt_system:coal_ore.item"] = 1, ["vd_belt_system:copper_ore.item"] = 1 },
		output = { item = "vd_belt_system:bullet_1", count = 1 },
	},
	{
		id = "glass_metal",
		time = 20,
		inputs = { ["vd_belt_system:bullet_1"] = 2, ["vd_belt_system:copper_ore.item"] = 1 },
		output = { item = "vd_belt_system:bullet_2", count = 1 },
	},
}

recipes.by_id = {}
for _, r in ipairs(recipes.list) do
	recipes.by_id[r.id] = r
end

function recipes.get(id)
	return recipes.by_id[id]
end

function recipes.can_craft(items, recipe)
	for name, count in pairs(recipe.inputs) do
		if (items[name] or 0) < count then
			return false
		end
	end
	return true
end

function recipes.find_craftable(items, ids)
	local pool = ids or recipes.list
	for _, entry in ipairs(pool) do
		local recipe = type(entry) == "string" and recipes.by_id[entry] or entry
		if recipe and recipes.can_craft(items, recipe) then
			return recipe
		end
	end
	return nil
end

function recipes.consume(items, recipe)
	for name, count in pairs(recipe.inputs) do
		local left = (items[name] or 0) - count
		if left <= 0 then
			items[name] = nil
		else
			items[name] = left
		end
	end
end

return recipes
