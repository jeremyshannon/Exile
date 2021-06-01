----------------------------------------------------------
--BRICKS AND MORTAR


--[[
Biggest pros:
-ease of use
-no need for stone (cheap)


Bricks:
clay + sand -> unfired loose brick (using brick mold etc)
Fire @ >600 (more like 1000?. Depends on the clay. We'll do within range of our wood fire)
-> fired loose brick
Plus mortar -> bricks and mortar


Mortar
sand + binder + water (modern just uses cement. Ancient is lime)
Lime mortar:
crush limestone - > crushed lime
-> fire @ > 900C ->quicklime
-> + water = slaked lime
3 sand + one lime slaked lime -> lime mortar

]]
-----------------------------------------------------------
local random = math.random

--LIME MORTAR
----------------------------


--pre-roast  functions
local function set_roast(pos, length, interval)
	-- and firing count
	local meta = minetest.get_meta(pos)
	meta:set_int("roast", length)
	--check heat interval
	minetest.get_node_timer(pos):start(interval)
end



local function roast(pos, selfname, name, length, heat)
	local meta = minetest.get_meta(pos)
	local roast = meta:get_int("roast")

	--check if wet stop
	if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:water"}) then
		return true
	end

	--exchange accumulated heat
	climate.heat_transfer(pos, selfname)

	--check if above firing temp
	local temp = climate.get_point_temp(pos)
	local fire_temp = heat

	if roast <= 0 then
		--finished firing
    minetest.set_node(pos, {name = name})
    minetest.check_for_falling(pos)
    return false
  elseif temp < fire_temp then
    --not lit yet
    return true
	elseif temp >= fire_temp then
    --do firing
    meta:set_int("roast", roast - 1)
    return true
  end

end




--crushed_lime
--broken into gravel
--fire into quicklime
minetest.register_node("tech:crushed_lime", {
	description = "Crushed Lime",
	tiles = {"tech_crushed_lime.png"},
	stack_max = minimal.stack_max_bulky *2,
	groups = {crumbly = 3, falling_node = 1, heatable =10},
	sounds = nodes_nature.node_sound_gravel_defaults(),
  on_construct = function(pos)
		--length(i.e. difficulty of firing), interval for checks (speed)
		set_roast(pos, 3, 10)
	end,
	on_timer = function(pos, elapsed)
    --finished product, length, heat
    --(realisticallty should be 900, but too hard for fires)
    return roast(pos, "tech:crushed_lime", "tech:quicklime", 3, 850)
	end,
})



--quicklime
--turns back into lime when exposed to air
minetest.register_node("tech:quicklime", {
	description = "Quicklime",
	tiles = {"tech_quicklime.png"},
	stack_max = minimal.stack_max_bulky *2,
	groups = {crumbly = 3, falling_node = 1},
	sounds = nodes_nature.node_sound_sand_defaults(),
  on_construct = function(pos)
		minetest.get_node_timer(pos):start(10)
	end,

	on_timer = function(pos, elapsed)

    --slake
    local p_water = minetest.find_node_near(pos, 1, {"group:water"})
    if p_water then
      local p_name = minetest.get_node(p_water).name
      --check water type. Salt would ruin it.
      local water_type = minetest.get_item_group(p_name, "water")
  		if water_type == 1 then
  			minetest.set_node(pos, {name = "tech:slaked_lime"})
        minetest.set_node(p_water, {name = "air"})
        minetest.sound_play("tech_boil",	{pos = pos, max_hear_distance = 8, gain = 1})
  		elseif water_type == 2 then
  			minetest.set_node(pos, {name = "tech:slaked_lime_ruined"})
        minetest.set_node(p_water, {name = "air"})
        minetest.sound_play("tech_boil",	{pos = pos, max_hear_distance = 8, gain = 1})
  		end
      return false
    end

    --slowly revert to lime by reacting with the air, or slake by rain
    if minetest.find_node_near(pos, 1, {"air"}) then
      if random() > 0.99 then
        if climate.get_rain(pos) then
          minetest.set_node(pos, {name = "tech:slaked_lime"})
          minetest.sound_play("tech_boil",	{pos = pos, max_hear_distance = 8, gain = 1})
        else
          minetest.set_node(pos, {name = "tech:crushed_lime"})
          return false
        end
      end
    end

    --it's still here...
    return true
	end,
})


--slaked lime
--turns back into lime when exposed to air
minetest.register_node("tech:slaked_lime", {
	description = "Slaked Lime",
	tiles = {"tech_flour.png"},
	stack_max = minimal.stack_max_bulky *2,
	groups = {crumbly = 3, falling_node = 1},
	sounds = nodes_nature.node_sound_sand_defaults({
		footstep = {name = "nodes_nature_mud", gain = 0.4},
		dug = {name = "nodes_nature_mud", gain = 0.4}}),
  on_construct = function(pos)
		minetest.get_node_timer(pos):start(60)
	end,

	on_timer = function(pos, elapsed)
    if random() > 0.9 then
      --wash it away
      if minetest.find_node_near(pos, 1, {"group:water"}) or climate.get_rain(pos) then
        minetest.set_node(pos, {name = "air"})
        return false
      end

      --slowly revert to lime by reacting with the air
      if minetest.find_node_near(pos, 1, {"air"}) then
        minetest.set_node(pos, {name = "tech:crushed_lime"})
        return false
      end
    end

    --it's still here...
    return true
	end,
})


--ruined slaked lime
--same as above, but got mixed with salt water, I suspect that's bad...
--but can't find what would happen
--turns back into lime when exposed to air
minetest.register_node("tech:slaked_lime_ruined", {
	description = "Slaked Lime (ruined)",
	tiles = {"tech_flour.png"},
	stack_max = minimal.stack_max_bulky *2,
	groups = {crumbly = 3, falling_node = 1},
	sounds = nodes_nature.node_sound_sand_defaults({
		footstep = {name = "nodes_nature_mud", gain = 0.4},
		dug = {name = "nodes_nature_mud", gain = 0.4}}),
  on_construct = function(pos)
		minetest.get_node_timer(pos):start(60)
	end,

	on_timer = function(pos, elapsed)
    --wash it away
    if minetest.find_node_near(pos, 1, {"group:water"}) or climate.get_rain(pos) then
      minetest.set_node(pos, {name = "air"})
      return false
    end

    --slowly revert to lime by reacting with the air
    if minetest.find_node_near(pos, 1, {"air"}) then
      if random() > 0.9 then
        minetest.set_node(pos, {name = "tech:crushed_lime"})
        return false
      end
    end

    --it's still here...
    return true
	end,
})



--Lime mortar
--Hooray... the product we actually want. Slaked lime with sand
--really should set to something, but creates logical mass balance problems
minetest.register_node("tech:lime_mortar", {
	description = "Lime Mortar",
	tiles = {"tech_lime_mortar.png"},
	stack_max = minimal.stack_max_bulky *2,
	groups = {crumbly = 3, falling_node = 1},
	sounds = nodes_nature.node_sound_sand_defaults({
		footstep = {name = "nodes_nature_mud", gain = 0.4},
		dug = {name = "nodes_nature_mud", gain = 0.4}}),
		--[[
  on_construct = function(pos)
		minetest.get_node_timer(pos):start(60)
	end,

	on_timer = function(pos, elapsed)
    --wash it away
    if minetest.find_node_near(pos, 1, {"group:water"}) or climate.get_rain(pos) then
      minetest.set_node(pos, {name = "air"})
      return false
    end

    --slowly revert to limestone by reacting with the air, or slake by rain
    if minetest.find_node_near(pos, 1, {"air"}) then
      if random() > 0.9 then
        minetest.set_node(pos, {name = "nodes_nature:limestone"})
        return false
      end
    end

    --it's still here...
    return true
	end,
	]]
})

-----------------------------------------------------
--MORTAR RECIPES

--crush lime
crafting.register_recipe({
	type = "hammering_block",
	output = "tech:crushed_lime",
	items = {'nodes_nature:limestone_boulder'},
	level = 1,
	always_known = true,
})

--mix mortar
crafting.register_recipe({
	type = "brick_makers_bench",
	output = "tech:lime_mortar 4",
	items = {"tech:slaked_lime", "nodes_nature:sand 3"},
	level = 1,
	always_known = true,
})



-------------------------------------------------------
--BRICKS

--step one bricks, it's same deal as pottery
--
--Pottery firing functions
local function set_firing(pos, length, interval)
	-- and firing count
	local meta = minetest.get_meta(pos)
	meta:set_int("firing", length)
	--check heat interval
	minetest.get_node_timer(pos):start(interval)
end



local function fire_pottery(pos, selfname, name, length)
	local meta = minetest.get_meta(pos)
	local firing = meta:get_int("firing")

	--check if wet, falls to bits and thats it for your pot
	if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:water"}) then
		minetest.set_node(pos, {name = 'nodes_nature:clay'})
		return false
	end

	--exchange accumulated heat
	climate.heat_transfer(pos, selfname)

	--check if above firing temp
	local temp = climate.get_point_temp(pos)
	local fire_temp = 850

	if firing <= 0 then
		--finished firing
		minetest.set_node(pos, {name = name})
		return false
	elseif temp < fire_temp then
		if firing < length and temp < fire_temp/2 then
			--firing began but is now interupted
			--causes firing to fail
			minetest.set_node(pos, {name = "tech:broken_pottery"})
			return false
		else
			--no fire lit yet
			return true
		end
	elseif temp >= fire_temp then
		--do firing
		meta:set_int("firing", firing - 1)
		return true
	end

end



minetest.register_node('tech:loose_brick_unfired', {
	description = 'Loose Bricks (unfired)',
	tiles = {"nodes_nature_clay.png"},
	stack_max = minimal.stack_max_bulky *2,
  drawtype = "nodebox",
	paramtype = "light",
  paramtype2 = "facedir",
  node_box = {
		type = "fixed",
		fixed = {
			{0.0625, -0.5, -0.5, 0.5, -0.25, -0.25}, -- NodeBox11
			{-0.5, -0.5, -0.5, -0.0625, -0.25, -0.25}, -- NodeBox12
			{-0.5, -0.5, -0.125, -0.0625, -0.25, 0.125}, -- NodeBox13
			{-0.5, -0.5, 0.25, -0.0625, -0.25, 0.5}, -- NodeBox14
			{0.0625, -0.5, -0.125, 0.5, -0.25, 0.125}, -- NodeBox15
			{0.0625, -0.5, 0.25, 0.5, -0.25, 0.5}, -- NodeBox16
			{0.1875, -0.25, -0.5, 0.4375, 0, 0}, -- NodeBox22
			{0.25, -0.25, 0, 0.5, 0, 0.5}, -- NodeBox23
			{-0.4375, -0.25, -0.5, -0.1875, 0,0}, -- NodeBox24
			{-0.375, -0.25, 0, -0.125, 0, 0.5}, -- NodeBox25
			{-0.125, -0.25, -0.1875, 0.125, 0, 0.3125}, -- NodeBox26
			{0.0625, 0, -0.4375, 0.5, 0.25, -0.1875}, -- NodeBox27
			{0.0625, 0, -0.125, 0.5, 0.25, 0.125}, -- NodeBox28
			{0, 0, 0.25, 0.4375, 0.25, 0.5}, -- NodeBox29
			{-0.4375, 0, 0.1875, 0, 0.25, 0.4375}, -- NodeBox30
			{-0.5, 0, -0.125, -0.0625, 0.25, 0.125}, -- NodeBox31
			{-0.5, 0, -0.4375, -0.0625, 0.25, -0.1875}, -- NodeBox32
			{-0.375, 0.25, 0, -0.125, 0.5, 0.5}, -- NodeBox33
			{-0.5, 0.25, -0.5, -0.25, 0.5, 0}, -- NodeBox34
			{-0.125, 0.25, -0.5, 0.125, 0.5, 0}, -- NodeBox35
			{0.1875, 0.25, -0.5, 0.4375, 0.5, 0}, -- NodeBox36
			{0.25, 0.25, 0, 0.5, 0.5, 0.5}, -- NodeBox37
			{-0.0625, 0.25, 0, 0.1875, 0.5, 0.5}, -- NodeBox38
		}
	},
	groups = {oddly_breakable_by_hand = 3, falling_node = 1, heatable =15},
	sounds = nodes_nature.node_sound_stone_defaults(),
  on_construct = function(pos)
		--length(i.e. difficulty of firing), interval for checks (speed)
		set_firing(pos, 40, 10)
	end,
	on_timer = function(pos, elapsed)
		return fire_pottery(pos, 'tech:loose_brick_unfired', 'tech:loose_brick', 40)
	end,
})


minetest.register_node('tech:loose_brick', {
	description = 'Loose Bricks',
	tiles = {"tech_roof_tiles.png"},
	stack_max = minimal.stack_max_bulky *3,
  drawtype = "nodebox",
	paramtype = "light",
  paramtype2 = "facedir",
  node_box = {
		type = "fixed",
		fixed = {
			{0.0625, -0.5, -0.5, 0.5, -0.25, -0.25}, -- NodeBox11
			{-0.5, -0.5, -0.5, -0.0625, -0.25, -0.25}, -- NodeBox12
			{-0.5, -0.5, -0.125, -0.0625, -0.25, 0.125}, -- NodeBox13
			{-0.5, -0.5, 0.25, -0.0625, -0.25, 0.5}, -- NodeBox14
			{0.0625, -0.5, -0.125, 0.5, -0.25, 0.125}, -- NodeBox15
			{0.0625, -0.5, 0.25, 0.5, -0.25, 0.5}, -- NodeBox16
			{0.1875, -0.25, -0.5, 0.4375, 0, 0}, -- NodeBox22
			{0.25, -0.25, 0, 0.5, 0, 0.5}, -- NodeBox23
			{-0.4375, -0.25, -0.5, -0.1875, 0,0}, -- NodeBox24
			{-0.375, -0.25, 0, -0.125, 0, 0.5}, -- NodeBox25
			{-0.125, -0.25, -0.1875, 0.125, 0, 0.3125}, -- NodeBox26
			{0.0625, 0, -0.4375, 0.5, 0.25, -0.1875}, -- NodeBox27
			{0.0625, 0, -0.125, 0.5, 0.25, 0.125}, -- NodeBox28
			{0, 0, 0.25, 0.4375, 0.25, 0.5}, -- NodeBox29
			{-0.4375, 0, 0.1875, 0, 0.25, 0.4375}, -- NodeBox30
			{-0.5, 0, -0.125, -0.0625, 0.25, 0.125}, -- NodeBox31
			{-0.5, 0, -0.4375, -0.0625, 0.25, -0.1875}, -- NodeBox32
			{-0.375, 0.25, 0, -0.125, 0.5, 0.5}, -- NodeBox33
			{-0.5, 0.25, -0.5, -0.25, 0.5, 0}, -- NodeBox34
			{-0.125, 0.25, -0.5, 0.125, 0.5, 0}, -- NodeBox35
			{0.1875, 0.25, -0.5, 0.4375, 0.5, 0}, -- NodeBox36
			{0.25, 0.25, 0, 0.5, 0.5, 0.5}, -- NodeBox37
			{-0.0625, 0.25, 0, 0.1875, 0.5, 0.5}, -- NodeBox38
		}
	},
	groups = {oddly_breakable_by_hand = 3, falling_node = 1},
	sounds = nodes_nature.node_sound_stone_defaults(),
})



--------------------------------------
--Mortared Bricks

minetest.register_node("tech:bricks_and_mortar", {
	description = "Brick and Mortar",
	tiles = {"tech_bricks_and_mortar.png"},
	stack_max = minimal.stack_max_medium/2,
	drop = "tech:loose_brick",
	groups = {cracky = 2, masonry = 1},
	sounds = nodes_nature.node_sound_stone_defaults(),
})


stairs.register_stair_and_slab(
	"bricks_and_mortar",
	"tech:bricks_and_mortar",
	"brick_makers_bench",
	"true",
	{cracky = 2},
	{"tech_bricks_and_mortar.png"},
	"Brick and Mortar Stair",
	"Brick and Mortar Slab",
	minimal.stack_max_medium,
	nodes_nature.node_sound_stone_defaults()
)

-----------------------------------------------------
--BRICK RECIPES

--unfired
crafting.register_recipe({
	type = "brick_makers_bench",
	output = "tech:loose_brick_unfired 6",
	items = {'nodes_nature:clay_wet 3', 'nodes_nature:sand_wet'},
	level = 1,
	always_known = true,
})

--mix with mortar
crafting.register_recipe({
	type = "brick_makers_bench",
	output = "tech:bricks_and_mortar 12",
	items = {"tech:lime_mortar", "tech:loose_brick 12"},
	level = 1,
	always_known = true,
})



--------------------------------------
--ROOF TILES

--loose tiles allow for bulk firing, later craft into usable tile
minetest.register_node("tech:roof_tile_loose_unfired", {
	description = "Loose Roof Tile (unfired)",
	tiles = {"nodes_nature_clay.png"},
	stack_max = minimal.stack_max_medium/2,
  drawtype = "nodebox",
	paramtype = "light",
  paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, -0.25, -0.375, -0.0625}, -- NodeBox1
			{-0.5, -0.5, 0.0625, -0.25, -0.375, 0.5}, -- NodeBox2
			{-0.125, -0.5, -0.5, 0.125, -0.375, -0.0625}, -- NodeBox3
			{0.25, -0.5, -0.5, 0.5, -0.375, -0.0625}, -- NodeBox4
			{-0.125, -0.5, 0.0625, 0.125, -0.375, 0.5}, -- NodeBox5
			{0.25, -0.5, 0.0625, 0.5, -0.375, 0.5}, -- NodeBox6
			{-0.5, -0.375, 0.25, -0.0625, -0.25, 0.5}, -- NodeBox7
			{-0.5, -0.375, -0.0625, -0.0625, -0.25, 0.1875}, -- NodeBox8
			{-0.5, -0.375, -0.4375, -0.0625, -0.25, -0.1875}, -- NodeBox9
			{0, -0.375, -0.4375, 0.4375, -0.25, -0.1875}, -- NodeBox10
			{0.0625, -0.375, -0.125, 0.5, -0.25, 0.125}, -- NodeBox11
			{0.0625, -0.375, 0.1875, 0.5, -0.25, 0.4375}, -- NodeBox12
			{-0.4375, -0.25, -0.5, -0.1875, -0.125, -0.0625}, -- NodeBox13
			{-0.125, -0.25, -0.4375, 0.125, -0.125, 0}, -- NodeBox14
			{0.25, -0.25, -0.5, 0.5, -0.125, -0.0625}, -- NodeBox15
			{0.1875, -0.25, 0.0625, 0.4375, -0.125, 0.5}, -- NodeBox16
			{-0.125, -0.25, 0.0625, 0.125, -0.125, 0.5}, -- NodeBox17
			{-0.5, -0.25, 0.0625, -0.25, -0.125, 0.5}, -- NodeBox18
			{0, -0.125, -0.4375, 0.4375, 0, -0.1875}, -- NodeBox19
			{-0.5, -0.125, -0.5, -0.0625, 0, -0.25}, -- NodeBox20
			{-0.5, -0.125, -0.125, -0.0625, 0, 0.125}, -- NodeBox21
			{-0.5, -0.125, 0.25, -0.0625, 0, 0.5}, -- NodeBox22
			{0.0625, -0.125, 0.25, 0.5, 0, 0.5}, -- NodeBox23
			{0.0625, -0.125, -0.125, 0.5, 0, 0.125}, -- NodeBox24
			{-0.4375, 0, 0.0625, -0.1875, 0.125, 0.5}, -- NodeBox28
			{-0.0625, 0, 0.0625, 0.1875, 0.125, 0.5}, -- NodeBox29
			{0.25, 0, 0.0625, 0.5, 0.125, 0.5}, -- NodeBox30
			{0.1875, 0, -0.5, 0.4375, 0.125, -0.0625}, -- NodeBox31
			{-0.125, 0, -0.4375, 0.125, 0.125, 0}, -- NodeBox32
			{-0.5, 0, -0.4375, -0.25, 0.125, 0}, -- NodeBox33
			{0.0625, 0.125, -0.125, 0.5, 0.25, 0.125}, -- NodeBox34
			{0.0625, 0.125, 0.1875, 0.5, 0.25, 0.4375}, -- NodeBox35
			{0.0625, 0.125, -0.5, 0.5, 0.25, -0.25}, -- NodeBox36
			{-0.5, 0.125, -0.5, -0.0625, 0.25, -0.25}, -- NodeBox37
			{-0.5, 0.125, -0.125, -0.0625, 0.25, 0.125}, -- NodeBox38
			{-0.4375, 0.125, 0.25, 0, 0.25, 0.5}, -- NodeBox39
			{-0.4375, 0.25, -0.5, -0.1875, 0.375, -0.0625}, -- NodeBox40
			{-0.0625, 0.25, -0.4375, 0.1875, 0.375, 0}, -- NodeBox41
			{0.25, 0.25, -0.4375, 0.5, 0.375, 0}, -- NodeBox42
			{0.1875, 0.25, 0.0625, 0.4375, 0.375, 0.5}, -- NodeBox43
			{-0.125, 0.25, 0.0625, 0.125, 0.375, 0.5}, -- NodeBox44
			{-0.5, 0.25, 0, -0.25, 0.375, 0.4375}, -- NodeBox45
			{-0.4375, 0.375, -0.4375, 0, 0.5, -0.1875}, -- NodeBox46
			{0.0625, 0.375, -0.4375, 0.5, 0.5, -0.1875}, -- NodeBox47
			{0.0625, 0.375, -0.125, 0.5, 0.5, 0.125}, -- NodeBox48
			{0.0625, 0.375, 0.1875, 0.5, 0.5, 0.4375}, -- NodeBox49
			{-0.4375, 0.375, 0.1875, 0, 0.5, 0.4375}, -- NodeBox50
			{-0.4375, 0.375, -0.125, 0, 0.5, 0.125}, -- NodeBox51
		}
	},
  groups = {oddly_breakable_by_hand = 3, falling_node = 1, heatable =15},
	sounds = nodes_nature.node_sound_stone_defaults(),
  on_construct = function(pos)
		--length(i.e. difficulty of firing), interval for checks (speed)
		set_firing(pos, 40, 10)
	end,
	on_timer = function(pos, elapsed)
		return fire_pottery(pos, 'tech:roof_tile_loose_unfired', 'tech:roof_tile_loose', 40)
	end,
})

