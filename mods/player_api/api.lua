-- Minetest 0.4 mod: player
-- See README.txt for licensing and other information.

-- Load support for MT game translation.
local S = minetest.get_translator("player_api")

player_api = {}

-- Player animation blending
-- Note: This is currently broken due to a bug in Irrlicht, leave at 0
local animation_blend = 0

player_api.registered_models = { }

-- Local for speed.
local models = player_api.registered_models

function player_api.register_model(name, def)
	models[name] = def
end

-- stubs for old api functions
function player_api.register_skin_modifier(modifier_func)
end
function player_api.read_textures_and_meta(hook)
end

-- Player stats and animations
local player_model = {}
local player_textures = {}
local player_anim = {}
local player_sneak = {}
player_api.player_attached = {}

function player_api.get_animation(player)
	local name = player:get_player_name()
	return {
		model = player_model[name],
		textures = player_textures[name],
		animation = player_anim[name],
	}
end

function player_api.set_gender(player, gender)
	if not(gender) or gender == "random" then
		if math.random(2) == 1 then
			gender = "male"
		else
			gender = "female"
		end
	end
	local meta = player:get_meta()
	meta:set_string("gender", gender)
	return gender
end

function player_api.get_gender(player)
	local meta = player:get_meta()
	return meta:get_string("gender")
end

function player_api.get_gender_model(gender)
	local model
	if gender == "male" then
		if minetest.get_modpath("3d_armor")~=nil then
			model =  "3d_armor_character.b3d"
		else
			model = "character.b3d"
		end
	else
		if minetest.get_modpath("3d_armor")~=nil then
			model =  "3d_armor_female.b3d"
		else
			model = "female.b3d"
		end
	end
	return model
end

function player_api.set_base_texture(player, gender)
	local meta = player:get_meta()
	meta:set_string("base_texture", gender)
end

minetest.register_chatcommand("toggle_gender", {
	description = S("Change the gender, from male to female or viceversa"),
    func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local meta = player:get_meta()
		local old_gender = player_api.get_gender(player)
		if old_gender then
			local new_gender
			if old_gender == "male" then
				new_gender = "female"
			else
				new_gender = "male"
			end
			meta:set_string("gender", new_gender)
			player_api.set_model(player, player_api.get_gender_model(new_gender))
			local gender_model = player_api.get_gender_model(new_gender)
			local cloth = player_api.compose_cloth(player)
			player_api.registered_models[gender_model].textures[1] = cloth
			player_api.set_textures(player, models[gender_model].textures)
			local new_gender_cap = new_gender:gsub("^%l", string.upper)
			minetest.chat_send_player(name, S("Your gender is changed to").." "..S(new_gender_cap)..".")
		end
    end,
})

--converts yaw to degrees
local function yaw_to_degrees(yaw)
	return(yaw * 180.0 / math.pi)
end

local last_look_at_dir

local function move_head(player, on_water)
	local look_at_dir = player:get_look_dir()
	--apply change only if the pitch changed
	if last_look_at_dir and look_at_dir.y == last_look_at_dir.y then
		return
	else
		last_look_at_dir = look_at_dir
	end
	local pitch = yaw_to_degrees(math.asin(look_at_dir.y))
	if on_water then
		pitch = pitch + 70
	end
	local head_rotation = {x= pitch, y= 0, z= 0} --the head movement {pitch, yaw, roll}
	local head_offset
	if minetest.get_modpath("3d_armor")~=nil then
		head_offset = 6.75
	else
		head_offset = 6.3
	end
	local head_position = {x=0, y=head_offset, z=0}
	player:set_bone_position("Head", head_position, head_rotation) --set the head movement
end

