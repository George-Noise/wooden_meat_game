local find = {}

find.CHECKPOINT = "vd_tower_defence:checkpoint"
find.CORE = "vd_tower_defence:core"
find.SPAWNER = "vd_tower_defence:spawner"
find.ENEMY_WEAK = "vd_tower_defence:enemy_weak"
find.ENEMY_STRONG = "vd_tower_defence:enemy_strong"

find.CORE_H = 1.5

function find.def_name(ent)
	local ok, name = pcall(function()
		return ent:def_name()
	end)
	if ok then
		return name
	end
	return nil
end

function find.pos_of(ent)
	local ok, pos = pcall(function()
		return ent.transform:get_pos()
	end)
	if ok and pos then
		return pos
	end
	return nil
end

function find.pos_key(pos)
	return string.format("%.2f|%.2f|%.2f", pos[1], pos[2], pos[3])
end

function find.by_def(defname)
	local result = {}
	local ok, all = pcall(entities.get_all)
	if not ok or not all then
		return result
	end
	for uid, ent in pairs(all) do
		if find.def_name(ent) == defname then
			local pos = find.pos_of(ent)
			if pos then
				table.insert(result, {
					uid = uid,
					ent = ent,
					pos = { pos[1], pos[2], pos[3] },
				})
			end
		end
	end
	table.sort(result, function(a, b)
		return a.uid < b.uid
	end)
	return result
end

function find.checkpoints(visited)
	visited = visited or {}
	local result = {}
	for _, c in ipairs(find.by_def(find.CHECKPOINT)) do
		local key = find.pos_key(c.pos)
		if not visited[key] then
			c.key = key
			table.insert(result, c)
		end
	end
	return result
end

function find.cores()
	return find.by_def(find.CORE)
end

function find.spawners()
	return find.by_def(find.SPAWNER)
end

return find
