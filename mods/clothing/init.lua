------------------------------------------------------------
--CLOTHING init
------------------------------------------------------------

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/api.lua")
--dofile(modpath.."/test_clothing.lua") --bug testing



------------------------------------------------------------
-- Inventory page

local clothing_formspec = "size[8,8.5]"..
"list[current_player;main;0,4.7;8,1;]"..
"list[current_player;main;0,5.85;8,3;8]"

sfinv.register_page("clothing:clothing", {
	title = "Clothing",
	get = function(self, player, context)
		local name = player:get_player_name()

		local meta = player:get_meta()
		local cur_tmin = climate.get_temp_string(meta:get_int("clothing_temp_min"))
		local cur_tmax = climate.get_temp_string(meta:get_int("clothing_temp_max"))
		
		local formspec = clothing_formspec..
		"label[3,0.4; Min Temperature Tolerance: " .. cur_tmin .. " ]"..
		"label[3,1; Max Temperature Tolerance: " .. cur_tmax .. " ]"..
		--"list[detached:"..name.."_clothing;clothing;0,0.5;2,3;]"..
		"list[current_player;cloths;0,0.5;2,3;]" ..
		"listring[current_player;main]"..
		--"listring[detached:"..name.."_clothing;clothing]"
		"listring[current_player;cloths]"
		return sfinv.make_formspec(player, context,
		formspec, false)
	end
})

minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
      if inventory_info.to_list == "cloths" or inventory_info.from_list == "cloths" then
	 clothing:update_temp(player)
	 player_api.set_texture(player)
      end
end)

minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
	local stack, from_inv, to_index
	if action == "move" and inventory_info.to_list == "cloths" then
		if inventory_info.from_list == inventory_info.to_list then --for moving inside the 'cloths' inventory
			return 1
		end
		--for moving items from player inventory list 'main' to 'cloths'
		from_inv = "main"
		to_index = inventory_info.to_index
		stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)
	elseif action == "put" and inventory_info.listname == "cloths" then
		--for moving from node inventory 'closet' to player inventory 'cloths'
		from_inv = "closet"
		to_index = inventory_info.index
		stack = inventory_info.stack
	else
		return
	end
	if stack then
		local stack_name = stack:get_name()
		local item_group = minetest.get_item_group(stack_name , "cloth")
		if item_group == 0 then --not a cloth
			return 0
		end
		--search for another cloth of the same type
		local player_inv = player:get_inventory()
		local cloth_list = player_inv:get_list("cloths")
		for i = 1, #cloth_list do
			local cloth_name = cloth_list[i]:get_name()
			local cloth_type = minetest.get_item_group(cloth_name, "cloth")
			if cloth_type == item_group then
				if player_inv:get_stack("cloths", to_index):get_count() == 0 then --if put on an empty slot
					if from_inv == "main" then
						if player_inv:room_for_item("main", cloth_name) then
							player_inv:remove_item("cloths", cloth_name)
							player_inv:add_item("main", cloth_name)
							print("Added clothing, updating temp")
							update_temp(player)
							return 1
						end
					end
				end
				return 0
			end
		end
		return 1
	end
	return 0
end)

--functions


local function get_element(item_name)
	for _, element in pairs(clothing.elements) do
		if minetest.get_item_group(item_name, "clothing_"..element) > 0 then
			return element
		end
	end
end



local function save_clothing_metadata(player, clothing_inv)
	local player_inv = player:get_inventory()
	local is_empty = true
	local clothes = {}

	for i = 1, 6 do
		local stack = clothing_inv:get_stack("clothing", i)
		-- Move all non-clothes back to the player inventory
		if not stack:is_empty() and not get_element(stack:get_name()) then
			player_inv:add_item("main", clothing_inv:remove_item("clothing", stack))
			stack:clear()
		end
		if not stack:is_empty() then
			clothes[i] = stack:to_string()
			is_empty = false
		end
	end

	local meta = player:get_meta()
	if is_empty then
		meta:set_string("clothing:inventory", "")
	else
		meta:set_string("clothing:inventory", minetest.serialize(clothes))
	end
end

