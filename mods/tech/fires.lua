------------------------------------
--TEMPERATURE CRAFTS
--crafts for temperature changing things (and associated things)
--e.g. fires
-----------------------------------
--interval
local base_burn_rate = 4
--how much to burn (for small fire)
local base_fuel = 300

--temperatures
--blocks are x 1.5 temp max, 2x temp effect,
--smouldering is 1/3 temp effect, but same temp max
local wood_temp_effect = 15
local wood_temp_max = 600
local wood_air_c = 0.65
--charchoal has higher max, and more effective output
--i.e. char is for smelting etc, wood for personal heating, kilns
local char_temp_effect = wood_temp_effect * 2
local char_temp_max = wood_temp_max * 2
local char_air_c = 0.45

-------------------------------
--Functions



--converts smoldering fire into full fire if air is present
local function can_smolder(pos, meta, fire_name, ash_name)
	--extinguish in water
	if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:puts_out_fire"}) then
		minetest.set_node(pos, {name = ash_name})
		minetest.sound_play("nodes_nature_cool_lava",	{pos = pos, max_hear_distance = 16, gain = 0.25})
		return false
	end

	--check for the presence of air
	if minetest.find_node_near(pos, 1, {"air"}) then
		local f = meta:get_int("fuel")
		--air, roar back to full flame
		minetest.set_node(pos, {name = fire_name})
		meta:set_int("fuel", f)
		return false
	else
		return true
	end
end

--converts fire into smoldering fire if air not present
local function can_burn_air(pos, meta, smolder_name, ash_name)
	--extinguish
	if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:puts_out_fire"}) then
		minetest.set_node(pos, {name = ash_name})
		minetest.sound_play("nodes_nature_cool_lava",	{pos = pos, max_hear_distance = 16, gain = 0.25})
		return false
	end

	--check for the presence of air
	if minetest.find_node_near(pos, 1, {"air"}) then
		return true
	else
		local f = meta:get_int("fuel")
		--smolder
		minetest.set_node(pos, {name = smolder_name})
		meta:set_int("fuel", f)
		return false
	end
end

--Particle Effects

local function hearth_fire_on(pos)
	if math.random()<0.6 then
		minetest.sound_play("tech_fire_small",{pos=pos, max_hear_distance = 15, loop=false, gain=0.2})
		--Smoke
		minetest.add_particlespawner({
			amount = 4,
			time = 0.5,
			minpos = {x = pos.x - 0.1, y = pos.y + 0.5, z = pos.z - 0.1},
			maxpos = {x = pos.x + 0.1, y = pos.y + 1, z = pos.z + 0.1},
			minvel = {x= 0, y= 0, z= 0},
			maxvel = {x= 0.01, y= 0.07, z= 0.01},
			minacc = {x= 0, y= 0, z= 0},
			maxacc = {x= 0.01, y= 0.2, z= 0.01},
			minexptime = 5,
			maxexptime = 20,
			minsize = 1,
			maxsize = 8,
			collisiondetection = true,
			vertical = true,
			texture = "tech_smoke.png",
		})

	end

	local meta = minetest.get_meta(pos)
	--flames
	minetest.add_particlespawner({
		amount = 6,
		time = 1,
		minpos = {x = pos.x - 0.1, y = pos.y + 0.1, z = pos.z - 0.1},
		maxpos = {x = pos.x + 0.1, y = pos.y + 0.7, z = pos.z + 0.1},
		minvel = {x= 0, y= 0, z= 0},
		maxvel = {x= 0.001, y= 0.001, z= 0.001},
		minacc = {x= 0, y= 0, z= 0},
		maxacc = {x= 0.001, y= 0.001, z= 0.001},
		minexptime = 3,
		maxexptime = 5,
		minsize = 4,
		maxsize = 8,
		collisiondetection = false,
		vertical = true,
		texture = "tech_flame_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1
		},
		glow = 13,
	})


end





-------------------------------------------------
--Nodes
--
-------------------------------------------------


