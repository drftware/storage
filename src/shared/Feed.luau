--!strict
--[[
	Feed: the security camera feed (S2-02d, the owner's idea, Nov 14), as Five Nights at Freddy's
	cameras show the animatronic standing where it wasn't. When a monster is about to do something
	the team should see, the corner map on every screen on that floor cuts to a security camera's
	grainy picture of it: a cold tint, choppy frames, the camera's number and a blinking red dot.
	The thing happens on camera, then static and the map is back. No words: the picture says it.

	The first user is the Mannequin throwing the breaker (Keepers): the camera cuts in as it walks
	the last steps to the box and shows its hand on the lever and the clunk. Any monster can use it
	later: a camera hangs where the server says, watches what the server names, and cuts out a
	little after the server says the moment happened (`Feeds` on the server, `FeedView` on screens).

	Pure: the numbers, and where a camera hangs on a wall's hall (`hang`), so Lune checks it
	(tests/feed.spec.luau).
]]

local Feed = {}

-- The remote the server tells screens through (ReplicatedStorage, made by `Feeds`): only ever
-- server to screen, so nothing comes back to check.
Feed.Remote = "Feed"

-- Timing: what the player watches.
Feed.Lead = 2.4 -- seconds of its walk left when the camera cuts in: a few stiff steps, then the hand
Feed.After = 1.7 -- seconds the feed stays after the moment: the dark hall and it standing there
Feed.Most = 8 -- the longest a feed runs if the moment never comes (a light held it, it turned away)
Feed.SnowIn = 0.22 -- seconds of snow as it cuts in: a jolt, not a wait
Feed.SnowOut = 0.4 -- seconds of snow as it cuts out, before the map comes back
Feed.Fps = 12 -- the picture's frames a second: an old camera's choppy motion, cheap for a phone
Feed.Pop = 0.16 -- seconds the corner window takes to grow from the map's square to the feed's

-- The picture: bigger than the map's square so a phone reads it, 4:3 like an old camera.
Feed.Grow = 1.55 -- the feed's width over the map's side
Feed.Aspect = 0.75 -- its height over its width
Feed.Fov = 52 -- degrees up and down: a wide security lens, the body head to foot at the box
Feed.Reach = 30 -- studs ahead of the camera the screen copies the halls from into the picture
Feed.Tint = { 168, 204, 214 } -- the picture's cold cast, over its own flat light
Feed.Ambient = { 118, 126, 130 } -- its light everywhere (the camera's own: halls lit or not)
Feed.Light = { 210, 222, 226 } -- its light from above the camera's shoulder
Feed.Dim = 0.42 -- what's left of its light after the moment, if the moment puts the halls out
Feed.Grain = "rbxassetid://97715200966482" -- art/feed: specks and scanlines, tiled over it
Feed.Snow = "rbxassetid://111492371127434" -- art/feed: a dead channel's snow, cutting in and out
Feed.GrainSee = 0.12 -- the grain's transparency: strong, it's an old camera
Feed.Dot = { 232, 38, 38 } -- the recording dot, blinking
Feed.Blink = 1 -- seconds per blink, on half of it

-- Its sounds (Pro Sound Effects, free on the Creator Store), flat in your ears, not in the hall.
Feed.InSound = "rbxassetid://9125999159" -- a burst of interference as it cuts in
Feed.InVolume = 0.55
Feed.BedSound = "rbxassetid://9126000057" -- static under the picture, quiet and thin, looped
Feed.BedVolume = 0.14
Feed.OutSound = "rbxassetid://9126000747" -- the burst as it cuts out
Feed.OutVolume = 0.6
Feed.MomentVolume = 0.9 -- the moment's own sound through the camera's tinny speaker

-- Where a camera hangs (`hang`): high in a corner of the hall the thing it watches faces, off to
-- one side along the wall, looking back at it, so a body standing at the wall shows its side and
-- the hand it reaches with rather than its back.
Feed.WallGap = 0.8 -- studs a camera keeps off any wall or ceiling
Feed.OutLeast = 4 -- studs out from the wall at the least, or the picture is all wall
Feed.OutMost = 9 -- and at the most: farther, and the thing it watches is a speck at phone size
Feed.SideMost = 6 -- studs along the wall at the most
Feed.UpLeast = 1.5 -- studs above the spot at the least, so it looks down as cameras do
Feed.UpMost = 4.5 -- and at the most
Feed.AimOut = 1.3 -- studs out from the wall it aims at: between the thing and whoever stands there
Feed.AimUp = -0.4 -- studs above the spot it aims at (below: the hand and the body's middle)

--- Where a camera hangs to watch a spot on a wall, from how much room there is from just off that
--- wall: `outFree` studs out across the hall, `sideFree` along the wall the way it hangs, and
--- `upFree` up to the ceiling (math.huge for none found). Returns the camera's place from the spot
--- as studs along the wall, up and out. It keeps `WallGap` off every surface it measured, sits
--- `OutLeast` out at the least even in a narrow hall (a camera on the far wall), and hangs straight
--- out from the spot when there's no room along the wall.
function Feed.hang(outFree: number, sideFree: number, upFree: number): (number, number, number)
	local function room(free: number): number
		if free ~= free then
			return 0 -- not a number: no room measured
		end
		return math.max(0, free - Feed.WallGap)
	end
	local out = math.clamp(room(outFree), Feed.OutLeast, Feed.OutMost)
	local side = math.min(room(sideFree), Feed.SideMost)
	local up = math.clamp(room(upFree), Feed.UpLeast, Feed.UpMost)
	return side, up, out
end

--- The number painted on a camera, 1 to 16, from where it hangs on its floor: the same spot reads
--- the same number every time it's shown.
function Feed.number(x: number, z: number): number
	if x ~= x or z ~= z or math.abs(x) == math.huge or math.abs(z) == math.huge then
		return 1
	end
	return 1 + (math.floor(math.abs(x * 7 + z * 13)) % 16)
end

--- Whether to cut in now: a walker `left` studs from where it does the thing, at `pace` studs a
--- second, has `Lead` seconds or less to go. A walker standing still (a light holding it) cuts in
--- only once it's there.
function Feed.due(left: number, pace: number): boolean
	if left ~= left then
		return false
	end
	if pace <= 0 then
		return left <= 0.5
	end
	return left <= pace * Feed.Lead
end

return Feed
