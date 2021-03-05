-----------------------------
--ON ACTION EFFECTS
--e.g. for eating items, exhaustion from moving etc

-----------------------------
local random = math.random

-----------------------------
--Quick physics
-- update the physics immediately, without going through all of malus_bonus
--(using malus_bonus itself produces conflicts)
--for things that need to instantly update physics i.e. need the flow on from reduced hunger now.
--only need the physics part as rates etc get applied from main health function
--MUST MATCH malus_bonus as it will get overriden by that when it kicks in!!!!

local function quick_physics(player, name, health, energy, thirst, hunger, temperature)
  --use standard values
  local mov = 0
  local jum = 0

  --
  --update rates
  --

  --bonus/malus from health
  if health <= 1 then
    mov = mov - 50
    jum = jum - 50
  elseif health < 4 then
    mov = mov - 25
    jum = jum - 25
  elseif health < 8 then
    mov = mov - 20
    jum = jum - 20
  elseif health < 12 then
    mov = mov - 15
    jum = jum - 15
  elseif health < 16 then
    mov = mov - 10
    jum = jum - 10
  end

  --bonus/malus from energy
  if energy > 800 then
    mov = mov + 15
    jum = jum + 15
  elseif energy < 1 then
    mov = mov - 30
    jum = jum - 30
  elseif energy < 200 then
    mov = mov - 20
    jum = jum - 20
  elseif energy < 400 then
    mov = mov - 10
    jum = jum - 10
  elseif energy < 600 then
    mov = mov - 1
    jum = jum - 1
  end


  --bonus/malus from thirst
  if thirst > 80 then
    mov = mov + 1
    jum = jum + 1
  elseif thirst < 1 then
    mov = mov - 30
    jum = jum - 30
  elseif thirst < 20 then
    mov = mov - 20
    jum = jum - 20
  elseif thirst < 40 then
    mov = mov - 10
    jum = jum - 10
  elseif thirst < 60 then
    mov = mov - 1
    jum = jum - 1
  end

  --bonus/malus from hunger
  if hunger > 800 then
    mov = mov + 1
    jum = jum + 1
  elseif hunger < 1 then
    mov = mov - 30
    jum = jum - 30
  elseif hunger < 200 then
    mov = mov - 20
    jum = jum - 20
  elseif hunger < 400 then
    mov = mov - 10
    jum = jum - 10
  elseif hunger < 600 then
    mov = mov - 1
    jum = jum - 1
  end

  --temp malus..severe..having this happen would make you very ill
  if temperature > 100 or temperature < 0 then
		--you dead
		mov = mov - 10000
		jum = jum - 10000
  elseif temperature > 47 or temperature < 27 then
    mov = mov - 80
    jum = jum - 80
  elseif temperature > 43 or temperature < 32 then
    mov = mov - 40
    jum = jum - 40
  elseif temperature > 38 or temperature < 37 then
    mov = mov - 20
    jum = jum - 20
  end


  --apply player physics
  --don't do in bed or it buggers the physics
  if not bed_rest.player[name] then
    player_monoids.speed:add_change(player, 1 + (mov/100), "health:physics")
    player_monoids.jump:add_change(player, 1 + (jum/100), "health:physics")
  end



end


-----------------------------
--On Actions
--

