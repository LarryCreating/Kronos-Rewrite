--[[
    @classmod DoorsService.lua
    @author LarryCreating
    @date 07/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Packages.import)

local Weaver = import("packages/Weaver")

local DoorClass = import("middleware/Doors/Door")

local DoorsService = Weaver.CreateService({
	Name = "DoorsService",
	Client = {},
	Doors = {},
})

local TagService

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

-- @staticfunction DoorsService:WeaverInit
function DoorsService:WeaverInit(): ()
	TagService = Weaver.GetService("TagService")
	TagService:BindToTag("Door", function(Object)
		local success, result = pcall(self.GetDoor, self, Object)

		if not success then
			warn("Error while initialising door", Object:GetFullName() .. ":", result)
		end
	end)
end

return DoorsService
