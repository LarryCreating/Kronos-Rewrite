--[[
    @classmod TestController.lua
    @author LarryCreating
    @date 04/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Packages.import)

local Knit = import("packages/Knit")

local TestController = Knit.CreateController({
	Name = "TestController",
})

-- @staticfunction TestController:KnitStart
function TestController:KnitStart(): ()
	print("[Client] Knit works!")
end

return TestController
