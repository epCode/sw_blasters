local THERMAL_DETONATOR={
	description=("Thermal Detonator"),
  range=0,
	stack_max = 1,
	inventory_image="sw_blasters_thermal_detonator.png",

	---THROW
  on_use = function(itemstack, user, pointed_thing)
    local timer_left = 0
    if sw_blasters.object_timer[user] then
      timer_left = sw_blasters.object_timer[user]
      sw_blasters.object_timer[user] = nil
    else
      timer_left = nil
    end
		local bomb = sw_blasters.shoot_entity(true, user, itemstack, "sw_blasters:detonator_entity", 30, 9.81, 0, {"sw_blasters_thermal_detonator.png"}, 0, timer_left)
		bomb:get_luaentity()._power = 4
		return itemstack
  end,

	---DROP
	on_drop = function(itemstack, dropper)
		local timer_left = 0
		if sw_blasters.object_timer[dropper] then
			timer_left = sw_blasters.object_timer[dropper]
			sw_blasters.object_timer[dropper] = nil
		else
			timer_left = nil
		end

		local bomb = sw_blasters.shoot_entity(true, dropper, itemstack, "sw_blasters:detonator_entity", 3, 9.81, 0, {"sw_blasters_thermal_detonator.png"}, 0, timer_left)
		bomb:get_luaentity()._power = 4
		return itemstack
	end,

	---ACTIVATE
	on_secondary_use = function(itemstack, user, pointed_thing)
		if not sw_blasters.object_timer[user] then
			sw_blasters.object_timer[user] = 3
			minetest.sound_play("sw_blasters_detonator_activate", {pos=user:get_pos(), max_hear_distance=5, pitch = math.random(90,120)/100}, true)
			user:set_wielded_item("sw_blasters:thermal_detonator_activated")
		end
	end,
}
minetest.register_craftitem("sw_blasters:thermal_detonator", THERMAL_DETONATOR)

THERMAL_DETONATOR_ACTIVATED = table.copy(THERMAL_DETONATOR)
THERMAL_DETONATOR_ACTIVATED.inventory_image="sw_blasters_thermal_detonator_activated.png"
THERMAL_DETONATOR_ACTIVATED.groups={not_in_creative_inventory=1}
minetest.register_craftitem("sw_blasters:thermal_detonator_activated", THERMAL_DETONATOR_ACTIVATED)

minetest.register_craftitem("sw_blasters:impact_grenade", {
	description=("Impact Grenade"),
  range=0,
  stack_max=3,
	inventory_image="sw_blasters_impact_grenade.png",
  on_use = function(itemstack, user, pointed_thing)
		local bomb = sw_blasters.shoot_entity(true, user, itemstack, "sw_blasters:detonator_entity", 30, 9.81, 0, {"sw_blasters_impact_grenade.png"}, 0, timer_left)
		bomb:get_luaentity()._power = 2
		bomb:get_luaentity()._explode_on_impact = true    return itemstack
  end,
	on_drop = function(itemstack, dropper)
		local bomb = sw_blasters.shoot_entity(true, dropper, itemstack, "sw_blasters:detonator_entity", 3, 9.81, 0, {"sw_blasters_impact_grenade.png"}, 0, timer_left)
		bomb:get_luaentity()._power = 2
		bomb:get_luaentity()._explode_on_impact = true
		return itemstack
	end,
})
