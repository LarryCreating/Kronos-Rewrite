--[[
    @classmod PermissionService.lua
    @author LarryCreating
    @date 04/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local import = require(ReplicatedStorage.Packages.import)

local Knit = import("packages/Knit")

local PermissionService = Knit.CreateService({
	Name = "PermissionService",
	Client = {},
})

local VERBOSE_LOGS = true

-- @staticfunction PermissionService:HasPermission
function PermissionService.Client:HasPermission(Player, Data): () -> boolean
	if not PermissionService.HasInitialised then
		if PermissionService.Initialising then
			repeat
				task.wait()
			until PermissionService.HasInitialised
		else
			PermissionService:init()
		end
	end

	if typeof(Data) == "Instance" then
		if Data:IsA("ObjectValue") then
			Data = Data.Value
		end
		if Data:IsA("ModuleScript") then
			Data = require(Data)
		end
	elseif typeof(Data) == "string" then
		Data = { Data }
	end

	if typeof(Player) == "number" then
		for i, PlayerObject in ipairs(Players:GetPlayers()) do
			if PlayerObject.UserId == Player then
				Player = PlayerObject
			end
		end

		if typeof(Player) == "number" then
			return false
		end
	end

	local RequireAll = not not (Data and Data.RequireAll)

	for _, PermissionSegment in pairs(Data) do
		if type(PermissionSegment) == "table" then
			if self:HasPermission(Player, PermissionSegment, true) then
				if not RequireAll then
					return true
				end
			end
		elseif type(PermissionSegment) == "string" then
			local returnOpposite = false

			if string.sub(PermissionSegment, 0, 1) == "!" then
				returnOpposite = true
				PermissionSegment = string.sub(PermissionSegment, 2)
			end

			local Split = string.split(PermissionSegment, ":")
			local FunctionName = Split[1]

			if PermissionService.Functions[FunctionName] then
				local hasPerm = PermissionService.Functions[FunctionName](Player, self, table.unpack(Split, 2))

				if returnOpposite then
					hasPerm = not hasPerm
				end

				if hasPerm then
					if not RequireAll then
						return true
					end
				elseif RequireAll then
					return false
				end
			elseif RequireAll then
				warn(
					'Permission function with the name "' .. FunctionName .. '" was not found (ReqAll).',
					debug.traceback()
				)
				return false
			end
		elseif typeof(PermissionSegment) == "function" then
			local success, result = pcall(PermissionSegment, Player)
			local PassedCheck = success and (result == true)

			if PassedCheck and not RequireAll then
				return true
			elseif not PassedCheck and RequireAll then
				return false
			end
		end
	end

	return RequireAll
end

-- @staticfunction PermissionService:RegisterFunction
function PermissionService:RegisterFunction(Name, Function): ()
	self.Functions[Name] = Function
end

-- @staticfunction PermissionService:RegisterFunctionsIn
function PermissionService:RegisterFunctionsIn(Folder): ()
	local Children = Folder:GetChildren()
	for i, Module in pairs(Children) do
		if Module:IsA("ModuleScript") then
			local success, result = pcall(function()
				return self:RegisterFunction(Module.Name, require(Module))
			end)
			if success and VERBOSE_LOGS then
				print("Registered permission function:", Module.Name, tostring(i) .. "/" .. tostring(#Children))
			elseif VERBOSE_LOGS then
				warn('Failed to register permission function "' .. Module.Name .. '":')
			end
		end
	end
	print("Registered Permissions functions in", Folder)
end

-- @staticfunction PermissionService:init
function PermissionService:init()
	self.Initialising = true

	local Permissions = import("modules/Permissions")
	repeat
		task.wait()
	until #Permissions:GetChildren() > 1
	self:RegisterFunctionsIn(Permissions)

	self.HasInitialised = true
	self.Initialising = false
end

return PermissionService
