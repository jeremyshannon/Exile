----------------------------------------------
--TEMPERATURE
--functions for calculating position temperature
--also for getting weather status
-- for use by other mods (e.g. health)



-------------------------------
--OUTDOORS AND EXPOSED TO ELEMENTS

--significantly raining/wet
--i.e. will expose to significant water, put out fires etc
climate.get_rain = function(pos, l)
	if pos.y < -30 then
		return false
	end
	--check if raining and outside
	if not l then
		l = minetest.get_node_light({x=pos.x, y=pos.y + 1, z=pos.z}, 0.5)
	end

	local w = climate.active_weather.name

	if l == 15
	and (w == 'overcast_heavy_rain'
	or w == 'overcast_rain'
	or w == 'thunderstorm'
	or w == 'superstorm') then
		return true
	else
		return false
	end
end

--significant snowing
--e.g. enough for snow build up
climate.get_snow = function(pos, l)
	if pos.y < -30 then
		return false
	end
	--check if raining and outside
	if not l then
		l = minetest.get_node_light({x=pos.x, y=pos.y + 1, z=pos.z}, 0.5)
	end

	local w = climate.active_weather.name

	if l == 15
	and (w == 'overcast_heavy_snow'
	or w == 'overcast_snow'
	or w == 'snowstorm') then
		return true
	else
		return false
	end
end


--evaporatable
climate.can_evaporate = function(pos, l)

	--must have air to be taken up by
	local posa = {x=pos.x, y=pos.y + 1, z=pos.z}
	if minetest.get_node(posa).name ~= "air" then
		return false
	end

	if not l then
		l = minetest.get_node_light(posa, 0.5)
	end

	--not when raining, i.e high humidity
	if not climate.get_rain(pos, l) then

		--higher chance of evap at higher temp.
		local t = climate.get_point_temp(pos)
		if t > 500 then
			--so hot things would get steamy fast
			return true
		elseif t > math.random(0,1000) then
			--none below 0 C, 10% chance at 100 C
			return true
		end
	end

	return false
end


--freeze
climate.can_freeze = function(pos)

	local c = math.random(-50,0)

	--stop freezing underwater
	--although technically you should be able to do it
	--given large volume of seas means lots of underwater ice
	--even if probabilities are low
	local t

	local posa = {x=pos.x, y=pos.y + 1, z=pos.z}
	local node = minetest.get_node(posa).name
	if minetest.get_item_group(node, "water") > 0 then
		return false
	elseif node == 'air' then
		--use air temp for air exposed ()
		t = climate.get_point_temp(posa)
	else
		t = climate.get_point_temp(pos)
	end

	--higher chance of freeze at lower temp.
	if t <= c then
		-- e.g. at -25 will freeze half the time.
		return true
	end

	return false
end


--thaw frozen
climate.can_thaw = function(pos)

	local posa = {x=pos.x, y=pos.y + 1, z=pos.z}

	--threshold must be low,
	--as its getting cooled by the ice itself
	local c = math.random(0,12)

	--rain washes it away
	if c < 2 then
		if climate.get_rain(posa) then
			return true
		end
	end

	--frozen nodes are also temp-source so have to
	--check outside the nodes
	--check above, or check below
	--water is an effective melting agent, so adjust c
	local node

	if c <6 then
		--above
		node = minetest.get_node(posa).name
	else
		--below
		posa.y = posa.y - 2
		node = minetest.get_node(posa).name
	end

	if minetest.get_item_group(node, "water") > 0 then
		c = c/3
	end

	if climate.get_point_temp(posa) > c then
		return true
	end

	return false
end


--exposed to lethal weather e.g. choking duststorm
--i.e. will expose to significant harm, do player damage
climate.get_damage_weather = function(pos, l)
	if pos.y < -30 then
		return false
	end
	--check if a damage weather and outside
	if not l then
		l = minetest.get_node_light({x=pos.x, y=pos.y + 1, z=pos.z}, 0.5)
	end

	if l == 15 and climate.active_weather.damage then
		return true
	else
		return false
	end
end



---------------------------------
--POINT TEMPERATURE

