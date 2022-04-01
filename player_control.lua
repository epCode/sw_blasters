minetest.register_on_joinplayer(function(player)
	sw_blasters.gun_stats[player] = {delay=0, pointing_at_shootable=false, venting=false, overheated=false, cooling_handle=0, cooling_delay=0}
	sw_blasters.shootable_hud[player] = nil
	sw_blasters.zoom_hud[player] = nil
end)

--function to control firing of blasters and cooling
local function blaster_shoot(player, blaster_name, wieldeditem, control, entity, gravity, textures, shoot_sound, shot_hear_distance)
	--get blaster properties
	local shots_default = minetest.get_item_group(blaster_name, "shots") + 2
	local bullet_speed = minetest.get_item_group(blaster_name, "bullet_speed")
	local damage = minetest.get_item_group(blaster_name, "bullet_damage")
	local shot_interval = minetest.get_item_group(blaster_name, "shot_interval")
	local cooldown_timeout = minetest.get_item_group(blaster_name, "cooldown_delay")
	local accuracy = minetest.get_item_group(blaster_name, "accuracy")
	--see if player is doing the right things with the right things to shoot
	if wieldeditem:get_name() == blaster_name and sw_blasters.gun_stats[player].overheated==false then
		if wieldeditem:get_wear() < 65535 - 65535 / (shots_default/2) then
			if control.RMB and sw_blasters.gun_stats[player].delay > shot_interval then
				wieldeditem:add_wear(65535 / shots_default)
				sw_blasters.gun_stats[player].venting=false
				--shoot function
				sw_blasters.shoot_entity(nil, player, wieldeditem, entity, bullet_speed, gravity, damage, textures, accuracy)
				minetest.sound_play(shoot_sound, {pos=player:get_pos(), max_hear_distance=shot_hear_distance, pitch = math.random(90,120)/100}, true)
				sw_blasters.gun_stats[player].delay = 0
				sw_blasters.gun_stats[player].cooling_delay=0
				player:set_wielded_item(wieldeditem)
			end
		--Make gun overheat if the last shot is taken
		elseif wieldeditem:get_wear() >= 65535 - 65535 / (shots_default/2) and sw_blasters.gun_stats[player].overheated==false then
			minetest.sound_play("sw_blasters_overheated", {pos=player:get_pos(), max_hear_distance=8, pitch = math.random(90,120)/100}, true)
			sw_blasters.gun_stats[player].overheated=true
		end
		--let the player cool thier gun or automatically
		if (control.LMB or sw_blasters.gun_stats[player].cooling_delay > cooldown_timeout) and sw_blasters.gun_stats[player].venting==false and wieldeditem:get_wear() > 0 then
			if control.LMB then
				wieldeditem:set_wear(65535 - 65535 / (shots_default/2)-1)
				player:set_wielded_item(wieldeditem)
			end
			minetest.sound_play("sw_blasters_cooling", {pos=player:get_pos(), max_hear_distance=8, pitch = math.random(90,120)/100}, true)
			sw_blasters.gun_stats[player].venting=true
			sw_blasters.gun_stats[player].delay=-0.7
			sw_blasters.gun_stats[player].cooling_handle = minetest.sound_play("sw_blasters_cooling_long", {pos=player:get_pos(), max_hear_distance=8, pitch = math.random(90,120)/100}, false)
		end
	end
end

---------Hud effect functions-----

function sw_blasters.add_zoom_hud(player)
	sw_blasters.zoom_hud[player] = {
		zoom_blur = player:hud_add({
			hud_elem_type = "image",
			position = {x = 0.505, y = 0.5},
			scale = {x = -101, y = -101},
			text = "sw_blasters_zoom_e11.png",
			z_index = -100,
		}),
	}
end
function sw_blasters.remove_zoom_hud(player)
	if sw_blasters.zoom_hud[player] then
		player:hud_remove(sw_blasters.zoom_hud[player].zoom_blur)
		sw_blasters.zoom_hud[player] = nil
	end
end

function sw_blasters.add_shootable_hud(player)
	sw_blasters.shootable_hud[player] = {
		_shootable_hud = player:hud_add({
			hud_elem_type = "image",
			position = {x = 0.505, y = 0.5},
			scale = {x = -101, y = -101},
			text = "sw_blasters_shootable_hud.png",
			z_index = -99,
		}),
	}
