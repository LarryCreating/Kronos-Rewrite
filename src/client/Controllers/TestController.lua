--[[
    @classmod TestController.lua
    @author LarryCreating
    @date 04/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local import = require(ReplicatedStorage.Packages.import)

local Weaver = import("packages/Weaver")

local TestController = Weaver.CreateController({
	Name = "TestController",
})

local PermissionService

local Player = Players.LocalPlayer

-- @staticfunction TestController:TestForPermissions
function TestController:TestForPermissions(): ()
	--[[if PermissionService:HasPermission("All") then
		print("Works!")
	end]]
end

-- @staticfunction TestController:WeaverInit
function TestController:WeaverInit(): ()
	PermissionService = Weaver.GetService("PermissionService")
	self:TestForPermissions()
end

return TestController