--------------------------------------------------
--Combustion Products

--wood_ash
minetest.register_node("tech:wood_ash_block", {
	description = "Wood Ash Block",
	tiles = {"tech_wood_ash.png"},
	stack_max = minimal.stack_max_bulky,
	groups = {crumbly = 3, falling_node = 1, fertilizer = 1},
	sounds = nodes_nature.node_sound_dirt_defaults(),
})


minetest.register_node("tech:wood_ash", {
	description = "Wood Ash",
	tiles = {"tech_wood_ash.png"},
	stack_max = minimal.stack_max_bulky *2,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	groups = {crumbly = 3, falling_node = 1, fertilizer = 1},
	sounds = nodes_nature.node_sound_dirt_defaults(),
})

--Charcoal
minetest.register_node("tech:charcoal_block", {
	description = "Charcoal Block",
	tiles = {"tech_charcoal.png"},
	stack_max = minimal.stack_max_bulky,
	groups = {crumbly = 3, falling_node = 1, fertilizer = 1, flammable = 1},
	sounds = nodes_nature.node_sound_dirt_defaults(),
	on_burn = function(pos)
		minetest.set_node(pos, {name = "tech:large_charcoal_fire"})
		minetest.check_for_falling(pos)
	end,
})


minetest.register_node("tech:charcoal", {
	description = "Charcoal",
	tiles = {"tech_charcoal.png"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	stack_max = minimal.stack_max_bulky *2,
	groups = {crumbly = 3, falling_node = 1, fertilizer = 1, flammable = 1},
	sounds = nodes_nature.node_sound_dirt_defaults(),
	on_burn = function(pos)
		minetest.set_node(pos, {name = "tech:small_charcoal_fire"})
		minetest.check_for_falling(pos)
	end,
})



--------------------------------------------------
-- extinguish on punch
--

local function extinguish_fire(pos, puncher, itemstack, ext_name)
	--you must be holding something to smother it with or you get burned
	--hit it with fertilizer to restore
	local itemstack = puncher:get_wielded_item()
	local ist_name = itemstack:get_name()

	if minetest.get_item_group(ist_name, "sediment") >= 1
	then

		--get meta and save to extinguished version
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
		minetest.set_node(pos, {name = ext_name})
		meta:set_int("fuel", fuel)
		minetest.sound_play("nodes_nature_cool_lava",	{pos = pos, max_hear_distance = 16, gain = 0.25})

	else
		local hp = puncher:get_hp()
		puncher:set_hp(hp-1)
	end

end

--------------------------------------------------
-- wood fires
--

--unlit wood fires
minetest.register_node('tech:small_wood_fire_unlit', {
	description = 'Small Wood Fire (unlit)',
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	tiles = {"tech_wood_fire_unlit.png"},
	stack_max = minimal.stack_max_bulky *2,
	paramtype = "light",
	groups = {oddly_breakable_by_hand = 3, choppy = 3, falling_node = 1, flammable = 1},
	sounds = nodes_nature.node_sound_wood_defaults(),
	on_burn = function(pos)
		minetest.set_node(pos, {name = "tech:small_wood_fire"})
		minetest.check_for_falling(pos)
	end
})

minetest.register_node('tech:large_wood_fire_unlit', {
	description = 'Large Wood Fire (unlit)',
	tiles = {"tech_wood_fire_unlit.png"},
	stack_max = minimal.stack_max_bulky,
	paramtype = "light",
	groups = {oddly_breakable_by_hand = 3, choppy = 3, falling_node = 1, flammable = 1},
	sounds = nodes_nature.node_sound_wood_defaults(),
	on_burn = function(pos)
		minetest.set_node(pos, {name = "tech:large_wood_fire"})
		minetest.check_for_falling(pos)
	end
})

--lit wood fires
minetest.register_node('tech:small_wood_fire', {
	description = 'Small Wood Fire',
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	tiles = {"tech_coal_bed.png"},
	light_source= 7,
	temp_effect = wood_temp_effect,
	temp_effect_max = wood_temp_max,
	paramtype = "light",
	--walkable = false,
	drop = "tech:wood_ash",
	groups = {crumbly = 1, igniter = 1, falling_node = 1,  temp_effect = 1, temp_pass = 1},
	--damage_per_second = 1,
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_punch = function(pos, node, puncher, pointed_thing)
		extinguish_fire(pos, puncher, itemstack, 'tech:small_wood_fire_ext')
	end,

	on_construct = function(pos)
		--duration of burn
		local meta = minetest.get_meta(pos)
		meta:set_int("fuel", base_fuel)

		--fire effects..
		minetest.get_node_timer(pos):start(math.random(base_burn_rate-1,base_burn_rate+1))
	end,
	on_timer =function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
		if fuel < 1 then
			minetest.set_node(pos, {name = "tech:wood_ash"})
			return false
		elseif can_burn_air(pos, meta, "tech:small_wood_fire_smoldering", "tech:wood_ash" ) then
			hearth_fire_on(pos)
			meta:set_int("fuel", fuel - 1)
			--add hot air
			climate.air_temp_source(pos, wood_temp_effect, wood_temp_max, wood_air_c, base_burn_rate)
			-- Restart timer
			return true
		end
	end,
})


minetest.register_node('tech:large_wood_fire', {
	description = 'Large Wood Fire',
	tiles = {"tech_coal_bed.png"},
	light_source= 8,
	paramtype = "light",
	temp_effect = wood_temp_effect *2,
	temp_effect_max = wood_temp_max *1.5,
	--walkable = false,
	drop = "tech:wood_ash_block",
	groups = {crumbly = 1, igniter = 1, falling_node = 1,  temp_effect = 1, temp_pass = 1},
	--damage_per_second = 1,
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_punch = function(pos, node, puncher, pointed_thing)
		extinguish_fire(pos, puncher, itemstack, 'tech:large_wood_fire_ext')
	end,

	on_construct = function(pos)
		--duration of burn
		local meta = minetest.get_meta(pos)
		meta:set_int("fuel", base_fuel*2)

		--fire effects
		minetest.get_node_timer(pos):start(math.random(base_burn_rate-1,base_burn_rate+1))
	end,
	on_timer =function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
		if fuel < 1 then
			minetest.set_node(pos, {name = "tech:wood_ash_block"})
			return false
		elseif can_burn_air(pos, meta, "tech:large_wood_fire_smoldering", "tech:wood_ash_block") then
			hearth_fire_on(pos)
			meta:set_int("fuel", fuel - 1)
			--add hot air
			climate.air_temp_source(pos, wood_temp_effect*2, wood_temp_max*2, wood_air_c-0.1, base_burn_rate)
			-- Restart timer
			return true
		end
	end,
})


--
-- smoldering wood fires (can turn into charcoal)
--colder and flameless
--
minetest.register_node('tech:small_wood_fire_smoldering', {
	description = 'Small Wood Fire (smoldering)',
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	tiles = {"tech_coal_bed.png"},
	light_source= 3,
	paramtype = "light",
	temp_effect = wood_temp_effect/3,
	temp_effect_max = wood_temp_max,
	--walkable = false,
	drop = "tech:wood_ash",
	groups = {crumbly = 1, igniter = 1, falling_node = 1,  temp_effect = 1, temp_pass = 1},
	--damage_per_second = 1,
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_punch = function(pos, node, puncher, pointed_thing)
		extinguish_fire(pos, puncher, itemstack, 'tech:small_wood_fire_ext')
	end,

	on_construct = function(pos)
		--no meta , should only be made from a pre-existing fire
		--checks
		minetest.get_node_timer(pos):start(base_burn_rate * 1.5)
	end,
	on_timer =function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
		if fuel < 1 then
			minetest.set_node(pos, {name = "tech:charcoal"})
			return false
		else
			if can_smolder(pos, meta, 'tech:small_wood_fire', "tech:wood_ash") then
				meta:set_int("fuel", fuel - 1)
				--add hot air
				climate.air_temp_source(pos, wood_temp_effect/3, wood_temp_max, wood_air_c+0.3, base_burn_rate)
				-- Restart timer
				return true
			end
		end
	end,
})

minetest.register_node('tech:large_wood_fire_smoldering', {
	description = 'Large Wood Fire (smoldering)',
	tiles = {"tech_coal_bed.png"},
	light_source= 3,
	paramtype = "light",
	temp_effect = (wood_temp_effect*2)/3,
	temp_effect_max = (wood_temp_max*1.5),
	--walkable = false,
	drop = "tech:wood_ash_block",
	groups = {crumbly = 1, igniter = 1, falling_node = 1,  temp_effect = 1, temp_pass = 1},
	--damage_per_second = 1,
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_punch = function(pos, node, puncher, pointed_thing)
		extinguish_fire(pos, puncher, itemstack, 'tech:large_wood_fire_ext')
	end,

	on_construct = function(pos)
		--no meta , should only be made from a pre-existing fire
		--checks
		minetest.get_node_timer(pos):start(base_burn_rate * 1.5)
	end,
	on_timer =function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
		if fuel < 1 then
			minetest.set_node(pos, {name = "tech:charcoal_block"})
			return false
		else
			if can_smolder(pos, meta, 'tech:large_wood_fire', "tech:wood_ash_block") then
				meta:set_int("fuel", fuel - 1)
				--add hot air
				climate.air_temp_source(pos, (wood_temp_effect*2)/3, wood_temp_max*2, wood_air_c+0.15, base_burn_rate)
				-- Restart timer
				return true
			end
		end
	end,
})



--------------------------------------------------

--Charcoal fires
--hotter than wood
--
minetest.register_node('tech:small_charcoal_fire', {
	description = 'Small Charcoal Fire',
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	tiles = {"tech_coal_bed.png"},
	light_source= 7,
	temp_effect = char_temp_effect,
	temp_effect_max = char_temp_max,
	paramtype = "light",
	--walkable = false,
	drop = "tech:wood_ash",
	groups = {crumbly = 1, igniter = 1, falling_node = 1,  temp_effect = 1, temp_pass = 1},
	--damage_per_second = 1,
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_punch = function(pos, node, puncher, pointed_thing)
		extinguish_fire(pos, puncher, itemstack, 'tech:small_charcoal_fire_ext')
	end,

	on_construct = function(pos)
		--duration of burn ...less than wood due to loss
		local meta = minetest.get_meta(pos)
		meta:set_int("fuel", base_fuel *0.75)

		--fire effects...more consistent burn.
		minetest.get_node_timer(pos):start(base_burn_rate)
	end,
	on_timer =function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
		if fuel < 1 then
			minetest.set_node(pos, {name = "tech:wood_ash"})
			return false
		elseif can_burn_air(pos, meta, "tech:small_charcoal_fire_smoldering", "tech:wood_ash" ) then
			hearth_fire_on(pos)
			meta:set_int("fuel", fuel - 1)
			--add hot air
			climate.air_temp_source(pos, char_temp_effect, char_temp_max, char_air_c, base_burn_rate)
			-- Restart timer
			return true
		end
	end,
})


minetest.register_node('tech:large_charcoal_fire', {
	description = 'Large Charcoal Fire',
	tiles = {"tech_coal_bed.png"},
	light_source= 8,
	temp_effect = char_temp_effect *2,
	temp_effect_max = char_temp_max *1.5,
	paramtype = "light",
	--walkable = false,
	drop = "tech:wood_ash_block",
	groups = {crumbly = 1, igniter = 1, falling_node = 1,  temp_effect = 1, temp_pass = 1},
	--damage_per_second = 1,
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_punch = function(pos, node, puncher, pointed_thing)
		extinguish_fire(pos, puncher, itemstack, 'tech:large_charcoal_fire_ext')
	end,

	on_construct = function(pos)
		--duration of burn
		local meta = minetest.get_meta(pos)
		meta:set_int("fuel", base_fuel *2*0.75)

		--fire effects
		minetest.get_node_timer(pos):start(base_burn_rate)
	end,
	on_timer =function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
		if fuel < 1 then
			minetest.set_node(pos, {name = "tech:wood_ash_block"})
			return false
		elseif can_burn_air(pos, meta, "tech:large_charcoal_fire_smoldering", "tech:wood_ash_block") then
			hearth_fire_on(pos)
			meta:set_int("fuel", fuel - 1)
			--add hot air
			climate.air_temp_source(pos, char_temp_effect*2, char_temp_max*2, char_air_c -0.1, base_burn_rate)
			-- Restart timer
			return true
		end
	end,
})


--
-- smoldering charcoal fires
--colder and flameless...reduce to ash
--
minetest.register_node('tech:small_charcoal_fire_smoldering', {
	description = 'Small Charcoal Fire (smoldering)',
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	tiles = {"tech_coal_bed.png"},
	light_source= 3,
	temp_effect = char_temp_effect/3,
	temp_effect_max = char_temp_max,
	paramtype = "light",
	--walkable = false,
	drop = "tech:wood_ash",
	groups = {crumbly = 1, igniter = 1, falling_node = 1,  temp_effect = 1, temp_pass = 1},
	--damage_per_second = 1,
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_punch = function(pos, node, puncher, pointed_thing)
		extinguish_fire(pos, puncher, itemstack, 'tech:small_charcoal_fire_ext')
	end,

	on_construct = function(pos)
		--no meta , should only be made from a pre-existing fire
		--checks
		minetest.get_node_timer(pos):start(base_burn_rate * 1.5)
	end,
	on_timer =function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
		if fuel < 1 then
			minetest.set_node(pos, {name = "tech:wood_ash"})
			return false
		else
			if can_smolder(pos, meta, 'tech:small_charcoal_fire', "tech:wood_ash") then
				meta:set_int("fuel", fuel - 1)
				--add hot air
				climate.air_temp_source(pos, char_temp_effect/3, char_temp_max, char_air_c +0.3, base_burn_rate)
				-- Restart timer
				return true
			end
		end
	end,
})

minetest.register_node('tech:large_charcoal_fire_smoldering', {
	description = 'Large Charcoal Fire (smoldering)',
	tiles = {"tech_coal_bed.png"},
	light_source= 3,
	temp_effect = (char_temp_effect*2)/3,
	temp_effect_max = (char_temp_max*1.5),
	paramtype = "light",
	--walkable = false,
	drop = "tech:wood_ash_block",
	groups = {crumbly = 1, igniter = 1, falling_node = 1,  temp_effect = 1, temp_pass = 1},
	--damage_per_second = 1,
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_punch = function(pos, node, puncher, pointed_thing)
		extinguish_fire(pos, puncher, itemstack, 'tech:large_charcoal_fire_ext')
	end,

	on_construct = function(pos)
		--duration of burn
		local meta = minetest.get_meta(pos)
		--no meta , should only be made from a pre-existing fire
		--checks
		minetest.get_node_timer(pos):start(base_burn_rate * 1.5)
	end,
	on_timer =function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
		if fuel < 1 then
			minetest.set_node(pos, {name = "tech:wood_ash_block"})
			return false
		else
			if can_smolder(pos, meta, 'tech:large_charcoal_fire', "tech:wood_ash_block") then
				meta:set_int("fuel", fuel - 1)
				--add hot air
				climate.air_temp_source(pos, (char_temp_effect*2)/3, char_temp_max*2, char_air_c+0.15, base_burn_rate)
				-- Restart timer
				return true
			end
		end
	end,
})





--------------------------------------------------
--Extinguished Fires
--Fires that got put out
--punch to turn lit fires into this
--saves burn amount in meta, including when in inv.
--can be relit like normal fire


--save usage into inventory
local on_dig_fire = function(pos, node, digger)
	if not digger or minetest.is_protected(pos, digger:get_player_name()) then
		return false
	end

	local meta = minetest.get_meta(pos)
	local fuel = meta:get_int("fuel")

	local new_stack = ItemStack(node.name)
	local stack_meta = new_stack:get_meta()
	stack_meta:set_int("fuel", fuel)


	minetest.remove_node(pos)
	local player_inv = digger:get_inventory()
	if player_inv:room_for_item("main", new_stack) then
		player_inv:add_item("main", new_stack)
	else
		minetest.add_item(pos, new_stack)
	end
end

--set saved fuel
local after_place_fire = function(pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta(pos)
	local stack_meta = itemstack:get_meta()
	local fuel = stack_meta:get_int("fuel")
	if fuel >0 then
		meta:set_int("fuel", fuel)
	end
end


-- wood fires
minetest.register_node('tech:small_wood_fire_ext', {
	description = 'Small Wood Fire (extinguished)',
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	tiles = {"tech_fire_ext.png"},
	paramtype = "light",
	groups = {crumbly = 3, oddly_breakable_by_hand = 1, falling_node = 1, temp_pass = 1},
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_dig = on_dig_fire,
	after_place_node = after_place_fire,

})


minetest.register_node('tech:large_wood_fire_ext', {
	description = 'Large Wood Fire (extinguished)',
	tiles = {"tech_fire_ext.png"},
	groups = {crumbly = 3, oddly_breakable_by_hand = 1, falling_node = 1, temp_pass = 1},
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_dig = on_dig_fire,
	after_place_node = after_place_fire,

})



-- charcoal fires
minetest.register_node('tech:small_charcoal_fire_ext', {
	description = 'Small Charcoal Fire (extinguished)',
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	tiles = {"tech_fire_ext.png"},
	paramtype = "light",
	groups = {crumbly = 3, oddly_breakable_by_hand = 1, falling_node = 1, temp_pass = 1},
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_dig = on_dig_fire,
	after_place_node = after_place_fire,

})


minetest.register_node('tech:large_charcoal_fire_ext', {
	description = 'Large Charcoal Fire (extinguished)',
	tiles = {"tech_fire_ext.png"},
	groups = {crumbly = 3, oddly_breakable_by_hand = 1, falling_node = 1, temp_pass = 1},
	sounds = nodes_nature.node_sound_dirt_defaults(),

	on_dig = on_dig_fire,
	after_place_node = after_place_fire,

})







---------------------------------------
--Recipes

--
--Hand crafts (Crafting spot)
--

----craft unlit fire from Sticks, tinder
crafting.register_recipe({
	type = "crafting_spot",
	output = "tech:small_wood_fire_unlit",
	items = {"tech:stick 6", "group:fibrous_plant 1"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "chopping_block",
	output = "tech:large_wood_fire_unlit",
	items = {"tech:stick 12", "group:fibrous_plant 2"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "chopping_block",
	output = "tech:large_wood_fire_unlit 2",
	items = {"group:log", "group:fibrous_plant 4"},
	level = 1,
	always_known = true,
})


--
--Hand crafts (Mixing spot)
--

--ash  / block
crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:wood_ash 2",
	items = {"tech:wood_ash_block"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:wood_ash_block",
	items = {"tech:wood_ash 2"},
	level = 1,
	always_known = true,
})


--charcoal  / block
crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:charcoal 2",
	items = {"tech:charcoal_block"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:charcoal_block",
	items = {"tech:charcoal 2"},
	level = 1,
	always_known = true,
})


--fires  / block
crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:small_wood_fire_unlit 2",
	items = {"tech:large_wood_fire_unlit"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:large_wood_fire_unlit",
	items = {"tech:small_wood_fire_unlit 2"},
	level = 1,
	always_known = true,
})
