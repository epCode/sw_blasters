local function dir_to_pitch(dir)
	--local dir2 = vector.normalize(dir)
	local xz = math.abs(dir.x) + math.abs(dir.z)
	return -math.atan2(-dir.y, xz)
end

local BLAST_ENTITY={
	use_texture_alpha = true,
	physical = true,
	pointable = false,
	visual = "mesh",
	mesh = "sw_blasters_blast_basic.obj",
	visual_size = {x=1.2, y=1.2},
	textures = {"sw_blasters_blast_red.png"},
	collisionbox = {-0.02, -0.02, -0.02, 0.02, 0.02, 0.02},
	collide_with_objects = false,

	_lastpos={},
	_damage=6,	-- Damage on impact
	_shooter=nil,	-- ObjectRef of player or mob who shot it
  _hit_wall=false,
  _destroyed=false,
	glow = 15,
	_bounces=5,
	_lifetimer=0,
}

local abs = math.abs

function BLAST_ENTITY.on_step(self, dtime)


	self._lifetimer = self._lifetimer + dtime
  if self._shooter then
  	local pos = self.object:get_pos()

  	--calculate blast rotatioin
		local vel = self.object:get_velocity()


		local yaw = minetest.dir_to_yaw(vel)
		local pitch = dir_to_pitch(vel)
		local last_pitch = self.object:get_rotation()
		local roll = last_pitch.z
		if not self._hit_wall then
	  	self.object:set_rotation({ x = pitch, y = yaw, z = roll })
		end

		--roughly calculate distance traveled for a range damage multiplier function
		if not self._hit_wall and self._last_vel then
			self._distance_traveled = self._lifetimer*(abs(self._last_vel.x)+abs(self._last_vel.y)+abs(self._last_vel.z))
		end

  	--check for collision, if so, disapear or bounce of stone wall
  	if ((math.abs(vel.x) < 0.0001) or (math.abs(vel.z) < 0.0001) or (math.abs(vel.y) < 0.00001)) and not self._hit_wall then
			minetest.sound_play("sw_blasters_small_hit_wall", {pos=pos, max_hear_distance=12, pitch = math.random(90,120)/100}, true)

			if self._last_vel then
				self._particle_block_pos = vector.add(vector.multiply(self._last_vel, 0.001), pos)
			else
				self._particle_block_pos = pos
			end

			if minetest.get_node(self._particle_block_pos).name == "default:stone" and self._last_vel then
				if (math.abs(vel.x) < 0.0001) then
					vel.x = self._last_vel.x*-1
					self._bounces = self._bounces - 1
				end
				if (math.abs(vel.y) < 0.0001) then
					vel.y = self._last_vel.y*-1
					self._bounces = self._bounces - 1
				end
				if (math.abs(vel.z) < 0.0001) then
					vel.z = self._last_vel.z*-1
					self._bounces = self._bounces - 1
				end

				self.object:set_velocity(vel)
			else

	      self._hit_wall = true
				minetest.add_particlespawner({
					amount = 10,
					time = 0.001,
					minpos = pos,
					maxpos = pos,
					minvel = vector.new(-1,-1,-1),
					maxvel = vector.new(1,2,1),
					minacc = vector.new(0,4,0),
					maxacc = vector.new(0,4,0),
					minexptime = 0.1,
					maxexptime = 1,
					minsize = 1,
					maxsize = 5,
					collisiondetection = false,
					vertical = false,
					texture = "sw_blasters_spark_burned"..math.random(1, 2)..".png",
					glow = 2,
				})
				local playerNode = minetest.get_node({x=self._particle_block_pos.x, y=self._particle_block_pos.y-1, z=self._particle_block_pos.z})
				local def = minetest.registered_nodes[playerNode.name]
				if def and def.walkable then
					minetest.add_particlespawner({
						amount = 20,
						time = 0.001,
						minpos = {x=pos.x, y=pos.y, z=pos.z},
						maxpos = {x=pos.x, y=pos.y, z=pos.z},
						minvel = {x=3, y=5, z=3},
						maxvel = {x=-3, y=-5, z=-3},
						minacc = {x=0, y=-9.81, z=0},
						maxacc = {x=0, y=-9.81, z=0},
						minexptime = 0.1,
						maxexptime = 1,
						minsize = 0.5,
						maxsize = 1.5,
						collisiondetection = true,
						vertical = false,
						node = playerNode,
						node_tile = 3,
					})
				end
			end
		end
		self._last_vel = vel

		if self._bounces < 1 then
			self._hit_wall = true
		end

    -- damage players and mobs while in flight
  	local objects = minetest.get_objects_inside_radius(pos, 1.5)
  	for _,obj in ipairs(objects) do
			if self._destroyed ~= true then
	  		if obj ~= self._shooter then
	  			if obj ~= self._shooter and self._lifetimer < 0.1 or self._lifetimer > 0.1 then
	  				if obj:is_player() or obj:get_luaentity()._cmi_is_mob then
							minetest.sound_play("sw_blasters_hit_enemy", {pos=self._shooter:get_pos(), max_hear_distance=4, pitch = math.random(90,120)/100}, true)
							if self._distance_traveled and self._distance_traveled > minetest.get_item_group(self._wielded_item_used:get_name(), "range") then
								self._damage = self._damage * (minetest.get_item_group(self._wielded_item_used:get_name(), "range")/self._distance_traveled)
								if self._damage < 1 then
									self._damage = 1
								end
							end
	  					obj:punch(self.object, 1.0, {
	  						full_punch_interval=1.0,
	  						damage_groups={fleshy=self._damage},
	  					}, self.object:get_velocity())
	            self._destroyed = true
	  				end
	  			end
	  		end
	  	end
		end

		if self._destroyed == true then
			self.object:remove()
		elseif self._hit_wall == true and self.textures[1] ~= "sw_blasters_hit_mark.png" then
			self.textures[1] = "sw_blasters_hit_mark.png"
			self.object:set_properties({textures=self.textures, visual_size = {x=4,y=4}, mesh = "sw_blasters_plane.obj"})
			if math.abs(self._last_vel.y) < 0.001 then
				self.object:set_rotation({x=pitch,y=yaw,z=roll+1.57})
			end
			self.object:set_velocity({x=0,y=0,z=0})
			self._last_vel = {x=0,y=0,z=0}
			minetest.after(5, function()
				self.object:remove()
			end)
    end
  else
    self.object:remove()
  end
end

minetest.register_entity("sw_blasters:blast_entity", BLAST_ENTITY)
