local props = {}
local damage_flash_timer = 0
local original_color = nil

local function def_prop(name, def_value)
	props[name] = SAVED_DATA[name] or ARGS[name] or def_value
	this["get_" .. name] = function()
		return props[name]
	end
	this["set_" .. name] = function(value)
		props[name] = value
		if math.abs(value - def_value) < 1e-7 then
			SAVED_DATA[name] = nil
		else
			SAVED_DATA[name] = value
		end
	end
end

def_prop("health", 100)

function on_save()
	SAVED_DATA.health = props.health
end

function take_damage(amount)
	animation.play("hit", entity.skeleton)

	local old_health = props.health
	props.health = props.health - amount
	print(
		"[Health] Сущность "
			.. entity:def_name()
			.. " (UID: "
			.. entity:get_uid()
			.. ") получила "
			.. amount
			.. " урона. Здоровье: "
			.. old_health
			.. " -> "
			.. props.health
	)

	local rig = entity.skeleton
	if rig then
		if damage_flash_timer <= 0 then
			original_color = rig:get_color()
		end
		rig:set_color({ 1.0, 0.4, 0.4 })
		damage_flash_timer = 0.2
	end

	if props.health <= 0 then
		print("[Health] Сущность " .. entity:def_name() .. " уничтожена!")
		entity:despawn()
	end
end

function on_update(tps)
	local dt = 1.0 / tps
	if damage_flash_timer > 0 then
		damage_flash_timer = damage_flash_timer - dt
		if damage_flash_timer <= 0 and original_color then
			local rig = entity.skeleton
			if rig then
				rig:set_color(original_color)
			end
			original_color = nil
		end
	end
end

function heal(amount)
	local old_health = props.health
	props.health = props.health + amount
	print(
		"[Health] Сущность "
			.. entity:def_name()
			.. " исцелена на "
			.. amount
			.. ". Здоровье: "
			.. old_health
			.. " -> "
			.. props.health
	)
end
