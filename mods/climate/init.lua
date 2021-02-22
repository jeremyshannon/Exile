--CLIMATE

--[[
Uses a markov chain to switch between weather states.
Has seasonal and diurnal fluctations in temperature, which adjust
the probability for which switch will occur (e.g rain more likely in cold)

This is climate rather than "weather" in the sense it treats the whole map
as the same, i.e. not big enough to get regional variation.


A specific locations Temperature and more can be called elsewhere (e.g. for health)

]]



climate = {
	active_weather = {},
	active_temp = {}

}

local modpath = minetest.get_modpath("climate")
local store = minetest.get_mod_storage()


-- Adds weather to register_weathers table
--all possible weather states
local registered_weathers = {}

-- Keeps sound handler references
local sound_handlers = {}

climate.register_weather = function(weather_obj)
	table.insert(registered_weathers, weather_obj)
end

dofile(modpath .. "/particles.lua")
dofile(modpath .. "/temperature.lua")
--weathers
dofile(modpath .. "/weathers/clear.lua")
dofile(modpath .. "/weathers/light_cloud.lua")
dofile(modpath .. "/weathers/medium_cloud.lua")
dofile(modpath .. "/weathers/sun_shower.lua")
dofile(modpath .. "/weathers/light_rain.lua")
dofile(modpath .. "/weathers/overcast_light_rain.lua")
dofile(modpath .. "/weathers/overcast.lua")
dofile(modpath .. "/weathers/overcast_rain.lua")
dofile(modpath .. "/weathers/overcast_heavy_rain.lua")
dofile(modpath .. "/weathers/thunderstorm.lua")
dofile(modpath .. "/weathers/superstorm.lua")
dofile(modpath .. "/weathers/light_haze.lua")
dofile(modpath .. "/weathers/haze.lua")
dofile(modpath .. "/weathers/duststorm.lua")
dofile(modpath .. "/weathers/snow_flurry.lua")
dofile(modpath .. "/weathers/light_snow.lua")
dofile(modpath .. "/weathers/overcast_light_snow.lua")
dofile(modpath .. "/weathers/overcast_snow.lua")
dofile(modpath .. "/weathers/overcast_heavy_snow.lua")
dofile(modpath .. "/weathers/snowstorm.lua")
dofile(modpath .. "/weathers/fog.lua")



--setting...for random intervals
local base_interval = 90
local base_int_range = 30

--temp classes for probabilities
local plvl_froz = -1
local plvl_cold = 15
local plvl_mid = 25


