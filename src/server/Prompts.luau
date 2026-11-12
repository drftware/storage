--!strict
--[[
	Prompts: the buttons the server puts in the world (ProximityPrompts), made one way. The doors
	(Doors), ladders, crawls, saws, a tool on a floor ("Pick up"), a kept friend's "Cut free"
	(KeptPlayers) and the test hall's posts use them.

	Each is drawn on every screen by the client's ButtonView in the one look `WorldButton`
	describes (L-19a, D-114): `Style` Custom, so Roblox's own box never shows. A button's name shows
	only where it's news, so most are made without one.

	A refusal reaches only the player who pressed: their screen shakes the button and shows the
	refusal's few words in red for a beat ("Padlocked", "Hands full"), then the verb comes back.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kept = require(ReplicatedStorage.Shared.Kept)
local WorldButton = require(ReplicatedStorage.Shared.WorldButton)

local Prompts = {}

--- Whether `player` is wrapped and kept in a unit (L-07a): every prompt in the world refuses them,
--- on the server, whatever their screen shows. Its own screen hides the prompts too.
function Prompts.wrapped(player: Player): boolean
	return player:GetAttribute(Kept.Attribute) == true
end

-- A post is touched from about a door's reach.
local POST_REACH = 8

export type Spec = {
	-- the thing's name, only where it's news: which unit lies behind a wall, who is under the film,
	-- which tool lies there. Nil where it's plain to see (a door's number is painted on it).
	objectText: string?,
	actionText: string,
	key: Enum.KeyCode,
	pad: Enum.KeyCode,
	reach: number,
	hold: number?, -- seconds to hold (0 or nil: a tap)
}

-- A prompt on `at`. It needs a clear line from the player, so a shut door hides what's behind it.
function Prompts.make(at: Attachment, spec: Spec): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.Style = Enum.ProximityPromptStyle.Custom -- drawn by the client's ButtonView
	p.ObjectText = spec.objectText or ""
	p.ActionText = spec.actionText
	p.KeyboardKeyCode = spec.key
	p.GamepadKeyCode = spec.pad
	p.HoldDuration = spec.hold or 0
	p.MaxActivationDistance = spec.reach
	p.RequiresLineOfSight = true
	p.Parent = at
	return p
end

-- The remote a refusal travels on, made the first time one is needed.
local refused: RemoteEvent? = nil
local function remote(): RemoteEvent
	local had = refused
	if had then
		return had
	end
	local folder = ReplicatedStorage:FindFirstChild(WorldButton.RemoteFolder)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = WorldButton.RemoteFolder
		folder.Parent = ReplicatedStorage
	end
	local found = folder:FindFirstChild(WorldButton.Remote)
	local r: RemoteEvent
	if found and found:IsA("RemoteEvent") then
		r = found
	else
		r = Instance.new("RemoteEvent")
		r.Name = WorldButton.Remote
		r.Parent = folder
	end
	refused = r
	return r
end

--- The remote is there from the start, so a screen finds it before its first refusal.
function Prompts.ready()
	remote()
end

--[[
	Returns a function that refuses `player`'s press on `p` with `text` (a few words naming the
	fix): their screen alone shakes the button and shows the words in red for a beat.
]]
function Prompts.refuser(p: ProximityPrompt): (text: string, player: Player) -> ()
	return function(text: string, player: Player)
		if p.Parent and player.Parent then
			remote():FireClient(player, p, text)
		end
	end
end

-- A test post's one prompt on `at`: E (X on a pad) unless `key` says otherwise.
function Prompts.post(
	at: Attachment,
	objectText: string,
	actionText: string,
	key: Enum.KeyCode?,
	pad: Enum.KeyCode?
): ProximityPrompt
	return Prompts.make(at, {
		objectText = objectText,
		actionText = actionText,
		key = key or Enum.KeyCode.E,
		pad = pad or Enum.KeyCode.ButtonX,
		reach = POST_REACH,
	})
end

return Prompts