minetest.register_node("tech:roof_tile_loose", {
	description = "Loose Roof Tile",
	tiles = {"tech_roof_tiles.png"},
	stack_max = minimal.stack_max_medium/2,
  drawtype = "nodebox",
	paramtype = "light",
  paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, -0.25, -0.375, -0.0625}, -- NodeBox1
			{-0.5, -0.5, 0.0625, -0.25, -0.375, 0.5}, -- NodeBox2
			{-0.125, -0.5, -0.5, 0.125, -0.375, -0.0625}, -- NodeBox3
			{0.25, -0.5, -0.5, 0.5, -0.375, -0.0625}, -- NodeBox4
			{-0.125, -0.5, 0.0625, 0.125, -0.375, 0.5}, -- NodeBox5
			{0.25, -0.5, 0.0625, 0.5, -0.375, 0.5}, -- NodeBox6
			{-0.5, -0.375, 0.25, -0.0625, -0.25, 0.5}, -- NodeBox7
			{-0.5, -0.375, -0.0625, -0.0625, -0.25, 0.1875}, -- NodeBox8
			{-0.5, -0.375, -0.4375, -0.0625, -0.25, -0.1875}, -- NodeBox9
			{0, -0.375, -0.4375, 0.4375, -0.25, -0.1875}, -- NodeBox10
			{0.0625, -0.375, -0.125, 0.5, -0.25, 0.125}, -- NodeBox11
			{0.0625, -0.375, 0.1875, 0.5, -0.25, 0.4375}, -- NodeBox12
			{-0.4375, -0.25, -0.5, -0.1875, -0.125, -0.0625}, -- NodeBox13
			{-0.125, -0.25, -0.4375, 0.125, -0.125, 0}, -- NodeBox14
			{0.25, -0.25, -0.5, 0.5, -0.125, -0.0625}, -- NodeBox15
			{0.1875, -0.25, 0.0625, 0.4375, -0.125, 0.5}, -- NodeBox16
			{-0.125, -0.25, 0.0625, 0.125, -0.125, 0.5}, -- NodeBox17
			{-0.5, -0.25, 0.0625, -0.25, -0.125, 0.5}, -- NodeBox18
			{0, -0.125, -0.4375, 0.4375, 0, -0.1875}, -- NodeBox19
			{-0.5, -0.125, -0.5, -0.0625, 0, -0.25}, -- NodeBox20
			{-0.5, -0.125, -0.125, -0.0625, 0, 0.125}, -- NodeBox21
			{-0.5, -0.125, 0.25, -0.0625, 0, 0.5}, -- NodeBox22
			{0.0625, -0.125, 0.25, 0.5, 0, 0.5}, -- NodeBox23
			{0.0625, -0.125, -0.125, 0.5, 0, 0.125}, -- NodeBox24
			{-0.4375, 0, 0.0625, -0.1875, 0.125, 0.5}, -- NodeBox28
			{-0.0625, 0, 0.0625, 0.1875, 0.125, 0.5}, -- NodeBox29
			{0.25, 0, 0.0625, 0.5, 0.125, 0.5}, -- NodeBox30
			{0.1875, 0, -0.5, 0.4375, 0.125, -0.0625}, -- NodeBox31
			{-0.125, 0, -0.4375, 0.125, 0.125, 0}, -- NodeBox32
			{-0.5, 0, -0.4375, -0.25, 0.125, 0}, -- NodeBox33
			{0.0625, 0.125, -0.125, 0.5, 0.25, 0.125}, -- NodeBox34
			{0.0625, 0.125, 0.1875, 0.5, 0.25, 0.4375}, -- NodeBox35
			{0.0625, 0.125, -0.5, 0.5, 0.25, -0.25}, -- NodeBox36
			{-0.5, 0.125, -0.5, -0.0625, 0.25, -0.25}, -- NodeBox37
			{-0.5, 0.125, -0.125, -0.0625, 0.25, 0.125}, -- NodeBox38
			{-0.4375, 0.125, 0.25, 0, 0.25, 0.5}, -- NodeBox39
			{-0.4375, 0.25, -0.5, -0.1875, 0.375, -0.0625}, -- NodeBox40
			{-0.0625, 0.25, -0.4375, 0.1875, 0.375, 0}, -- NodeBox41
			{0.25, 0.25, -0.4375, 0.5, 0.375, 0}, -- NodeBox42
			{0.1875, 0.25, 0.0625, 0.4375, 0.375, 0.5}, -- NodeBox43
			{-0.125, 0.25, 0.0625, 0.125, 0.375, 0.5}, -- NodeBox44
			{-0.5, 0.25, 0, -0.25, 0.375, 0.4375}, -- NodeBox45
			{-0.4375, 0.375, -0.4375, 0, 0.5, -0.1875}, -- NodeBox46
			{0.0625, 0.375, -0.4375, 0.5, 0.5, -0.1875}, -- NodeBox47
			{0.0625, 0.375, -0.125, 0.5, 0.5, 0.125}, -- NodeBox48
			{0.0625, 0.375, 0.1875, 0.5, 0.5, 0.4375}, -- NodeBox49
			{-0.4375, 0.375, 0.1875, 0, 0.5, 0.4375}, -- NodeBox50
			{-0.4375, 0.375, -0.125, 0, 0.5, 0.125}, -- NodeBox51
		}
	},
  groups = {oddly_breakable_by_hand = 3, falling_node = 1},
	sounds = nodes_nature.node_sound_stone_defaults(),
})


