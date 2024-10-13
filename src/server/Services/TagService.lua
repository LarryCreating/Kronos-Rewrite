--[[
    @classmod TagService.lua
    @author LarryCreating
    @date 07/10/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local import = require(ReplicatedStorage.Packages.import)

local Weaver = import("packages/Weaver")

local TagService = Weaver.CreateService({
	Name = "TagService",
	Client = {},
})

-- @staticfunction TagService:BindToTag
function TagService:BindToTag(Tag, Callback): ()
	task.spawn(function()
		for _, Item in ipairs(CollectionService:GetTagged(Tag)) do
			task.spawn(function()
				Callback(Item)
			end)
		end
	end)

	return CollectionService:GetInstanceAddedSignal(Tag):Connect(Callback)
end

-- @staticfunction TagService:BindToTagRemoved
function TagService:BindToTagRemoved(Tag, Callback): ()
	return CollectionService:GetInstanceRemovedSignal(Tag):Connect(Callback)
end

return TagService