-- Called when a player's appearance needs to be updated
function player_api.set_model(player, model_name)
	local name = player:get_player_name()
	local model = models[model_name]
	if model then
		if player_model[name] == model_name then
			return
		end
		player:set_properties({
			mesh = model_name,
			textures = player_textures[name] or model.textures,
			visual = "mesh",
			visual_size = model.visual_size or {x = 1, y = 1},
			collisionbox = model.collisionbox or {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
			stepheight = model.stepheight or 0.6,
			eye_height = model.eye_height or 1.47,
		})
		player_api.set_animation(player, "stand")
	else
		player:set_properties({
			textures = {"player.png", "player_back.png"},
			visual = "upright_sprite",
			visual_size = {x = 1, y = 2},
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.75, 0.3},
			stepheight = 0.6,
			eye_height = 1.625,
		})
	end
	player_model[name] = model_name
end

function player_api.set_textures(player, textures)
	local name = player:get_player_name()
	local model = models[player_model[name]]
	local model_textures = model and model.textures or nil
	player_textures[name] = textures or model_textures
	player:set_properties({textures = textures or model_textures})
end

function player_api.set_animation(player, anim_name, speed)
	local name = player:get_player_name()
	if player_anim[name] == anim_name then
		return
	end
	local model = player_model[name] and models[player_model[name]]
	if not (model and model.animations[anim_name]) then
		return
	end
	local anim = model.animations[anim_name]
	player_anim[name] = anim_name
	player:set_animation(anim, speed or model.animation_speed, animation_blend)
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	player_model[name] = nil
	player_anim[name] = nil
	player_textures[name] = nil
	player_sneak[name] = nil
	player_api.player_attached[name] = nil
end)

-- Localize for better performance.
local player_set_animation = player_api.set_animation
local player_attached = player_api.player_attached

-- Prevent knockback for attached players
local old_calculate_knockback = minetest.calculate_knockback
function minetest.calculate_knockback(player, ...)
	if player_attached[player:get_player_name()] then
		return 0
	end
	return old_calculate_knockback(player, ...)
end

