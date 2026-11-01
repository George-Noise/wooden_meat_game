local factory = {}
factory.storage = {}

factory.STORAGE_LIMIT = 2

function factory.key(x, y, z)
	return x .. "," .. y .. "," .. z
end

function factory.get(x, y, z)
	local k = factory.key(x, y, z)
	if not factory.storage[k] then
		factory.storage[k] = { items = {} }
	end
	return factory.storage[k]
end

function factory.can_add(x, y, z, item_name, count)
	local data = factory.get(x, y, z)
	return (data.items[item_name] or 0) + (count or 1) <= factory.STORAGE_LIMIT
end

function factory.add(x, y, z, item_name, count)
	local data = factory.get(x, y, z)
	data.items[item_name] = (data.items[item_name] or 0) + (count or 1)
end

function factory.reset(x, y, z)
	factory.get(x, y, z).items = {}
end

return factory
