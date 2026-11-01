local find = require("vd_tower_defence:find")

local PARAMS = {
	[find.ENEMY_WEAK] = {
		damage = 1,
		half = 0.5,
		speed = 2.0,
		scale = 1.0,
	},
	[find.ENEMY_STRONG] = {
		damage = 5,
		half = 0.75,
		speed = 1.4,
		scale = 1.5,
	},
}

local function defname()
	local ok, name = pcall(function()
		return entity:def_name()
	end)
	return ok and name or nil
end

local function get_params()
	return PARAMS[defname()] or PARAMS[find.ENEMY_WEAK]
end

local RETARGET_INTERVAL = 1.0
local STUCK_TIME = 3.0
local PROGRESS_EPS = 0.05
local CORE_TOUCH_EPS = 0.15
local CHECKPOINT_TOUCH_EPS = 0.5

local warned_no_target = false

local function get_state()
	if not SAVED_DATA.visited then
		SAVED_DATA.visited = {}
	end
	return SAVED_DATA
end

local function visited_set(state)
	local set = {}
	for _, key in ipairs(state.visited) do
		set[key] = true
	end
	return set
end

local function mark_visited(state, key)
	for _, k in ipairs(state.visited) do
		if k == key then
			return
		end
	end
	table.insert(state.visited, key)
end

local target = nil
local best_dist = math.huge
local stuck_timer = 0.0
local rescan_timer = 0.0

local function dist3(a, b)
	local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function dist_xz(a, b)
	local dx, dz = b[1] - a[1], b[3] - a[3]
	return math.sqrt(dx * dx + dz * dz)
end

local function touch_radius(kind)
	local half = get_params().half
	if kind == "core" then
		return find.CORE_H + half + CORE_TOUCH_EPS
	end
	return half + CHECKPOINT_TOUCH_EPS
end

local function target_alive(t)
	if not t then
		return false
	end
	local ok, ent = pcall(entities.get, t.uid)
	return ok and ent ~= nil
end

local function retarget()
	target = nil
	best_dist = math.huge
	stuck_timer = 0.0

	local pos = entity.transform:get_pos()
	local visited = visited_set(get_state())

	local best = nil
	local best_d = math.huge

	for _, c in ipairs(find.checkpoints(visited)) do
		local d = dist3(pos, c.pos)
		if d < best_d then
			best_d = d
			best = {
				kind = "checkpoint",
				uid = c.uid,
				key = c.key,
				pos = c.pos,
			}
		end
	end

	for _, c in ipairs(find.cores()) do
		local d = dist3(pos, c.pos)
		if d < best_d then
			best_d = d
			best = {
				kind = "core",
				uid = c.uid,
				pos = c.pos,
			}
		end
	end

	if best then
		target = best
		best_dist = dist_xz(pos, best.pos)
		stuck_timer = 0.0
		warned_no_target = false
	end
	return target
end

local function on_reach(t)
	if t.kind == "core" then
		local ok, ent = pcall(entities.get, t.uid)
		if ok and ent then
			local ok2, core = pcall(function()
				return ent:get_component("vd_tower_defence:core")
			end)
			if ok2 and core and core.take_damage then
				pcall(core.take_damage, get_params().damage)
			end
		end
		entity:despawn()
		return
	end

	mark_visited(get_state(), t.key)
	target = nil
	retarget()
end

local function apply_scale()
	local params = get_params()
	if params.scale ~= 1.0 then
		pcall(function()
			entity.transform:set_size({ params.scale, params.scale, params.scale })
		end)
	end
end

local ok_gravity, err_gravity = pcall(function()
	entity.rigidbody:set_gravity_scale(0)
	entity.rigidbody:set_vel({ 0, 0, 0 })
end)
if not ok_gravity then
	print("[TD][enemy] rigidbody API недоступен: " .. tostring(err_gravity))
end

apply_scale()

function on_update(tps)
	local dt = 1.0 / tps
	local pos = entity.transform:get_pos()

	if not target_alive(target) then
		retarget()
	end

	rescan_timer = rescan_timer - dt
	if rescan_timer <= 0 then
		rescan_timer = RETARGET_INTERVAL
		if not target then
			retarget()
		end
	end

	if not target then
		if not warned_no_target then
			warned_no_target = true
			print(
				"[TD] "
					.. tostring(defname())
					.. ": цели нет (нужны чекпоинты или коробка-ядро), стоим"
			)
		end
		return
	end

	local t = target
	local dx = t.pos[1] - pos[1]
	local dz = t.pos[3] - pos[3]
	local dist = math.sqrt(dx * dx + dz * dz)

	if dist <= touch_radius(t.kind) then
		on_reach(t)
		return
	end

	if dist < best_dist - PROGRESS_EPS then
		best_dist = dist
		stuck_timer = 0.0
	else
		stuck_timer = stuck_timer + dt
	end
	if stuck_timer >= STUCK_TIME then
		if t.kind == "checkpoint" then
			print(
				"[TD] "
					.. tostring(defname())
					.. ": не добрался до чекпоинта, пропускаю его"
			)
			mark_visited(get_state(), t.key)
		end
		retarget()
		return
	end

	local step = get_params().speed * dt
	if step > dist then
		step = dist
	end
	local nx = pos[1] + dx / dist * step
	local nz = pos[3] + dz / dist * step
	entity.transform:set_pos({ nx, pos[2], nz })
end
