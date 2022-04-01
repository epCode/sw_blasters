minetest.register_tool("sw_blasters:e_11", {
	description=("E-11"),
	wield_scale = {x = 2, y = 2, z = 2},
  range=0,
	inventory_image="sw_blasters_e11_inv.png",
	groups={med_rifle = 1, cooling_speed = 900, shots = 10, bullet_speed = 62, bullet_damage = 4, shot_interval = 0.3, cooldown_delay = 2.2, accuracy = 0.1, range=37},
})
minetest.register_tool("sw_blasters:fwmb10", {
	description=("FWMB-10 Repeating Rifle"),
	wield_scale = {x = 4, y = 4, z = 4},
  range=0,
	inventory_image="sw_blasters_fwmb10_inv.png",
	groups={heavy_short = 1, cooling_speed = 500, shots = 20, bullet_speed = 43, bullet_damage = 2, shot_interval = 0.12, cooldown_delay = 3.4, accuracy = 0.5, range=15},
})
minetest.register_tool("sw_blasters:nt242", {
	description=("NT-242 Sniper Rifle"),
	wield_scale = {x = 4, y = 4, z = 4},
  range=0,
	inventory_image="sw_blasters_nt242_inv.png",
	groups={long_range_rifle = 1, cooling_speed = 1000, shots = 3, bullet_speed = 94, bullet_damage = 12, shot_interval = 0.8, cooldown_delay = 2, accuracy = 0.005, range=90},
})
minetest.register_tool("sw_blasters:dh17", {
	description=("DH-17 Pistol"),
	wield_scale = {x = 1, y = 1, z = 1},
  range=0,
	inventory_image="sw_blasters_dh17_inv.png",
	groups={med_rifle = 1, cooling_speed = 1400, shots = 15, bullet_speed = 58, bullet_damage = 2, shot_interval = 0.16, cooldown_delay = 1, accuracy = 0.25, range=19.5},
})
minetest.register_tool("sw_blasters:a295", {
	description=("A-295 Rifle"),
	wield_scale = {x = 2.5, y = 2.5, z = 2.5},
  range=0,
	inventory_image="sw_blasters_a295_inv.png",
	groups={med_rifle = 1, cooling_speed = 1000, shots = 15, bullet_speed = 65, bullet_damage = 3, shot_interval = 0.2, cooldown_delay = 2, accuracy = 0.15, range=40},
})
