
----------------------------------------------------------------------
--HUD

----------------------------------------------------------------------
local hud = {}

local setup_hud = function(player)

	player:hud_set_flags({healthbar = false})
	local playername = player:get_player_name()

	local hud_data = {}
	hud[playername] = hud_data

	local py = 0.84
	local pys = 0.025
	local col = 0xFFFFFF
	local px = 0.05

	--labels then values
	player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
	  number = col, offset = {x = 0, y = 0},
		position = {x = 0.694, y = 0.925}, text = "Health:"
	})

	hud_data.hp_hud = player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = 	{x = 0.76, y = 0.925}, text = ""
	})


	player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
	  number = col, offset = {x = 0, y = 0},
		position = {x = 0.44, y = 0.88}, text = "Energy:"
	})

	hud_data.energy_hud  = player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.483, y = 0.88}, text = ""
	})


	player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.261, y = 0.925}, text = "Thirst:"
	})

	hud_data.thirst_hud  = player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.31, y = 0.925}, text = ""
	})

	player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.265, y = 0.97}, text = "Hunger:"
	})

	hud_data.hunger_hud  = player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.31, y = 0.97}, text = ""
	})

	player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.705, y = 0.97}, text = "Body Temp:"
	})

	hud_data.body_temp_hud  = player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.76, y = 0.97}, text = ""
	})


	player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.351, y = 0.88}, text = "Temp:"
	})

	hud_data.enviro_temp_hud  = player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.39, y = 0.88}, text = ""
	})


	player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.265, y = 0.88}, text = "Effects:"
	})

	hud_data.effects_hud  = player:hud_add({
		alignment = "right",
		hud_elem_type = "text",
		number = col, offset = {x = 0, y = 0},
		position = {x = 0.3, y = 0.88}, text = ""
	})


end


minetest.register_on_joinplayer(function(player)
	setup_hud(player)

end)


--colors
--fine = white (not noticeable)
--slight issue = yellow
--problem = orange
--major probem = red
--extreme = purple



local function color(v)
	local col = 0xFFFFFF
	if v <= 20 then
		col = 0x8008FF
	elseif v <= 40 then
		col = 0xDF0000
	elseif v <= 60 then
		col = 0xFF8100
	elseif v <= 80 then
		col = 0xFDFF46
	end
	return col
end

local function color_bodytemp(v)
	local col = 0xFFFFFF
	if v > 47 or v < 27 then
		col = 0x8008FF
	elseif v > 43 or v < 32 then
		col = 0xDF0000
	elseif v > 38 or v < 37 then
		col = 0xFF8100
	end
	return col
end

local function color_envirotemp(v, meta)
	--make sure matches actual values used!
	local comfort_low = meta:get_int("clothing_temp_min")
	local comfort_high = meta:get_int("clothing_temp_max")
	local stress_low = comfort_low - 10
	local stress_high = comfort_high + 10
	local danger_low = stress_low - 40
	local danger_high = stress_high +40

	local col = 0xFFFFFF

	if v > danger_high or v < danger_low then
		col = 0x8008FF
	elseif v > stress_high or v < stress_low then
		col = 0xDF0000
	elseif v > comfort_high or v < comfort_low then
		col = 0xFDFF46
	end

	return col
end


local function health(player, hud_data)
	local v = player:get_hp()
	v = (v/20)*100
	local col = color(v)
	local t = v .." %"
	local hud = hud_data.hp_hud
	player:hud_change(hud, "text", t)
	player:hud_change(hud, "number", col)

end


local function energy(player, hud_data)
  local meta = player:get_meta()
	local v = meta:get_int("energy")
	v = (v/1000)*100
	local col = color(v)
	local t = v .." %"
	local hud = hud_data.energy_hud
	player:hud_change(hud, "text", t)
	player:hud_change(hud, "number", col)
end

local function thirst(player, hud_data)
	local meta = player:get_meta()
	local v = meta:get_int("thirst")
	v = (v/100)*100
	local col = color(v)
	local t = v .." %"
	local hud =  hud_data.thirst_hud
	player:hud_change(hud, "text", t)
	player:hud_change(hud, "number", col)
end

local function hunger(player,  hud_data)
	local meta = player:get_meta()
	local v = meta:get_int("hunger")
	v = (v/1000)*100
	local col = color(v)
	local t = v .." %"
	local hud =  hud_data.hunger_hud
	player:hud_change(hud, "text", t)
	player:hud_change(hud, "number", col)
end


local function temp(player, hud_data)
	local meta = player:get_meta()
	local v = meta:get_int("temperature")
	local col = color_bodytemp(v)
	local t = climate.get_temp_string(v)
	local hud =  hud_data.body_temp_hud
	player:hud_change(hud, "text", t)
	player:hud_change(hud, "number", col)
end

local function enviro_temp(player, hud_data)
	local meta = player:get_meta()
	local player_pos = player:get_pos()
	player_pos.y = player_pos.y + 0.6 --adjust to body height
	local v = math.floor(climate.get_point_temp(player_pos))
	local col = color_envirotemp(v, meta)
	local t = climate.get_temp_string(v)
	local hud =  hud_data.enviro_temp_hud
	player:hud_change(hud, "text", t)
	player:hud_change(hud, "number", col)
end


local function effects(player, hud_data)
	local meta = player:get_meta()
	local v = meta:get_int("effects_num")
	local t = "x "..v
	local hud =  hud_data.effects_hud
	player:hud_change(hud, "text", t)
end




local function _0_(_)
  for _0, player in ipairs(minetest.get_connected_players()) do

		local name = player:get_player_name()
		local hud_data = hud[name]
		if not hud_data then
			return
		end

		health(player, hud_data)
		energy(player, hud_data)
		thirst(player, hud_data)
		hunger(player, hud_data)
		temp(player, hud_data)
		enviro_temp(player, hud_data)
		effects(player, hud_data)

  end
  return nil
end

return minetest.register_globalstep(_0_)
