hud_data = {}
invhud_data = {}
hud_text = {}

local huddef = {
	hud_elem_type = "text",
	scale = {x = 100, y = 100},
	number = 0xffaf00,
	alignment = {x = 1, y = 1},
	offset = {x = 10, y = 120},
	text = ""
}
local imghuddef = {
	hud_elem_type = "image",
	scale = {x = 1, y = 1},
	text = "default_wood.png",
	alignment = {x = 1, y = 13},
	offset = {x = 30, y = 25}
}
local default_texture = minetest.inventorycube("blank.png", "blank.png", "blank.png")
local missing_texture = minetest.inventorycube("unknown_node.png", "unknown_node.png", "unknown_node.png")
local function get_inv_image(name)
	if not name then return end
	local t = default_texture
	local d = minetest.registered_items[name]
	if name ~= "air" and d and name ~= "" then
		if minetest.registered_craftitems[name] or minetest.registered_tools[name] then
			t = d.inventory_image
		else
			if d.tiles then
				local c = #d.tiles
				local x = {}
				for i, v in ipairs(d.tiles) do
					if type(v) == "table" then
						x[i] = v.name
					else
						x[i] = v
					end
					i = i + 1
				end
				if not x[3] then x[3] = x[1] end
				if not x[4] then x[4] = x[3] end
				t = minetest.inventorycube(x[1], x[3], x[4])
			else
				t = missing_texture
			end
		end
	end
	return t
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0, function()
		hud_data[player:get_player_name()] = player:hud_add(huddef)
		invhud_data[player:get_player_name()] = player:hud_add(imghuddef)
		hud_text[player:get_player_name()] = {}
	end)
end)

minetest.register_globalstep(function(dtime)
	local key, val
	local player
	local near, dist
	local lua, obj, i = 0, 0, 0
	local hp, breath
	local rank = ""
	
	for key in pairs(minetest.luaentities) do
		lua = lua + 1
	end
	
	for key in pairs(minetest.object_refs) do
		obj = obj + 1
	end
	
	for key, val in pairs(hud_data) do
		player = minetest.get_player_by_name(key)
		if player then 
			local pos = vector.round(player:getpos())
			if minetest.get_modpath("rank") then
				rank = "\tR: "..minetest.colorize(rank_colors[ranks[player:get_player_name()]], ranks[player:get_player_name()])
			end
			near, dist = nearest(player)
			if near ~= "nil" then
				hp = minetest.get_player_by_name(near):get_hp()
				breath = minetest.get_player_by_name(near):get_breath()
			end
			player:hud_change(val, "text", "Np: "..near.."\tD: "..dist.."\nH: "..tostring(hp or "nil").."\tB: "..tostring(breath or "nil").."\nTd: "..tostring(math.floor(minetest.get_timeofday()*24000)).."\tLe: "..tostring(lua).."\tOr: "..tostring(obj).."\nT: "..tostring(math.floor(dtime*1000))..rank.."\tC:"..tostring(player:get_player_control_bits()).."\nX: "..tostring(pos.x).."\tY: "..tostring(pos.y).."\tZ: "..tostring(pos.z).."\n\nHi:         W: "..tostring(100 - math.floor((player:get_wielded_item():get_wear() / 65535) * 100)).."%".."\nI: "..(minetest.registered_items[player:get_wielded_item():get_name()] or {description = ""}).description.."\nSs: "..player:get_wielded_item():get_name().."\nUs (sec): "..tonumber(math.floor(minetest.get_server_uptime())).."\tUc: "..math.floor(minetest.get_player_information(key).connection_uptime).."\tIP: "..minetest.get_player_information(key).address .. "\nGt: " .. tostring(minetest.get_gametime()) .. "\tDc: " .. tostring(minetest.get_day_count()))
		end
	end
	for key, val in pairs(invhud_data) do
		player = minetest.get_player_by_name(key)
		if player then
			player:hud_change(val, "text", get_inv_image(player:get_wielded_item():get_name()) .. "^[resize:32x32")
		end
	end
end)

function nearest(player)
	if #minetest.get_connected_players() == 1 then
		return "nil", "nil"
	else
		local pos1 = player:getpos()
		local i, j
		local poss = {}
		local pos2
		local dist
		local top, name = 1000000, ""
		for _, i in pairs(minetest.get_connected_players()) do
			pos2 = i:getpos()
			dist = math.sqrt(((pos2.x - pos1.x) * (pos2.x - pos1.x)) + ((pos2.y - pos1.y) * (pos2.y - pos1.y)) + ((pos2.z - pos1.z) * (pos2.z - pos1.z)))
			poss[i:get_player_name()] = dist
		end
		for j, i in pairs(poss) do
			if i < top and j ~= player:get_player_name() then
				top = i
				name = j
			end
		end
		return name, math.floor(top)
	end
end

minetest.register_on_leaveplayer(function(player)
	hud_data[player:get_player_name()] = nil
	invhud_data[player:get_player_name()] = nil
end)
