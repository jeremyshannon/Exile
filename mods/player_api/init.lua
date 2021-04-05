-- player/init.lua

dofile(minetest.get_modpath("player_api") .. "/api.lua")
dofile(minetest.get_modpath("player_api") .. "/base_texture.lua")
dofile(minetest.get_modpath("player_api") .. "/cloths.lua")

-- Default player appearance
player_api.register_model("character.b3d", {
	animation_speed = 30,
	textures = {"character.png"},
	animations = {
		-- Standard animations.
		stand = {x = 0,   y = 79},
		lay = {x = 162, y = 166},
		walk = {x = 168, y = 187},
		mine = {x = 189, y = 198},
		walk_mine = {x = 200, y = 219},
		sit = {x = 81,  y = 160},
		swin = {x = 232, y = 280},
		swin_mine = {x = 281, y = 305},
		swin_and_mine = {x = 306, y = 330},
		swin_stand = {x = 232, y = 232},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.47,
})

player_api.register_model("female.b3d", {
	animation_speed = 30,
	textures = {
		"female.png",
		"3d_armor_trans.png",
		"3d_armor_trans.png",
	},
	animations = {
		-- Standard animations.
		stand = {x = 0,   y = 79},
		lay = {x = 162, y = 166},
		walk = {x = 168, y = 187},
		mine = {x = 189, y = 198},
		walk_mine = {x = 200, y = 219},
		sit = {x = 81,  y = 160},
		swin = {x = 232, y = 280},
		swin_mine = {x = 281, y = 305},
		swin_and_mine = {x = 306, y = 330},
		swin_stand = {x = 232, y = 232},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.47,
})

-- Update appearance when the player joins
minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	print("Player joined: ",player_name)
	player_api.player_attached[player_name] = false
	local gender = player_api.get_gender(player)
	if gender == "" then
		player_api.set_gender(player, "random") --set random gender
	end
	if not player_api.has_cloths(player) then
	   player_api.set_cloths(player)
	end
	local cloth = player_api.compose_cloth(player)
	player_api.registered_models[player_api.get_gender_model(gender)].textures[1] = cloth
	player_api.set_model(player, player_api.get_gender_model(gender))
end)
