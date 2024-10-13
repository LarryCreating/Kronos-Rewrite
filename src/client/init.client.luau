local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Packages.import)

import.setAliases({
	packages = ReplicatedStorage.Packages,
	controllers = script.Controllers,
})

import.setConfig({
	scriptAlias = "@",
	useWaitForChild = true,
	waitForChildTimeout = 5,
})

local Weaver = import("packages/Weaver")
local Promise = import("packages/Promise")
local Controllers = import("controllers")

local Runtime = os.clock()

Weaver.AddControllers(Controllers)

Promise.try(Weaver.Start)
	:andThen(function(): ()
		print(string.format("[Client] Took %.4f seconds to initialize controllers.", os.clock() - Runtime))
	end)
	:catch(warn)
