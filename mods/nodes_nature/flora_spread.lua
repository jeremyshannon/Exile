-------------------------------------------------------------
--SPREAD PLANTS
--grow "flora" on sediment in light,
--grow mushrooms on sediment in darker
-- cane growth
--spreading surfaces



----------------------------------------------------------------
-- Flora
--


local function flora_spread(pos, node)
	pos.y = pos.y - 1
	local under = minetest.get_node(pos)
	pos.y = pos.y + 1


	if minetest.get_item_group(under.name, "sediment") == 0 then
		return
	end

	--extreme temps will kill, semi-extreme stop growth
	local temp = climate.get_point_temp(pos)
	if temp < -30 or temp > 60 then
		minetest.remove_node(pos)
	elseif temp < 0 or temp > 40 then
		return
	end

	--cannot grow indoors
	local light = minetest.get_node_light({x=pos.x, y=pos.y + 1, z=pos.z}, 0.5)
	if not light or light < 13 then
		return
	end

	local pos0 = vector.subtract(pos, 4)
	local pos1 = vector.add(pos, 4)
	-- Testing shows that a threshold of 3 results in an appropriate maximum
	-- density of approximately 7 flora per 9x9 area.
	if #minetest.find_nodes_in_area(pos0, pos1, "group:flora") > 3 then
		return
	end

	local soils = minetest.find_nodes_in_area_under_air(
		pos0, pos1, "group:sediment")
	local num_soils = #soils
	if num_soils >= 1 then
		for si = 1, math.min(3, num_soils) do
			local soil = soils[math.random(num_soils)]
			local soil_name = minetest.get_node(soil).name
			local soil_above = {x = soil.x, y = soil.y + 1, z = soil.z}
			light = minetest.get_node_light(soil_above)
			if light and light >= 13 and soil_name == under.name then
				local plant = node.name
				local seedling_nodedef = minetest.registered_nodes[plant.."_seed"]
				if not seedling_nodedef then
					--use adult plant
					minetest.set_node(soil_above, {name = plant, param2= node.param2})
				else
					--use seedling
					minetest.set_node(soil_above, {name = plant.."_seed"})
				end
			end
		end
	end
end

---------------

minetest.register_abm({
	label = "Flora spread",
	nodenames = {"group:flora"},
	interval = 260,
	chance = 60,
	action = function(...)
		flora_spread(...)
	end,
})


------------------------------------------------------------
-- Mushrooms
--


-- Mushroom spread
local function mushroom_spread(pos, node)
	--don't do for young
	if minetest.get_item_group(node.name, "seedling") >= 1 then
		return
	end

	pos.y = pos.y - 1
	local under = minetest.get_node(pos)
	pos.y = pos.y + 1


	if minetest.get_item_group(under.name, "sediment") == 0 then
		return
	end

	--extreme temps will kill, semi-extreme stop growth
	local temp = climate.get_point_temp(pos)
	if temp < -30 or temp > 60 then
		minetest.remove_node(pos)
	elseif temp < 0 or temp > 40 then
		return
	end

	local positions = minetest.find_nodes_in_area_under_air(
		{x = pos.x - 1, y = pos.y - 2, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
		{"group:sediment"})

	if #positions == 0 then
		return
	end

	local pos2 = positions[math.random(#positions)]
	pos2.y = pos2.y + 1
	if minetest.get_node_light(pos, 0.5) <= 14 and
	minetest.get_node_light(pos2, 0.5) <= 14 then
		local plant = node.name
		local seedling_nodedef = minetest.registered_nodes[plant.."_seed"]
		if not seedling_nodedef then
			--use adult plant
			local nodedef = minetest.registered_nodes[plant]
			minetest.set_node(pos2, {name = plant, param2= nodedef.place_param2})
		else
			--use seedling
			minetest.set_node(pos2, {name = plant.."_seed"})
		end
	end
end

----------------------
minetest.register_abm({
	label = "Mushroom spread",
	nodenames = {"group:mushroom"},
	interval = 260,
	chance = 60,
	action = function(...)
		mushroom_spread(...)
	end,
})




---------------------------------
local function grow_cane(pos, node)
	pos.y = pos.y - 1
	local under = minetest.get_node(pos)
	pos.y = pos.y + 1

	if minetest.get_item_group(under.name, "wet_sediment") ~= 1 then
		return
	end

	---extreme stop growth
	local temp = climate.get_point_temp(pos)
	if temp < 10 or temp > 40 then
		return
	end

	local plant_name = node.name

	local height = 0
	while node.name == plant_name and height < 5 do
		height = height + 1
		pos.y = pos.y + 1
		node = minetest.get_node(pos)
	end

	if height == 5 or node.name ~= "air" then
		return
	end

	if minetest.get_node_light(pos) < 13 then
		return
	end
	local nodedef = minetest.registered_nodes[plant_name]
	minetest.set_node(pos, {name = plant_name, param2= nodedef.place_param2})
	return true
end


minetest.register_abm({
	label = "Grow cane",
	nodenames = {"group:cane_plant"},
	neighbors = {"group:sediment"},
	interval = 220,
	chance = 3,
	action = function(...)
		grow_cane(...)
	end
})



-------------------------------------------------------------
-- Spreading Surfaces
--

minetest.register_abm({
	label = "Surface spread",
	nodenames = {"group:spreading"},
	neighbors = {"air", "group:sediment"},
	interval = 161,
	chance = 5,
	catch_up = false,
	action = function(pos, node)

		--get drop so we know what it grows on
		local nodedef = minetest.registered_nodes[node.name]
		local drop = nodedef.drop
		if not nodedef or not drop then
			return
		end

		--remove in dark
		local light = minetest.get_node_light({x=pos.x, y=pos.y + 1, z=pos.z}, 0.5)
		if light ~= nil and light < 10 then
			minetest.set_node(pos, {name = drop})
			return
		end

		--spread if suitable nearby
		local positions = minetest.find_nodes_in_area_under_air(
			{x = pos.x - 1, y = pos.y - 2, z = pos.z - 1},
			{x = pos.x + 1, y = pos.y + 2, z = pos.z + 1},
			{drop})

		if #positions == 0 then
			return
		end

		local pos2 = positions[math.random(#positions)]
		local pos2_ab = {x = pos2.x, y = pos2.y + 1, z = pos2.z}
		if minetest.get_node_light(pos, 0.5) >= 13 and
		  minetest.get_node_light(pos2_ab, 0.5) >= 13 then
			minetest.set_node(pos2, {name = node.name})
		end

	end
})
