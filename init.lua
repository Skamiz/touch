local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- dofile(modpath .. "/other_file.lua")

--[[
make lifetime configurable
rotate entity to reflect node rotation
maybe figure out whats wrong with glow updating
]]

local function lerp(a, b, scale)
	return a * (1 - scale) + b * scale
end


local lifetime = 5
local scale = (2/3) + 0.001
minetest.register_entity(modname .. ":node_object", {
	initial_properties = {
		visual = "item",
		visual_size = {x = scale, y = scale, z = scale},
		physical = false,
		pointable = false,
		static_save = false,
		glow = 2,
		shaded = false,
	},
	on_activate = function(self, staticdata, dtime_s)
		self.time = 0
	end,

	on_step = function(self, dtime, moveresult)
		self.time = self.time + dtime

		-- WARNING: For some obscure reason the glow is NOT UPDATED!
		-- self.object:set_properties({glow = lerp(15,0,self.time/lifetime)})
		-- minetest.chat_send_all("" .. lerp(15,0,self.time/lifetime))

		if self.time > lifetime then
			self.object:remove()
		end
	end,
})


minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	-- minetest.chat_send_all(type(puncher:get_wielded_item():get_name()) .. " | '" .. puncher:get_wielded_item():get_name() .. "'")

	if puncher:get_wielded_item():get_name() == "" and
		minetest.get_node_light(puncher:get_pos()) < 2
	then
		local node_obj = minetest.add_entity(pointed_thing.under, modname .. ":node_object")
		node_obj:set_properties({wield_item = node.name})
	end
end)
