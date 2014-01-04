
function SendChatMessage(ply, ...)
	args = {...}
	if type(args[1]) == "table" then
		Events:Fire("ZEDSendChatMessage", {player=ply, message=args[1]})
	else
		Events:Fire("ZEDSendChatMessage", {player=ply, message={...}})
	end
end

Groups = {}
CreateGroup = function(name, permission, inherits, color, useprefix)
	grp = {}
	grp.name = name
	grp.permission = permission
	grp.inherits = inherits
	grp.color = color
	grp.useprefix = useprefix
	Groups[name] = grp
end 
ParseColor = function(t)
	if(type(t) == "table")then
		return Color(tonumber(t[1]),tonumber(t[2]),tonumber(t[3]))
	end
end
GetGroup = function(g)
	for _,grp in pairs(Groups) do
		if(grp.name == g)then
			return grp
		end
	end
end
GroupHasPermission = function(grp, str)
	if(GetGroup(grp))then
		if GetGroup(grp).inherits then
			if(GroupHasPermission(GetGroup(grp).inherits, str))then 
				return true 
			end
		end
		for k,v in pairs(GetGroup(grp).permission) do
			if(v == "*")then return true end
			if(string.lower(str) == string.lower(v))then
				return true
			end
		end
		return false
	else
		return false
	end
end
GetPlayerGroup = function(ply)
		local pdata = PData:Get(ply)
		if(pdata)then
				for _,grp in pairs(Groups) do
						if(strEquals(grp.name, pdata.group))then
								return grp
						end
				end
		end
end
GroupExists = function(str)
		for _,grp in pairs(Groups) do
				if(strEquals(grp.name, str))then
						return true
				end
		end
		return false
end
FindGroup = function(str)
		for _,grp in pairs(Groups) do
				if(strFind(grp.name, str))then
						return grp
				end
		end
		return false
end
GetPlayer = function(str)
	for player in Server:GetPlayers() do
		if(string.find(string.lower(player:GetName()), string.lower(str)))then
			return player
		end
	end
end
strFind = function(v1, v2)
	if(string.find(string.lower(tostring(v1)), string.lower(tostring(v2))))then
		return true
	else
		return false
	end
end
strEquals = function(v1, v2)
	if(string.lower(tostring(v1)) == string.lower(tostring(v2)))then
		return true
	else
		return false
	end
end


