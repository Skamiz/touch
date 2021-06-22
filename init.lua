local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- dofile(modpath .. "/other_file.lua")

--[[
rotate entity to reflect node rotation
maybe figure out whats wrong with glow updating

doesn't quite work with connected parts of connected nodeboxes
]]

local GLOW_TIME = tonumber(minetest.settings:get("touch_glow_time")) or 5
local GLOW_STRENGTH = tonumber(minetest.settings:get("touch_glow_strength")) or 2
local MAX_LIGHT = tonumber(minetest.settings:get("touch_max_light")) or 1

-- By default objects with 'visual = "item"' are too large so they need to be rescaled
local scale = (2/3) + 0.001 -- +0.001 to avoid Z fighting

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
			self.object:remove()
		end
	end,
})


minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	local light_above = minetest.get_node_light(pointed_thing.above)
	if puncher:get_wielded_item():get_name() == "" and
		light_above <= MAX_LIGHT
	then
		local node_obj = minetest.add_entity(pointed_thing.under, modname .. ":node_object")
		node_obj:set_properties({wield_item = node.name})
		
		-- to avoid the touched node to be darker then before
		if light_above > GLOW_STRENGTH then
			node_obj:set_properties({glow = light_above})
		end
	end
end)
