local S = minetest.get_translator("player_api")

function player_api.has_cloths(player)
	local inv = player:get_inventory()
	if inv:is_empty("cloths") then
		return false
	else
		return true
	end
end

function player_api.register_cloth(name, def)
	if not(def.inventory_image) then
		def.wield_image = def.texture
	end
	if not(def.wield_image) then
		def.wield_image = def.inventory_image
	end
	local tooltip
	local gender, gender_color
	local description
	if not def.attached then
		if def.groups["cloth"] == 1 then
			tooltip = S("Head")
		elseif def.groups["cloth"] == 2 then
			tooltip = S("Upper")
		elseif def.groups["cloth"] == 3 then
			tooltip = S("Lower")
		else
			tooltip = S("Footwear")
		end
		tooltip = "(" .. tooltip .. ")"
		if def.gender == "male" then
			gender = S("Male")
			gender_color = "#00baff"
		elseif def.gender == "female" then
			gender = S("Female")
			gender_color = "#ff69b4"
		else
			gender = S("Unisex")
			gender_color = "#9400d3"
		end
		tooltip = tooltip.."\n".. minetest.colorize(gender_color, gender)
		description = def.description .. "\n" .. tooltip
	end
	minetest.register_craftitem(name, {
		description = description or nil,
		inventory_image = def.inventory_image or nil,
		wield_image = def.wield_image or nil,
		stack_max = def.stack_max or 16,
		_cloth_attach = def.attach or nil,
		_cloth_attached = def.attached or false,
		_cloth_texture = def.texture or nil,
		_cloth_preview = def.preview or nil,
		_cloth_gender = def.gender or nil,
		groups = def.groups or nil,
	})
end

player_api.register_cloth("player_api:cloth_female_upper_default", {
	description = S("Purple Stripe Summer T-shirt"),
	inventory_image = "cloth_female_upper_default_inv.png",
	wield_image = "cloth_female_upper_default.png",
	texture = "cloth_female_upper_default.png",
	preview = "cloth_female_upper_preview.png",
	gender = "female",
	groups = {cloth = 2},
})

player_api.register_cloth("player_api:cloth_female_lower_default", {
	description = S("Fresh Summer Denim Shorts"),
	inventory_image = "cloth_female_lower_default_inv.png",
	wield_image = "cloth_female_lower_default_inv.png",
	texture = "cloth_female_lower_default.png",
	preview = "cloth_female_lower_preview.png",
	gender = "female",
	groups = {cloth = 3},
})

player_api.register_cloth("player_api:cloth_unisex_footwear_default", {
	description = S("Common Black Shoes"),
	inventory_image = "cloth_unisex_footwear_default_inv.png",
	wield_image = "cloth_unisex_footwear_default_inv.png",
	texture = "cloth_unisex_footwear_default.png",
	preview = "cloth_unisex_footwear_preview.png",
	gender = "unisex",
	groups = {cloth = 4},
})

player_api.register_cloth("player_api:cloth_female_head_default", {
	description = S("Pink Bow"),
	inventory_image = "cloth_female_head_default_inv.png",
	wield_image = "cloth_female_head_default_inv.png",
	texture = "cloth_female_head_default.png",
	preview = "cloth_female_head_preview.png",
	gender = "female",
	groups = {cloth = 1},
})

player_api.register_cloth("player_api:cloth_male_upper_default", {
	description = S("Classic Green Sweater"),
	inventory_image = "cloth_male_upper_default_inv.png",
	wield_image = "cloth_male_upper_default_inv.png",
	texture = "cloth_male_upper_default.png",
	preview = "cloth_male_upper_preview.png",
	gender = "male",
	groups = {cloth = 2},
})

player_api.register_cloth("player_api:cloth_male_lower_default", {
	description = S("Fine Blue Pants"),
	inventory_image = "cloth_male_lower_default_inv.png",
	wield_image = "cloth_male_lower_default_inv.png",
	texture = "cloth_male_lower_default.png",
	preview = "cloth_male_lower_preview.png",
	gender = "male",
	groups = {cloth = 3},
})

function player_api.set_cloths(player)
	local gender = player_api.get_gender(player)
	--Create the "cloths" inventory
	local inv = player:get_inventory()
	inv:set_size("cloths", 8)

	if gender == "female" then
		--inv:add_item("cloths", 'player_api:cloth_lower_underwear_default')
		--TODO: Add a bra for female characters
	end
end

local cloth_pos = {
	"48,0",
	"32,32",
	"0,32",
	"0,32",
}

function player_api.compose_cloth(player)
	local inv = player:get_inventory()
	local inv_list = inv:get_list("cloths") 
	local upper_ItemStack, lower_ItemStack, footwear_ItemStack, head_ItemStack
	local underwear = false
	local attached_cloth = {}
	for i = 1, #inv_list do
		local item_name = inv_list[i]:get_name()
		local cloth_itemstack = minetest.registered_items[item_name]
		--minetest.chat_send_all(item_name)
		local cloth_type = minetest.get_item_group(item_name, "cloth")
		--if cloth_type then minetest.chat_send_all(cloth_type) end
		if cloth_type == 1 then
			head_ItemStack = cloth_itemstack._cloth_texture
		elseif cloth_type == 2 then
			upper_ItemStack = cloth_itemstack._cloth_texture
		elseif cloth_type == 3 then
			lower_ItemStack = cloth_itemstack._cloth_texture
			underwear = true
		elseif cloth_type == 4 then
			footwear_ItemStack = cloth_itemstack._cloth_texture
		end
		if cloth_itemstack and cloth_itemstack._cloth_attach then
			attached_cloth[#attached_cloth+1] = cloth_itemstack._cloth_attach
		end
	end
	if not(underwear) then
		lower_ItemStack = "cloth_lower_underwear_default.png"
	end
	local base_texture = player_api.compose_base_texture(player, {
		canvas_size ="128x64",
		skin_texture = "player_skin.png",
		eyebrowns_pos = "16,16",
		eye_right_pos = "18,24",
		eye_left_pos = "26,24",
		mouth_pos = "16,28",
		hair_preview = false,
		hair_pos = "0,0",
	})
	local cloth = base_texture.."^".."[combine:128x64:0,0="
	if head_ItemStack then
		cloth = cloth .. ":"..cloth_pos[1].."="..head_ItemStack
	end
	if upper_ItemStack then
		cloth = cloth .. ":"..cloth_pos[2].."="..upper_ItemStack
	end
	if lower_ItemStack then
		cloth = cloth .. ":"..cloth_pos[3].."="..lower_ItemStack
	end
	if footwear_ItemStack then
		cloth = cloth .. ":"..cloth_pos[4].."="..footwear_ItemStack
	end
	--Now attached cloth
	if not(next(attached_cloth) == nil) then
		for i = 1, #attached_cloth do
			local attached_item_name = attached_cloth[i]
			local attached_itemstack = minetest.registered_items[attached_item_name]
			local attached_cloth_type = minetest.get_item_group(attached_item_name, "cloth")
			cloth = cloth .. ":"..cloth_pos[attached_cloth_type].."="..attached_itemstack._cloth_texture
		end
	end
	return cloth
end