-- Check each player and apply animations
local timer = 0
minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local model_name = player_model[name]
		local model = model_name and models[model_name]
		if model and not player_attached[name] then
			local controls = player:get_player_control()
			local animation_speed_mod = model.animation_speed or 30

			-- Determine if the player is sneaking, and reduce animation speed if so
			if controls.sneak then
				animation_speed_mod = animation_speed_mod / 2
			end

			local on_water
			--Determine if the player is in a water node
			local player_pos = player:get_pos()
			local node_name = minetest.get_node(player_pos).name
			if minetest.registered_nodes[node_name] then
				if minetest.registered_nodes[node_name]["liquidtype"] == "source" or
					minetest.registered_nodes[node_name]["liquidtype"] == "flowing" then
						local player_pos_below = {x= player_pos.x, y= player_pos.y-1, z= player_pos.z}
						local node_name_below = minetest.get_node(player_pos_below).name
						local player_pos_above = {x= player_pos.x, y= player_pos.y+1, z= player_pos.z}
						local node_name_above = minetest.get_node(player_pos_above).name
						if minetest.registered_nodes[node_name_below] and minetest.registered_nodes[node_name_above] then
							local node_below_is_liquid
							if minetest.registered_nodes[node_name_below]["liquidtype"] == "source" or
								minetest.registered_nodes[node_name_below]["liquidtype"] == "flowing" then
									node_below_is_liquid = true
							else
									node_below_is_liquid = false
							end
							local node_above_is_liquid
							if minetest.registered_nodes[node_name_above]["liquidtype"] == "source" or
								minetest.registered_nodes[node_name_above]["liquidtype"] == "flowing" then
									node_above_is_liquid = true
							else
									node_above_is_liquid = false
							end
							local node_above_is_air
							if minetest.registered_nodes[node_name_above] == "air" then
								node_above_is_air = true
							else
								node_above_is_air = false
							end
							if	((node_below_is_liquid) and not(node_above_is_air)) or
								(not(node_below_is_liquid) and node_above_is_liquid) then
								on_water = true
							else
								on_water = false
							end
						else
							on_water = true
						end
				else
						on_water = false
				end
			end

			--Set head pitch if not on singleplayer and first person view
			--minetest.chat_send_all(tostring(player:get_fov()))
			--if not(minetest.is_singleplayer() and (player:get_fov() == 0)) then
				--minetest.chat_send_all("test")
				move_head(player, on_water)
			--end

			-- Apply animations based on what the player is doing
			if player:get_hp() == 0 then
				player_set_animation(player, "lay")
			-- Determine if the player is walking
			elseif controls.up or controls.down or controls.left or controls.right then
				if player_sneak[name] ~= controls.sneak then
					player_anim[name] = nil
					player_sneak[name] = controls.sneak
				end
				if controls.LMB or controls.RMB then
					if not(on_water) then
						player_set_animation(player, "walk_mine", animation_speed_mod)
					else
						player_set_animation(player, "swin_and_mine", animation_speed_mod)
					end
				else
					if not(on_water) then
						player_set_animation(player, "walk", animation_speed_mod)
					else
						player_set_animation(player, "swin", animation_speed_mod)
					end
				end
			elseif controls.LMB or controls.RMB then
				if not(on_water) then
					player_set_animation(player, "mine", animation_speed_mod)
				else
					player_set_animation(player, "swin_mine", animation_speed_mod)
				end
			else
				if not(on_water) then
					player_set_animation(player, "stand", animation_speed_mod)
				else
					player_set_animation(player, "swin_stand", animation_speed_mod)
				end
			end
			if on_water and player_pos.y < 0 then
				timer = timer + dtime
				if timer > 1 then
					player_pos.y = player_pos.y + 1
					minetest.add_particlespawner({
						amount = 6,
						time = 1,
						minpos = player_pos,
						maxpos = player_pos,
						minvel = {x=0, y=0, z=0},
						maxvel = {x=1, y=5, z=1},
						minacc = {x=0, y=0, z=0},
						maxacc = {x=1, y=1, z=1},
						minexptime = 0.2,
						maxexptime = 1.0,
						minsize = 1,
						maxsize = 1.5,
						collisiondetection = false,
						vertical = false,
						texture = "bubble.png",
					})
					timer = 0
				end
			end
		end
	end
end)

function player_api.get_gender_formspec(name)
	local text = S("Select your gender")

	local formspec = {
		"formspec_version[3]",
		"size[3.2,2.476]",
		"label[0.375,0.5;", minetest.formspec_escape(text), "]",
		"image_button_exit[0.375,1;1,1;player_male_face.png;btn_male;"..S("Male").."]",
		"image_button_exit[1.7,1;1,1;player_female_face.png;btn_female;"..S("Female").."]"
	}

	-- table.concat is faster than string concatenation - `..`
	return table.concat(formspec, "")
end

function player_api.select_gender(player_name)
    minetest.show_formspec(player_name, "player_api:gender", player_api.get_gender_formspec(player_name))
end

function player_api.set_texture(player)
	local cloth = player_api.compose_cloth(player)
	local gender = player_api.get_gender(player)
	local gender_model = player_api.get_gender_model(gender)
	player_api.registered_models[gender_model].textures[1] = cloth
	player_api.set_model(player, gender_model)
	if minetest.get_modpath("3d_armor")~=nil then
		--armor.default_skin = cloth
		local player_name = player:get_player_name()
		armor.textures[player_name].skin = cloth
	end
	player_api.set_textures(player, models[gender_model].textures)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "player_api:gender" then
		return
	end
	local gender
	if fields.btn_male or fields.btn_female then
		if fields.btn_male then
			gender = "male"
		else
			gender = "female"
		end
		player_api.set_gender(player, gender)
	else
		player_api.set_gender(player, "random")
	end
	player_api.set_base_textures(player) --set the default base_texture
	player_api.set_cloths(player) --set the default clothes
	player_api.set_texture(player)
end)
