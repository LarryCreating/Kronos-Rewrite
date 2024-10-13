--[[
    @classmod Permissions.lua
    @author LarryCreating
    @date 13/10/2024
]]
local Permissions = {
	Functions = {},
}

local import = require(game.ReplicatedStorage.Packages.import)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local VERBOSE_LOGS = false

local IsClient = RunService:IsClient()

-- @staticfunction Permissions:HasPermission
function Permissions:HasPermission(Player, Data, FallbackToServer): () -> boolean
	if not self.HasInitialised then
		if self.Initilising then
			repeat
				task.wait()
			until self.HasInitialised
		else
			self:init()
		end
	end

	if Data == nil and Player ~= nil and IsClient then
		Data = Player
		Player = Players.LocalPlayer
	end

	if typeof(Data) == "Instance" then
		if Data:IsA("ObjectValue") then
			Data = Data.Value
		end
		if Data:IsA("ModuleScript") then
			Data = require(Data)
		end
	elseif type(Data) == "string" then
		Data = { Data }
	end

	if typeof(Player) == "number" then
		for _, PlayerObject in ipairs(Players:GetPlayers()) do
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
			elseif RequireAll then
				return false
			end
		elseif type(PermissionSegment) == "string" then
			local returnOpposite = false

			if string.sub(PermissionSegment, 0, 1) == "!" then
				returnOpposite = true
				PermissionSegment = string.sub(PermissionSegment, 2)
			end

			local Split = string.split(PermissionSegment, ":")
			local FunctionName = Split[1]
			if self.Functions[FunctionName] then
				local hasPerm = self.Functions[FunctionName](Player, self, table.unpack(Split, 2))

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
			elseif FallbackToServer and IsClient then
				local HasPermissionSegmentServer = self:CheckWithServer(Player, PermissionSegment)

				if HasPermissionSegmentServer then
					if not RequireAll then
						return true
					end
				end
			elseif RequireAll then
				warn(
					'Permission function with the name "' .. FunctionName .. '" was not found (ReqAll).',
					debug.traceback()
				)
				return false
			else
				warn('Permission function with the name "' .. FunctionName .. '" was not found.', debug.traceback())
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

-- @staticfunction Permissions:CheckWithServer
function Permissions:CheckWithServer(Player, Data): ()
	return import("/ReplicatedStorage/PermissionRemotes/ServerCheck"):InvokeServer(Player, Data)
end

-- @staticfunction Permissions:RegisterFunction
function Permissions:RegisterFunction(Name, Function): ()
	self.Functions[Name] = Function
end

-- @staticfunction Permissions:RegisterFunctionsIn
function Permissions:RegisterFunctionsIn(Folder): ()
	local Children = Folder:GetChildren()
	for i, Module in pairs(Children) do
		if Module:IsA("ModuleScript") then
			local success, _ = pcall(function()
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

-- @staticfunction Permissions:init
function Permissions:init(): ()
	self.Initilising = true
	self.ReplicatedFolder = ReplicatedStorage:WaitForChild("ReplicatedPermissions")
	self:RegisterFunctionsIn(Permissions.ReplicatedFolder.shared)
	if IsClient then
		self:RegisterFunctionsIn(Permissions.ReplicatedFolder:WaitForChild("client"))
	else
		local ServerFunctions = import("middleware/Permissions/server")
		self:RegisterFunctionsIn(ServerFunctions)
	end
	self.HasInitialised = true
	self.Initilising = false
end

setmetatable(Permissions, {
	__call = function(self, ...)
		return Permissions.HasPermission(self, ...)
	end,
})

return Permissions
