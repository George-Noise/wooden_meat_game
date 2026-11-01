local MAX_HP = 100

local hp = SAVED_DATA.hp or MAX_HP

local function update_color()
	local rig = entity.skeleton
	if not rig then
		return
	end
	local k = math.max(0, math.min(1, hp / MAX_HP))
	rig:set_color({ 1.0, 0.3 + 0.7 * k, 0.3 + 0.7 * k })
end

local ok, err = pcall(function()
	entity.rigidbody:set_gravity_scale(0)
	entity.rigidbody:set_vel({ 0, 0, 0 })
end)
if not ok then
	print("[TD][core] rigidbody API недоступен: " .. tostring(err))
end

update_color()

function take_damage(amount)
	hp = hp - (amount or 0)
	SAVED_DATA.hp = hp
	update_color()
	print(
		"[TD] Коробка получила "
			.. tostring(amount)
			.. " урона. HP: "
			.. math.max(0, hp)
			.. "/"
			.. MAX_HP
	)
	if hp <= 0 then
		print("[TD] ========================================")
		print("[TD] КОРОБКА УНИЧТОЖЕНА! Игра окончена.")
		print("[TD] ========================================")
		entity:despawn()
	end
end

function get_hp()
	return hp
end

function get_max_hp()
	return MAX_HP
end
