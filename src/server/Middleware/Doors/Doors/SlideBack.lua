local TweenService = game:GetService("TweenService")

function Weld(o1, o2)
	if o1:IsA("BasePart") and o2:IsA("BasePart") then
		local w = Instance.new("Weld")
		w.Parent = o1
		w.C0 = o1.CFrame:Inverse() * CFrame.new(o1.CFrame.p)
		w.C1 = o2.CFrame:Inverse() * CFrame.new(o1.CFrame.p)
		w.Part0 = o1

		w.Part1 = o2

		o2.Anchored = false
	end
end

return {
	Name = "SlideBack",
	Actuate = function(self, Open)
		local TimeToComplete

		local SoundName = Open and "OpenSound" or "CloseSound"

		if self[SoundName] and self[SoundName]:IsA("Sound") then
			self[SoundName]:Play()
		end

		if not Open then
			for _, Object in ipairs(self.Object.Doors:GetChildren()) do
				TimeToComplete = (Object.Main.Size.Z / self.MoveSpeedDivider)

				TweenService:Create(Object.Main, TweenInfo.new(TimeToComplete), { CFrame = Object.Main.OrigPos.Value })
					:Play()
			end

			task.wait(TimeToComplete)

			return true
		else
			for _, Object in ipairs(self.Object.Doors:GetChildren()) do
				TimeToComplete = (Object.Main.Size.Z / self.MoveSpeedDivider)

				TweenService:Create(
					Object.Main,
					TweenInfo.new(TimeToComplete),
					{ CFrame = Object.Main.OrigPos.Value * CFrame.new(0, 0, Object.Main.Size.Z) }
				):Play()
			end

			task.wait(TimeToComplete)

			return true
		end
	end,
	Setup = function(self)
		if
			self.OpenSound
			and tonumber(self.OpenSound)
			and self.Object.Doors
			and self.Object.Doors.Door
			and self.Object.Doors.Door.Main
		then
			local OpenSound = Instance.new("Sound")
			OpenSound.SoundId = "rbxassetid://" .. tostring(self.OpenSound)
			OpenSound.Name = "Open"
			OpenSound.Parent = self.Object.Doors.Door.Main

			self.OpenSound = OpenSound
		end

		if
			self.CloseSound
			and tonumber(self.CloseSound)
			and self.Object.Doors
			and self.Object.Doors.Door
			and self.Object.Doors.Door.Main
		then
			local CloseSound = Instance.new("Sound")
			CloseSound.SoundId = "rbxassetid://" .. tostring(self.CloseSound)
			CloseSound.Name = "Close"
			CloseSound.Parent = self.Object.Doors.Door.Main

			self.CloseSound = CloseSound
		end

		for _, Door in pairs(self.Object.Doors:GetChildren()) do
			local OriginalPosition = Instance.new("CFrameValue")
			OriginalPosition.Name = "OrigPos"
			OriginalPosition.Value = Door.Main.CFrame
			OriginalPosition.Parent = Door.Main

			for _, Child in pairs(Door:GetChildren()) do
				if Child ~= Door.Main and Child:IsA("BasePart") then
					Weld(Door.Main, Child)
				end
			end
		end

		self:SetObjectCollisionGroup("Doors")
	end,
}
