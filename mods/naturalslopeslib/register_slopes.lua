
-- Table of replacement from solid block to slopes.
-- Populated on slope node registration with add_replacement
local replacements = {}
local replacement_ids = {}
local function add_replacement(source_name, update_chance, chance_factors, fixed_replacements)
	local subname = string.sub(source_name, string.find(source_name, ':') + 1)
	local straight_name = nil
	local ic_name = nil
	local oc_name = nil
	local pike_name = nil
	if fixed_replacements then
		straight_name = fixed_replacements[1]
		ic_name = fixed_replacements[2]
		oc_name = fixed_replacements[3]
		pike_name = fixed_replacements[4]
	else
		straight_name = naturalslopeslib.get_straight_slope_name(subname)
		ic_name = naturalslopeslib.get_inner_corner_slope_name(subname)
		oc_name = naturalslopeslib.get_outer_corner_slope_name(subname)
		pike_name = naturalslopeslib.get_pike_slope_name(subname)
	end
	local source_id = minetest.get_content_id(source_name)
	local straight_id = minetest.get_content_id(straight_name)
	local ic_id = minetest.get_content_id(ic_name)
	local oc_id = minetest.get_content_id(oc_name)
	local pike_id = minetest.get_content_id(pike_name)
	-- Full to slopes
	local dest_data = {
		source = source_name,
		straight = straight_name,
		inner = ic_name,
		outer = oc_name,
		pike = pike_name,
		chance = update_chance,
		chance_factors = chance_factors
	}
	local dest_data_id = {
		source = source_id,
		straight = straight_id,
		inner = ic_id,
		outer = oc_id,
		pike = pike_id,
		chance = update_chance,
		chance_factors = chance_factors
	}
	-- Block
	replacements[source_name] = dest_data
	replacement_ids[source_id] = dest_data_id
	-- Straight
	replacements[straight_name] = dest_data
	replacement_ids[straight_id] = dest_data_id
	-- Inner
	replacements[ic_name] = dest_data
	replacement_ids[ic_id] = dest_data_id
	-- Outer
	replacements[oc_name] = dest_data
	replacement_ids[oc_id] = dest_data_id
	-- Pike
	replacements[pike_name] = dest_data
	replacement_ids[pike_id] = dest_data_id
end

--- Get replacement description of a node.
-- Contains replacement names in either source or (straight, inner, outer)
-- and chance.
function naturalslopeslib.get_replacement(source_node_name)
	return replacements[source_node_name]
end
--- Get replacement description of a node by content id for VoxelManip.
-- Contains replacement ids in either source or (straight, inner, outer)
-- and chance.
function naturalslopeslib.get_replacement_id(source_id)
	return replacement_ids[source_id]
end

function naturalslopeslib.get_all_shapes(source_node_name)
	if replacements[source_node_name] then
		local rp = replacements[source_node_name]
		return {rp.source, rp.straight, rp.inner, rp.outer, rp.pike}
	else
		return {source_node_name}
	end
end

--[[ Bounding boxes
--]]

local slope_straight_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0.5, 0.5, 0.5},
	},
}
local slope_inner_corner_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0.5, 0.5, 0.5},
		{-0.5, 0, -0.5, 0, 0.5, 0},
	},
}
local slope_outer_corner_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0, 0.5, 0.5},
	},
}
local slope_pike_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
}

--- {Private} Update the node definition for a straight slope
local function get_straight_def(base_node_name, node_def)
	if naturalslopeslib.setting_smooth_rendering() then
		node_def.drawtype = 'mesh'
		node_def.mesh = 'naturalslopeslib_straight.obj'
	else
		node_def.drawtype = 'nodebox'
		node_def.node_box = slope_straight_box
	end
	node_def.selection_box = slope_straight_box
	node_def.collision_box = slope_straight_box
	node_def.paramtype = 'light'
	node_def.paramtype2 = 'facedir'
	if not node_def.groups then node_def.groups = {} end
	node_def.groups.natural_slope = 1
	if not node_def.groups["family:" .. base_node_name] then
		node_def.groups["family:" .. base_node_name] = 1
	end
	return node_def