end
function sw_blasters.remove_shootable_hud(player)
	if sw_blasters.shootable_hud[player] then
		player:hud_remove(sw_blasters.shootable_hud[player]._shootable_hud)
		sw_blasters.shootable_hud[player] = nil
	end
end
-------------------------------------

minetest.register_on_leaveplayer(function(player)
	sw_blasters.shootable_hud[player] = nil
	sw_blasters.zoom_hud[player] = nil
end)


minetest.register_globalstep(function(dtime)


	for _,player in pairs(minetest.get_connected_players()) do

		if sw_blasters.gun_stats[player] then
			sw_blasters.gun_stats[player].delay = sw_blasters.gun_stats[player].delay + dtime
			sw_blasters.gun_stats[player].cooling_delay = sw_blasters.gun_stats[player].cooling_delay + dtime
		end

    local control = player:get_player_control()
    local wieldeditem = player:get_wielded_item()
    local type = ""

		if sw_blasters.wieldeditem[player] and sw_blasters.wieldeditem[player]:get_name() ~= wieldeditem:get_name() then
			if sw_blasters.gun_stats[player].cooling_handle then
				minetest.sound_stop(sw_blasters.gun_stats[player].cooling_handle)
			end
			sw_blasters.gun_stats[player].cooling_delay=0
			sw_blasters.gun_stats[player].venting=false
		end
		sw_blasters.wieldeditem[player] = wieldeditem

		if sw_blasters.object_timer[player] then
			sw_blasters.object_timer[player] = sw_blasters.object_timer[player] - dtime
			if sw_blasters.object_timer[player] < 0 then
				sw_blasters.object_timer[player] = nil
				if minetest.get_modpath("mcl_explosions") then
					mcl_explosions.explode(player:get_pos(), 6, {})
				elseif minetest.get_modpath("tnt") then
					tnt.boom(player:get_pos(), {radius=4, damage=4})
				end
			end
		end

		sw_blasters.gun_stats[player].pointing_at_shootable = false
		-- check to see of we are holding a blaster, of so, what class?
		if minetest.get_item_group(wieldeditem:get_name(), "med_rifle") ~= 0 then
			type = "med_rifle"
		elseif minetest.get_item_group(wieldeditem:get_name(), "long_range_rifle") ~= 0 then
			type = "long_range_rifle"
		elseif minetest.get_item_group(wieldeditem:get_name(), "heavy_short") ~= 0 then
			type = "heavy_short"
		else
			type = "other"
		end

		--check for blaster being cooled
		if sw_blasters.gun_stats[player].venting==true and wieldeditem:get_wear() > 0 and type ~= "other" then
			wieldeditem:add_wear(-minetest.get_item_group(wieldeditem:get_name(), "cooling_speed"))
			player:set_wielded_item(wieldeditem)
		elseif wieldeditem:get_wear() < 1 and sw_blasters.gun_stats[player].venting==true then
			if sw_blasters.gun_stats[player].cooling_handle then
				minetest.sound_stop(sw_blasters.gun_stats[player].cooling_handle)
				minetest.sound_play("sw_blasters_cooling_finished", {pos=player:get_pos(), max_hear_distance=5, pitch = math.random(90,120)/100}, true)
			end
			sw_blasters.gun_stats[player].venting=false
		end

		--Check to see if we overheated
		if sw_blasters.gun_stats[player].overheated==true and wieldeditem:get_wear() > 0 and type ~= "other" then
			wieldeditem:add_wear(-300)
			player:set_wielded_item(wieldeditem)
		elseif wieldeditem:get_wear() < 1 and type ~= "other" then
			sw_blasters.gun_stats[player].overheated=false
		end

		if type ~= "other" then
			-- check to see if we are pointing at an object
			local objs = minetest.get_objects_inside_radius(player:get_pos(), 100)
			for n = 1, #objs do
				local obj = objs[n]
				if obj and (obj:is_player() or obj:get_luaentity()._cmi_is_mob) then

					local pos = obj:get_pos()
					local player_pos = player:get_pos()

					local ender_distance = vector.distance(pos, player_pos)
					if ender_distance <= 100 and ender_distance >= 5 then

						local look_dir_ = player:get_look_dir()
						local look_dir = vector.normalize(look_dir_)
						local player_eye_height = player:get_properties().eye_height

						--calculate very quickly the exact location the player is looking
						local look_pos = vector.new(player_pos.x, player_pos.y + player_eye_height, player_pos.z)
						local look_pos_base = look_pos
						local ender_eye_pos = vector.new(pos.x, pos.y + (player_eye_height/2), pos.z)
						local eye_distance_from_player = vector.distance(ender_eye_pos, look_pos)
						look_pos = vector.add(look_pos, vector.multiply(look_dir, eye_distance_from_player))
						--if looking in general head position, pointing at shootable = true
						--line_of_sight function check's to see if ANYTHING is between pos1 and pos2, but we want this to work through plants and other walkable objects
						if --[[minetest.line_of_sight(ender_eye_pos, look_pos_base) and]]vector.distance(look_pos, ender_eye_pos) <= 1 and player ~= obj then
							if sw_blasters.gun_stats[player] then
								sw_blasters.gun_stats[player].pointing_at_shootable = true
							end
						end
					end
				end
			end
		end


		--check to see if we are pointing at a shootable object, if so, activate our hud for that.
		if control.zoom and type ~= "other" and type ~= "heavy_short" then
			if not sw_blasters.zoom_hud[player] then
				sw_blasters.add_zoom_hud(player)
			end
			if sw_blasters.gun_stats[player].pointing_at_shootable == true and sw_blasters.shootable_hud[player] == nil then
				sw_blasters.add_shootable_hud(player)
			elseif sw_blasters.gun_stats[player].pointing_at_shootable ~= true then
				sw_blasters.remove_shootable_hud(player)
			end
		elseif not control.zoom or type == "other" or type == "heavy_short" then
			if sw_blasters.zoom_hud[player] then
				sw_blasters.remove_zoom_hud(player)
			end
			if sw_blasters.shootable_hud[player] ~= nil then
				sw_blasters.remove_shootable_hud(player)
			end
		end

		--set respecive zoom per blaster class
    if control.zoom then
      if type == "med_rifle" then
				if player:get_fov() ~= 40 then
	        player:set_fov(40, false, 0.2)
				end
			elseif type == "long_range_rifle" then
				if player:get_fov() ~= 20 then
	        player:set_fov(20)
				end
			elseif type == "heavy_short" then
				if player:get_fov() ~= 75 then
	        player:set_fov(75, false, 0.2)
				end
      else
				if player:get_fov() ~= 80 then
	        player:set_fov(80, false, 0.2)
				end
      end
    else
			if player:get_fov() ~= 80 then
	      player:set_fov(80, false, 0.2)
			end
    end

		--Check to see if player is shooting, if so, spawn the respective blasts.
		--TODO: this shouldn't be on a server tick like this in my opinion.
		if player:get_hp() > 0 then
			--e_11
			blaster_shoot(player, "sw_blasters:e_11", wieldeditem, control, "sw_blasters:blast_entity", 0, {"sw_blasters_blast_red.png"}, "sw_blasters_e_11", 26)
			--FMWB-10
			blaster_shoot(player, "sw_blasters:fwmb10", wieldeditem, control, "sw_blasters:blast_entity", 0, {"sw_blasters_blast_red.png"}, "sw_blasters_fmwb10", 23)
			--NT-242
			blaster_shoot(player, "sw_blasters:nt242", wieldeditem, control, "sw_blasters:blast_entity", 0, {"sw_blasters_blast_red.png"}, "sw_blasters_nt242", 30)
			--DH-17
			blaster_shoot(player, "sw_blasters:dh17", wieldeditem, control, "sw_blasters:blast_entity", 0, {"sw_blasters_blast_red.png"}, "sw_blasters_dh17", 20)
			--A-295
			blaster_shoot(player, "sw_blasters:a295", wieldeditem, control, "sw_blasters:blast_entity", 0, {"sw_blasters_blast_red.png"}, "sw_blasters_a295", 20)
		end
  end
end)