--what weather is on, and how long it will last, and temp
--random values that should get overriden by mod storage
climate.active_weather = registered_weathers[math.random(#registered_weathers)]
climate.active_temp = math.random(15,25)
local active_weather_interval = 1


--random walk, for temp
local ran_walk_range = 10
local ran_walk = math.random(-ran_walk_range,ran_walk_range)

--------------------------
-- Functions
--------------------------

--------------------
--create a random interval for the weather to last
local function set_active_interval()
  local intv = base_interval + math.random(-base_int_range, base_int_range)
  return intv
end


-----------------
--set the sky, for on join and when new weather set
local function set_sky_clouds(player)
	local active_weather = climate.active_weather

	player:set_sky(active_weather.sky_data)
	player:set_clouds(active_weather.cloud_data)
	player:set_moon(active_weather.moon_data)
	player:set_sun(active_weather.sun_data)
	player:set_stars(active_weather.star_data)


end

-----------------
local function get_weather_table(name, registered_weathers)
	local t = false
  for i, reg_weather in ipairs(registered_weathers) do
    if name == reg_weather.name then
      local active_weather = reg_weather
			t = true
      return active_weather
		end
	end

	if not t then
		--error, got a name it can't find
		--currently will likely make it crash
		minetest.log("error", "Climate: "..name.." not found")
		return
	end

end

-------------------------
--SAVE AND LOAD

--[[
--on_leave seems incapable of saving stuff :-(
minetest.register_on_leaveplayer(function(player)
	--save climate info it your the last one out
	local num_p = minetest.get_connected_players()
	if #num_p <=1 then
		local name = climate.active_weather.name
		local t = climate.active_temp
		store:set_string("weather", name)
		store:set_float("temp", t)
	end
end)
]]

minetest.register_on_joinplayer(function(player)
	--get weather from storage, override random start values
	local num_p = minetest.get_connected_players()
	if #num_p <=1 then

		local w_name = store:get_string("weather")

		if w_name ~= "" then
			--check valid
			local weather = get_weather_table(w_name, registered_weathers)
			if weather then
				climate.active_weather = weather
			end
		end

		--same again, but for temperature
		local temp = store:get_float("temp")
		if temp then
			climate.active_temp = temp
		end

		--same again, but for ran_walk
		local ranw = store:get_float("ran_walk")
		if ranw then
			ran_walk = ranw
		end

	end

	--set weather effects for this player
  set_sky_clouds(player)
  if climate.active_weather.sound_loop then
    local p_name = player:get_player_name()
    sound_handlers[p_name] = minetest.sound_play(climate.active_weather.sound_loop, {to_player = p_name, loop = true})
  end

end)


--------------------------
-- Main step
--------------------------

local timer = 0
local timer_p = 0

minetest.register_globalstep(function(dtime)

	--check if anyone is above ground to bother doing this for
	local ag_c = 0
	for _,player in ipairs(minetest.get_connected_players()) do
		local pos = player:get_pos()
		if pos.y > -12 then
			ag_c = ag_c + 1
		else
			--underground so remove sounds
			local p_name = player:get_player_name()
			local sound = sound_handlers[p_name]
			if sound ~= nil then
				minetest.sound_stop(sound)
				sound_handlers[p_name] = nil
			end
		end
	end
	if ag_c == 0 then
		--no one will experience any weather!
		--temperature doesn't get changed by seasons etc
		return
	end


  timer = timer + dtime
  timer_p = timer_p + dtime

	--fast weather effects
  if (climate.active_weather.particle_interval and timer_p > climate.active_weather.particle_interval) then
    -- do particle effects for current weather
    climate.active_weather.particle_function()
	end

	if climate.active_weather.sound_loop or climate.active_weather.sky_color_day then

    --update sky during transitions, and reset sounds
    for _,player in ipairs(minetest.get_connected_players()) do

			--add missing sounds (e.g. if turned off by going underground)
			if climate.active_weather.sound_loop  then
				local p_name = player:get_player_name()
				local sound = sound_handlers[p_name]
				if sound == nil  then
					sound_handlers[p_name] = minetest.sound_play(climate.active_weather.sound_loop, {to_player = p_name, loop = true})
				end
			end

    end

    timer_p = 0
	end

	--update weather state
  if timer > active_weather_interval then
    --timer has expired, switch to a new weather state

    --reset timer and interval
    timer = 0
    active_weather_interval = set_active_interval()
    --save interval
    --mod_storage:set_float('active_weather_interval', active_weather_interval)


    --select a new active_weather from probabilities
    --it will loop through and try to change the weather
    local new_weather_name
    for n, next in pairs(climate.active_weather.chain) do
      --roll dice
      local c = math.random()
      --use temperature adjusted probability
      if climate.active_temp < plvl_froz then
				--frozen temperature
				if next[2] > c then
					new_weather_name = next[1]
				end
			elseif climate.active_temp < plvl_cold then
        --cold temperature
        if next[3] > c then
          new_weather_name = next[1]
        end
      elseif climate.active_temp < plvl_mid then
        --mid temperature
        if next[4] > c then
          new_weather_name = next[1]
        end
      else
        --hot temperature
        if next[5] > c then
          new_weather_name = next[1]
        end
      end
    end

    --did it succeed in getting a new state?
    if new_weather_name and new_weather_name ~= climate.active_weather.name then

      --we need to update the sky and set the new
      climate.active_weather = get_weather_table(new_weather_name, registered_weathers)

      --do for each player
      for _,player in ipairs(minetest.get_connected_players()) do
        --set sky and clouds for new state using the new active_weather
        set_sky_clouds(player)

        --remove old sounds
        local p_name = player:get_player_name()
        local sound = sound_handlers[p_name]
      	if sound ~= nil then
      		minetest.sound_stop(sound)
      		sound_handlers[p_name] = nil
      	end
        --add new loop
        if climate.active_weather.sound_loop then
          sound_handlers[p_name] = minetest.sound_play(climate.active_weather.sound_loop, {to_player = p_name, loop = true})
        end

      end

    end


		--this is a universal temperature for the whole map
		--we are treating the whole map as one coherent region, with a single climate
		--specific player temp adjusted from this (e.g. by altitude)

		--get day night wave
		local tod = minetest.get_timeofday()
		--diff between day and night is this x2
		local dn_amp = -8
		local dn_period = 6.283 ---match day length
		local dn_wav = dn_amp * math.cos(tod * dn_period)

		--get seasonal wave
		local dc = minetest.get_day_count()
		--diff +/- from yearly mean (seasonal variation)
		local dc_amp = 17
		--~80 day year, 20 day seasons
		local dc_period = 0.08
		--yearly average,
		local dc_mean = 13
		local dc_wav = dc_amp * math.sin(dc * dc_period) + dc_mean
		--random walk...an incremental fluctuation that is capped
		ran_walk = ran_walk + math.random(-2, 2)
		if ran_walk > ran_walk_range or ran_walk < -ran_walk_range then
			ran_walk = ran_walk/1.04
		end

		--sum waves plus some random noise
		climate.active_temp = dc_wav + dn_wav + ran_walk



		--save state so can be reloaded.
		--only actually needed on log out,... but that doesn't work
		store:set_string("weather", climate.active_weather.name)
		store:set_float("temp", climate.active_temp)
		store:set_float("ran_walk", ran_walk)

	end
end)




--------------------------------------------------------------------
--CHAT COMMANDS


minetest.register_privilege("set_temp", {
	description = "Set the Climate active temperature",
	give_to_singleplayer = false
})


minetest.register_chatcommand("set_temp", {
    params = "<temp>",
    description = "Set the Climate active temperature",
		privs = {privs=true},
    func = function(name, param)
		newtemp = tonumber(param)
		if not newtemp or newtemp < -100 or newtemp > 100 then
		   return false, "Invalid temperature"
		end
		if minetest.check_player_privs(name, {set_temp = true}) then
			climate.active_temp = newtemp

			--only actually needed on log out,... but that doesn't work
			store:set_float("temp", climate.active_temp)

			return true, "Climate active temperature set to: "..newtemp

		else
			return false, "You need the set_temp privilege to use this command."
		end
	end,
})



-------------

minetest.register_privilege("set_weather", {
	description = "Set the Climate active weather",
	give_to_singleplayer = false
})


minetest.register_chatcommand("set_weather", {
    params = "<weather>",
    description = "Set the Climate active weather",
		privs = {privs=true},
    func = function(name, param)
		if minetest.check_player_privs(name, {set_weather = true}) then
			--check valid
			local weather = get_weather_table(param, registered_weathers)
			if weather then
				climate.active_weather = weather
				--do for each player
				for _,player in ipairs(minetest.get_connected_players()) do
					--set sky and clouds for new state using the new active_weather

					set_sky_clouds(player)

					--remove old sounds
					local p_name = player:get_player_name()
					local sound = sound_handlers[p_name]
					if sound ~= nil then
						minetest.sound_stop(sound)
						sound_handlers[p_name] = nil
					end
					--add new loop
					if climate.active_weather.sound_loop then
						sound_handlers[p_name] = minetest.sound_play(climate.active_weather.sound_loop, {to_player = p_name, loop = true})
					end

				end
				--only actually needed on log out,... but that doesn't work
				store:set_string("weather", climate.active_weather.name)

				return true, "Climate active weather set to: "..param
			else
				return false, "Invalid weather name"
			end

		else
			return false, "You need the set_temp privilege to use this command."
		end
	end,
})
