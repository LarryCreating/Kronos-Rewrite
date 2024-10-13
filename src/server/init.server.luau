local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Packages.import)

import.setAliases({
	packages = ReplicatedStorage.Packages,
	services = script.Services,
	shared = ReplicatedStorage.Shared,
	middleware = script.Middleware,
})

import.setConfig({
	scriptAlias = "@",
	useWaitForChild = false,
	waitForChildTimeout = 5,
})

local Weaver = import("packages/Weaver")
local Promise = import("packages/Promise")
local TestEZ = import("packages/TestEZ")
local Services = import("services")

local Runtime = os.clock()

Weaver.AddServices(Services)

Promise.try(Weaver.Start)
	:andThen(function()
		print(string.format("[Server] Took %.4f seconds to initialize services.", os.clock() - Runtime))
	end)
	:catch(warn)

TestEZ.run(Services, function(CallbackReturn)
	print(CallbackReturn)
end)