end

--- {Private} Update the node definition for an inner corner
local function get_inner_def(base_node_name, node_def)
	if naturalslopeslib.setting_smooth_rendering() then
		node_def.drawtype = 'mesh'
		node_def.mesh = 'naturalslopeslib_inner.obj'
	else
		node_def.drawtype = 'nodebox'
		node_def.node_box = slope_inner_corner_box
	end
	node_def.selection_box = slope_inner_corner_box
	node_def.collision_box = slope_inner_corner_box
	node_def.paramtype = 'light'
	node_def.paramtype2 = 'facedir'
	if not node_def.groups then node_def.groups = {} end
	node_def.groups.natural_slope = 2
	if not node_def.groups["family:" .. base_node_name] then
		node_def.groups["family:" .. base_node_name] = 1
	end
	return node_def
end

--- {Private} Update the node definition for an outer corner
local function get_outer_def(base_node_name, node_def)
	if naturalslopeslib.setting_smooth_rendering() then
		node_def.drawtype = 'mesh'
		node_def.mesh = 'naturalslopeslib_outer.obj'
	else
		node_def.drawtype = 'nodebox'
		node_def.node_box = slope_outer_corner_box
	end
	node_def.selection_box = slope_outer_corner_box
	node_def.collision_box = slope_outer_corner_box
	node_def.paramtype = 'light'
	node_def.paramtype2 = 'facedir'
	if not node_def.groups then node_def.groups = {} end
	node_def.groups.natural_slope = 3
	if not node_def.groups["family:" .. base_node_name] then
		node_def.groups["family:" .. base_node_name] = 1
	end
	return node_def
end

--- {Private} Update the node definition for a pike
local function get_pike_def(base_node_name, node_def, update_chance)
	if naturalslopeslib.setting_smooth_rendering() then
		node_def.drawtype = 'mesh'
		node_def.mesh = 'naturalslopeslib_pike.obj'
	else
		node_def.drawtype = 'nodebox'
		node_def.node_box = slope_pike_box
	end
	node_def.selection_box = slope_pike_box
	node_def.collision_box = slope_pike_box
	node_def.paramtype = 'light'
	node_def.paramtype2= 'facedir'
	if not node_def.groups then node_def.groups = {} end
	node_def.groups.natural_slope = 4
	if not node_def.groups["family:" .. base_node_name] then
		node_def.groups["family:" .. base_node_name] = 1
	end
	return node_def
end

function naturalslopeslib.get_slope_defs(base_node_name, def_changes)
	local base_node_def = minetest.registered_nodes[base_node_name]
	if not base_node_def then
		minetest.log("error", "Trying to get slopes for an unknown node " .. (base_node_name or "nil"))
		return
	end
	local full_copy = table.copy(base_node_def)
	for key, value in pairs(def_changes) do
		if value == "nil" then
			full_copy[key] = nil
		else
			full_copy[key] = value
		end
	end
	-- Use a copy because tables are passed by reference. Otherwise the node
	-- description is shared and updated after each call
	return {
		get_straight_def(base_node_name, table.copy(full_copy)),
		get_inner_def(base_node_name, table.copy(full_copy)),
		get_outer_def(base_node_name, table.copy(full_copy)),
		get_pike_def(base_node_name, table.copy(full_copy))
	}
end

local function default_factors(factors)
	f = {}
	if factors == nil then factors = {} end
	for _, name in ipairs({"mapgen", "time", "stomp", "place"}) do
		if factors[name] ~= nil then
			f[name] = factors[name]
		else
			f[name] = 1
		end
	end
	return f
end