Events:Subscribe("ZEDExecuteCommand", function(a)
	local ply = a.player
	local args = a.cmd
	if(strEquals("setgroup", args[1]))then
		if(args[2] and args[3])then
			if GetPlayer(args[2]) then
				target = GetPlayer(args[2])
				if(FindGroup(args[3]))then
					PData:Set(target, {group = FindGroup(args[3]).name})
					SendChatMessage(ply, Color(0,200,0,255),"Set group from " .. target:GetName() .. " to " .. FindGroup(args[3]).name, Color(0,200,0,255))
					SendChatMessage(target, Color(0,200,0,255),"Your group has been set to " .. FindGroup(args[3]).name)
				else
					SendChatMessage(ply, Color(200,0,0,255),"Can't find group " .. args[3])
				end
			else
				SendChatMessage(ply, Color(200,0,0,255),"Can't find " .. args[2], Color(200,0,0,255))
			end
		else
			SendChatMessage(ply, Color(200,0,0,255),"Syntax: /setgroup <player> <group>", Color(200,0,0,255))
		end
	end
	if(strEquals("group", args[1]))then
		if(args[2] and args[3])then
			if(strFind(args[2], "create"))then
				if(GroupExists(args[3]))then
					SendChatMessage(ply, Color(200,0,0,255),"Group already exists: " .. args[3])
				else
					if(FindGroup(args[4]))then
						CreateGroup(args[3], {}, FindGroup(args[4]).name)
					else
						CreateGroup(args[3], {})
					end
					local str = json():encode(FindGroup(args[3]))
					local file = io.open("./data/groups/"..args[3]..".txt", "w")
					file:write(str)
					file:close()
					SendChatMessage(ply, Color(0,200,0,255),"Group created: " .. args[3], Color(0,200,0,255))
				end
			elseif(strFind(args[2], "delete"))then
				if(FindGroup(args[3]))then
					local name = FindGroup(args[3]).name
					for k,v in pairs(Groups) do
						if(strEquals(v.name, name))then
							local file = io.open("./data/groups/"..name..".txt", "w")
							file:write("Deleted by " .. ply:GetName())
							file:close()
							Groups[k] = nil
							SendChatMessage(ply, Color(0,200,0,255),"Group deleted: " .. name)
							break
						end
					end
				else
					SendChatMessage(ply, Color(200,0,0,255),"Can't find " .. args[3], Color(200,0,0,255))
				end
			elseif(strFind(args[2], "addperm"))then
				if(FindGroup(args[3]))then
					if(not args[4])then
						SendChatMessage(ply, Color(200,0,0,255),"Syntax: /group addperm <group> <permission>", Color(200,0,0,255))
						return
					end
					for k,v in pairs(Groups) do
						if(v.name == FindGroup(args[3]).name)then
							for i,j in pairs(Groups[k].permission) do
								if(strEquals(j, args[4]))then
									SendChatMessage(ply, Color(200,0,0,255),"This group has already this permission: " .. args[4])
									return
								end
							end
							table.insert(Groups[k].permission, args[4])
						end
					end
					local str = json():encode(FindGroup(args[3]))
					local file = io.open("./data/groups/"..FindGroup(args[3]).name..".txt", "w")
					file:write(str)
					file:close()
					SendChatMessage(ply, Color(0,200,0,255),"Permission added: " .. args[4])
				else
					SendChatMessage(ply, Color(200,0,0,255),"Can't find " .. args[3])
				end
			elseif(strFind(args[2], "delperm"))then
				if(FindGroup(args[3]))then
					if(not args[4])then
						SendChatMessage(ply, Color(200,0,0,255), "Syntax: /group delperm <group> <permission>")
						return
					end
					local found = -1
					local group = -1
					local perm = ""
					for k,v in pairs(Groups) do
						if(v.name == FindGroup(args[3]).name)then
							group = k
							for i,j in pairs(Groups[k].permission) do
								if(strFind(j, args[4]))then
									found = i
									perm = j
								end
							end
							break
						end
					end
					if(found > -1)then
						Groups[group].permission[found]=nil
						local str = json():encode(FindGroup(args[3]))
						local file = io.open("./data/groups/"..FindGroup(args[3]).name..".txt", "w")
						file:write(str)
						file:close()
						SendChatMessage(ply, Color(0,200,0,255),"Permission removed: " .. perm)
					else
						SendChatMessage(ply, Color(200,0,0,255),"Permission not found: " .. args[4])
					end
				else
					SendChatMessage(ply, Color(200,0,0,255),"Can't find " .. args[3])
				end
			elseif(strFind(args[2], "setcolor"))then
				if(FindGroup(args[3]))then
					if (not args[4]) or (not args[5]) or (not args[6]) then
						SendChatMessage(ply, Color(200,0,0,255),"Syntax: group setcolor <group> <r> <g> <b>")
						return
					end
					for k,v in pairs(Groups) do
						if(v.name == FindGroup(args[3]).name)then
							Groups[k].color = {tonumber(args[4]), tonumber(args[5]), tonumber(args[6])}
						end
					end
					local str = json():encode(FindGroup(args[3]))
					local file = io.open("./data/groups/"..FindGroup(args[3]).name..".txt", "w")
					file:write(str)
					file:close()
					SendChatMessage(ply, Color(tonumber(args[4]), tonumber(args[5]), tonumber(args[6])),"Color set.")
				else
					SendChatMessage(ply, Color(200,0,0,255),"Can't find " .. args[3])
				end
			elseif(strFind(args[2], "toggleprefix"))then
				if(FindGroup(args[3]))then
					for k,v in pairs(Groups) do
						if(v.name == FindGroup(args[3]).name)then
							if not Groups[k].useprefix then
								Groups[k].useprefix = true
							else
								Groups[k].useprefix = not Groups[k].useprefix
							end
						end
					end
					local str = json():encode(FindGroup(args[3]))
					local file = io.open("./data/groups/"..FindGroup(args[3]).name..".txt", "w")
					file:write(str)
					file:close()
					SendChatMessage(ply, Color(0,200,0,255), "Prefix toggled.")
				else
					SendChatMessage(ply, Color(200,0,0,255), "Can't find " .. args[2])
				end
			end
		else
			SendChatMessage(ply, Color(200,0,0,255),"Syntax: /group create <name> <inherits>")
			SendChatMessage(ply, Color(200,0,0,255),"Syntax: /group delete <name>")
			SendChatMessage(ply, Color(200,0,0,255),"Syntax: /group addperm <group> <permission>")
			SendChatMessage(ply, Color(200,0,0,255),"Syntax: /group delperm <group> <permission>")
			SendChatMessage(ply, Color(200,0,0,255),"Syntax: /group setcolor <group> <r> <g> <b>")
			SendChatMessage(ply, Color(200,0,0,255),"Syntax: /group toggleprefix <group>")
			if(#Groups > 0)then
				SendChatMessage(ply, Color(0,180,130),"Available Groups:")
				local c = 0
				local str = ""
				for k,v in pairs(Groups) do
					c = c + 1
					str = str .. ", " .. v.name
					if (c == 5)then
						c = 0
						SendChatMessage(ply, Color(0,200,150),string.sub(str, 3))
						str = ""
					end
				end
				if(c > 0)then
					SendChatMessage(ply, Color(0,200,150),string.sub(str, 3))
				end
			end
		end
	end
end)

Console:Subscribe("setgroup", function(args)
	if(args[1] and args[2])then
		if GetPlayer(args[1]) then
			target = GetPlayer(args[1])
			if(FindGroup(args[2]))then
				PData:Set(target, {group = FindGroup(args[2]).name})
				print("Set group from " .. target:GetName() .. " to " .. FindGroup(args[2]).name)
				SendChatMessage(target, Color(0,200,0), "Your group has been set to " .. FindGroup(args[2]).name)
			else
				print("Can't find group " .. args[2])
			end
		else
			print("Can't find " .. args[1])
		end
	else
		print("Syntax: /setgroup <player> <group>")
	end
end)

Console:Subscribe("group", function(args)
	if(args[1] and args[2])then
		if(strFind(args[1], "create"))then
			if(GroupExists(args[2]))then
				print("Group already exists: " .. args[2])
			else
				if(FindGroup(args[3]))then
					CreateGroup(args[2], {}, FindGroup(args[3]).name)
				else
					CreateGroup(args[2], {})
				end
				local str = json():encode(FindGroup(args[2]))
				local file = io.open("./data/groups/"..args[2]..".txt", "w")
				file:write(str)
				file:close()
				print("Group created: " .. args[2])
			end
		elseif(strFind(args[1], "delete"))then
			if(FindGroup(args[2]))then
				local name = FindGroup(args[2]).name
				for k,v in pairs(Groups) do
					if(strEquals(v.name, name))then
						local file = io.open("./data/groups/"..name..".txt", "w")
						file:write("Deleted by " .. ply:GetName())
						file:close()
						Groups[k] = nil
						print("Group deleted: " .. name)
						break
					end
				end
			else
				print("Can't find " .. args[2])
			end
		elseif(strFind(args[1], "addperm"))then
			if(FindGroup(args[2]))then
				if(not args[3])then
					print("Syntax: group addperm <group> <permission>")
					return
				end
				for k,v in pairs(Groups) do
					if(v.name == FindGroup(args[2]).name)then
						for i,j in pairs(Groups[k].permission) do
							if(strEquals(j, args[3]))then
								print("This group has already this permission: " .. args[3])
								return
							end
						end
						table.insert(Groups[k].permission, args[3])
					end
				end
				local str = json():encode(FindGroup(args[2]))
				local file = io.open("./data/groups/"..FindGroup(args[2]).name..".txt", "w")
				file:write(str)
				file:close()
				print("Permission added: " .. args[3])
			else
				print("Can't find " .. args[2])
			end
		elseif(strFind(args[1], "delperm"))then
			if(FindGroup(args[2]))then
				if(not args[3])then
					print("Syntax: group delperm <group> <permission>")
					return
				end
				local found = -1
				local group = -1
				local perm = ""
				for k,v in pairs(Groups) do
					if(v.name == FindGroup(args[2]).name)then
						group = k
						for i,j in pairs(Groups[k].permission) do
							if(strFind(j, args[3]))then
								found = i
								perm = j
							end
						end
						break
					end
				end
				if(found > -1)then
					Groups[group].permission[found]=nil
					local str = json():encode(FindGroup(args[2]))
					local file = io.open("./data/groups/"..FindGroup(args[2]).name..".txt", "w")
					file:write(str)
					file:close()
					print("Permission removed: " .. perm)
				else
					print("Permission not found: " .. args[3])
				end
			else
				print("Can't find " .. args[2])
			end
		elseif(strFind(args[1], "setcolor"))then
			if(FindGroup(args[2]))then
				if (not args[3]) or (not args[4]) or (not args[5]) then
					print("Syntax: group setcolor <group> <r> <g> <b>")
					return
				end
				for k,v in pairs(Groups) do
					if(v.name == FindGroup(args[2]).name)then
						Groups[k].color = {args[3], args[4], args[5]}
					end
				end
				local str = json():encode(FindGroup(args[2]))
				local file = io.open("./data/groups/"..FindGroup(args[2]).name..".txt", "w")
				file:write(str)
				file:close()
				print("Color set.")
			else
				print("Can't find " .. args[2])
			end
		elseif(strFind(args[1], "toggleprefix"))then
			if(FindGroup(args[2]))then
				for k,v in pairs(Groups) do
					if(v.name == FindGroup(args[2]).name)then
						if not Groups[k].useprefix then
							Groups[k].useprefix = true
						else
							Groups[k].useprefix = not Groups[k].useprefix
						end
					end
				end
				local str = json():encode(FindGroup(args[2]))
				local file = io.open("./data/groups/"..FindGroup(args[2]).name..".txt", "w")
				file:write(str)
				file:close()
				print("Prefix toggled.")
			else
				print("Can't find " .. args[2])
			end
		end
	else
		print("Syntax: group create <name> <inherits>")
		print("Syntax: group delete <name>")
		print("Syntax: group addperm <group> <permission>")
		print("Syntax: group delperm <group> <permission>")
		print("Syntax: group setcolor <group> <r> <g> <b>")
		print("Syntax: group toggleprefix <group>")
		if(#Groups > 0)then
			print("Available Groups:")
			local c = 0
			local str = ""
			for k,v in pairs(Groups) do
				c = c + 1
				str = str .. ", " .. v.name
				if (c == 5)then
					c = 0
					print(string.sub(str, 3))
					str = ""
				end
			end
			if(c > 0)then
				print(string.sub(str, 3))
			end
		end
	end
end)

Events:Subscribe("ZEDScoreboardUpdate", function()
	local tbl = {}
	for player in Server:GetPlayers() do
		if(GetPlayerGroup(player))then
			tbl[player:GetId()] = GetPlayerGroup(player).name
		end
	end
	Events:Fire("ZEDUpdateScoreboard", {Extra={Group=tbl},Columns={},Buttons={}})
end)
	
Events:Subscribe("ZEDPlayerInit", function(args)
	if not GetPlayerGroup(args.player) then
		PData:Load(args.player, {group="User"})
		if(not PData:Get(args.player).group)then
			PData:Set(args.player, {group = "User"})
		end
	end
end)

Events:Subscribe("PlayerQuit", function(args)
	PData:Save(args.player)
	PData:Delete(args.player)
end)

Events:Subscribe("ZEDRequestPrefix", function(player)
	if GetPlayerGroup(player).useprefix then
		if not GetPlayerGroup(player).color then 
			for k,v in pairs(Groups) do
				if(v.name == GetPlayerGroup(player).name)then
					Groups[k].color = {255, 255, 255}
				end
			end
		end
		Events:Fire("ZEDSetPrefix", {player=player, prefix={ParseColor(GetPlayerGroup(player).color), "[" .. GetPlayerGroup(player).name .. "] "}})
	end
end)

Events:Subscribe("ZEDPlayerHasPermission", function(args)
	if(GetPlayerGroup(args.player) and args.permission)then
		if(GroupHasPermission(GetPlayerGroup(args.player).name, args.permission))then
			return false
		end
	end
end)

Events:Subscribe("ModulesLoad", function()
	for k,v in pairs(io.files("./data/groups")) do
		local file = io.open("./data/groups/" .. v, "r")
		local ret = json():decode(file:read("*all"))
		if(ret)then
			CreateGroup(string.sub(v, 1, -5), ret.permission, ret.inherits, ret.color, ret.useprefix)
		end
	end
end)

Events:Subscribe("ModuleUnload", function()
	for player in Server:GetPlayers() do
		PData:Save(player)
	end
end)