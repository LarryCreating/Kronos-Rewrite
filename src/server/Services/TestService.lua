--[[
    @classmod TestService.lua
    @author LarryCreating
    @date 04/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Packages.import)

local Knit = import("packages/Knit")

local TestService = Knit.CreateService({
	Name = "TestService",
	Client = {},
})

-- @staticfunction TestService:KnitStart
function TestService:KnitStart(): ()
	print("Knit works!")
end

return TestService