minetest.register_node("tech:roof_tile", {
	description = "Roof Tile",
	tiles = {"tech_roof_tiles.png"},
	stack_max = minimal.stack_max_medium,
  drawtype = "nodebox",
	paramtype = "light",
  paramtype2 = "facedir",
  node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.25, 0.125, -0.25, 0.5, 0.5}, -- s1
			{-0.5, 0, -0.0625, -0.25, 0.25, 0.3125}, -- s2
			{-0.5, -0.25, -0.25, -0.25, 0, 0.125}, -- s3
			{-0.5, -0.5, -0.5, -0.25, -0.25, -0.125}, -- s4
			{0.25, 0.25, 0.125, 0.5, 0.5, 0.5}, -- s5
			{0.25, -0.5, -0.5, 0.5, -0.25, -0.125}, -- s6
			{0.25, 0, -0.0625, 0.5, 0.25, 0.3125}, -- s7
			{0.25, -0.25, -0.25, 0.5, 0, 0.125}, -- s8
			{-0.25, 0.25, 0.125, 0.25, 0.4375, 0.5}, -- NodeBox23
			{-0.25, 0, -0.0625, 0.25, 0.1875, 0.3125}, -- NodeBox24
			{-0.25, -0.25, -0.25, 0.25, -0.0625, 0.125}, -- NodeBox25
			{-0.25, -0.5, -0.5, 0.25, -0.3125, -0.125}, -- NodeBox26
			{-0.25, -0.3125, -0.3125, 0.25, -0.25, -0.125}, -- NodeBox30
			{-0.25, -0.0625, -0.125, 0.25, 0, 0.125}, -- NodeBox32
			{-0.25, 0.1875, 0.0625, 0.25, 0.25, 0.3125}, -- NodeBox33
			{-0.25, 0.4375, 0.3125, 0.25, 0.5, 0.5}, -- NodeBox34
		}
	},
	groups = {cracky = 3, oddly_breakable_by_hand = 1},
	sounds = nodes_nature.node_sound_stone_defaults(),
})


