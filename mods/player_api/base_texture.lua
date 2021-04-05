player_api.hair_colors = {
	black = {
		color = "#000000",
		ratio = 175,
	},
	gray = nil,
	brown = {
		color = "#7a4c20",
		ratio = 150,
	},
	red = {
		color = "#ed6800",
		ratio = 140,
	},
	blonde = {
		color = "#a7ad06",
		ratio = 112,
	},
}

player_api.skin_colors = {
	normal = nil,
	brown = {
		color = "#a56d40",
		ratio = 150,
	},
	black = {
		color = "#462409",
		ratio = 127,
	},
}

function player_api.get_base_texture_table(player)
	local meta = player:get_meta()
	local base_texture_str = meta:get_string("base_texture")
	if base_texture_str == nil or base_texture_str == "" then
		player_api.set_base_textures(player)
	end
	local base_texture = minetest.deserialize(base_texture_str)
	return base_texture
end

function player_api.set_base_texture(player, base_texture)
	local meta = player:get_meta()
	meta:set_string("base_texture", minetest.serialize(base_texture))
end

function player_api.set_base_textures(player)
	local meta = player:get_meta()
	local base_texture = {}
	local gender = meta:get_string("gender")
	if gender == "male" then
		base_texture["eyebrowns"] = {texture = "player_eyebrowns_default.png", color = nil}
		base_texture["eye"] = "player_brown_eye.png"
		base_texture["mouth"] = {texture = "player_male_mouth_default.png", color = nil}
		base_texture["hair"] = {texture = "player_male_hair_default.png", color = "brown"}
	else
		base_texture["eyebrowns"] = {texture = "player_eyebrowns_default.png", color = nil}
		base_texture["eye"] = "player_blue_eye.png"
		base_texture["mouth"] = {texture = "player_female_mouth_default.png", color = nil}
		base_texture["hair"] = {texture = "player_female_hair_default.png", color = "brown"}
	end
	base_texture["skin"] = {texture = "player_skin.png", color = "normal"}
	player_api.set_base_texture(player, base_texture)
end

function player_api.colorize_texture(player, what, texture)
	local base_texture = player_api.get_base_texture_table(player)
	if base_texture[what]["color"] then
		local value
		if what == "skin" then
			value = player_api.skin_colors[base_texture[what]["color"]]
		else --"hair"
			value = player_api.hair_colors[base_texture[what]["color"]]
		end
		if value then
			return texture .. "\\^\\[colorize\\:\\"..value.color.."\\:"..tostring(value.ratio)
		else
			return texture
		end
	else
		return texture
	end
end

function player_api.compose_base_texture(player, def)
	local base_texture = player_api.get_base_texture_table(player)
	local texture = player_api.colorize_texture(player, "skin", "[combine:"..def.canvas_size..":0,0="..def.skin_texture)

	local ordered_keys = {}

	for key in pairs(base_texture) do
		table.insert(ordered_keys, key)
	end

	table.sort(ordered_keys)

	for i = 1, #ordered_keys do
		local key, value = ordered_keys[i], base_texture[ordered_keys[i]]
		if key == "eyebrowns" then
			value.texture = player_api.colorize_texture(player, "eyebrowns", value.texture)
			texture = texture .. ":"..def.eyebrowns_pos.."="..value.texture
		elseif key == "eye" then
			texture = texture .. ":"..def.eye_right_pos.."="..value
			texture = texture .. ":"..def.eye_left_pos.."="..value
		elseif key == "mouth" then
			texture = texture .. ":"..def.mouth_pos.."="..value.texture
		elseif key == "hair" then
			if def.hair_preview then
				value.texture = string.sub(value.texture, 0, -5).."_preview.png"
			end
			value.texture = player_api.colorize_texture(player, "hair", value.texture)
			texture = texture .. ":"..def.hair_pos.."="..value.texture
		end
	end
	return texture
end
