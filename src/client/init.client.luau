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

local Knit = import("packages/Knit")
local Promise = import("packages/Promise")
local Controllers = import("controllers")

local Runtime = os.clock()

Promise.new(function(resolve)
	for i, Controller in ipairs(Controllers:GetDescendants()) do
		if Controller:IsA("ModuleScript") and string.find(Controller.Name, "Controller") then
			require(Controller)
		end
	end

	resolve()
end):catch(warn)

Knit.Start()
	:andThen(function()
		print(string.format("[Client] Took %.4f seconds to initialize controllers.", os.clock() - Runtime))
	end)
	:catch(warn)