--- Register slopes from a full block node.
-- @param base_node_name: The full block node name.
-- @param node_desc: base for slope node descriptions.
-- @param update_chance: inverted chance for the node to be updated.
-- @param factors (optional): chance factor for each type.
-- @return Table of slope names: [straight, inner, outer, pike] or nil on error.
function naturalslopeslib.register_slope(base_node_name, def_changes, update_chance, factors)
	if not update_chance then
		minetest.log('error', 'Natural slopes: chance is not set for node ' .. base_node_name)
		return
	end
	local base_node_def = minetest.registered_nodes[base_node_name]
	if not base_node_def then
		minetest.log("error", "Trying to register slopes for an unknown node " .. (base_node_name or "nil"))
		return
	end
	local full_copy = table.copy(base_node_def)
	for key, value in pairs(def_changes) do
		if value == "nil" then
			full_copy[key] = nil
		else
			full_copy[key] = value
		end
	end
	local chance_factors = default_factors(factors)
	-- Get new definitions
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	local slope_names = {
		naturalslopeslib.get_straight_slope_name(subname),
		naturalslopeslib.get_inner_corner_slope_name(subname),
		naturalslopeslib.get_outer_corner_slope_name(subname),
		naturalslopeslib.get_pike_slope_name(subname)
	}
	local slope_defs = naturalslopeslib.get_slope_defs(base_node_name, full_copy)
	-- Register all slopes
	for i, name in ipairs(slope_names) do
		minetest.register_node(name, slope_defs[i])
		-- Register walk listener
		if naturalslopeslib.setting_enable_shape_on_walk() then
			poschangelib.register_stomp(name,
				naturalslopeslib.update_shape_on_walk,
				{name = name .. '_upd_shape',
				chance = update_chance * chance_factors.stomp, priority = 500})
		end
	end
	-- Register replacements
	add_replacement(base_node_name, update_chance, chance_factors, slope_names)
	-- Enable on walk update for base node
	if naturalslopeslib.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(base_node_name,
			naturalslopeslib.update_shape_on_walk,
			{name = base_node_name .. '_upd_shape',
			chance = update_chance * chance_factors.stomp, priority = 500})
	end
	-- Enable surface update
	if naturalslopeslib.setting_enable_surface_update() then
		twmlib.register_twm({
			nodenames = {base_node_name, str_name, ic_name, oc_name, pk_name},
			chance = update_chance * chance_factors.time,
			action = naturalslopeslib.update_shape
		})
	end
	return naturalslopeslib.get_replacement(base_node_name)
end

--- Add a slopping behaviour to existing nodes.
function naturalslopeslib.set_slopes(base_node_name, straight_name, inner_name, outer_name, pike_name, update_chance, factors)
	-- Defensive checks
	if not minetest.registered_nodes[base_node_name] then
		if not base_node_name then
			minetest.log('error', 'naturalslopeslib.set_slopes failed: base node_name is nil.')
		else
			minetest.log('error', 'naturalslopeslib.set_slopes failed: ' .. base_node_name .. ' is not registered.')
		end
		return
	end
	if not minetest.registered_nodes[straight_name]
	or not minetest.registered_nodes[inner_name]
	or not minetest.registered_nodes[outer_name]
	or not minetest.registered_nodes[pike_name] then
		minetest.log('error', 'naturalslopeslib.set_slopes failed: one of the slopes for ' .. base_node_name .. ' is not registered.')
		return
	end
	if not update_chance then
		minetest.log('error', 'Natural slopes: chance is not set for node ' .. base_node_name)
		return
	end
	local chance_factors = default_factors(factors)
	-- Set shape update data
	local slope_names = {straight_name, inner_name, outer_name, pike_name}
	add_replacement(base_node_name, update_chance, chance_factors, slope_names)
	-- Set surface update
	if naturalslopeslib.setting_enable_surface_update() then
		twmlib.register_twm({
			nodenames = {base_node_name, straight_name, inner_name, outer_name, pike_name},
			chance = update_chance * chance_factors.time,
			action = naturalslopeslib.update_shape
		})
	end
	-- Set walk listener for the 5 nodes
	if naturalslopeslib.setting_enable_shape_on_walk() then
		local stomp_desc = {name = base_node_name .. '_upd_shape',
			chance = update_chance * chance_factors.stomp, priority = 500}
		poschangelib.register_stomp(base_node_name, naturalslopeslib.update_shape_on_walk, stomp_desc)
		for i, name in pairs(slope_names) do
			poschangelib.register_stomp(name, naturalslopeslib.update_shape_on_walk, stomp_desc)
		end
	end
	return naturalslopeslib.get_replacement(base_node_name)
end

