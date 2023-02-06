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

TODO: wallmounted rotations
]]

local GLOW_TIME = tonumber(minetest.settings:get("touch_glow_time")) or 5
local GLOW_STRENGTH = tonumber(minetest.settings:get("touch_glow_strength")) or 2
local MAX_LIGHT = tonumber(minetest.settings:get("touch_max_light")) or 1
local SHAPE_ONLY = minetest.settings:get_bool("touch_shape_only", false)


-- By default objects with 'visual = "item"' are too large so they need to be rescaled
local item_scale = (2/3) + 0.001 -- +0.001 to avoid Z fighting
local cube_scale = 1 + 0.001

-- tracking which nodes are currently touched to hopefully optimize
-- glow removal on beeing dug
local touched_nodes = {}

minetest.register_entity(modname .. ":node_object", {
	initial_properties = {
		visual = "cube",
		physical = false,
		pointable = false,
		static_save = false,
		glow = GLOW_STRENGTH,
		shaded = false,
		-- collisionbox = {-0.0, -0.0, -0.0, 0.0, 0.0, 0.0},
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

	on_deactivate = function(self, removal)
		for _, child in pairs(self.object:get_children() or {}) do
			child:detach()
			child:remove()
		end
	end
})


local shape_texture = {
	"touch_shape_only.png",
	"touch_shape_only.png",
	"touch_shape_only.png",
	"touch_shape_only.png",
	"touch_shape_only.png",
	"touch_shape_only.png",
}

local function nodebox(pos, node)
	local node_def = minetest.registered_nodes[node.name]
	local root_obj = minetest.add_entity(pos, modname .. ":node_object")
	root_obj:set_properties({textures = {
		"touch_empty.png",
		"touch_empty.png",
		"touch_empty.png",
		"touch_empty.png",
		"touch_empty.png",
		"touch_empty.png",
	}})
	local boxes = node_def.node_box.fixed
	if type(boxes[1]) == "number" then
		boxes = {boxes}
	end
	for _, box in pairs(boxes) do
		local box_obj = minetest.add_entity(pos, modname .. ":node_object")
		local visual_size = {
			x = box[4] - box[1] + 0.001,
			y = box[5] - box[2] + 0.001,
			z = box[6] - box[3] + 0.001,
		}
		local textures
		if SHAPE_ONLY then
			textures = table.copy(shape_texture)
		else
			textures = table.copy(node_def.tiles)
			for i = 1, 6 do
				if textures[i] and type(textures[i]) == "table" then
					textures[i] = textures[i].name
				end
			end
			for i = 2, 6 do
				if not textures[i] then
					textures[i] = textures[i-1]
				end
			end
		end

		-- Yes I know this it looks kind of janky, but it works correctly and that's all I need from it.
		-- This cuts out the specific parts of the texture needed by the nodbox box.
		-- It also probably crashes with nodeboxes which aren't pixel aligned
		-- It also probably doesn't work with textures which aren't 16*16
		textures[1] = "[combine:" .. (box[4] - box[1])*16 .. "x" .. (box[6] - box[3])*16 .. ":" .. (-box[1] - 0.5) * 16 .. "," .. ( box[6] - 0.5) * 16 .. "=" .. textures[1]
		textures[2] = "[combine:" .. (box[4] - box[1])*16 .. "x" .. (box[6] - box[3])*16 .. ":" .. (-box[1] - 0.5) * 16 .. "," .. (-box[3] - 0.5) * 16 .. "=" .. textures[2]
		textures[3] = "[combine:" .. (box[6] - box[3])*16 .. "x" .. (box[5] - box[2])*16 .. ":" .. (-box[3] - 0.5) * 16 .. "," .. ( box[5] - 0.5) * 16 .. "=" .. textures[3]
		textures[4] = "[combine:" .. (box[6] - box[3])*16 .. "x" .. (box[5] - box[2])*16 .. ":" .. ( box[6] - 0.5) * 16 .. "," .. ( box[5] - 0.5) * 16 .. "=" .. textures[4]
		textures[5] = "[combine:" .. (box[4] - box[1])*16 .. "x" .. (box[5] - box[2])*16 .. ":" .. ( box[4] - 0.5) * 16 .. "," .. ( box[5] - 0.5) * 16 .. "=" .. textures[5]
		textures[6] = "[combine:" .. (box[4] - box[1])*16 .. "x" .. (box[5] - box[2])*16 .. ":" .. (-box[1] - 0.5) * 16 .. "," .. ( box[5] - 0.5) * 16 .. "=" .. textures[6]
		box_obj:set_properties({visual_size = visual_size, textures = textures})


		local attach_pos = {
			x = (box[4] + box[1]) / 2 * 10,
			y = (box[5] + box[2]) / 2 * 10,
			z = (box[6] + box[3]) / 2 * 10,
		}
		box_obj:set_attach(root_obj, nil, attach_pos)
	end
	return root_obj
end


local function simple_cube(pos, node)
	local node_obj = minetest.add_entity(pos, modname .. ":node_object")
	if SHAPE_ONLY then
		node_obj:set_properties({
			visual = "cube",
			textures = shape_texture,
			visual_size = {x = cube_scale, y = cube_scale, z = cube_scale},
		})
	else
		node_obj:set_properties({
			visual = "item",
			visual_size = {x = item_scale, y = item_scale, z = item_scale},
			wield_item = node.name,
			glow = glow,
		})
	end
	return node_obj
end

local function spawn_touch_object(pos, node, glow)
	local node_def = minetest.registered_nodes[node.name]
	if not node_def then return false end
	local node_obj
	if node_def.drawtype == "nodebox" then
		node_obj = nodebox(pos, node)
	else
		node_obj = simple_cube(pos, node, glow)
	end


	node_obj:set_properties({glow = glow})
	for _, child in pairs(node_obj:get_children() or {}) do
		child:set_properties({glow = glow})
	end

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
		spawn_touch_object(pointed_thing.under, node, glow)

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