local function load_clothing_metadata(player, clothing_inv)
	local player_inv = player:get_inventory()
	local meta = player:get_meta()
	local clothing_meta = meta:get_string("clothing:inventory")
	local clothes = clothing_meta and minetest.deserialize(clothing_meta) or {}
	local dirty_meta = false
	if not clothing_meta then
		-- Backwards compatiblity
		for i = 1, 6 do
			local stack = player_inv:get_stack("clothing", i)
			if not stack:is_empty() then
				clothes[i] = stack:to_string()
				dirty_meta = true
			end
		end
	end
	-- Fill detached slots
	clothing_inv:set_size("clothing", 6)
	for i = 1, 6 do
		clothing_inv:set_stack("clothing", i, clothes[i] or "")
	end

	if dirty_meta then
		-- Requires detached inventory to be set up
		save_clothing_metadata(player, clothing_inv)
	end

	-- Clean up deprecated garbage after saving
	player_inv:set_size("clothing", 0)
end

local orig_init_on_joinplayer = player_api.init_on_joinplayer
function player_api.init_on_joinplayer(player)
	local name = player:get_player_name()
	local player_inv = player:get_inventory()
	local clothing_inv = minetest.create_detached_inventory(name.."_clothing",{

		on_put = function(inv, listname, index, stack, player)
			save_clothing_metadata(player, inv)
			clothing:run_callbacks("on_equip", player, index, stack)
			clothing:set_player_clothing(player)
		end,

		on_take = function(inv, listname, index, stack, player)
			save_clothing_metadata(player, inv)
			clothing:run_callbacks("on_unequip", player, index, stack)
			clothing:set_player_clothing(player)
		end,

		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			save_clothing_metadata(player, inv)
			clothing:set_player_clothing(player)
		end,

		allow_put = function(inv, listname, index, stack, player)

			local item = stack:get_name()

			--stop not clothes
			local element = get_element(item)
			if not element then
				return 0
			end

			--stop same groups
			for i = 1, 6 do
				local stack = inv:get_stack("clothing", i)
				local def = stack:get_definition() or {}
				if def.groups and def.groups["clothing_"..element] then --and i ~= index then
					return 0
				end
			end

			--stop putting in filled spot
			local orig_stack = inv:get_stack("clothing", index)
			if orig_stack:get_count() > 0 then
				return 0
			end


			return 1
		end,

		allow_take = function(inv, listname, index, stack, player)
			return stack:get_count()
		end,

		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			return count
		end,

	}, name)



	load_clothing_metadata(player, clothing_inv)
	orig_init_on_joinplayer(player)
	clothing:set_player_clothing(player)
end


---------------------------------------------------------
--Player death
local drop_clothes = function(pos, stack)
	local node = minetest.get_node_or_nil(pos)
	if node then
		local obj = minetest.add_item(pos, stack)
		if obj then
			obj:setvelocity({x=math.random(-1, 1), y=5, z=math.random(-1, 1)})
		end
	end
end



minetest.register_on_dieplayer(function(player)

	local drop = {}

	local meta = player:get_meta()
	local clothing_meta = meta:get_string("clothing:inventory")
	local clothes = clothing_meta and minetest.deserialize(clothing_meta) or {}

	local name = player:get_player_name()
	local clothing_inv = minetest.get_inventory({type="detached", name = name.."_clothing"})

	for i=1, 6 do
		local stack = ItemStack(clothes[i])
		--queue to drop, remove effects, remove item
		if stack:get_count() > 0 then
			table.insert(drop, stack)
			clothing:run_callbacks("on_unequip", player, i, stack)
			clothing_inv:set_stack("clothing", i, nil)
		end
	end

	--wipe meta, reset appearance
	meta:set_string("clothing:inventory", "")
	clothing:set_player_clothing(player)




	local pos = player:get_pos()
	local name = player:get_player_name()
	minetest.after(1, function()
		local meta = nil
		local maxp = vector.add(pos, 8)
		local minp = vector.subtract(pos, 8)
		local bones = minetest.find_nodes_in_area(minp, maxp, {"bones:bones"})
		for _, p in pairs(bones) do
			local m = minetest.get_meta(p)
			if m:get_string("owner") == name then
				meta = m
				break
			end
		end
		if meta then
			local inv = meta:get_inventory()
			for _,stack in ipairs(drop) do
				if inv:room_for_item("main", stack) then
					inv:add_item("main", stack)
				else
					drop_clothes(pos, stack)
				end
			end
		else
			for _,stack in ipairs(drop) do
				drop_clothes(pos, stack)
			end
		end
	end)

end)