minetest.register_node("tech:roof_tile_oc", {
	description = "Roof Tile (outer corner)",
	tiles = {"tech_roof_tiles.png"},
	stack_max = minimal.stack_max_medium,
  drawtype = "nodebox",
	paramtype = "light",
  paramtype2 = "facedir",
  node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.1875, 0.25, -0.25, 0.5, 0.5}, -- s1
			{-0.25, -0.0625, 0, 0, 0.25, 0.25}, -- NodeBox40
			{0, -0.3125, -0.25, 0.25, 0, 0}, -- NodeBox41
			{0.25, -0.5, -0.5, 0.5, -0.25, -0.25}, -- NodeBox42
			{-0.5, -0.5, -0.5, 0.25, -0.3125, -0.25}, -- NodeBox43
			{-0.5, -0.25, -0.25, 0, -0.0625, 0}, -- NodeBox44
			{-0.5, 0, 0, -0.25, 0.1875, 0.25}, -- NodeBox45
			{-0.25, 0, 0.25, 0, 0.1875, 0.5}, -- NodeBox47
			{0, -0.25, 0, 0.25, -0.0625, 0.5}, -- NodeBox48
			{0.25, -0.5, -0.25, 0.5, -0.3125, 0.5}, -- NodeBox49
			{-0.5, 0.1875, 0.125, -0.25, 0.3125, 0.25}, -- NodeBox54
			{-0.25, 0.1875, 0.25, -0.125, 0.3125, 0.5}, -- NodeBox55
			{-0.5, -0.0625, -0.125, 0, 0.0625, 0}, -- NodeBox56
			{0, -0.0625, 0, 0.125, 0.0625, 0.5}, -- NodeBox57
			{0.25, -0.3125, -0.25, 0.375, -0.1875, 0.5}, -- NodeBox58
			{-0.5, -0.3125, -0.375, 0.25, -0.1875, -0.25}, -- NodeBox59
		}
	},
	groups = {cracky = 3, oddly_breakable_by_hand = 1},
	sounds = nodes_nature.node_sound_stone_defaults(),
})



