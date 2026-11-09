--!strict
-- lune run tests/hands.spec
-- What you hold kept out of walls (L-13b2c2): drawn small it still clears the camera's near plane;
-- with room ahead it stays put; nearer a wall than it reaches it pulls back just enough, more the
-- nearer, never less than nothing; it pulls in at once and comes back out smoothly without passing
-- where it should be; a hitch never makes it jump; the beam starts at the lens unless a surface is
-- nearer, then just short of it, never behind where the line starts.
local fs = require("@lune/fs")
local Hands = require("../src/shared/Hands")
local Torch = require("../src/shared/Flashlight/Torch")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

do -- drawn small, the torch still clears the near plane, and its far end comes near your eye
	-- the torch's length and middle from its generated Specs (Vector3s, which Lune doesn't have)
	local specs = fs.readFile("src/shared/Flashlight/Specs.luau")
	local body = string.match(specs, "Body = {(.-)}") or ""
	local length = tonumber(string.match(body, "Size = Vector3%.new%([^,]+, [^,]+, ([%-%d%.]+)%)"))
	local middle =
		tonumber(string.match(body, "Centre = Vector3%.new%([^,]+, [^,]+, ([%-%d%.]+)%)"))
	assert(length and middle, "no torch body in its Specs")
	local tail = -Torch.Hold[3] - (middle + length / 2)
	local head = -Torch.Hold[3] - (middle - length / 2)
	ok(tail * Hands.Scale > 0.1 + 0.05, "the torch's tail clears the near plane drawn small")
	ok(head * Hands.Scale < 0.75, "the torch's far end within three quarters of a stud of your eye")
	ok(Hands.Scale > 0 and Hands.Scale < 1, "drawn smaller, not bigger")
end

do -- the pull
	ok(Hands.pull(nil, 0.6) == 0, "nothing ahead: no pull")
	ok(Hands.pull(2, 0.6) == 0, "a wall well past what you hold: no pull")
	ok(Hands.pull(0.6 + Hands.Margin, 0.6) == 0, "just room: no pull")
	ok(near(Hands.pull(0.4, 0.6), 0.2 + Hands.Margin), "nearer than it reaches: back by the gap")
	ok(near(Hands.pull(0, 0.6), 0.6 + Hands.Margin), "nose to the wall: all the way")
	ok(near(Hands.pull(-0.3, 0.6), 0.6 + Hands.Margin), "a wall behind your eye counts as at it")
	local last = -1
	local rising = true
	for i = 0, 100 do
		local p = Hands.pull(1 - i / 100, 0.6)
		rising = rising and p >= last and p >= 0
		last = p
	end
	ok(rising, "the nearer the wall, the further back, never below nothing")
end

do -- in at once, out smoothly
	ok(Hands.follow(0, 0.5, 1 / 60) == 0.5, "pulls in at once")
	local v = 0.5
	local steps, smooth = 0, true
	while v > 0.001 and steps < 600 do
		local nv = Hands.follow(v, 0, 1 / 60)
		smooth = smooth and nv < v and nv >= 0 and v - nv < 0.5 * 7 / 60 + 1e-9
		v = nv
		steps += 1
	end
	ok(smooth, "comes back out smoothly, never past where it should be")
	ok(steps > 20 and steps < 120, `back out in a third to two seconds ({steps} frames)`)
	ok(Hands.follow(0.5, 0.2, 0) == 0.5, "no time, no move")
	ok(Hands.follow(0.5, 0.2, -1) == 0.5, "a backwards clock, no move")
	local hitch = Hands.follow(0.5, 0.2, 5)
	ok(hitch >= 0.2 and hitch < 0.21, "a long hitch settles, never overshoots")
end

do -- the beam
	ok(Hands.lightAt(2.6, nil) == 2.6, "nothing in the way: at the lens")
	ok(Hands.lightAt(2.6, 3) == 2.6, "a wall past the lens: at the lens")
	ok(near(Hands.lightAt(2.6, 1.5), 1.5 - Hands.LightGap), "a wall before the lens: just short")
	ok(Hands.lightAt(2.6, 0.05) == 0, "a wall at the line's start: never behind it")
end

print(`hands: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} hands checks failed`)
end
