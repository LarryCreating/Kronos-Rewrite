local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Packages.import)

import.setAliases({
	packages = ReplicatedStorage.Packages,
	services = script.Services,
	shared = ReplicatedStorage.Shared,
})

import.setConfig({
	scriptAlias = "@",
	useWaitForChild = false,
	waitForChildTimeout = 5,
})

local Knit = import("packages/Knit")
local Promise = import("packages/Promise")
local TestEZ = import("packages/TestEZ")
local Services = import("services")

local Runtime = os.clock()

Promise.new(function(resolve)
	for i, Service in ipairs(Services:GetDescendants()) do
		if Service:IsA("ModuleScript") and string.find(Service.Name, "Service") then
			require(Service)
		end
	end

	resolve()
end):catch(warn)

Knit:Start()
	:andThen(function()
		print(string.format("[Server] Took %.4f seconds to initialize services.", os.clock() - Runtime))
	end)
	:catch(warn)

TestEZ.run(Services, function(CallbackReturn)
	print(CallbackReturn)
end)
