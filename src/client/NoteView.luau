--!strict
--[[
	NoteView: makes sure every code note on this screen shows its digits. The notes are written in
	Kalam, a hand Roblox ships but loads on first use, and a note that arrives before its hand has
	loaded can stay blank until its writing is redrawn (docs/STUDIO.md, "A SurfaceGui draws on an
	invisible part"). So this client loads Kalam as it starts, before anyone can reach a unit, and
	redraws any note that streamed in while it loaded. Notes arriving after that draw at once.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)

local NoteView = {}

-- The note's writing, off and on again, so it lays out its text in the loaded hand.
local function redraw(notes: { Instance })
	local guis: { SurfaceGui } = {}
	for _, note in notes do
		local gui = note:FindFirstChild("Digits", true)
		if gui and gui:IsA("SurfaceGui") and gui.Enabled then
			gui.Enabled = false
			table.insert(guis, gui)
		end
	end
	if #guis == 0 then
		return
	end
	task.wait() -- a frame off, or the toggle is never seen
	for _, gui in guis do
		if gui.Parent then
			gui.Enabled = true
		end
	end
end

function NoteView.new(): Brix.System
	local loading: thread? = nil

	return {
		name = "NoteView",
		start = function(_: any, _context: Brix.Context)
			loading = task.spawn(function()
				-- Measuring text in a font loads it: the async measure waits for its files.
				local params = Instance.new("GetTextBoundsParams")
				params.Text = "0123456789 _"
				params.Font = Font.new(Elevator.Specs.Note.Font, Enum.FontWeight.Bold)
				params.Size = 48
				local ok, err = pcall(TextService.GetTextBoundsAsync, TextService, params)
				if not ok then
					warn(`NoteView: Kalam didn't load ({err}); a note may show blank until redrawn`)
				end
				redraw(CollectionService:GetTagged(Elevator.NoteTag))
				loading = nil
			end)
		end,
		stop = function(_: any)
			if loading and coroutine.status(loading) ~= "dead" then
				task.cancel(loading)
			end
			loading = nil
		end,
	}
end

return NoteView
