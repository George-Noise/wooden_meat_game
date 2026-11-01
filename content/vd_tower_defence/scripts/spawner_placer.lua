local find = require("vd_tower_defence:find")

local H = 0.25

function on_use_on_block(x, y, z, pid, normal)
	normal = normal or { 0, 1, 0 }
	local pos = {
		x + 0.5 + normal[1] * (0.5 + H / 2),
		y + 0.5 + normal[2] * (0.5 + H / 2),
		z + 0.5 + normal[3] * (0.5 + H / 2),
	}
	local ok, ent = pcall(entities.spawn, find.SPAWNER, pos)
	if ok and ent then
		print("[TD] Точка спавна установлена (всего: " .. #find.spawners() .. ")")
		return true
	end
	print("[TD] Не удалось поставить точку спавна")
	return false
end

function on_use(pid)
	print("[TD] Кликни по блоку, чтобы поставить точку спавна врагов")
end
