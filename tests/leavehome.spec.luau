--!strict
-- lune run tests/leavehome.spec
-- Nothing worn or switched on runs down at home (S5-03f3, D-259, Finds/Use): a light lit on the
-- ground floor burns for good there (`Use.home`); as you ride a lobby car up, each one you carry
-- or wear gets its own full light from then (`Use.leave`), its press's clock kept so nothing
-- plays again, and every screen takes the new light without replaying the press (`Use.relit`).
local Fixture = require("./fixtures/finds")
local OneMesh = require("../src/shared/Finds/OneMesh")
local Use = require("../src/shared/Finds/Use")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- a find's motions' lengths, as its set wrote them (a one-mesh find's, as `OneMesh` does)
local function durations(name: string): { [string]: number }
	local out: { [string]: number } = {}
	local find = Fixture.kit[name]
	local one = OneMesh[name]
	local motions = if find then find.Motions else if one then one.motions else nil
	if motions then
		for motion, m in motions do
			out[motion] = m.Duration
		end
	end
	return out
end

local hat, lantern = Use.Rows.HardHat, Use.Rows.CampLantern
local hatD, lanternD = durations("HardHat"), durations("CampLantern")

-- at home: a light switched on or worn never runs down; anything else is pressed as anywhere
do
	ok(Use.home(hat, "On", 60) == Use.Forever, "home: the hat worn burns for good")
	ok(Use.home(lantern, "On", 60) == Use.Forever, "home: a lantern switched on burns for good")
	ok(Use.home(lantern, "Off", 25) == 25, "home: switched off keeps what's left")
	ok(Use.home(Use.Rows.JackInTheBox, "On", Use.Forever) == Use.Forever, "home: a toy as ever")
	ok(Use.home(Use.Rows.DiecastCar, "Again", 0) == 0, "home: a toy pressed again as ever")
	ok(
		Use.home(Use.Rows.GlowSticks, "On", Use.Forever) == Use.Forever,
		"home: a light that never runs down as ever"
	)
end

-- leaving home: the hat worn at home since 100 s ago gets its own minute from now
do
	local lasts = hat.lasts or 0
	ok(lasts == 60, "the hat lasts a minute")
	local worn: Use.Stamp = { state = "On", at = 1000, left = Use.Forever, count = 1 }
	local now = 1100
	local s = Use.leave(hat, worn, now)
	ok(s ~= nil, "leave: the hat lit at home is restamped")
	if s then
		ok(s.state == "On" and s.at == 1000 and s.count == 1, "leave: its press's clock kept")
		ok(near(Use.litUntil(hat, s) or 0, now + lasts), "leave: lit a minute from now")
		local f = Use.frame(hat, s, now - s.at, hatD)
		ok(f.lit and not f.spent, "leave: still lit as you arrive")
		ok(f.motion == "SwitchOn", "leave: no press plays again (still at its switch's end)")
		local before = Use.frame(hat, s, now - s.at + lasts - 0.01, hatD)
		ok(before.lit and before.motion == "SwitchOn", "leave: lit to the end of its minute")
		local after = Use.frame(hat, s, now - s.at + lasts + 0.01, hatD)
		ok(after.motion == "RunDown" and not after.lit, "leave: then it runs down")
	end
	-- worn at home just now (its press still playing): the minute from now all the same
	local fresh = Use.leave(hat, { state = "On", at = now, left = Use.Forever }, now)
	ok(fresh ~= nil and near(Use.litUntil(hat, fresh) or 0, now + lasts), "leave: lit just now")
end

-- a switch: lit at home runs its own light from now; switched off at home keeps a full one
do
	local lasts = lantern.lasts or 0
	ok(lasts > 0, "the lantern runs down")
	local lit = Use.leave(lantern, { state = "On", at = 0, left = Use.Forever }, 500)
	ok(lit ~= nil and near(Use.litUntil(lantern, lit) or 0, 500 + lasts), "leave: lantern lit")
	if lit then
		local state, left = Use.press(lantern, lit, 500 + 10 - lit.at, lanternD)
		ok(state == "Off" and near(left, lasts - 10), "leave: switched off keeps what's left")
	end
	local off = Use.leave(lantern, { state = "Off", at = 0, left = Use.Forever }, 500)
	ok(off ~= nil and off.state == "Off" and off.left == lasts, "leave: off keeps a full light")
	if off then
		local state, left = Use.press(lantern, off, 500 - off.at, lanternD)
		ok(state == "On" and left == lasts, "leave: switched on later, its full light")
	end
end

-- nothing else changes as you leave
do
	ok(Use.leave(hat, nil, 10) == nil, "leave: never pressed")
	local running: Use.Stamp = { state = "On", at = 0, left = 60 }
	ok(Use.leave(hat, running, 10) == nil, "leave: lit on a climb runs on as it was")
	local glow: Use.Stamp = { state = "On", at = 0, left = Use.Forever, count = 1 }
	ok(Use.leave(Use.Rows.GlowSticks, glow, 10) == nil, "leave: never runs down anyway")
	local jack: Use.Stamp = { state = "On", at = 0, left = Use.Forever }
	ok(Use.leave(Use.Rows.JackInTheBox, jack, 10) == nil, "leave: a toy plays no light")
end

-- a bundle's next stick gets its own full light, never what a restamped stick had left
do
	local bundle = table.clone(Use.Rows.GlowSticks)
	bundle.lasts = 60
	local d = durations("GlowSticks")
	local first = Use.leave(bundle, { state = "On", at = 0, left = Use.Forever, count = 1 }, 3600)
	ok(first ~= nil, "bundle: the first stick restamped")
	if first then
		local state, left, count = Use.press(bundle, first, 3600 + 5 - first.at, d)
		ok(state == "On" and left == 60 and count == 2, "bundle: the next stick its own minute")
	end
end

-- every screen: the same press with a new light takes the light and keeps its clock (your own
-- press's, which may differ a little from the server's); anything else is a press, re-read whole
do
	local shown: Use.Stamp = { state = "On", at = 1000.3, left = Use.Forever, count = 1 }
	local read: Use.Stamp = { state = "On", at = 1000, left = 160, count = 1 }
	local r = Use.relit(shown, read)
	ok(r ~= nil and r.at == 1000.3 and r.left == 160 and r.state == "On", "relit: the new light")
	ok(Use.relit(nil, read) == nil, "relit: nothing shown yet")
	ok(Use.relit(shown, nil) == nil, "relit: nothing read")
	local off: Use.Stamp = { state = "Off", at = 1000, left = 160, count = 1 }
	ok(Use.relit(shown, off) == nil, "relit: a new state is a press")
	local later: Use.Stamp = { state = "On", at = 1005, left = 160, count = 1 }
	ok(Use.relit(shown, later) == nil, "relit: a new clock is a press")
	local next: Use.Stamp = { state = "On", at = 1000, left = 160, count = 2 }
	ok(Use.relit(shown, next) == nil, "relit: the next stick is a press")
	local running: Use.Stamp = { state = "On", at = 1000.3, left = 60, count = 1 }
	ok(Use.relit(running, read) == nil, "relit: only a light lit for good is given one")
end

print(`leavehome: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
