--------------------------------------------------------------------------
--CRAFTS
--------------------------------------------------------------------------
--[[
Carcasses:
Invertebrate,
Fish,
Bird,
(Mammal, Lizard)


Sizes:
small, large



--
leather, Bone, skin, sinews, feathers?
]]




local random = math.random
local floor = math.floor
--------------------------------------------------------------------------
--Carcasses

--Bread baking functions
local function set_cook(pos, length, interval)
	-- and firing count
	local meta = minetest.get_meta(pos)
	meta:set_int("baking", length)
	--check heat interval
	minetest.get_node_timer(pos):start(interval)
end



local function cook(pos, selfname, name_cooked, name_burned, length, heat)
	local meta = minetest.get_meta(pos)
	local baking = meta:get_int("baking")

	--check if wet stop
	if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:water"}) then
		return true
	end

  --exchange accumulated heat
  climate.heat_transfer(pos, selfname)

	--check if above firing temp
	local temp = climate.get_point_temp(pos)
	local fire_temp = heat

	if baking <= 0 then
		--finished firing
		minetest.set_node(pos, {name = name_cooked})
    minetest.check_for_falling(pos)
		return false
  elseif temp < fire_temp then
    --not lit yet
    return true
	elseif temp > fire_temp * 2 then
		--too hot, burn
		minetest.set_node(pos, {name = name_burned})
    --Smoke
    minetest.sound_play("tech_fire_small",{pos=pos, max_hear_distance = 10, loop=false, gain=0.1})
    minetest.add_particlespawner({
      amount = 2,
      time = 0.5,
      minpos = {x = pos.x - 0.1, y = pos.y, z = pos.z - 0.1},
      maxpos = {x = pos.x + 0.1, y = pos.y + 0.5, z = pos.z + 0.1},
      minvel = {x= 0, y= 0, z= 0},
      maxvel = {x= 0.01, y= 0.06, z= 0.01},
      minacc = {x= 0, y= 0, z= 0},
      maxacc = {x= 0.01, y= 0.1, z= 0.01},
      minexptime = 3,
      maxexptime = 10,
      minsize = 1,
      maxsize = 4,
      collisiondetection = true,
      vertical = true,
      texture = "tech_smoke.png",
    })
		return false
	elseif temp >= fire_temp then
		--do firing
		meta:set_int("baking", baking - 1)
		return true
	end

end




-------------------------------------------
local box_small_invert = {
  {-0.125, -0.5, -0.1875, 0.125, -0.4375, 0.1875}, -- NodeBox1
  {-0.0625, -0.4375, -0.1875, 0.0625, -0.375, 0.1875}, -- NodeBox2
  {-0.0625, -0.5, -0.25, 0.0625, -0.4375, -0.1875}, -- NodeBox3
  {-0.0625, -0.5, 0.1875, 0.0625, -0.4375, 0.25}, -- NodeBox4
}

local box_large_invert ={
  {-0.1875, -0.5, -0.25, 0.1875, -0.375, 0.25}, -- NodeBox1
  {-0.125, -0.375, -0.25, 0.125, -0.3125, 0.25}, -- NodeBox2
  {-0.0625, -0.5, -0.375, 0.0625, -0.375, -0.25}, -- NodeBox3
  {-0.0625, -0.5, 0.25, 0.0625, -0.375, 0.375}, -- NodeBox4
}

local box_small_bird = {
  {-0.125, -0.5, -0.1875, 0.125, -0.375, 0.125}, -- NodeBox1
  {-0.0625, -0.375, -0.1875, 0.0625, -0.3125, 0.0625}, -- NodeBox2
  {-0.0625, -0.5, -0.3125, 0.0625, -0.375, -0.1875}, -- NodeBox3
  {-0.0625, -0.5, 0.125, 0.0625, -0.4375, 0.25}, -- NodeBox4
  {0.125, -0.5, -0.125, 0.3125, -0.4375, 0}, -- NodeBox5
  {-0.3125, -0.5, -0.125, -0.125, -0.4375, 0}, -- NodeBox6
  {0.125, -0.5, 0.0625, 0.1875, -0.4375, 0.25}, -- NodeBox7
  {-0.1875, -0.5, 0.0625, -0.125, -0.4375, 0.25}, -- NodeBox8
}

local box_small_fish = {
  {-0.125, -0.5, -0.1875, 0.125, -0.4375, 0.1875}, -- NodeBox1
  {-0.0625, -0.4375, -0.1875, 0.0625, -0.375, 0.1875}, -- NodeBox2
  {-0.0625, -0.5, -0.3125, 0.0625, -0.4375, -0.1875}, -- NodeBox3
  {-0.0625, -0.5, 0.1875, 0.0625, -0.4375, 0.375}, -- NodeBox4
  {0.125, -0.5, -0.125, 0.1875, -0.4375, 0.125}, -- NodeBox9
  {-0.1875, -0.5, -0.125, -0.125, -0.4375, 0.125}, -- NodeBox10
}

local box_large_fish = {
  {-0.25, -0.5, -0.3125, 0.25, -0.375, 0.3125}, -- NodeBox1
  {-0.125, -0.375, -0.3125, 0.125, -0.3125, 0.25}, -- NodeBox2
  {-0.125, -0.5, -0.4375, 0.125, -0.375, -0.3125}, -- NodeBox3
  {-0.125, -0.5, 0.3125, 0.125, -0.375, 0.4375}, -- NodeBox4
  {0.25, -0.5, 0, 0.375, -0.4375, 0.25}, -- NodeBox9
  {-0.375, -0.5, 0, -0.25, -0.4375, 0.25}, -- NodeBox10
  {-0.0625, -0.3125, -0.1875, 0.0625, -0.25, 0}, -- NodeBox11
}