--apply heatable group if node is heatable
--heatable nodes carry extra heat or cooling gained from sources
local adjust_for_heatable = function(pos, name, temp)

	local heatable = minetest.get_item_group(name,"heatable")
	if heatable then
		local meta = minetest.get_meta(pos)
		local boost = meta:get_float("temp")
		temp = temp + boost
	end

	return temp
end

--Shelter. 
local adjust_for_shelter = function(pos, temp, av_temp)
	--Shelter. Brings temp closer to average
	--daytime dark is the closest proxy for shelter.
	--can't do darker than artificial light sources, or it will think it's outside
	local light = minetest.get_node_light({x=pos.x, y=pos.y+1, z=pos.z}, 0.5)
	if light and light <= 13 then
		if light <= 9 then
			temp = (temp*0.25)+(av_temp*0.75)
		elseif light <= 11 then
			temp = (temp*0.5)+(av_temp*0.5)
		else
			temp = (temp*0.75)+(av_temp*0.25)
		end
	end

	return temp

end


--adjust raw air temperature to be more appropriate for the location
local adjust_active_temp = function(pos, temp)

	--average temp (make sure it matches climate)
	local av_temp = 15
	local name = minetest.get_node(pos).name
  local water = minetest.get_item_group(name,"water")


	--sea water for deep ocean --stratification and density set a constant temperature
	if water == 2 and pos.y < -40 then
		temp = 4
		return temp
	end

	-------------------------------
	--Underground
  if pos.y < -12 and water ==0  then
    --average temp, heating under the earth. ~ 25C/km
    temp = -0.025*pos.y + av_temp
		temp = adjust_for_heatable(pos, name, temp)
    return temp
	end

	--transition to underground
	if pos.y <= -1 and water ==0 then
		--below ground is closer to average
		--should probably match to heightmap rather than y = 0 (maybe unnecessarily complicated)
		temp = (temp*0.2)+(temp*0.8)
		temp = adjust_for_shelter(pos, temp, av_temp)
		temp = adjust_for_heatable(pos, name, temp)
		return temp
	end

	-------------------------
	--Above ground and oceans

	--altitude cooling. ~ -2C per 300m
	if pos.y > 50 then
		temp = -0.0067*pos.y + temp
	end

	--Shelter.
	temp = adjust_for_shelter(pos, temp, av_temp)


	--Water and oceans
	if water ~= 0 then

		--water is closer to average than air...
		--also a little colder +(av_sea_temp *0.75)
		temp = (temp*0.25)+ 8
		temp = adjust_for_heatable(pos, name, temp) --currently nothing fits this

		--apply caps (not frozen or boiling)
		--freezing/boiling dynamics should kick in (in nodes_nature)
		if temp > 100 then
			temp = 100
			return temp
		elseif temp < 0 then
			temp = 0
			return temp
		else
			return temp
		end
	end

	temp = adjust_for_heatable(pos, name, temp)
	return temp

end










---------------------------------------------------------------
--Heatable
--nodes which can hold a temperature
--can be significantly heated or cooled e.g. for smelting



--For air_temp. Heat based movement. returns if moved or not
local move_air_nodes = function(pos, meta, temp_m)

	--heat rises 	-cold sink
	local pos_new
	if temp_m > 0 then
		pos_new = {x=pos.x, y=pos.y +1, z=pos.z}
	else
		pos_new = {x=pos.x, y=pos.y -1, z=pos.z}
	end

	--movement
	local timer = 8
	local name_new = minetest.get_node(pos_new).name
	if name_new == 'air' then
		--displace it
		minetest.set_node(pos, {name = 'air'})
		minetest.set_node(pos_new, {name = 'climate:air_temp'})
		local meta = minetest.get_meta(pos_new)
		meta:set_float("temp", temp_m)
		minetest.get_node_timer(pos_new):start(math.random(timer, timer*2))
		return true
	else
		--blocked above/below, so just select anywhere
		--then same again
		local pos_air = minetest.find_node_near(pos, 1, 'air')

		if pos_air then
			--displace it
			minetest.set_node(pos, {name = 'air'})
			minetest.set_node(pos_air, {name = 'climate:air_temp'})
			local meta = minetest.get_meta(pos_air)
			meta:set_float("temp", temp_m)
			minetest.get_node_timer(pos_air):start(math.random(timer, timer*2))
			return true
		end
	end
	return false
