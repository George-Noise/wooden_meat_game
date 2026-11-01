local find = require("vd_tower_defence:find")

local wave = {}
local WAVES = {
	{ weak = 5, strong = 0 },
	{ weak = 8, strong = 0 },
	{ weak = 10, strong = 1 },
	{ weak = 12, strong = 2 },
	{ weak = 14, strong = 4 },
	{ weak = 16, strong = 6 },
	{ weak = 18, strong = 8 },
	{ weak = 20, strong = 11 },
	{ weak = 24, strong = 14 },
	{ weak = 28, strong = 18 },
}

local ENEMY_PARAMS = {
	[find.ENEMY_WEAK] = { hp = 20, half = 0.5 },
	[find.ENEMY_STRONG] = { hp = 60, half = 0.75 },
}

local SPAWNER_COMP = "vd_tower_defence:spawner"

local SPAWN_SPREAD = 0.5

local session_wave = nil

function wave.count()
	return #WAVES
end

function wave.def(n)
	return WAVES[n]
end

function wave.enemy_params(defname)
	return ENEMY_PARAMS[defname]
end

function wave.describe(n)
	local def = WAVES[n]
	if not def then
		return "?"
	end
	return "Волна "
		.. n
		.. "/"
		.. #WAVES
		.. ": "
		.. def.weak
		.. " слабых, "
		.. def.strong
		.. " сильных"
end

function wave.get_current()
	if session_wave then
		return session_wave
	end
	for _, s in ipairs(find.spawners()) do
		local ok, comp = pcall(function()
			return s.ent:get_component(SPAWNER_COMP)
		end)
		if ok and comp and comp.get_wave then
			local ok2, n = pcall(comp.get_wave)
			if ok2 and type(n) == "number" and n >= 1 and n <= #WAVES then
				session_wave = n
				return n
			end
		end
	end
	session_wave = 1
	return 1
end

function wave.set_current(n)
	n = math.floor(n or 1)
	if n < 1 then
		n = 1
	end
	if n > #WAVES then
		n = #WAVES
	end
	session_wave = n
	for _, s in ipairs(find.spawners()) do
		local ok, comp = pcall(function()
			return s.ent:get_component(SPAWNER_COMP)
		end)
		if ok and comp and comp.set_wave then
			pcall(comp.set_wave, n)
		end
	end
	return n
end

function wave.start(n)
	n = n or wave.get_current()
	local def = WAVES[n]
	if not def then
		print("[TD] Волна " .. tostring(n) .. " не определена")
		return false
	end

	local spawners = find.spawners()
	if #spawners == 0 then
		print(
			"[TD] Некуда спавнить: ни одной точки спавна не поставлено"
				.. ' (предмет "Place Spawner")'
		)
		return false
	end

	if #find.cores() == 0 then
		print(
			"[TD] Внимание: коробка-ядро не установлена"
				.. ' (предмет "Place Core Box") — врагам будет некуда идти'
		)
	end

	local queue = {}
	for _ = 1, def.weak do
		table.insert(queue, find.ENEMY_WEAK)
	end
	for _ = 1, def.strong do
		table.insert(queue, find.ENEMY_STRONG)
	end

	local spawned = 0
	for i, defname in ipairs(queue) do
		local spawner = spawners[((i - 1) % #spawners) + 1]
		local params = ENEMY_PARAMS[defname]
		local y = spawner.pos[2] + params.half
		local pos = {
			spawner.pos[1] + (math.random() - 0.5) * SPAWN_SPREAD,
			y,
			spawner.pos[3] + (math.random() - 0.5) * SPAWN_SPREAD,
		}
		local ok, ent = pcall(entities.spawn, defname, pos, {
			["my_pack__health"] = { health = params.hp },
		})
		if ok and ent then
			spawned = spawned + 1
		else
			print("[TD] Не удалось заспавнить " .. defname)
		end
	end

	print(
		"[TD] Запущена "
			.. wave.describe(n)
			.. " | заспавнено "
			.. spawned
			.. "/"
			.. #queue
			.. " из "
			.. #spawners
			.. " точек"
	)
	return true
end

return wave
