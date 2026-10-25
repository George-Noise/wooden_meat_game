local belt = require("vd_belt_system:belt")

function on_world_tick()
	belt.tick(20)
end

-- function on_world_quit()
	-- belt.clear()
-- end
