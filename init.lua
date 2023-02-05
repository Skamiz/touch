local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local rotations = dofile(modpath .. "/rotations.lua")

--[[
maybe figure out what's wrong with glow updating
	hey past me, what did you mean with 'glow updating'
	speaking of, it would be cool if the touched node gradually faded to darkness

funfact: snow doesn't display correctly, the top surface is pusshed further down
		when the node is scaled up (to avoid z-fighting)

doesn't quite work with connected parts of connected nodeboxes
]]

local GLOW_TIME = tonumber(minetest.settings:get("touch_glow_time")) or 5
local GLOW_STRENGTH = tonumber(minetest.settings:get("touch_glow_strength")) or 2
local MAX_LIGHT = tonumber(minetest.settings:get("touch_max_light")) or 1
local SHAPE_ONLY = minetest.settings:get_bool("touch_shape_only", false)


-- By default objects with 'visual = "item"' are too large so they need to be rescaled
local scale = (2/3) + 0.001 -- +0.001 to avoid Z fighting

-- tracking which nodes are currently touched to hopefully optimize
-- glow removal on beeing dug
local touched_nodes = {}

minetest.register_entity(modname .. ":node_object", {
	initial_properties = {
		visual = "item",
		visual_size = {x = scale, y = scale, z = scale},
		physical = false,
		pointable = false,
		static_save = false,
		glow = GLOW_STRENGTH,
		shaded = false,
		collisionbox = {-0.0, 0.0, -0.0, 0.0, 0.0, 0.0},
	},
	on_activate = function(self, staticdata, dtime_s)
		self.time = 0
	end,

	on_step = function(self, dtime, moveresult)
		self.time = self.time + dtime

		if self.time > GLOW_TIME then
			touched_nodes[minetest.hash_node_position(self.object:get_pos())] = nil
			self.object:remove()
		end
	end,
})

-- local box_drawtypes = {
-- 	["normal"] = true,
-- 	["glasslike"] = true,
-- 	["glasslike_framed"] = true,
-- 	["glasslike_framed_optional"] = true,
-- 	["normal"] = true,
-- }
local function spawn_touch_object(pos, node, glow)
	local node_def = minetest.registered_nodes[node.name]
	if not node_def then return false end

	local node_obj = minetest.add_entity(pos, modname .. ":node_object")
	node_obj:set_properties({wield_item = node.name, glow = glow})

	if node_def and node_def.paramtype2 == "facedir" then
		local rot = rotations.facedir[node.param2]
		node_obj:set_rotation(rot)
	end
	return node_obj
end
local shape_texture = {
	"touch_shape_only.png",
	"touch_shape_only.png",
	"touch_shape_only.png",
	"touch_shape_only.png",
	"touch_shape_only.png",
	"touch_shape_only.png",
}
local cube_scale = 1 + 0.001
local function spawn_touch_shape_object(pos, node, light)
	local node_def = minetest.registered_nodes[node.name]
	if not node_def then return false end

	local node_obj = minetest.add_entity(pos, modname .. ":node_object")
	node_obj:set_properties({
		visual = "cube",
		textures = shape_texture,
		glow = glow,
		visual_size = {x = cube_scale, y = cube_scale, z = cube_scale},
	})

	if node_def and node_def.paramtype2 == "facedir" then
		local rot = rotations.facedir[node.param2]
		node_obj:set_rotation(rot)
	end
	return node_obj
end


minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	local light_above = minetest.get_node_light(pointed_thing.above)
	if puncher:get_wielded_item():get_name() == "" and
			light_above <= MAX_LIGHT
	then
		local glow = math.max(light_above, GLOW_STRENGTH)
		if not SHAPE_ONLY then
			spawn_touch_object(pointed_thing.under, node, glow)
		else
			spawn_touch_shape_object(pointed_thing.under, node, glow)
		end

		touched_nodes[minetest.hash_node_position(pointed_thing.under)] = true
	end
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
	local node_index = minetest.hash_node_position(pos)
	if touched_nodes[node_index] then
		local objects = minetest.get_objects_in_area(pos, pos)
		for _, v in pairs(objects) do
			if not v:is_player() and v:get_luaentity().name == modname .. ":node_object" then
				v:remove()
			end
		end

		touched_nodes[node_index] = nil
	end
end)
