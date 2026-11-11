--!strict
--[[
	PadlockView: the building's padlock coming for someone kept (L-07e), on every screen. The
	moment: alone in the dark, you hear a hand at your door working keys in a padlock, and a
	countdown comes up; down the hall your friends see your name counting down too, and the last
	of them sprints. Then the bolt shoots, the shackle clicks shut, and the dark gets worse. Dead by
	Daylight's hook stages are the precedent: wait too long and it gets worse, and everyone can
	see the clock.

	The server (KeptPlayers) owns the clock and says only two things, on the kept player:
	`Kept.WarnAttribute`, the server time the padlock goes on while its warning runs, and
	`Kept.PadlockedAttribute` once it's on. From those, every screen plays the rest itself:

	- The hand at the door (`Kept.Handlings`): takes of keys in a padlock, closer together and
	  louder toward the end, from the hall side of the kept player's door (their `Kept.InsideValue`)
	  for anyone near, `Kept.HandleReach`. Each one trembles the kept player's own view a little.
	- The kept player's own line, high in the middle: "Padlock in 20", beating each second, red
	  for the last five; at the click (DoorSound's PadlockShut, `DoorSound.lockCues`) their view
	  jolts (`Kept.ClickKick`), a low hit sounds (`Kept.Dread`) and the line punches to
	  "Padlocked", staying while it's on.
	- Friends' lines under the top bar, one each: "Sam: padlock in 12", then "Sam: padlocked"
	  with the hit, quieter (`Kept.DreadFriends`), wherever they are.

	The bolt and the click themselves are the door's (DoorSounds hears the padlock go on). A line
	fades as its padlock is cut off or its friend is let out. Only lines showing are stepped.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local DoorSound = require(ReplicatedStorage.Shared.StorageUnit.DoorSound)
local Kept = require(ReplicatedStorage.Shared.Kept)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Tools = require(ReplicatedStorage.Shared.Tools)

local INK = Color3.fromRGB(232, 226, 214) -- the buttons' warm off-white (CaughtView)
local RED = Color3.fromRGB(226, 70, 56) -- the last seconds, and the padlock on
local FRIEND = "#6EBAFF" -- the corner map's friend blue (BangMarks), for a friend's name
local OWN_SIZE = 32 -- the kept player's line: near the "Caught" headline's 34
local OWN_Y = 0.2 -- its middle, a share of the screen's height: above the door, in the eye
local FRIEND_SIZE = 20 -- a friend's line
local FRIEND_TOP = 10 -- pixels under the top bar to the first friend's line
local RED_FROM = 5 -- seconds left from which the count goes red
local BEAT = 1.14 -- a line's scale as its second ticks over, settling back
local PUNCH = 1.35 -- and as the padlock clicks on
local SETTLE = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLAM = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FADE_IN = 0.25 -- seconds a line takes to come up
local FADE_OUT = 0.5 -- and to go
local HAND_UP = 1.5 -- studs up the door the hand works, on the hall side
local HAND_OUT = 0.6 -- studs out from the door into the hall

-- Seconds after the padlock goes on that its shackle snaps shut (DoorSounds plays it then).
local CLICK_AT = (function(): number
	for _, c in DoorSound.lockCues(true) do
		if c.sound == "PadlockShut" then
			return c.at
		end
	end
	return 0
end)()

-- Someone kept, as this screen follows them: their line (the kept player's own for this
-- player), how far it's faded in, the clock's seconds left as last stepped (for the
-- handlings), the second it last showed, whether their padlock is on, and seconds since it went
-- on (-1 before the click lands).
type Watch = {
	player: Player,
	label: TextLabel,
	stroke: UIStroke,
	scale: UIScale,
	own: boolean,
	shown: number, -- 0 hidden to 1 up
	lastLeft: number?,
	second: number,
	padlocked: boolean,
	since: number,
}

local function makeLabel(size: number): (TextLabel, UIStroke, UIScale)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	l.TextSize = size
	l.TextColor3 = INK
	l.TextTransparency = 1
	l.RichText = true
	l.Visible = false
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = l
	local scale = Instance.new("UIScale")
	scale.Parent = l
	return l, stroke, scale
end

local PadlockView = {}

-- The system; `kick` jolts this player's view (CameraShake's).
function PadlockView.new(kick: (amount: number) -> ()): Brix.System
	local me = Players.LocalPlayer
	local watches: { [Player]: Watch } = {}
	local active: { [Watch]: true } = {} -- watches with a line up or coming
	local hooks: { [Player]: { RBXScriptConnection } } = {}
	local connections: { RBXScriptConnection } = {}
	local ownGui: ScreenGui? = nil
	local friendList: Frame? = nil

	-- The take of `h` at the hall side of `player`'s door, if their unit has streamed in here.
	local function handle(w: Watch, h: Kept.Handling)
		local found = w.player:FindFirstChild(Kept.InsideValue)
		local unit = if found and found:IsA("ObjectValue") then found.Value else nil
		if not (unit and unit:IsA("Model") and unit:FindFirstChild("DoorOrigin", true)) then
			return
		end
		local take = Kept.Handle[h.take]
		if not take then
			return
		end
		local at = Instance.new("Attachment")
		at.Name = "PadlockHand"
		at.WorldPosition = (RollUpDoor.frame(unit) * CFrame.new(0, HAND_UP, -HAND_OUT)).Position
		at.Parent = Workspace.Terrain
		Tools.play({
			id = take.id,
			from = take.from,
			length = take.length,
			volume = take.volume * h.loud,
			pitch = take.pitch,
		}, at, Kept.HandleReach)
		task.delay(take.length / take.pitch + 1, function()
			at:Destroy()
		end)
		if w.own then
			kick(Kept.HandleKick)
		end
	end

	-- The low hit as a padlock clicks on: full for the one shut in, quieter for friends.
	local function dread(own: boolean)
		local d = Kept.Dread
		Tools.play({
			id = d.id,
			from = d.from,
			length = d.length,
			volume = d.volume * (if own then 1 else Kept.DreadFriends),
			pitch = d.pitch,
		}, SoundService, 40)
	end

	local function beat(w: Watch, to: number)
		w.scale.Scale = to
		TweenService:Create(w.scale, if to >= PUNCH then SLAM else SETTLE, { Scale = 1 }):Play()
	end

	local function nameOf(w: Watch): string
		if w.own then
			return ""
		end
		return `<font color="{FRIEND}">{w.player.DisplayName}</font>: `
	end

	-- `w`'s line now, from the server's word on its player: what it says, and whether it's up.
	local function refresh(w: Watch, now: number): boolean
		local kept = w.player:GetAttribute(Kept.Attribute) == true
		local due = w.player:GetAttribute(Kept.WarnAttribute)
		local padlocked = w.player:GetAttribute(Kept.PadlockedAttribute) == true
		if padlocked and not w.padlocked then
			w.since = 0 -- the bolt's going: the click lands at CLICK_AT
		elseif not padlocked then
			w.since = -1
		end
		w.padlocked = padlocked
		local label = w.label
		if padlocked and kept and w.since >= CLICK_AT then
			label.Text = if w.own then "Padlocked" else `{nameOf(w)}padlocked`
			label.TextColor3 = RED
		elseif type(due) == "number" and kept then
			local left = due - now
			local s = Kept.seconds(left)
			if s ~= w.second then
				if w.second >= 0 and w.shown > 0 then
					beat(w, BEAT)
				end
				w.second = s
			end
			local count = if s > 0 then `padlock in {s}` else "padlock"
			label.Text = if w.own
				then (if s > 0 then `Padlock in {s}` else "Padlock")
				else `{nameOf(w)}{count}`
			label.TextColor3 = if s <= RED_FROM then RED else INK
			-- the hand at the door, as the clock passes each handling (the last, after a long
			-- frame); never on the first look, nor as the clock comes back after the door was up
			local before = w.lastLeft
			if before == nil then
				w.lastLeft = left
			elseif left < before then
				local hs = Kept.handlings(before, left)
				if #hs > 0 then
					handle(w, hs[#hs])
				end
				w.lastLeft = left
			end
		elseif not (padlocked and kept) then
			return false
		end
		return true
	end

	local function wake(player: Player)
		local w = watches[player]
		if w then
			active[w] = true
		end
	end

	local function watch(player: Player)
		if watches[player] then
			return
		end
		local own = player == me
		local label, stroke, scale = makeLabel(if own then OWN_SIZE else FRIEND_SIZE)
		label.Name = player.Name
		if own then
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = UDim2.fromScale(0.5, OWN_Y)
			label.Size = UDim2.new(0.9, 0, 0, OWN_SIZE + 12)
			label.Parent = ownGui
		else
			label.Size = UDim2.fromOffset(0, FRIEND_SIZE + 6)
			label.AutomaticSize = Enum.AutomaticSize.X
			label.Parent = friendList
		end
		-- a padlock already on when this screen first looks clicked shut long ago: no click now
		local on = player:GetAttribute(Kept.PadlockedAttribute) == true
		local w: Watch = {
			player = player,
			label = label,
			stroke = stroke,
			scale = scale,
			own = own,
			shown = 0,
			second = -1,
			padlocked = on,
			since = if on then CLICK_AT else -1,
		}
		watches[player] = w
		local function poke()
			wake(player)
		end
		hooks[player] = {
			player:GetAttributeChangedSignal(Kept.WarnAttribute):Connect(poke),
			player:GetAttributeChangedSignal(Kept.PadlockedAttribute):Connect(poke),
			player:GetAttributeChangedSignal(Kept.Attribute):Connect(poke),
		}
		poke()
	end

	local function unwatch(player: Player)
		local w = watches[player]
		if w then
			active[w] = nil
			w.label:Destroy()
			watches[player] = nil
		end
		local list = hooks[player]
		if list then
			for _, c in list do
				c:Disconnect()
			end
			hooks[player] = nil
		end
	end

	return {
		name = "PadlockView",
		start = function(_: any, _context: Brix.Context)
			local ids = { Kept.Dread.id }
			for _, take in Kept.Handle do
				table.insert(ids, take.id)
			end
			task.spawn(SoundPrimer.prime, ids)
			local gui = me:WaitForChild("PlayerGui")
			local own = Instance.new("ScreenGui")
			own.Name = "Padlock"
			own.ResetOnSpawn = false
			own.IgnoreGuiInset = true
			own.DisplayOrder = 32 -- over the kept screen's black and its Bang button
			own.Parent = gui
			ownGui = own
			local lines = Instance.new("ScreenGui")
			lines.Name = "PadlockLines"
			lines.ResetOnSpawn = false
			lines.DisplayOrder = 6 -- just over the gate clock's bar
			local list = Instance.new("Frame")
			list.Name = "Lines"
			list.AnchorPoint = Vector2.new(0.5, 0)
			list.Position = UDim2.new(0.5, 0, 0, FRIEND_TOP)
			list.Size = UDim2.fromScale(0.8, 0)
			list.AutomaticSize = Enum.AutomaticSize.Y
			list.BackgroundTransparency = 1
			list.Parent = lines
			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.Padding = UDim.new(0, 2)
			layout.SortOrder = Enum.SortOrder.Name
			layout.Parent = list
			lines.Parent = gui
			friendList = list
			for _, player in Players:GetPlayers() do
				watch(player)
			end
			table.insert(connections, Players.PlayerAdded:Connect(watch))
			table.insert(connections, Players.PlayerRemoving:Connect(unwatch))
		end,
		step = function(_: any, dt: number)
			if next(active) == nil then
				return
			end
			local now = Workspace:GetServerTimeNow()
			for w in active do
				local was = w.since
				if w.since >= 0 then
					w.since += dt
				end
				local up = refresh(w, now)
				-- the click: the shackle shut, on every screen
				if was >= 0 and was < CLICK_AT and w.since >= CLICK_AT and w.padlocked then
					beat(w, PUNCH)
					dread(w.own)
					if w.own then
						kick(Kept.ClickKick)
					end
				end
				local label = w.label
				if up then
					w.shown = math.min(w.shown + dt / FADE_IN, 1)
				else
					w.shown = math.max(w.shown - dt / FADE_OUT, 0)
				end
				label.Visible = w.shown > 0
				label.TextTransparency = 1 - w.shown
				w.stroke.Transparency = 1 - 0.8 * w.shown
				if not up and w.shown <= 0 then
					-- gone: ready for their next keep
					active[w] = nil
					w.lastLeft, w.second, w.since = nil, -1, -1
					w.padlocked = false
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for player in watches do
				unwatch(player)
			end
			if ownGui then
				ownGui:Destroy()
				ownGui = nil
			end
			if friendList then
				local g = friendList:FindFirstAncestorOfClass("ScreenGui")
				if g then
					g:Destroy()
				end
				friendList = nil
			end
		end,
	}
end

return PadlockView