minetest.register_node("tech:roof_tile_ic", {
	description = "Roof Tile (inner corner)",
	tiles = {"tech_roof_tiles.png"},
	stack_max = minimal.stack_max_medium,
  drawtype = "nodebox",
	paramtype = "light",
  paramtype2 = "facedir",
  node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.1875, 0.25, -0.25, 0.5, 0.5}, -- s1
			{-0.25, -0.0625, 0, 0, 0.25, 0.25}, -- NodeBox40
			{0, -0.3125, -0.25, 0.25, 0, 0}, -- NodeBox41
			{0.25, -0.5, -0.5, 0.5, -0.25, -0.25}, -- NodeBox42
			{-0.125, -0.3125, -0.5, 0.25, -0.125, -0.25}, -- NodeBox60
			{-0.375, -0.0625, -0.5, 0, 0.125, 0}, -- NodeBox61
			{-0.5, 0.1875, -0.5, -0.25, 0.375, 0.25}, -- NodeBox62
			{-0.25, 0.1875, 0.25, 0.5, 0.375, 0.5}, -- NodeBox63
			{0, -0.0625, 0, 0.5, 0.125, 0.375}, -- NodeBox64
			{0.25, -0.3125, -0.25, 0.5, -0.125, 0.125}, -- NodeBox65
			{-0.125, -0.125, -0.5, 0.0625, -0.0625, -0.25}, -- NodeBox66
			{-0.375, 0.125, -0.5, -0.1875, 0.1875, 0}, -- NodeBox67
			{-0.5, 0.375, -0.5, -0.375, 0.5, 0.25}, -- NodeBox68
			{-0.25, 0.375, 0.375, 0.5, 0.5, 0.5}, -- NodeBox69
			{0, 0.125, 0.1875, 0.5, 0.1875, 0.375}, -- NodeBox70
			{0.25, -0.125, -0.0625, 0.5, -0.0625, 0.125}, -- NodeBox71
		}
	},
	groups = {cracky = 3, oddly_breakable_by_hand = 1},
	sounds = nodes_nature.node_sound_stone_defaults(),
})


