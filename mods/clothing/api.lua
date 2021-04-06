----------------------------------------------------------
clothing = {
	registered_callbacks = {
		on_update = {},
		on_equip = {},
		on_unequip = {},
	},
	player_textures = {},
	elements = {
		"hat",
		"shirt",
		"pants",
		"cape",
		"shoes",
		"gloves"
	},
}




----------------------------------------------------------
-- CLothing callbacks

clothing.register_on_update = function(self, func)
	if type(func) == "function" then
		table.insert(self.registered_callbacks.on_update, func)
	end
end

clothing.register_on_equip = function(self, func)
	if type(func) == "function" then
		table.insert(self.registered_callbacks.on_equip, func)
	end
end

clothing.register_on_unequip = function(self, func)
	if type(func) == "function" then
		table.insert(self.registered_callbacks.on_unequip, func)
	end
end

clothing.run_callbacks = function(self, callback, player, index, stack)
	if stack then
		local def = stack:get_definition() or {}
		if type(def[callback]) == "function" then
			def[callback](player, index, stack)
		end
	end
	local callbacks = self.registered_callbacks[callback]
	if callbacks then
		for _, func in pairs(callbacks) do
			func(player, index, stack)
		end
	end
end

clothing.set_player_clothing = function(self, player)
-- set clothing and update comfortable temperature range
--[[
clothing temp_min: subtracted from minimum temperature tolerance
clothing temp_max: added to maximum temperature tolerance

e.g. if current comfort range is 21 to 35 then...
temp_min: 6
temp_max: -8
new range = 15 to 28 (e.g. you put on a warm coat)

note: ranges are
-comfort zone: no energy drain
-stress zone: some energy drain
-danger zone: large energy drain
-extreme zone: direct damage

]]

-- default range, no clothes yet
local temp_min = 20
local temp_max = 30

   if not player then
		return
	end
	local name = player:get_player_name()

	local layer = {
		clothing = {},
		cape = {},
	}
	local meta = player:get_meta()
	local clothing_meta = meta:get_string("clothing:inventory")
	local clothes = clothing_meta and minetest.deserialize(clothing_meta) or {}

	local capes = {}
	for i=1, 6 do
		local stack = ItemStack(clothes[i])
		if stack:get_count() == 1 then
			local def = stack:get_definition()
			if def.uv_image then
				if def.groups.clothing == 1 then
					table.insert(layer.clothing, def.uv_image)
				elseif def.groups.clothing_cape == 1 then
					table.insert(layer.cape, def.uv_image)
				end
			end
			-- set comfortable temperature range
			temp_min = temp_min - def.temp_min
			temp_max = temp_max + def.temp_max
		end
	end
	-- apply new temperature comfort range
	meta:set_int("clothing_temp_min", temp_min)
	meta:set_int("clothing_temp_max", temp_max )
	local clothing_out = table.concat(layer.clothing, "^")
	local cape_out = table.concat(layer.cape, "^")
	if clothing_out == "" then
		clothing_out = "blank.png"
	end
	if cape_out == "" then
		cape_out = "blank.png"
	end

	clothing.player_textures[name] = clothing.player_textures[name] or {}
	clothing.player_textures[name].clothing = clothing_out
	clothing.player_textures[name].cape = cape_out
	player_api.update_textures(player)
	self:run_callbacks("on_update", player)
end

player_api.register_skin_modifier(function(textures, player, player_model, player_skin)
	local name = player:get_player_name()
	local clothing_textures = clothing.player_textures[name]
	if not clothing_textures then
		return
	end
	textures.cape = clothing_textures.cape
	textures.clothing = clothing_textures.clothing
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


------------------------------------------------------
--default calls for equipping

clothing.default_equip = function(player, index, stack)

	--sound effect
	--minetest.sound_play("health_eat", {pos = pos, gain = 0.5, max_hear_distance = 2}

	--update page
	sfinv.set_player_inventory_formspec(player)

end



clothing.default_unequip = function(player, index, stack)
	--sound effect
	--minetest.sound_play("health_eat", {pos = pos, gain = 0.5, max_hear_distance = 2}

	--update page
	sfinv.set_player_inventory_formspec(player)

end
