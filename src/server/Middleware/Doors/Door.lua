--[[
    @classmod Door.lua
    @author LarryCreating
    @date 07/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")

local import = require(ReplicatedStorage.Packages.import)

local Knit = import("packages/Knit")
local Janitor = import("packages/Janitor")

local DoorFunctions = import("middleware/Doors/Doors")

local PermissionService

local Door = {}
Door.__index = Door

-- @staticfunction Door.new
-- @type Constructor
-- @description Sets up a new door object.
function Door.new(Object): ()
	PermissionService = Knit.GetService("PermissionService")
	local SettingsFile = Object:FindFirstChild("Settings")
	local self = setmetatable((SettingsFile and require(SettingsFile) or {}), Door)

	assert(self.Function, "You must specify a door function within a settings file to run Door.new")

	self.Janitor = Janitor.new()
	self.Object = Object
	self:SetNetworkOwnership()

	local PermissionsFile = Object:FindFirstChild("Permissions")
	self.Permissions = {
		Regular = (PermissionsFile or {}),
		Lockdown = Object:FindFirstChild("LockdownPermissions"),
	}

	self.IsOpen = self.StartOpen or false
	self.WasOpen = false
	self.Lockdown = false
	self.Cooldown = false

	self.DoorFunction = self:FindFunction(self.Function)
	assert(
		self.DoorFunction,
		'Door function with the name"' .. self.Function .. '" could not be found for ' .. self.Object:GetFullName()
	)

	if self.DoorFunction.Setup then
		self.DoorFunction.Setup(self)
	end

	if not self.AutoCloseTime then
		self.AutoCloseTime = 3
	end

	if self.IsOpen then
		task.spawn(self.Open, self)
	end

	self:SetupReaders()

	if self.ConnectedLockdowns then
		for _, LockdownZone in pairs(self.ConnectedLockdowns) do
			local AttributeName = string.lower(LockdownZone) .. "lockdown"
			ReplicatedStorage:GetAttributeChangedSignal(AttributeName):Connect(function()
				self:HandleLockdownChange()
			end)
		end
	end

	self:HandleLockdownChange()

	if self.StartLockdown then
		self:SetLockdown(true)
	end

	return self
end

-- @staticfunction Door:FindFunction
function Door:FindFunction(): ()
	for _, Module in ipairs(DoorFunctions:GetChildren()) do
		if Module:IsA("ModuleScript") then
			local success, result = pcall(require, Module)

			if not success then
				warn("An error occured while loading door function module", Module:GetFullName() .. ":", result)
			elseif not result.Name then
				warn("Configuration fault in door function module", Module:GetFullName())
			elseif result.Name == self.Function then
				return result
			end
		end
	end
end

-- @staticfunction Door:SetNetworkOwnership
-- @description Allows the player to have client-sided tween transitions.
function Door:SetNetworkOwnership(): ()
	for _, Descendant in ipairs(self.Object:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			pcall(Descendant.SetNetworkOwner, Descendant, nil)
		end
	end
end

-- @staticfunction Door:SetObjectCollisionGroup
function Door:SetObjectCollisionGroup(GroupName): ()
	for _, part in ipairs(self.Object:GetDescendants()) do
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, GroupName)
		end
	end
end

-- @staticfunction Door:Open
function Door:Open(): ()
	self.Cooldown = true
	self.IsOpen = true
	self:UpdatePrompts()

	if self.DoorFunction.Actuate then
		self.DoorFunction.Actuate(self, true)
	end

	if self.AutoClose or self.Lockdown then
		task.delay(self.AutoCloseTime, function()
			if self.IsOpen then
				self:Close()
			end
		end)
	end

	self.Cooldown = false
end

-- @staticfunction Door:Close
function Door:Close(): ()
	self.Cooldown = true
	self.IsOpen = false
	self:UpdatePrompts()

	if self.DoorFunction.Actuate then
		self.DoorFunction.Actuate(self, false)
	end

	self.Cooldown = false
end

-- @staticfunction Door:Toggle
function Door:Toggle(): ()
	if self.IsOpen then
		self:Close()
	else
		self:Open()
	end
end

-- @staticfunction Door:UpdatePrompts
function Door:UpdatePrompts(): ()
	for _, Prompt in ipairs(self.ProximityPrompts or {}) do
		if Prompt:IsA("ProximityPrompt") then
			Prompt.ActionText = (self.IsOpen and "Close" or "Open")
		end
	end
end

-- @staticfunction Door:SetLockdown
function Door:SetLockdown(Enabled): ()
	self.Lockdown = not not Enabled

	for _, LED in ipairs(self.LEDs.LEDG) do
		LED.Color = (Enabled and BrickColor.new("Gold").Color or Color3.fromRGB(75, 151, 75))
		LED.Material = (Enabled and Enum.Material.Neon or Enum.Material.Metal)
	end

	for _, LED in ipairs(self.LEDs.LEDGLOBAL) do
		LED.Color = (Enabled and BrickColor.new("Gold").Color or Color3.fromRGB(163, 162, 165))
	end

	if Enabled then
		self.WasOpen = self.IsOpen
	end
end

-- @staticfunction Door:IsConnectedLockdownEnabled
-- @description Checks to see if the door is supposed to be locked down.
function Door:IsConnectedLockdownEnabled(): () -> boolean
	if self.ConnectedLockdowns then
		for _, LockdownZone in pairs(self.ConnectedLockdowns) do
			local AttributeName = string.lower(LockdownZone) .. "lockdown"
			if ReplicatedStorage:GetAttribute(AttributeName) == true then
				return true
			end
		end
	end

	return false
end

-- @staticfunction Door:HandleLockdownChange
function Door:HandleLockdownChange(): ()
	local ShouldEnable = self:IsConnectedLockdownEnabled()
	if ShouldEnable and not self.Lockdown then
		self:SetLockdown(true)
		if self.IsOpen then
			self:Close()
		end
	elseif not ShouldEnable and self.Lockdown then
		self:SetLockdown(false)

		if self.WasOpen and not self.IsOpen then
			self:Open()
		end
	end
end

-- @staticfunction Door:CanPlayerAccess
-- @description Checks to see if the player can access the door.
function Door:CanPlayerAccess(Player): () -> boolean
	-- Actors will be allowed to open doors no matter what unless specifically specified.
	if Player.Team.Name == "Actor" and not (self.DoorFunction and self.DoorFunction.NoActor) then
		return true
	end

	-- The player will be able to open any (or most) door(s) with SCP-005.
	if not self.NoSCP005 and Player.Character and Player.Character:FindFirstChild("SCP-005") then
		return true
	end

	local HasBasePermissions = PermissionService:HasPermission(Player, self.Permissions.Regular)
	-- Each door will be able to have its lockdown overridden if conditions are met upon their clearance.
	local HasLockdownPermissions = not self.Lockdown
		or not self.Permissions.Lockdown
		or PermissionService:HasPermission(Player, self.Permissions.Lockdown)

	return HasBasePermissions and HasLockdownPermissions
end

-- @staticfunction Door:PlayerInteracted
function Door:PlayerInteracted(Player): ()
	if self.Cooldown then
		return false
	end

	if self:CanPlayerAccess(Player) then
		self:FlashLEDs("LEDG")
		self:Toggle()
	else
		self:FlashLEDs("LEDR")
		return false
	end
end

-- @staticfunction Door:FlashLEDs
-- @description Flashes the keycard reader lights.
function Door:FlashLEDs(LEDGroup)
	local LEDs = self.LEDs[LEDGroup]
	local CheckLockdown = (LEDGroup == "LEDG")

	if LEDGroup ~= "LEDGLOBAL" then
		for _, LEDObject in ipairs(LEDs) do
			LEDObject.Material = Enum.Material.Neon
			LEDObject.Color = (LEDGroup == "LEDG" and Color3.fromRGB(75, 151, 75) or Color3.fromRGB(117, 0, 0))

			task.delay(1.5, function()
				if CheckLockdown and self.Lockdown then
					LEDObject.BrickColor = BrickColor.new("Gold")
				else
					LEDObject.Material = Enum.Material.Metal
				end
			end)
		end
	end

	for _, LEDObject in ipairs(self.LEDs["LEDGLOBAL"]) do
		LEDObject.Material = Enum.Material.Neon
		LEDObject.Color = (LEDGroup == "LEDG" and Color3.fromRGB(75, 151, 75) or Color3.fromRGB(117, 0, 0))

		task.delay(1.5, function()
			if self.Lockdown then
				LEDObject.BrickColor = BrickColor.new("Gold")
			else
				LEDObject.Color = Color3.fromRGB(163, 162, 165)
			end
		end)
	end
end

-- @staticfunction Door:SetupReaders
function Door:SetupReaders(): ()
	local ReaderNames = {
		["NFCReader"] = {
			HoldDuration = 2,
			RequiresKeycard = false,
		},
	}
	self.LEDs = {
		LEDG = {},
		LEDR = {},
		LEDGLOBAL = {},
	}
	self.ProximityPrompts = {}

	for _, Descendant in ipairs(self.Object:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			for LightName, Array in pairs(self.LEDs) do
				if LightName == Descendant.Name then
					table.insert(Array, Descendant)
				end
			end

			for ReaderName, Data in pairs(ReaderNames) do
				if ReaderName == Descendant.Name then
					local ProximityPrompt = Instance.new("ProximityPrompt")
					ProximityPrompt.ObjectText = self.CustomName or "Door"
					ProximityPrompt.ActionText = (self.IsOpen and "Close" or "Open")
					ProximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
					ProximityPrompt.RequiresLineOfSight = true
					ProximityPrompt.MaxActivationDistance = self.ReaderMaxActivationDistance or 6
					ProximityPrompt.Style = Enum.ProximityPromptStyle.Default
					ProximityPrompt.HoldDuration = Data.HoldDuration or 0
					ProximityPrompt.Parent = Descendant
					ProximityPrompt.Enabled = false

					if not Data.RequiresKeycard then
						ProximityPrompt.Enabled = true
					else
						CollectionService:AddTag(ProximityPrompt, "DoorPrompt")
					end

					table.insert(self.ProximityPrompts, ProximityPrompt)

					local TriggeredConnection = ProximityPrompt.Triggered:Connect(function(Player)
						if self.OnlyOpen and self.IsOpen then
							return
						end

						self:PlayerInteracted(Player)
					end)

					self.Janitor:Add(TriggeredConnection)
					self.Janitor:Add(ProximityPrompt)

					break
				end
			end
		end
	end
end

-- @staticfunction Door:Destroy
function Door:Destroy(): ()
	self.Janitor:Cleanup()
	self.Object = nil
	self.Permissions = nil
	self.LEDs = nil
	self.ProximityPrompts = nil
end

return Door
