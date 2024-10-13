--[[
    @classmod PermissionService.lua
    @author LarryCreating
    @date 04/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local import = require(ReplicatedStorage.Packages.import)

local Weaver = import("packages/Weaver")

local PermissionFunctionsFolder = import("middleware/Permissions")

local PermissionService = Weaver.CreateService({
	Name = "PermissionService",
	Client = {},
})

-- @staticfunction PermissionService:HasPermission
function PermissionService:HasPermission(...): () -> boolean
	return import("shared/Permissions"):HasPermission(...)
end

-- @staticfunction PermissionService:WeaverInit
function PermissionService:WeaverInit(): ()
	if not ReplicatedStorage:FindFirstChild("ReplicatedPermissions") then
		self.ReplicatedFolder = Instance.new("Folder")
		self.ReplicatedFolder.Name = "ReplicatedPermissions"
		self.ReplicatedFolder.Parent = ReplicatedStorage
	else
		self.ReplicatedFolder = ReplicatedStorage.ReplicatedPermissions
	end

	if PermissionFunctionsFolder:FindFirstChild("shared") then
		PermissionFunctionsFolder.shared.Parent = self.ReplicatedFolder
	end

	if PermissionFunctionsFolder:FindFirstChild("client") then
		PermissionFunctionsFolder.client.Parent = self.ReplicatedFolder
	end

	if not ReplicatedStorage:FindFirstChild("ServerCheck") then
		local ServerCheck = Instance.new("RemoteFunction")
		ServerCheck.Name = "ServerCheck"
		ServerCheck.Parent = self.PermissionRemotes

		ServerCheck.OnServerInvoke = function(_, Player, Data)
			return self:HasPermission(Player, Data)
		end
	end

	return self
end

return PermissionService
