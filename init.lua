sw_blasters = {
	zoom_hud = {},
	shootable_hud = {},
	gun_stats = {},
	object_timer = {},
	wieldeditem = {},
}

local function dir_to_pitch(dir)
	--local dir2 = vector.normalize(dir)
	local xz = math.abs(dir.x) + math.abs(dir.z)
	return -math.atan2(-dir.y, xz)
end

local path = minetest.get_modpath("sw_blasters")
dofile(path .. "/blast_normal.lua")
dofile(path .. "/blasters.lua")
dofile(path .. "/player_control.lua")
dofile(path .. "/throwables.lua")
if minetest.get_modpath("mcl_explosions") or minetest.get_modpath("tnt") then
	dofile(path .. "/detonator.lua")
end


function sw_blasters.shoot_entity(take_item, thrower, itemstack, thrown_thing, speed, gravity, damage, textures, accuracy, timer)
	local player_pos = thrower:get_pos()
	local dir = thrower:get_look_dir()
	local arrow = minetest.add_entity({x=player_pos.x, y=player_pos.y+1.4, z=player_pos.z}, thrown_thing)
 	local le = arrow:get_luaentity()
 	le._damage = damage
 	le.textures = textures
 	le._bomb_timer = timer
 	le._wielded_item_used = thrower:get_wielded_item()
 	le._shooter = thrower

	local _x = (1-math.random())/20*dir.x*accuracy
	local _y = (1-math.random())/30*accuracy
	local _z = (1-math.random())/20*dir.z*accuracy

	dir.x=dir.x+_x
	dir.y=dir.y+_y
	dir.z=dir.z+_z

	arrow:set_properties({textures=textures})
	arrow:set_velocity(vector.multiply(dir, speed))
	arrow:set_acceleration({x=0, y=-gravity, z=0})
	if take_item == true then
    if take_item then
      itemstack:take_item()
    end
	end
	return arrow
end
