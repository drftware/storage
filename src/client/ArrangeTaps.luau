--!strict
--[[
	Arrange's phone taps (S5-03j4b; the plan's "Phone" column): a lift's light tap, a step's tick,
	a set-down's firm tap. Each `Feedback.Taps` entry is one HapticEffect with a custom waveform
	(a pulse of its strength and length), made once and played again and again.

	Only while the last input was a finger: a mouse has nothing to feel, and a gamepad's rumble on
	every grid step would be a buzz. HapticEffect (2025) is checked on create.roblox.com (STUDIO.md,
	"Phone taps"); where a phone has no haptics, Play does nothing.

	ArrangeHand calls `tap`; ArrangeView makes one and calls `destroy` as Arrange closes (the
	effects are made again on the next open's first tap).
]]
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Feedback = require(ReplicatedStorage.Shared.Home.Feedback)

export type ArrangeTaps = {
	-- Plays `tap` on a phone held now; nothing otherwise.
	tap: (tap: Feedback.Tap) -> (),
	destroy: () -> (),
}

local ArrangeTaps = {}

function ArrangeTaps.new(): ArrangeTaps
	local folder: Folder? = nil
	local made: { [Feedback.Tap]: HapticEffect } = {}
	local ok = true -- off for good if this Roblox can't make one

	local function effectFor(tap: Feedback.Tap): HapticEffect?
		local e = made[tap]
		if e or not ok then
			return e
		end
		local into = folder
		if not into then
			local f = Instance.new("Folder")
			f.Name = "ArrangeTaps"
			f.Parent = Workspace.CurrentCamera
			folder, into = f, f
		end
		local good, result = pcall(function(): HapticEffect
			local h = Instance.new("HapticEffect")
			h.Type = Enum.HapticEffectType.Custom
			local ms = tap.length * 1000
			h:SetWaveformKeys({
				FloatCurveKey.new(0, tap.strength, Enum.KeyInterpolationMode.Constant),
				FloatCurveKey.new(ms, 0, Enum.KeyInterpolationMode.Constant),
			})
			h.Parent = into
			return h
		end)
		if not good then
			ok = false
			warn(`ArrangeTaps: no phone taps here ({result})`)
			return nil
		end
		made[tap] = result
		return result
	end

	local function tap(t: Feedback.Tap)
		if UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch then
			return
		end
		local e = effectFor(t)
		if e then
			e:Play()
		end
	end

	return {
		tap = tap,
		destroy = function()
			local f = folder
			if f then
				f:Destroy()
				folder = nil
			end
			table.clear(made)
		end,
	}
end

return ArrangeTaps
