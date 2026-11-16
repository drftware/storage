--!strict
-- lune run tests/finduse.spec
-- Using a find (F-G1b, Finds/Use): every row plays motions its find really has; a light stays
-- lit through its press, runs down where the catalog says and is spent after; a switch keeps
-- what's left of its light; the jack-in-the-box can't be wound mid-tune, is shut before it's
-- wound again, and its bang comes as its Pop starts.
local Fixture = require("./fixtures/finds")
local Use = require("../src/shared/Finds/Use")

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

-- a find's motions' lengths, as its set wrote them
local function durations(name: string): { [string]: number }
	local out: { [string]: number } = {}
	local find = Fixture.kit[name]
	if find then
		for motion, m in find.Motions do
			out[motion] = m.Duration
		end
	end
	return out
end

-- every row's motions are its find's own
for name, row in Use.Rows do
	local d = durations(name)
	ok(Fixture.kit[name] ~= nil, `{name}: a kit-built find`)
	local steps: { Use.Step } = table.clone(row.on)
	for _, s in row.out or {} do
		table.insert(steps, s)
	end
	if row.off then
		table.insert(steps, row.off)
	end
	if row.reset then
		table.insert(steps, row.reset)
	end
	for _, s in steps do
		ok(d[s.motion] ~= nil, `{name}: has a {s.motion} motion`)
	end
	ok(#row.verb > 0 and not string.find(row.verb, " "), `{name}: one word on the press`)
	ok(row.out == nil or row.lasts ~= nil, `{name}: runs down only if it lasts`)
end

-- the tea light: catches, flickers, gutters out after a minute, then spent
do
	local row, d = Use.Rows.TeaLight, durations("TeaLight")
	local state, left = Use.press(row, nil, 0, d)
	ok(state == "On" and left == 60, "tea light: a first press lights it for 60 s")
	local stamp: Use.Stamp = { state = "On", at = 0, left = left }
	local f = Use.frame(row, stamp, 0.2, d)
	ok(f.motion == "Light" and f.step == 1 and f.lit, "tea light: the wick catching")
	local into = d.Light + 0.5
	f = Use.frame(row, stamp, into, d)
	ok(f.motion == "Flicker" and f.step == 2 and near(f.t, 0.5), "tea light: then flickering")
	f = Use.frame(row, stamp, d.Light + d.Flicker * 3 + 0.25, d)
	ok(f.motion == "Flicker" and near(f.t, 0.25), "tea light: the flicker loops")
	ok(Use.press(row, stamp, 30, d) == nil, "tea light: can't be pressed while it burns")
	f = Use.frame(row, stamp, 60.5, d)
	ok(f.motion == "GoOut" and f.step == 3 and not f.lit and not f.spent, "tea light: going out")
	f = Use.frame(row, stamp, 60 + d.GoOut + 1, d)
	ok(f.spent and f.motion == "GoOut" and near(f.t, d.GoOut), "tea light: out for good")
	ok(Use.press(row, stamp, 200, d) == nil, "tea light: spent takes no press")
end

-- the lantern: a switch that keeps its battery
do
	local row, d = Use.Rows.CampLantern, durations("CampLantern")
	local stamp: Use.Stamp = { state = "On", at = 0, left = 90 }
	local state, left = Use.press(row, stamp, 30, d)
	ok(state == "Off" and near(left, 60), "lantern: switched off keeps 60 s")
	local off: Use.Stamp = { state = "Off", at = 30, left = left }
	local f = Use.frame(row, off, 0.3, d)
	ok(f.motion == "SwitchOff" and not f.lit and not f.spent, "lantern: switching off")
	f = Use.frame(row, off, 500, d)
	ok(f.motion == "SwitchOff" and near(f.t, d.SwitchOff), "lantern: stays off, never runs down")
	state, left = Use.press(row, off, 500, d)
	ok(state == "On" and near(left, 60), "lantern: on again with what was left")
	local on: Use.Stamp = { state = "On", at = 530, left = 60 }
	f = Use.frame(row, on, 59, d)
	ok(f.motion == "SwitchOn" and f.lit and near(f.t, d.SwitchOn), "lantern: held lit")
	f = Use.frame(row, on, 61, d)
	ok(f.motion == "RunDown" and not f.lit, "lantern: running down")
	ok(Use.press(row, on, 61, d) == nil, "lantern: too late to save it")
	f = Use.frame(row, on, 60 + d.RunDown + 0.1, d)
	ok(f.spent, "lantern: dead")
	ok(Use.press(row, on, 100, d) == nil, "lantern: dead takes no press")
end

-- the glow stick: cracked once, lit for good
do
	local row, d = Use.Rows.GlowSticks, durations("GlowSticks")
	local state, left = Use.press(row, nil, 0, d)
	ok(state == "On" and left == Use.Forever, "glow stick: never runs down")
	local stamp: Use.Stamp = { state = "On", at = 0, left = left }
	local f = Use.frame(row, stamp, 1000, d)
	ok(f.motion == "Crack" and near(f.t, d.Crack) and f.lit and not f.spent, "glow stick: lit")
	ok(Use.press(row, stamp, 1000, d) == nil, "glow stick: cracked once")
end

-- the disco ball: spins until stopped, and again
do
	local row, d = Use.Rows.DiscoBall, durations("DiscoBall")
	local stamp: Use.Stamp = { state = "On", at = 0, left = Use.Forever }
	local f = Use.frame(row, stamp, 30, d)
	ok(f.motion == "Spinning" and near(f.t, (30 - d.Spin) % d.Spinning), "disco ball: spinning")
	local state = Use.press(row, stamp, 30, d)
	ok(state == "Off", "disco ball: stopped")
	state = Use.press(row, { state = "Off", at = 30, left = Use.Forever }, 5, d)
	ok(state == "On", "disco ball: spun again")
end

-- the jar: opens, the fireflies drift a minute, then they're gone
do
	local row, d = Use.Rows.FireflyJar, durations("FireflyJar")
	local stamp: Use.Stamp = { state = "On", at = 0, left = 60 }
	ok(Use.frame(row, stamp, d.Open + 1, d).motion == "Drift", "jar: fireflies drifting")
	local f = Use.frame(row, stamp, 60 + d.Gone + 0.1, d)
	ok(f.spent and f.motion == "Gone", "jar: they're gone")
end

-- the jack-in-the-box: the tune, the bang, shut before it's wound again
do
	local row, d = Use.Rows.JackInTheBox, durations("JackInTheBox")
	local stamp: Use.Stamp = { state = "On", at = 0, left = Use.Forever }
	local f = Use.frame(row, stamp, 5, d)
	ok(f.motion == "Wind" and f.lit, "jack: winding")
	ok(Use.press(row, stamp, 5, d) == nil, "jack: can't be wound mid-tune")
	ok(near(Use.noiseAt(row, "On", d) or -1, d.Wind), "jack: the bang as it pops")
	f = Use.frame(row, stamp, d.Wind + 0.2, d)
	ok(f.motion == "Pop" and f.step == 2, "jack: popping")
	f = Use.frame(row, stamp, d.Wind + d.Pop + 1, d)
	ok(f.motion == "Pop" and not f.lit and not f.spent, "jack: popped, at rest")
	local state = Use.press(row, stamp, d.Wind + d.Pop + 1, d)
	ok(state == "Again", "jack: wound again once it's popped")
	local again: Use.Stamp = { state = "Again", at = 20, left = Use.Forever }
	ok(Use.frame(row, again, 0.2, d).motion == "Shut", "jack: shut first")
	ok(Use.frame(row, again, d.Shut + 0.2, d).motion == "Wind", "jack: then wound")
	ok(near(Use.noiseAt(row, "Again", d) or -1, d.Shut + d.Wind), "jack: its bang later again")
	ok(Use.noiseAt(Use.Rows.CampLantern, "On", durations("CampLantern")) == nil, "lantern: quiet")
end

-- never pressed: at rest
do
	local f = Use.frame(Use.Rows.TeaLight, nil, 10, durations("TeaLight"))
	ok(f.motion == nil and not f.lit and not f.spent, "unpressed: at rest")
end

-- the stamp as attributes carry it, and each frame's step back by number (its sound)
do
	local row = Use.Rows.CampLantern
	ok(Use.encode(Use.Forever) == -1 and Use.encode(42) == 42, "encode: forever as -1")
	local s = Use.read("On", 100, -1)
	ok(s ~= nil and s.state == "On" and s.at == 100 and s.left == Use.Forever, "read: forever")
	ok(Use.read("Lit", 100, 5) == nil, "read: no such state")
	ok(Use.read("On", "100", 5) == nil and Use.read("On", 100, nil) == nil, "read: not numbers")
	ok(Use.read("On", 0 / 0, 5) == nil, "read: not a number")
	ok(Use.read(nil, nil, nil) == nil, "read: never pressed")
	local d = durations("CampLantern")
	local f = Use.frame(row, { state = "On", at = 0, left = 90 }, 90 + 0.01, d)
	local step = Use.stepAt(row, "On", f.step)
	ok(step ~= nil and step.motion == "RunDown", "stepAt: into out")
	local on = Use.stepAt(row, "On", 1)
	ok(on ~= nil and on.sound ~= nil, "stepAt: the switch clicks")
	ok(Use.stepAt(row, "On", 0) == nil, "stepAt: none before")
	local off = Use.stepAt(row, "Off", 1)
	ok(off ~= nil and off.motion == "SwitchOff" and Use.stepAt(row, "Off", 2) == nil, "stepAt: off")
	local jack = Use.Rows.JackInTheBox
	local shut = Use.stepAt(jack, "Again", 1)
	local pop = Use.stepAt(jack, "Again", 3)
	ok(shut ~= nil and shut.motion == "Shut" and pop ~= nil and pop.motion == "Pop", "stepAt: jack")
end

-- the cymbal monkey: wound, it bashes its cymbals, lured monsters hear it all through its Play,
-- and once it stalls it's wound again from the start (no lid to shut)
do
	local row, d = Use.Rows.CymbalMonkey, durations("CymbalMonkey")
	local state = Use.press(row, nil, 0, d)
	ok(state == "On", "monkey: wound")
	local stamp: Use.Stamp = { state = "On", at = 0, left = Use.Forever }
	ok(Use.frame(row, stamp, d.Wind + 1, d).motion == "Play", "monkey: plays after its wind")
	ok(Use.frame(row, stamp, d.Wind + 1, d).lit, "monkey: still going mid-play")
	ok(Use.press(row, stamp, d.Wind + 1, d) == nil, "monkey: can't be wound mid-play")
	ok(near(Use.noiseAt(row, "On", d) or -1, d.Wind), "monkey: heard from its first clash")
	ok(near(Use.lureUntil(row, "On", d) or -1, d.Wind + d.Play), "monkey: heard until it stalls")
	local done = d.Wind + d.Play + 0.1
	local over = Use.frame(row, stamp, done, d)
	ok(not over.lit and not over.spent, "monkey: stalled, not spent")
	local again = Use.press(row, stamp, done, d)
	ok(again == "Again", "monkey: wound again once it stalls")
	ok(Use.chain(row, "Again")[1].motion == "Wind", "monkey: again is a wind, no reset")
	ok(
		Use.lureUntil(Use.Rows.JackInTheBox, "On", durations("JackInTheBox")) == nil,
		"jack: no lure"
	)
	ok(row.on[2].hit ~= nil and row.on[2].hit.part == "CymbalMonkey_ArmL", "monkey: clash per beat")
end

-- the toy car: pushed, it's set down and rolls; once it stops it's pushed again, never a light
do
	local row, d = Use.Rows.DiecastCar, durations("DiecastCar")
	ok(row.down == true, "car: set down to roll")
	ok(Use.press(row, nil, 0, d) == "On", "car: pushed")
	local stamp: Use.Stamp = { state = "On", at = 0, left = Use.Forever }
	ok(Use.frame(row, stamp, 1, d).lit, "car: rolling")
	ok(Use.press(row, stamp, 1, d) == nil, "car: no push mid-roll")
	local stopped = Use.frame(row, stamp, d.Push + 1, d)
	ok(not stopped.lit and stopped.motion == "Push", "car: stopped, held at its roll's end")
	ok(Use.press(row, stamp, d.Push + 1, d) == "Again", "car: pushed again")
	ok(Use.noiseAt(row, "On", d) == nil, "car: quiet to monsters")
end

-- the glow stick is still a light (not a toy): lit for good after its crack
do
	local row, d = Use.Rows.GlowSticks, durations("GlowSticks")
	ok(not Use.toy(row) and Use.toy(Use.Rows.JackInTheBox), "toys: the jack, not the glow stick")
	local f = Use.frame(row, { state = "On", at = 0, left = Use.Forever }, 999, d)
	ok(f.lit, "glow stick: lit for good")
end

-- found lights hold a Mannequin (F-G1b3b): a light lying lit is lit until its stamp says, just as
-- every screen plays it (`frame`); switched off, never pressed or a toy, it's no light; its reach
-- is its widest point light's range, cut to the share whose glow still reads on a body
do
	local lights = 0
	for key, row in Use.Rows do
		local d = durations(key)
		local state, left = Use.press(row, nil, 0, d)
		if state and left then
			local stamp: Use.Stamp = { state = state, at = 100, left = left }
			local till = Use.litUntil(row, stamp)
			if Use.toy(row) then
				ok(till == nil, `{key}: a toy is no light, playing or not`)
			else
				lights += 1
				ok(till ~= nil and till > 100, `{key}: pressed, it's lit`)
				for _, e in { 0, 1, 59.9, 60.1, 89.9, 90.1, 149.9, 150.1, 5000 } do
					ok(
						Use.frame(row, stamp, e, d).lit == (100 + e < (till or 0)),
						`{key}: lit {e} s on as its screen plays it`
					)
				end
				if row.off then
					local off: Use.Stamp = { state = "Off", at = 100, left = left }
					ok(Use.litUntil(row, off) == nil, `{key}: switched off, it isn't lit`)
				end
				local art = Fixture.kit[key]
				if art then
					local r = Use.reach(art)
					ok(r > 0 and r < 20, `{key}: its light holds a Mannequin {r} studs off`)
				end
			end
		end
		ok(Use.litUntil(row, nil) == nil, `{key}: never pressed, it isn't lit`)
	end
	ok(lights >= 6, `enough lights to check ({lights})`)
	ok(
		Use.litUntil(Use.Rows.GlowSticks, { state = "On", at = 0, left = Use.Forever }) == math.huge,
		"glow stick: lit for good"
	)
	local lantern = Fixture.kit.CampLantern
	ok(
		lantern ~= nil and near(Use.reach(lantern), 12 * Use.LightShare),
		"lantern: 12 studs of light, cut"
	)
	ok(Use.reach(nil) == 0, "no art: no reach")
	local monkey = Fixture.kit.CymbalMonkey
	ok(monkey == nil or Use.reach(monkey) == 0, "monkey: no light of its own")
end

-- the lamps once kept for home (D-250): each switches on anywhere, lit about a minute, keeps
-- what's left when switched off, fades out by its switch-off, and holds a Mannequin lying lit
do
	for _, name in
		{ "DeskLamp", "NightLight", "MoonLamp", "BlobLamp", "NeonSign", "StainedGlassLamp" }
	do
		local row, d = Use.Rows[name], durations(name)
		ok(row ~= nil and row.verb == "Switch", `{name}: a Switch press`)
		if row then
			local state, left = Use.press(row, nil, 0, d)
			ok(state == "On" and left == Use.LampLasts, `{name}: lit for a lamp's minute`)
			local on: Use.Stamp = { state = "On", at = 10, left = Use.LampLasts }
			ok(Use.litUntil(row, on) == 10 + Use.LampLasts, `{name}: lit until its minute is out`)
			local f = Use.frame(row, on, Use.LampLasts - 1, d)
			ok(f.lit and not f.spent, `{name}: lit through its minute`)
			state, left = Use.press(row, on, 20, d)
			ok(
				state == "Off" and near(left, Use.LampLasts - 20),
				`{name}: switched off keeps the rest`
			)
			f = Use.frame(row, on, Use.LampLasts + 0.1, d)
			ok(f.motion == "SwitchOff" and not f.lit and not f.spent, `{name}: fading out`)
			local fade = Use.stepAt(row, "On", f.step)
			ok(fade ~= nil and fade.sound == nil, `{name}: fades out without a click`)
			ok(Use.press(row, on, Use.LampLasts + 0.1, d) == nil, `{name}: too late to save it`)
			f = Use.frame(row, on, Use.LampLasts + (d.SwitchOff or 0) + 0.1, d)
			ok(f.spent, `{name}: out for good`)
			ok(Use.reach(Fixture.kit[name]) > 0, `{name}: lying lit, it holds a Mannequin`)
		end
	end
	local blob, d = Use.Rows.BlobLamp, durations("BlobLamp")
	local f = Use.frame(blob, { state = "On", at = 0, left = Use.LampLasts }, d.SwitchOn + 1, d)
	ok(f.motion == "Flow" and f.lit, "blob lamp: its blobs flow once it's on")
	local neon, n = Use.Rows.NeonSign, durations("NeonSign")
	f = Use.frame(neon, { state = "On", at = 0, left = Use.LampLasts }, n.SwitchOn + 1, n)
	ok(f.motion == "Buzz" and f.lit, "neon sign: it buzzes once it's on")
	ok(Use.Rows.UnpluggedLamp == nil, "the Secret lamp: found lit, no press")
end

print(`finduse: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
