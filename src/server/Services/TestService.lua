--[[
    @classmod TestService.lua
    @author LarryCreating
    @date 04/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Packages.import)

local Weaver = import("packages/Weaver")

local TestService = Weaver.CreateService({
	Name = "TestService",
	Client = {},
})

-- @staticfunction TestService:WeaverInit
function TestService:WeaverInit(): ()
	print("[Server] Weaver works!")
end

return TestService