end





--anything in heatable group must already be running a node timer,
--and call heat_transfer function.
-- (e.g. as part of the smelting function. )

--replace is optional node to turn it into when its heat effect is gone
--e.g. air_temp -> air (has to makes sense with both cooling and heating)
function climate.heat_transfer(pos, nodename, replace)

	--get current accumulated temperature
	--remember meta temp is a booster, not the positions actual temp
	local meta = minetest.get_meta(pos)
	local temp_m = meta:get_float("temp")

	--remove node when boost is too small (if set)
	if replace then
		if temp_m <= 1 and temp_m >= -1 then
			minetest.set_node(pos, {name = replace})
			return false
		end
	end

	--heat transfers (exchange heat with other 'heatable')

	local pos_neighs = minetest.find_nodes_in_area(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y - 1, z = pos.z + 1},
		{"group:heatable"})

	if #pos_neighs > 0 then
		--doing this instead of minetest.find_node_near due to directional bias
		local neighbor = pos_neighs[math.random(#pos_neighs)]

		--heat flows down a gradient
		local meta_new = minetest.get_meta(neighbor)
		local temp_new = meta_new:get_float("temp")
		local t_diff = temp_m - temp_new
		local t_mo = math.abs(t_diff/4)
		--move quarter the difference to the colder one.
		--e.g. 8 vs 4. move 1, -> 7, 5
		--e.g. 20, 2, move 4.5 -> 15.5, 6.5

		--new is colder
		if t_diff > 0 then
			temp_m = temp_m - t_mo
			meta:set_float("temp", temp_m)
			meta_new:set_int("temp", temp_new + t_mo)
		else
			--old is colder
			temp_m = temp_m + t_mo
			meta:set_float("temp", temp_m)
			meta_new:set_int("temp", temp_new - t_mo)
		end

	end

	--dissappation..lose heat to environment
	local pos_max = {x=pos.x +1, y=pos.y +1, z=pos.z +1}
	local pos_min = {x=pos.x -1, y=pos.y -1, z=pos.z -1}
	local air, cn = minetest.find_nodes_in_area(pos_min, pos_max, {'air', 'group:water', 'climate:air_temp'})
	--including group:temp_pass causes problems for doing pottery etc in groups (cools down bc of neighbors).
	--taking them out of temp_pass would allow exploits (e.g. furnaces built from pots)
	-- it seems good to let air_temp self cool. Any other temp_pass nodes that ought to be here
	--will need to be added individually
	local amb = #air

	--factors:  base rate + ambient exposure X strength. * dis_speed = %reduction
	--dis_speed: 100 % means disspates fast. 0% means disspates slow

	local dis_speed =  minetest.get_item_group(nodename, "heatable") /100
	local dis_rate = ( 0.02 + (amb*0.035) ) * dis_speed

	temp_m = temp_m *(1 - dis_rate)
	meta:set_float("temp", temp_m)


	if nodename == "climate:air_temp" then
		local moved = move_air_nodes(pos, meta, temp_m)
		--no longer here, stop timer
		if moved then
			return false
		end
	end

	--made it here without removing the node
	return true

end




--Air
--these will move
minetest.register_node("climate:air_temp", {
	description = "Temperature Effect Air",
	tiles = {"climate_air.png"},
	drawtype = "airlike",
	--drawtype = "glasslike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	floodable = true,
	groups = {temp_pass = 1, heatable = 100},
	on_timer =function(pos, elapsed)
		return climate.heat_transfer(pos, "climate:air_temp", 'air')
	end,
	post_effect_color = {a = 5, r = 254, g = 254, b = 254}
})

--Water
--add here if that ever becomes necessary



--node timers call this to  heat/cool `heatable` group.
--if only air around it will create air_temp nodes
function climate.air_temp_source(pos, temp_effect, temp_max, chance, timer)
	--get all surrounding air positions, and heatables
	local pos_max = {x=pos.x +1, y=pos.y +1, z=pos.z +1}
	local pos_min = {x=pos.x -1, y=pos.y -1, z=pos.z -1}
	local heatable = minetest.find_nodes_in_area(pos_min, pos_max, {'air', 'group:heatable'})

	--heat/cool or create air nodes
	for _, node in pairs(heatable) do
		--use chance to decide if that postion will be affected
		--chance is determined by the source (i.e. how powerful it is)
		if math.random() > chance then
			local name = minetest.get_node(node).name

			--create air_temp
			if name == 'air' then
				--if it is air then create air_temp
				minetest.set_node(node, {name = 'climate:air_temp'})
				--save temp_effect in meta. This can accumulate over time
				--and will be added to temp adjust calculations
				local meta = minetest.get_meta(node)
				local temp = temp_effect
				meta:set_float("temp", temp)
				--set air_temp's timer for movement and dissappation
				--(first timer step based on the source node e.g. fire's burn rate)...
				--so that it matches production
				minetest.get_node_timer(node):start(math.random(timer, timer*2))

			else
				--heatable group
				--includes air_temp and anything else
				--accumulate meta temp from temp_effect capped by temp_max
				--add a diminishing % of effect the closer gets to cap
				local meta = minetest.get_meta(node)
				local temp = meta:get_float("temp")

				temp_effect = temp_effect*(1-(temp/temp_max))

				--apply temp caps
				local temp_new =  temp + temp_effect
				--heaters
				if temp_effect > 0 then
					if temp_new < temp_max then
						--still below cap... apply full heat.
						temp = temp_new
					elseif temp < temp_max then
						--can't add full heat, but not yet at cap
						--so raise it to the cap
						temp = temp_max
					end
				--coolers
				elseif temp_effect < 0 then
					if temp_new > temp_max then
						--still above cap... apply cooling.
						temp = temp_new
					elseif temp > temp_max then
						--can't add full cooling, but not yet at cap
						--so lower it to the cap
						temp = temp_max
					end
				end

				--update temp
				meta:set_float("temp", temp)
			end
		end
	end

end



----------------------------------------------
--"Radiation" based point temperature method
--this works, but doesn't allow for realistic furnace design on its own, so...
--make anything where air movements matter (e.g. fires) produce the above air nodes too


--Get line of temperature, can source transmit effect through to the target.
--returns boolean, and position (though position not currently useds)
local line_of_temp = function(node_pos, target_pos)
	--how close it needs to get
	local step = 0.5

	--get neighboring node
	local stepv = vector.direction(node_pos, target_pos)
	local new_pos = vector.add(node_pos, stepv)

	--checks
	local new_name = minetest.get_node(new_pos).name
	local pass = minetest.get_item_group(new_name,"temp_pass")

	--have reached target
	if vector.distance(new_pos, target_pos) < step then
		return true, new_pos
	end

	--loop through
	while new_name == 'air' or pass > 0 do
		--check neighbor
		stepv = vector.direction(new_pos, target_pos)
		new_pos = vector.add(new_pos, stepv)
		new_name = minetest.get_node(new_pos).name
		pass = minetest.get_item_group(new_name,"temp_pass")

		--have reached target
		if vector.distance(new_pos, target_pos) < step then
			return true, new_pos
		end
	end

	--made it through without finding target
	--return as blocked, with position
	return false, new_pos
end




-- Gets three lines from the faces of the nodes facing the player.
--los can spread through one temp_effect node e.g. to allow stacked fires to work
local get_los = function(node_pos, target_pos)
	local results = {}

	if target_pos.x > node_pos.x then
		--local los, lpos = minetest.line_of_sight({x=node_pos.x+0.51, y=node_pos.y, z=node_pos.z}, target_pos)
		local los, lpos = line_of_temp(node_pos, target_pos)
		table.insert(results, {los, lpos})
	else
		--local los, lpos = minetest.line_of_sight({x=node_pos.x-0.51, y=node_pos.y, z=node_pos.z}, target_pos)
		local los, lpos = line_of_temp(node_pos, target_pos)
		table.insert(results, {los, lpos})
	end

	if target_pos.y > node_pos.y then
		--local los, lpos = minetest.line_of_sight({x=node_pos.x, y=node_pos.y + 0.51, z=node_pos.z}, target_pos)
		local los, lpos = line_of_temp(node_pos, target_pos)
		table.insert(results, {los, lpos})
	else
		--local los, lpos = minetest.line_of_sight({x=node_pos.x, y=node_pos.y - 0.51, z=node_pos.z}, target_pos)
		local los, lpos = line_of_temp(node_pos, target_pos)
    table.insert(results, {los, lpos})
	end

	if target_pos.z > node_pos.z then
		--local los, lpos = minetest.line_of_sight({x=node_pos.x, y=node_pos.y, z=node_pos.z +0.51}, target_pos)
		local los, lpos = line_of_temp(node_pos, target_pos)
		table.insert(results, {los, lpos})
	else
		--local los, lpos = minetest.line_of_sight({x=node_pos.x, y=node_pos.y, z=node_pos.z -0.51}, target_pos)
		local los, lpos = line_of_temp(node_pos, target_pos)
		table.insert(results, {los, lpos})
	end

	return results
end






-- temp source  adjusts it based on distance.
local radiate_temp = function(target_pos, source_pos, temp_effect)
  local dist = vector.distance(target_pos, source_pos)

  if dist <=1 and target_pos.y > source_pos.y then
    --you are standing in it.
    return temp_effect * 6
  elseif dist <= 1 then
    -- just next to fire
    return temp_effect
  end

  --{{b,o},{b,o},{b,o}}
  local sight_lines = get_los(source_pos, target_pos)
  local los = false

  for k, v in pairs(sight_lines) do
    if v[1] then
      los = true
      break
    end
  end


  --check for line of sight, can any direction "see"
  if los then
    --adjust by distance
    temp_effect = temp_effect/dist
    return temp_effect
  else
    --completely blocked
    return 0
  end


end






--Function for getting the temperature of a specific location
climate.get_point_temp = function(pos)

	--if it's a temp_effect node then thats how hot it is by definition
	local nodename = minetest.get_node(pos).name
	local t_effect = minetest.get_item_group(nodename,"temp_effect")
	if t_effect ~= 0 then
		local t_effect_max = minetest.registered_nodes[nodename].temp_effect_max
		return t_effect_max
	end

  --correct the general temperature for location
	local temp = climate.active_temp
  temp = adjust_active_temp(pos, temp)

  --take into account heat and cooling sources nearby
  local r = 4
  local a = minetest.find_nodes_in_area({x=pos.x-r, y=pos.y-r, z=pos.z-r}, {x=pos.x+r, y=pos.y+r, z=pos.z+r}, {"group:temp_effect"})

	if #a < 1 then
		return temp
	end

  for i, no in pairs(a) do
		local name = minetest.get_node(no).name
		local effect = minetest.registered_nodes[name].temp_effect
    --adjust by distance
    effect = radiate_temp(pos, no, effect)

    --check caps. If temp has already gone too far it cannot contribute more
    local temp_effect_max = minetest.registered_nodes[name].temp_effect_max
		local temp_new =  temp + effect
    --heaters
    if effect > 0 then
			if temp_new < temp_effect_max then
				--still below cap... apply full heat.
				temp = temp_new
			elseif temp < temp_effect_max then
				--can't add full heat, but not yet at cap
				--so raise it to the cap
				temp = temp_effect_max
			end
		--coolers
		elseif effect < 0 then
			if temp_new > temp_effect_max then
	      --still above cap... apply cooling.
	      temp = temp_new
			elseif temp > temp_effect_max then
				--can't add full cooling, but not yet at cap
				--so lower it to the cap
				temp = temp_effect_max
			end
    end
  end

	return temp
end

--function for getting a temperature string set to the user's chosen scale
climate.get_temp_string = function(v)
   local scale = minetest.settings:get('exile_temp_scale')
   local t = v .." °C"
   if scale == "Fahrenheit" then
      v = v / 5 * 9 + 32
      t = v .." °F"
   elseif scale == "Kelvin" then
      v = v + 273.15
      t = v .."K"
   end
   return t
end