--Consummable items
function HEALTH.use_item(itemstack, user, hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item)

	if itemstack == nil or user == nil or not minetest.settings:get_bool("enable_damage") then
		return
	end

	local item = itemstack:get_name()
	local name = user:get_player_name()
	local meta = user:get_meta()

	local health = user:get_hp()
	local thirst = meta:get_int("thirst")
	local hunger = meta:get_int("hunger")
	local energy = meta:get_int("energy")
	local temperature = meta:get_int("temperature")

  local mov = meta:get_int("move")
	local jum = meta:get_int("jump")

	--calc change with min max
	health = health + hp_change
	if health < 0 then
		health = 0
	elseif health > 20 then
		health = 20
	end

	thirst = thirst + thirst_change
	if thirst < 0 then
		thirst = 0
	elseif thirst > 100 then
		thirst = 100
	end

	hunger = hunger + hunger_change
	if hunger < 0 then
		hunger = 0
	elseif hunger > 1000 then
		hunger = 1000
	end

	energy = energy + energy_change
	if energy < 0 then
		energy = 0
	elseif energy > 1000 then
		energy = 1000
	end

	temperature = temperature + temp_change

	--set new values
	-- and update malus (need for setting correct physics) --conflicts with Health Effects!
	--HEALTH.malus_bonus(user, name, meta, health, energy, thirst, hunger, temperature)
  quick_physics(user, name, health, energy, thirst, hunger, temperature)

	user:set_hp(health)
	meta:set_int("thirst", thirst)
	meta:set_int("hunger", hunger)
	meta:set_int("energy", energy)
	meta:set_int("temperature", temperature)
  --update form so can see change while looking
  sfinv.set_player_inventory_formspec(user)

	--minetest.chat_send_player(name, minetest.registered_items[item].description .." effect = Health: "..hp_change..", Thirst: "..thirst_change.. ", Hunger: "..hunger_change.. ", Energy: "..energy_change.. ", Body Temperature: "..temp_change )
  local pos = user:get_pos()
  minetest.sound_play("health_eat", {pos = pos, gain = 0.5, max_hear_distance = 2}
  )

	--replace/take
	itemstack:take_item()


	if itemstack:get_count() == 0 then
		itemstack:add_item(replace_with_item)
	else
		local inv = user:get_inventory()
		if inv:room_for_item("main", replace_with_item) then
			inv:add_item("main", replace_with_item)
		else
			minetest.add_item(user:get_pos(), replace_with_item)
		end
	end

	return itemstack
end


