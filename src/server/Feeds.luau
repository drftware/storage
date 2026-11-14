--!strict
--[[
	Feeds: the server's security camera feeds (S2-02d, `Feed`'s rules; FeedView draws them).

	A monster's system asks for a feed when it's about to do something the team should see:
	`show` names who watches (the players on that floor), where the camera hangs and what it
	follows each frame (the monster's body, the thing it moves), and every one of those screens
	cuts its corner map to the camera. `close` says the moment happened: their screens play its
	sound through the camera, dim the picture if the moment put the lights out, and cut back to
	the map `Feed.After` seconds later. A feed nobody closes cuts out on its own after `Feed.Most`.

	`hang` finds where a camera goes to watch a spot on a wall: it measures the hall from just off
	the wall (out, along the wall the way it hangs, up) with rays against the floor and leaves the
	numbers to `Feed.hang`. `ready` streams the spot in on those screens ahead of time (the feed
	copies what's there into its picture), so call it as the monster sets off.

	Only the server talks: one RemoteEvent, server to screen, so there's nothing to check.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Feed = require(ReplicatedStorage.Shared.Feed)

local STREAM_WAIT = 4 -- seconds a screen's streaming of the spot may take before we stop waiting
local MEASURE = 24 -- studs each measuring ray runs

export type Shot = {
	players: { Player }, -- who watches
	camera: CFrame, -- where it hangs, looking at what it watches (the world's)
	number: number, -- the number painted on it
	watch: { Instance }, -- what moves in the picture: followed each frame
	within: Instance, -- the floor it's on: what screens copy the still halls from
}

export type Feeds = Brix.System & {
	-- Cuts each of `shot.players`' corner maps to the camera. A number to close it with.
	show: (self: any, shot: Shot) -> number,
	-- The moment happened on feed `id`: play `sound` through the camera, dim the picture if
	-- `dim`, and cut back to the map after `Feed.After`. Nothing for a feed long gone.
	close: (self: any, id: number, sound: string?, dim: boolean) -> (),
	-- Streams the area around `at` in on each of `players`' screens, in the background.
	ready: (self: any, players: { Player }, at: Vector3) -> (),
	-- Where a camera hangs to watch `spot` (its look out into the hall, its right along the wall),
	-- to its right if `side` is 1, left if -1, measured against `within`'s parts only.
	hang: (self: any, spot: CFrame, side: number, within: Instance, ignore: { Instance }) -> CFrame,
}

local Feeds = {}

function Feeds.new(): Feeds
	local remote: RemoteEvent? = nil
	local open: { [number]: { Player } } = {} -- each feed still showing, who watches it
	local count = 0

	local system = { name = "Feeds" } :: any

	function system.start(_: any, _context: Brix.Context)
		local r = Instance.new("RemoteEvent")
		r.Name = Feed.Remote
		r.Parent = ReplicatedStorage
		remote = r
	end

	function system.stop(_: any)
		local r = remote
		if r then
			r:Destroy()
		end
		remote = nil
		table.clear(open)
	end

	function system.show(_: any, shot: Shot): number
		count += 1
		local id = count
		local r = remote
		if not r then
			return id
		end
		local watching: { Player } = {}
		for _, player in shot.players do
			if player.Parent == Players then
				table.insert(watching, player)
				r:FireClient(player, "Show", id, shot.camera, shot.number, shot.watch, shot.within)
			end
		end
		open[id] = watching
		task.delay(Feed.Most + 1, function()
			open[id] = nil -- every screen has cut it out on its own by now
		end)
		return id
	end

	function system.close(_: any, id: number, sound: string?, dim: boolean)
		local watching = open[id]
		local r = remote
		if not (watching and r) then
			return
		end
		open[id] = nil
		for _, player in watching do
			if player.Parent == Players then
				r:FireClient(player, "Close", id, sound or "", dim)
			end
		end
	end

	function system.ready(_: any, players: { Player }, at: Vector3)
		for _, player in players do
			task.spawn(function()
				-- pcall: it errors if the player has left meanwhile; a feed without it still shows
				pcall(player.RequestStreamAroundAsync, player, at, STREAM_WAIT)
			end)
		end
	end

	function system.hang(
		_: any,
		spot: CFrame,
		side: number,
		within: Instance,
		ignore: { Instance }
	): CFrame
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { within }
		local look, right = spot.LookVector, spot.RightVector * (if side < 0 then -1 else 1)
		local from = spot.Position + look * Feed.WallGap
		local function free(origin: Vector3, direction: Vector3): number
			local reach = MEASURE
			while true do
				local hit = Workspace:Raycast(origin, direction * reach, params)
				if not hit then
					return math.huge
				end
				-- the halls' walls answer through their invisible collision boxes (the pieces you
				-- see don't answer rays), so every hit counts but the bodies and things it watches
				local inst = hit.Instance
				local skip = false
				for _, other in ignore do
					if inst:IsDescendantOf(other) then
						skip = true
					end
				end
				if not skip then
					return (hit.Position - origin).Magnitude
				end
				-- through a body or the thing it watches: carry on past it
				local gone = (hit.Position - origin).Magnitude + 0.05
				origin += direction * gone
				reach -= gone
				if reach <= 0 then
					return math.huge
				end
			end
		end
		local outFree = free(from, look)
		local along = from + look * math.min(Feed.OutLeast, math.max(0, outFree - Feed.WallGap))
		local s, u, o = Feed.hang(outFree, free(along, right), free(from, Vector3.yAxis))
		local camera = from + right * s + Vector3.yAxis * u + look * o
		local target = spot.Position + look * Feed.AimOut + Vector3.yAxis * Feed.AimUp
		-- a corner between it and what it watches (the hall turns): in front of the corner
		local line = camera - target
		local clear = free(target, line.Unit)
		if clear < line.Magnitude then
			camera = target + line.Unit * math.max(clear - Feed.WallGap, Feed.WallGap)
		end
		return CFrame.lookAt(camera, target)
	end

	return system :: Feeds
end

return Feeds