-----------------------------------------------------
--ROOF TLE RECIPES

--unfired
crafting.register_recipe({
	type = "brick_makers_bench",
	output = "tech:roof_tile_loose_unfired",
	items = {'nodes_nature:clay_wet 6'},
	level = 1,
	always_known = true,
})

--usable tile
crafting.register_recipe({
	type = "brick_makers_bench",
	output = "tech:roof_tile 6",
	items = {'tech:roof_tile_loose'},
	level = 1,
	always_known = true,
})


--switch inner/outer
crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:roof_tile_ic",
	items = {"tech:roof_tile"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:roof_tile_oc",
	items = {"tech:roof_tile"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:roof_tile",
	items = {"tech:roof_tile_ic"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "mixing_spot",
	output = "tech:roof_tile",
	items = {"tech:roof_tile_oc"},
	level = 1,
	always_known = true,
})


--------------------------------------------------------------------
--MASONARY WITH MORTAR
--made at masonary bench,
--(except mortared blocks can also be done by brick maker)
--added mortar binds them so not diggable by hand or falling.
--drop unmortared stone.

local list = {
	{"limestone", "Limestone", 3},
	{"ironstone", "Ironstone", 3},
  {"granite", "Granite", 1},
	{"basalt", "Basalt", 2},
	{"gneiss", "Gneiss", 1},
	{"jade", "Jade", 1},

}


for i in ipairs(list) do
	local name = list[i][1]
	local desc = list[i][2]
	local hardness = list[i][3]


	--blocks and bricks
	--Bricks
	minetest.register_node("tech:"..name.."_brick_mortar", {
		description = desc.." Brick with Mortar",
		tiles = {"nodes_nature_"..name.."_brick.png^tech_mortar_brick.png"},
		drop = "nodes_nature:"..name.."_brick",
		stack_max = minimal.stack_max_bulky *3,
		groups = {cracky = hardness, masonry = 1},
		sounds = nodes_nature.node_sound_stone_defaults(),
	})

	--block
	minetest.register_node("tech:"..name.."_block_mortar", {
		description = desc.. " Block with Mortar",
		tiles = {"nodes_nature_"..name.."_block.png^tech_mortar_block.png"},
		drop = "nodes_nature:"..name.."_block",
		stack_max = minimal.stack_max_bulky *2,
		groups = {cracky = hardness, masonry = 1},
		sounds = nodes_nature.node_sound_stone_defaults(),
	})

	---
	crafting.register_recipe({
		type = "masonry_bench",
		output = "tech:"..name.."_brick_mortar 4",
		items = {"nodes_nature:"..name.."_brick 3", "tech:lime_mortar"},
		level = 1,
		always_known = true,
	})

	crafting.register_recipe({
		type = "masonry_bench",
		output = "tech:"..name.."_block_mortar 4",
		items = {"nodes_nature:"..name.."_block 3", "tech:lime_mortar"},
		level = 1,
		always_known = true,
	})

	crafting.register_recipe({
		type = "brick_makers_bench",
		output = "tech:"..name.."_block_mortar 4",
		items = {"nodes_nature:"..name.."_block 3", "tech:lime_mortar"},
		level = 1,
		always_known = true,
	})


	--stairs and slabs

	--brick
	stairs.register_stair_and_slab(
		name.."_brick_mortar",
		"tech:"..name.."_brick_mortar",
		"masonry_bench",
		"true",
		{cracky = hardness},
		{"nodes_nature_"..name.."_brick.png^tech_mortar_brick.png" },
		desc.." Brick with Mortar Stair",
		desc.." Brick with Mortar Slab",
		minimal.stack_max_bulky * 6,
		nodes_nature.node_sound_stone_defaults()
	)

	--block
	stairs.register_stair_and_slab(
		name.."_block_mortar",
		"tech:"..name.."_block_mortar",
		"masonry_bench",
		"false",
		{cracky = hardness},
		{"nodes_nature_"..name.."_block.png^tech_mortar_block.png" },
		desc.." Block with Mortar Stair",
		desc.." Block with Mortar Slab",
		minimal.stack_max_bulky * 4,
		nodes_nature.node_sound_stone_defaults()
	)


end