local chance_food_poison = 0.05
local chance_food_parasite = 0.01

local list = {
	{
    "invert_small",
    "Small Invertebrate",
    box_small_invert,
    minimal.stack_max_medium,
    80,
    0, 1, -2,
    1, 100,
    0, 2, 1,
    chance_food_poison*2, chance_food_parasite,
    -1, 1, -3
  },
  {
    "invert_large",
    "Large Invertebrate",
    box_large_invert,
    minimal.stack_max_medium/4,
    70,
    1, 3, -6,
    3, 100,
    1, 6, 3,
    chance_food_poison*4, chance_food_parasite*2,
    -1, 2, -7
  },
  {
    "bird_small",
    "Small Bird",
    box_small_bird,
    minimal.stack_max_medium/4,
    70,
    1, 5, -4,
    6, 100,
    1, 10, 2,
    chance_food_poison, chance_food_parasite*2,
    -1, 3, -5
  },
  {
    "fish_small",
    "Small Fish",
    box_small_fish,
    minimal.stack_max_medium/4,
    70,
    1, 5, -4,
    6, 100,
    1, 10, 2,
    chance_food_poison, chance_food_parasite*2,
    -1, 3, -5
  },
  {
    "fish_large",
    "Large Fish",
    box_large_fish,
    minimal.stack_max_bulky,
    65,
    3, 15, -12,
    18, 100,
    3, 30, 6,
    chance_food_poison*2, chance_food_parasite*4,
    -1, 8, -13
  },

}


for i in ipairs(list) do
	local name = list[i][1]
	local desc = list[i][2]
	local box = list[i][3]
	local stack = list[i][4]
	local heat = list[i][5]
  local eat_raw_thirst = list[i][6]
  local eat_raw_hunger = list[i][7]
  local eat_raw_energy = list[i][8]
  local cook_diff = list[i][9]
  local cook_heat = list[i][10]
  local eat_cooked_thirst = list[i][11]
  local eat_cooked_hunger = list[i][12]
  local eat_cooked_energy = list[i][13]
	local c_fpoison = list[i][14]
	local c_fparasite = list[i][15]
  local eat_burned_thirst = list[i][16]
  local eat_burned_hunger = list[i][17]
  local eat_burned_energy = list[i][18]

  --raw
  minetest.register_node("animals:carcass_"..name, {
  	description = desc..' Carcass',
    tiles = {"animals_carcass.png"},
    drawtype = "nodebox",
  	paramtype = "light",
  	node_box = {
  		type = "fixed",
  		fixed = box
  	},
  	stack_max = stack/2,
  	groups = {snappy = 3, dig_immediate = 3, falling_node = 1, temp_pass = 1, heatable = heat},
  	sounds = nodes_nature.node_sound_defaults(),
  	on_use = function(itemstack, user, pointed_thing)

			--food poisoning
			if random() < c_fpoison then
				HEALTH.add_new_effect(user, {"Food Poisoning", floor(random(1,4))})
			end

			--parasites
			if random() < c_fparasite then
				HEALTH.add_new_effect(user, {"Intestinal Parasites"})
			end


  		--hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
  		return HEALTH.use_item(itemstack, user, 0, eat_raw_thirst, eat_raw_hunger, eat_raw_energy, 0)
  	end,
    on_construct = function(pos)
      --length(i.e. difficulty), interval for checks (speed)
      set_cook(pos, cook_diff, 6)
    end,
    on_timer = function(pos, elapsed)
      --finished product, length, heat
      return cook(pos, "animals:carcass_"..name, "animals:carcass_"..name.."_cooked", "animals:carcass_"..name.."_burned", cook_diff, cook_heat)
    end,
  })


  --cooked
  minetest.register_node("animals:carcass_"..name.. "_cooked", {
    description = 'Cooked '..desc,
    tiles = {"nodes_nature_silt.png"},
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
      type = "fixed",
      fixed = box
    },
    stack_max = stack,
    groups = {snappy = 3, dig_immediate = 3, falling_node = 1, temp_pass = 1},
    sounds = nodes_nature.node_sound_defaults(),
    on_use = function(itemstack, user, pointed_thing)

			--food poisoning
			if random() < c_fpoison*0.1 then
				HEALTH.add_new_effect(user, {"Food Poisoning", floor(random(1,2))})
			end

      --hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
      return HEALTH.use_item(itemstack, user, 0, eat_cooked_thirst, eat_cooked_hunger, eat_cooked_energy, 0)
    end,
  })


 --burned food only gives ~50% of the energy but makes thirthy and more exhausted 
  minetest.register_node("animals:carcass_"..name.. "_burned", {
    description = 'Burned '..desc,
    tiles = {"animals_carcass_burned.png"},
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
      type = "fixed",
      fixed = box
    },
    stack_max = stack,
    groups = {snappy = 3, dig_immediate = 3, falling_node = 1, temp_pass = 1},
    sounds = nodes_nature.node_sound_defaults(),
    on_use = function(itemstack, user, pointed_thing)

      --food poisoning has lower chance, burned food has less salmonella
      if random() < c_fpoison*0.05 then
        HEALTH.add_new_effect(user, {"Food Poisoning", 1})
      end

      --hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
      return HEALTH.use_item(itemstack, user, 0, eat_burned_thirst, eat_burned_hunger, eat_burned_energy, 0)
    end,
  })


end
