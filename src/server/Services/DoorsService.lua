--[[
    @classmod DoorsService.lua
    @author LarryCreating
    @date 07/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Packages.import)

local Knit = import("packages/Knit")
local DoorClass = import("middleware/Doors/Door")

local DoorsService = Knit.CreateService({
	Name = "DoorsService",
	Client = {},
})

-- @staticfunction DoorsService:GetDoor
function DoorsService:GetDoor(Object): ()
	if self.Doors[Object] then
		return self.Doors[Object]
	else
		local NewDoor = DoorClass.new(Object)
		self.Doors[Object] = NewDoor
		return NewDoor
	end
end

-- @staticfunction DoorsService:Clicker
-- @description This function is used for the Clicker tool which opens/closes doors without restriction.
function DoorsService.Client:Clicker(Player, DoorModel, ShouldLockdown): ()
	if
		Player.Backpack:FindFirstChild("Clicker") or (Player.Character and Player.Character:FindFirstChild("Clicker"))
	then
		local Door = DoorsService:GetDoor(DoorModel)

		if ShouldLockdown then
			Door:SetLockdown(not Door.Lockdown)
		else
			Door:Toggle()
		end
	end
end

-- @staticfunction DoorsService:KnitStart
function DoorsService:KnitStart(): () end

return DoorsService
