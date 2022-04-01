local function dir_to_pitch(dir)
	--local dir2 = vector.normalize(dir)
	local xz = math.abs(dir.x) + math.abs(dir.z)
	return -math.atan2(-dir.y, xz)
end

local function explode(self, pos, power)
	if minetest.get_modpath("mcl_explosions") then
		mcl_explosions.explode(pos, power*1.7, {}, self.object)
		self._destroyed=true
	elseif minetest.get_modpath("tnt") then
		tnt.boom(pos, {radius=power, damage=power})
		self._destroyed=true
	end
end

local BLAST_ENTITY={
	use_texture_alpha = true,
	physical = true,
	visual = "mesh",
	mesh = "sw_blasters_detonator.obj",
	visual_size = {x=2, y=2},
	textures = {"sw_blasters_thermal_detonator.png"},
	collisionbox = {-0.19, -0.125, -0.19, 0.19, 0.125, 0.19},
	collide_with_objects = false,

	_lastpos={},
	_damage=6,	-- Damage on impact
	_shooter=nil,	-- ObjectRef of player or mob who shot it
  _destroyed=false,
	glow = 15,
	_bounces=5,
	_de_timer=0,
	_explode_on_impact=nil,
	_power=4,
}
function BLAST_ENTITY.on_activate(self, staticdata, dtime_s)
	pos = self.object:get_pos()
	local objects = minetest.get_objects_inside_radius({x=pos.x, y=pos.y+-1.4, z=pos.z}, 0.05)
	for _,obj in ipairs(objects) do
		if obj:is_player() then
			self._shooter = obj
		end
	end
end

function BLAST_ENTITY.on_punch(self, puncher)
	if self._de_timer > 0.5 then
		if puncher:is_player() then
			if puncher:get_inventory():room_for_item("main", "sw_blasters:thermal_detonator") then
				self._destroyed=true
				if self._bomb_timer then
					puncher:get_inventory():add_item("main", "sw_blasters:thermal_detonator_activated")
				else
					puncher:get_inventory():add_item("main", "sw_blasters:thermal_detonator")
				end
				if self._bomb_timer then
					sw_blasters.object_timer[puncher] = self._bomb_timer
				end
			end
		end
	end
end

function BLAST_ENTITY.on_step(self, dtime)

	self._de_timer = self._de_timer + dtime

  if self._shooter then
  	local pos = self.object:get_pos()
		local vel=self.object:get_velocity()
		if self._bomb_timer then
			minetest.sound_play("sw_blasters_detonator_long", {pos=pos, max_hear_distance=12, pitch = math.random(90,120)/100}, true)
		end

		if self._bomb_timer then
			self._bomb_timer = self._bomb_timer - dtime
			if self._bomb_timer < 0 then
				explode(self, pos, self._power)
			end
		end

  	--check for collision, if so, disapear or bounce of metal wall
  	if (math.abs(vel.x) < 0.0001) or (math.abs(vel.z) < 0.0001) or (math.abs(vel.y) < 0.00001) then

			if self._explode_on_impact then
				explode(self, pos, self._power)
			else
				if self._last_vel then
					if (math.abs(vel.x) < 0.0001) then
						vel.x = self._last_vel.x*-0.2
					end
					if (math.abs(vel.z) < 0.0001) then
						vel.z = self._last_vel.z*-0.2
					end
					if (math.abs(vel.y) < 0.0001) then
						vel.x = vel.x * 0.8
						vel.z = vel.z * 0.8
						vel.y = self._last_vel.y*-0.2
					end

					self.object:set_velocity(vel)
				end
			end
		end

		self._last_vel = vel

    if self._destroyed == true then
      self.object:remove()
    end
  else
		self.object:remove()
  end
end

minetest.register_entity("sw_blasters:detonator_entity", BLAST_ENTITY)