--fast interval (cf main update)
--Moving and digging and building
--Environmental based, bed rest ...
if minetest.settings:get_bool("enable_damage") then

	local timer = 0
	local interval = 4
	minetest.register_globalstep(function(dtime)
		timer = timer + dtime

		--run
		if timer > interval then
			for _,player in ipairs(minetest.get_connected_players()) do
				local name = player:get_player_name()
				local meta = player:get_meta()

				local health = player:get_hp()
				local thirst = meta:get_int("thirst")
				local hunger = meta:get_int("hunger")
				local energy = meta:get_int("energy")
				local temperature = meta:get_int("temperature")

				----------------
				--movement/digging
				local controls = player:get_player_control()
				-- Determine if the player is active,
        --some actions more energetic
				if controls.up
				or controls.down
				or controls.left
				or controls.right
				or controls.RMB
				then
					energy = energy - 3
          --thirsty work
          if random()<0.07 then
            thirst = thirst - 1
            hunger = hunger - 2
          end
				elseif controls.LMB
				or controls.jump then
					energy = energy - 8
          --thirsty work
          if random()<0.07 then
            thirst = thirst - 2
            hunger = hunger - 4
          end
				end

				----------------
				--Environmental temperature
				local player_pos = player:get_pos()
        local node_name = minetest.get_node(player_pos).name
        local water = minetest.get_item_group(node_name,"water")
				player_pos.y = player_pos.y + 0.6 --adjust to body height (for radiant heat)
				local enviro_temp = climate.get_point_temp(player_pos)
				--being outside tolerance range will drain energy. When energy is drained will succumb.
        --[safe] comfort zone ->[low cost]->stress zone ->[high cost]-> danger zone->[damage]

        local comfort_low = meta:get_int("clothing_temp_min")
      	local comfort_high = meta:get_int("clothing_temp_max") + 1
	-- comfort is rounded off in display, so you can be half a degree
	-- over and still in the white. Don't confuse players by penalizing!
        local stress_low = comfort_low - 10
        local stress_high = comfort_high + 10
        local danger_low = stress_low - 40
        local danger_high = stress_high +40
        --energy costs (extreme, danger, stress)
        local costex = 8
        local costd = 4
        local costs = 1
        --water conducts heat better
        if water then
          costex = 13
          costd = 8
          costs = 4
        end


        --burn or freeze
        if enviro_temp < danger_low or enviro_temp > danger_high then
          --tissue damaging freeze/burn
          health = health - 1
          energy = energy - costex
        --exhaustion from temp
        elseif energy > 0 then
					--have energy to resist (and it is resistable cf extreme)
					if enviro_temp < comfort_low or enviro_temp > comfort_high then
            --outside comfort zone
						if enviro_temp < stress_low or enviro_temp > stress_high then
							energy = energy - costd
						else
							energy = energy - costs
						end
					end
        end

          --totally exhausted, heat stroke or hypothermia now sets in
        if energy <= 0
        and (enviro_temp < stress_low or enviro_temp > stress_high) then
          --heat or cool to ambient temperature
          temperature = (temperature*0.95) + (enviro_temp*0.05)
          meta:set_int("temperature", temperature)
        end


				------------------
				local light = minetest.get_node_light(player_pos, 0.5)
				local rain = climate.get_rain(player_pos, light)
				local snow = climate.get_snow(player_pos, light)
				local dam_weather = climate.get_damage_weather(player_pos, light)

				--bed rest
				--when in bed, under shelter boost energy
				if energy < 1000 then
					if bed_rest.player[name] then
						--best rest is under shelter, in a non-extreme temperature
            local lvl = bed_rest.level[name]
						if rain
            or snow
            or dam_weather
            or enviro_temp < stress_low
            or enviro_temp > stress_high then
              --terrible sleep in the rain etc
              if random()>0.1 then
                energy = energy + (2 * lvl)
              end

            elseif enviro_temp < comfort_low
            or enviro_temp > comfort_high
            or light >= 14 then
              --okay sleep if in uncomfortable temp, exposed
              energy = energy + (4 * lvl)

            elseif enviro_temp < comfort_high and enviro_temp > comfort_low and light < 14 then
              --best rest is under shelter, in a non-extreme temperature
							energy = energy + (16 * lvl)
						end
					end
				end

        ------------------
				--drink a little rain
				if rain and thirst < 100 then
					--only sometimes or too easy
					if random()<0.2 then
						thirst = thirst + 1
					end
				end

        --thirsty in heat
        if random()<0.1 then
          if enviro_temp > stress_high then
            thirst = thirst - 2
          elseif enviro_temp > comfort_high then
            thirst = thirst - 1
          end
        end

				------------------
				--harmed by damaging weather,
				--exhausted by rain, snow
				if random()<0.5 then

					if dam_weather then
            health = health - 1
						energy = energy - 15
						if energy < 0 then
							energy = 0
						end

            --dust fever
            if random() < 0.02 then
              if climate.active_weather.name == 'duststorm' then
                HEALTH.add_new_effect(player, {"Dust Fever", 1})
              end
            end

					elseif rain or snow then
						energy = energy - 2
						if energy < 0 then
							energy = 0
						end
					end
				end


        ------------------
        --Health effects

        --zoonotic and contagious diseases
        --in biome
         --in node

        -- Fungal Infection from standing on wet soil
        if random() < 0.002 then
          local posu = player_pos
          posu.y = posu.y - 1.6

          local s_name = minetest.get_node(posu).name
      		if minetest.get_item_group(s_name, "wet_sediment") > 0 then
            HEALTH.add_new_effect(player, {"Fungal Infection", 1})
          end
        end





        ------------------
        --Final Housekeeping

        --cap energy etc
        if energy < 0 then
          energy = 0
        elseif energy > 1000 then
          energy = 1000
        end

        if thirst < 0 then
          thirst = 0
        elseif thirst > 100 then
          thirst = 100
        end

        if hunger < 0 then
          hunger = 0
        elseif hunger > 1000 then
          hunger = 1000
        end


				--update
				meta:set_int("energy", energy)
        meta:set_int("thirst", thirst)
        meta:set_int("hunger", hunger)
        player:set_hp(health)
				--update form so can see change while looking
				sfinv.set_player_inventory_formspec(player)

			end


		end

		--reset
		if timer > interval then
			timer = 0
		end
	end)

end
