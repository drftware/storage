--!strict
-- lune run tests/finduse.spec
-- Using a find (F-G1b, Finds/Use): every row plays motions its find really has; a light stays
-- lit through its press, runs down where the catalog says and is spent after; a switch keeps
-- what's left of its light; the jack-in-the-box can't be wound mid-tune, is shut before it's
-- wound again, and its bang comes as its Pop starts.
local Fixture = require("./fixtures/finds")
local OneMesh = require("../src/shared/Finds/OneMesh")
local Pose = require("../src/shared/Finds/Pose")
local Use = require("../src/shared/Finds/Use")

-- Seconds a lamp stays lit in all (D-250): about a minute, D-188's default for a found light
-- (art/finds/kit/game.py's LAMP_LASTS, written into each lamp's row).
local LAMP_LASTS = 60

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

-- every row's motions are its find's own
for name, row in Use.Rows do
	local d = durations(name)
	ok(Fixture.kit[name] ~= nil or OneMesh[name] ~= nil, `{name}: a kit-built or one-mesh find`)
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
	-- the Old lamp is found lit with no press and never runs down (D-229): lying anywhere it holds
	-- a Mannequin for good, as a cracked glow stick does (F-G1e5d); a pressed light still goes by
	-- its stamp, and a find that's neither is no light
	ok(Use.Rows.UnpluggedLamp == nil, "Old lamp: no press")
	ok(Use.lampUntil("UnpluggedLamp", nil) == math.huge, "Old lamp: lit for good, never pressed")
	local old = Fixture.kit.UnpluggedLamp
	ok(old ~= nil and near(Use.reach(old), 10 * Use.LightShare), "Old lamp: its 10 studs, cut")
	ok(Use.lampUntil("CampLantern", nil) == nil, "lantern: never pressed, it isn't lit")
	ok(
		Use.lampUntil("CampLantern", { state = "On", at = 5, left = 90 }) == 95,
		"lantern: lit by its stamp"
	)
	ok(Use.lampUntil("CymbalMonkey", { state = "On", at = 5, left = 20 }) == nil, "monkey: a toy")
	ok(Use.lampUntil("Nothing", nil) == nil, "no such find: no light")
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
			ok(state == "On" and left == LAMP_LASTS, `{name}: lit for a lamp's minute`)
			local on: Use.Stamp = { state = "On", at = 10, left = LAMP_LASTS }
			ok(Use.litUntil(row, on) == 10 + LAMP_LASTS, `{name}: lit until its minute is out`)
			local f = Use.frame(row, on, LAMP_LASTS - 1, d)
			ok(f.lit and not f.spent, `{name}: lit through its minute`)
			state, left = Use.press(row, on, 20, d)
			ok(
				state == "Off" and near(left, LAMP_LASTS - 20),
				`{name}: switched off keeps the rest`
			)
			f = Use.frame(row, on, LAMP_LASTS + 0.1, d)
			ok(f.motion == "SwitchOff" and not f.lit and not f.spent, `{name}: fading out`)
			local fade = Use.stepAt(row, "On", f.step)
			ok(fade ~= nil and fade.sound == nil, `{name}: fades out without a click`)
			ok(Use.press(row, on, LAMP_LASTS + 0.1, d) == nil, `{name}: too late to save it`)
			f = Use.frame(row, on, LAMP_LASTS + (d.SwitchOff or 0) + 0.1, d)
			ok(f.spent, `{name}: out for good`)
			ok(Use.reach(Fixture.kit[name]) > 0, `{name}: lying lit, it holds a Mannequin`)
		end
	end
	local blob, d = Use.Rows.BlobLamp, durations("BlobLamp")
	local f = Use.frame(blob, { state = "On", at = 0, left = LAMP_LASTS }, d.SwitchOn + 1, d)
	ok(f.motion == "Flow" and f.lit, "blob lamp: its blobs flow once it's on")
	local neon, n = Use.Rows.NeonSign, durations("NeonSign")
	f = Use.frame(neon, { state = "On", at = 0, left = LAMP_LASTS }, n.SwitchOn + 1, n)
	ok(f.motion == "Buzz" and f.lit, "neon sign: it buzzes once it's on")
	ok(Use.Rows.UnpluggedLamp == nil, "the Secret lamp: found lit, no press")
end

-- Squeeze (F-G1e1): every squishy and the duck squash in your hand, each with a sound of its own,
-- and can be squeezed again once they've come back; only the duck is heard, down the hall,
-- nearer than the air horn; the squishies are quiet (the catalog's Squeeze).
do
	local squishies = {
		"StressBall",
		"ButterStick",
		"MochiBun",
		"PaperSquishy",
		"ToastSlice",
		"GelBeadBall",
		"GlitterGooBall",
		"JumboStrawberry",
		"Capybara",
		"GalaxyGooBall",
		"RubberDuck",
	}
	local sounds: { [string]: string } = {}
	for _, name in squishies do
		local row, d = Use.Rows[name], durations(name)
		ok(row ~= nil and row.verb == "Squeeze", `{name}: squeezed`)
		if row then
			local step = row.on[1]
			local sound = step.sound
			ok(#row.on == 1 and step.motion == "Squeeze", `{name}: one squash`)
			ok(sound ~= nil, `{name}: squashes with a sound`)
			if sound then
				local id = `{sound.id} {sound.from} {sound.pitch or 1}`
				ok(sounds[id] == nil, `{name}: a sound of its own, not {sounds[id]}'s`)
				sounds[id] = name
			end
			ok(Use.press(row, nil, 0, d) == "On", `{name}: squeezed once`)
			local on: Use.Stamp = { state = "On", at = 0, left = Use.Forever }
			ok(Use.press(row, on, d.Squeeze * 0.5, d) == nil, `{name}: not again mid-squash`)
			ok(Use.press(row, on, d.Squeeze + 0.01, d) == "Again", `{name}: again once it's back`)
			ok(not Use.frame(row, on, d.Squeeze + 0.01, d).lit, `{name}: over once it's back`)
			ok(Use.litUntil(row, on) == nil, `{name}: no light to hold a monster`)
			if name ~= "RubberDuck" then
				ok(row.noise == nil and row.lure == nil, `{name}: quiet: no monster hears it`)
			end
		end
	end
	local duck, d = Use.Rows.RubberDuck, durations("RubberDuck")
	if duck then
		ok(Use.noiseAt(duck, "On", d) == 0, "duck: heard as the squeeze starts")
		ok(Use.lureUntil(duck, "On", d) == nil, "duck: one squeak a squeeze, not a lure")
		local loud = Use.loudness(duck)
		ok(loud >= 40 and loud < Use.LureReach, "duck: heard down the hall, not two halls round")
	end
	ok(Use.loudness(Use.Rows.CymbalMonkey) == Use.LureReach, "monkey: as far as the air horn")
	ok(Use.loudness(Use.Rows.JackInTheBox) == Use.LureReach, "jack: as far as the air horn")
	ok(Use.lureBeat(Use.Rows.CymbalMonkey) == 2, "monkey: heard every 2 seconds, as before")
end

-- The noise cap (F-G1e1): one find heard once a `HearGap` at most, however fast it's pressed;
-- `LuresAtOnce` lures heard at once, the newest.
do
	local din: Use.Din<string> = Use.din()
	ok(Use.hear(din, "duck", 0), "a first squeak is heard")
	ok(not Use.hear(din, "duck", Use.HearGap * 0.5), "mashed: not heard again so soon")
	ok(Use.hear(din, "jack", Use.HearGap * 0.5), "another find is heard meanwhile")
	ok(Use.hear(din, "duck", Use.HearGap), "heard again after the gap")
	Use.hear(din, "monkey", 100)
	ok(din.last.duck == nil and din.last.jack == nil, "finds heard long ago are let go")
	ok(Use.lureBeat({ verb = "Wind", on = {}, lure = 0.1 }) == Use.HearGap, "no lure beats faster")

	local lures: Use.Din<number> = Use.din()
	for i = 1, Use.LuresAtOnce do
		ok(Use.startLure(lures, i) == nil, `lure {i}: heard alongside the rest`)
	end
	ok(Use.startLure(lures, 99) == 1, "one past the cap: the oldest stops being heard")
	ok(not Use.luring(lures, 1) and Use.luring(lures, 99), "the newest is heard instead")
	ok(#lures.lures == Use.LuresAtOnce, "never more than the cap")
	ok(Use.startLure(lures, 2) == nil, "wound again: nothing dropped")
	ok(lures.lures[#lures.lures] == 2 and #lures.lures == Use.LuresAtOnce, "wound again: newest")
	Use.stopLure(lures, 2)
	ok(not Use.luring(lures, 2) and #lures.lures == Use.LuresAtOnce - 1, "a lure that ends stops")
end

-- Wind and go for the rest (F-G1e2b): the robot clanks a footfall at a time, the mouse squeaks
-- only where it stalls, the bird whistles two notes at each stop; all three are set down, walk
-- on at a wall and lure where they are as they go. The carousel plays in place, luring.
do
	local function beatsOf(key: string, motion: string): { number }
		local row = Use.Rows[key]
		local step = row and row.on[2]
		local hit = step and step.hit
		local art = Fixture.kit[key]
		if not (step and hit and art and step.motion == motion) then
			return {}
		end
		return Use.beats(art.Motions[motion], hit.part, hit.channel)
	end
	for key, motion in { WalkingRobot = "Walk", WindupMouse = "Zip", TinBird = "Hop" } do
		local row = Use.Rows[key]
		ok(row ~= nil and row.verb == "Wind", `{key}: wound`)
		if row then
			ok(row.down == true and row.walks == true, `{key}: set down, and walks on at a wall`)
			ok(
				row.noise == motion and row.lure ~= nil and row.toy == true,
				`{key}: lures as it goes`
			)
			ok(row.heard ~= nil and Use.loudness(row) < Use.LureReach, `{key}: under the cymbals`)
		end
	end
	local walk = Fixture.kit.WalkingRobot.Motions.Walk
	local clanks = beatsOf("WalkingRobot", "Walk")
	ok(#clanks >= 40 and clanks[1] < 0.3, `robot: a clank each footfall ({#clanks})`)
	ok(
		#clanks > 0 and clanks[#clanks] > 14 and clanks[#clanks] < walk.Duration,
		"robot: to the end"
	)
	local squeaks = beatsOf("WindupMouse", "Zip")
	ok(
		#squeaks >= 1 and #squeaks <= 2 and squeaks[1] > 5,
		`mouse: squeaks where it stalls ({#squeaks})`
	)
	local notes = beatsOf("TinBird", "Hop")
	ok(#notes == 10, `bird: five whistles of two notes ({#notes})`)
	ok(
		#notes == 10 and notes[2] - notes[1] < 0.4 and notes[3] - notes[2] > 1,
		"bird: notes in pairs"
	)
	local carousel = Use.Rows.TinCarousel
	ok(carousel ~= nil and carousel.verb == "Wind", "carousel: wound")
	if carousel then
		ok(
			not carousel.down and carousel.noise == "Play" and carousel.lure ~= nil,
			"carousel: in place"
		)
		ok(carousel.toy == true and carousel.on[2].sound ~= nil, "carousel: plays its tune, again")
		-- its tune slows as the spring runs down (F-G1e5f), on the curve its top turns by
		-- (art/finds/windups/spec.py's RIDE): full speed, then (1 - s) ^ fade to nothing
		local tune = carousel.on[2].sound :: Use.Sound
		local slows = tune.slows
		ok(slows ~= nil, "carousel: its tune slows")
		if slows then
			local d = durations("TinCarousel")
			ok(slows.stop <= d.Play and slows.at < slows.stop, "carousel: slows before it stops")
			ok(Use.pace(slows, 1) == 1 and Use.pace(slows, slows.at) == 1, "carousel: full speed")
			local mid = (slows.at + slows.stop) / 2
			ok(near(Use.pace(slows, mid), 0.5 ^ slows.fade), "carousel: half way down")
			ok(Use.pace(slows, slows.stop) == 0, "carousel: stopped with the top")
			ok(near(Use.through(slows, 4), 4), "carousel: the recording at full speed")
			local whole = slows.at + (slows.stop - slows.at) / (slows.fade + 1)
			ok(near(Use.through(slows, slows.stop + 3), whole), "carousel: no more after the stop")
			-- the recording runs out as the top stops, not before and not cut off
			ok(near(tune.length, whole * (tune.pitch or 1)), "carousel: the tune ends as it stops")
			-- walked up to as it runs down: joined where the tune is, slowing on from there
			local into = slows.at + 1.5
			local j = Use.join(tune, into)
			ok(j ~= nil, "carousel: joined as it slows")
			if j and j.slows then
				local js = j.slows
				ok(
					near(j.from, tune.from + Use.through(slows, into)),
					"carousel: joined where it is"
				)
				ok(near(Use.pace(js, 0), Use.pace(slows, into)), "carousel: joined at its pace")
				ok(
					near(Use.pace(js, 2), Use.pace(slows, into + 2)),
					"carousel: slowing on as it was"
				)
				ok(
					near(
						Use.through(js, 2),
						Use.through(slows, into + 2) - Use.through(slows, into)
					),
					"carousel: the joined tune's recording, from where it was joined"
				)
				ok(
					near(Use.through(js, 99), tune.length - (j.from - tune.from)),
					"carousel: to its end"
				)
			else
				ok(false, "carousel: the joined tune slows")
			end
		end
	end
end

-- The siren car (F-G1e4): pushed off, it rolls as the toy car does, wailing and luring where it
-- is as it goes; a wall stops it going, not its flywheel. Its roof light shines only while it
-- plays: lit as it rolls, out once it has run down, even stopped short at a wall (a frame held
-- at the wall would stay lit for good). A toy, so its light never holds a Mannequin.
do
	local row = Use.Rows.SirenCar
	local art = Fixture.kit.SirenCar
	ok(row ~= nil and row.verb == "Push", "siren car: pushed")
	if row and art then
		local push = art.Motions.Push
		local durations = { Push = push.Duration }
		ok(row.down == true and row.walks == true, "siren car: set down, wheels on at a wall")
		ok(
			row.noise == "Push" and row.lure ~= nil and row.toy == true,
			"siren car: lures as it goes"
		)
		ok(Use.loudness(row) < Use.LureReach, "siren car: under the cymbals")
		ok(row.on[1].sound ~= nil, "siren car: wails from the first push")
		local cues = Use.timeline(row.on[1], push)
		ok(#cues >= 1 and cues[1].t > 0.9 and cues[1].t < 1.2, "siren car: rolls as it's let go")
		local stamp: Use.Stamp = { state = "On", at = 0, left = Use.Forever }
		local function litAt(e: number, stop: number?): boolean
			local elapsed = Use.played(row, e, stop)
			return Use.frame(row, stamp, elapsed, durations).lit
		end
		ok(litAt(3) and litAt(3, 1.5), "siren car: lit as it rolls, and against a wall")
		ok(not litAt(push.Duration + 0.1), "siren car: out once it has run down")
		ok(not litAt(push.Duration + 0.1, 1.5), "siren car: out after a wall too")
		ok(Use.litUntil(row, stamp) == nil, "siren car: never holds a Mannequin")
		local beacon = false
		for _, light in art.Lights do
			beacon = beacon or light.Part == "SirenCar_Beacon"
		end
		ok(beacon and Use.reach(art) > 0, "siren car: its light on the turning beacon")
	end
end

-- Wind and go (F-G1e2): the chattering teeth set down chatter off on their own path, a clack
-- each snap, luring as they go; a wall stops their going forward, not their chattering.
do
	local teeth = Use.Rows.ChatteringTeeth
	ok(teeth ~= nil, "teeth: a press")
	if teeth then
		ok(teeth.down == true and teeth.walks == true, "teeth: set down, and walk on at a wall")
		ok(teeth.noise == "Chatter" and teeth.lure ~= nil, "teeth: lure all through the chatter")
		ok(
			Use.loudness(teeth) > 60 and Use.loudness(teeth) < Use.LureReach,
			"teeth: louder than a squeak, under the cymbals"
		)
		local frame, travel = Use.played(teeth, 7, 3)
		ok(frame == 7 and travel == 3, "teeth at a wall: chattering on, held where they stopped")
		frame, travel = Use.played(teeth, 2, 3)
		ok(frame == 2 and travel == 2, "teeth before the wall: going")
		local hit = teeth.on[2].hit
		local chatter = Fixture.kit.ChatteringTeeth.Motions.Chatter
		local beats = if hit then Use.beats(chatter, hit.part, hit.channel) else {}
		-- seven snaps a second for most of the chatter, slowing as the spring gives out
		ok(#beats >= 40, `teeth: a clack each snap ({#beats})`)
		local rising = true
		for i = 2, #beats do
			rising = rising and beats[i] > beats[i - 1]
		end
		ok(
			rising and beats[1] < 0.5 and beats[#beats] < chatter.Duration,
			"teeth: snaps in order, through the chatter"
		)
	end
	local car = Use.Rows.DiecastCar
	if car then
		local frame, travel = Use.played(car, 7, 3)
		ok(frame == 3 and travel == 3, "the toy car at a wall: holds the frame it stopped in")
		frame, travel = Use.played(car, 2, nil)
		ok(frame == 2 and travel == 2, "the toy car: no wall, no hold")
	end
	-- the monkey still clashes on every full swing, as the old rule had it
	local monkey = Use.Rows.CymbalMonkey
	local hit = monkey and monkey.on[2].hit
	if hit then
		local play = Fixture.kit.CymbalMonkey.Motions.Play
		local beats = Use.beats(play, hit.part, hit.channel)
		local set: { [number]: boolean } = {}
		for _, t in beats do
			set[t] = true
		end
		local full, kept = 0, 0
		for _, track in play.Tracks do
			if track.Part == hit.part and track.Channel == "turn" then
				local far = 0
				for _, k in track.Keys do
					if math.abs(k[2]) > math.abs(far) then
						far = k[2]
					end
				end
				for _, k in track.Keys do
					if math.abs(k[2] - far) < 1e-3 then
						full += 1
						kept += if set[k[1]] then 1 else 0
					end
				end
			end
		end
		ok(full > 0 and kept == full, `monkey: every full swing still clashes ({kept}/{full})`)
	end
	-- held at a wall: its place over the floor from where it stopped, the rest from now
	local base = { Root = { x = 1, y = 2, yaw = 30 }, Leg = { turn = 5 } }
	local held = Pose.hold(base, { Root = { x = 9, z = 4, yaw = 90, y = 7 } }, "Root", Use.Holds)
	ok(held.Root.x == 9 and held.Root.z == 4 and held.Root.yaw == 90, "held: where it stopped")
	ok(held.Root.y == 2 and held.Leg.turn == 5, "held: its bob and legs play on")
	ok(base.Root.x == 1 and base.Root.z == nil, "held: the values it came from left alone")
end

-- One press, one noise (F-G1e3): the kazoo hums once it's at your lips; the drum bangs at each of
-- its five hits. Each is heard once as it's pressed (the jack's one noise, no lure), its own
-- loudness, and takes another press once it's done.
do
	local kazoo, drum = Use.Rows.Kazoo, Use.Rows.ToyDrum
	ok(kazoo ~= nil and kazoo.verb == "Blow", "kazoo: blown")
	ok(drum ~= nil and drum.verb == "Bang", "drum: banged")
	for key, row in { Kazoo = kazoo, ToyDrum = drum } do
		local d = durations(key)
		ok(Use.noiseAt(row, "On", d) == 0, `{key}: heard as it's pressed`)
		ok(Use.lureUntil(row, "On", d) == nil, `{key}: one noise, not a lure`)
		ok(row.heard ~= nil and Use.toy(row), `{key}: its own loudness, pressed again`)
	end
	ok(Use.loudness(kazoo) < Use.loudness(drum), "kazoo: quieter than the drum")
	local blow = kazoo.on[1]
	local hum = Use.timeline(blow, Fixture.kit.Kazoo.Motions.Blow)
	ok(#hum == 1 and math.abs(hum[1].t - 0.36) < 1e-6, "kazoo: its hum once it's at your lips")
	ok(
		#hum == 1 and hum[1].sound.length / (hum[1].sound.pitch or 1) > 1.1,
		"kazoo: the hum lasts its note"
	)
	local bang = drum.on[1]
	local hits = Use.timeline(bang, Fixture.kit.ToyDrum.Motions.Bang)
	ok(#hits == 5, `drum: a bang each hit ({#hits})`)
	ok(#hits == 5 and hits[1].t > 0.2 and hits[1].t < 0.3, "drum: the first hit lands")
	ok(#hits == 5 and hits[5].t - hits[4].t > 0.5, "drum: then both sticks, after a gap")
	-- a cue and a hit at once, in time order
	local both = Use.timeline(
		{
			motion = "Bang",
			hit = bang.hit,
			cues = { { at = 0.5, sound = blow.cues and blow.cues[1].sound or bang.hit.sound } },
		} :: any,
		Fixture.kit.ToyDrum.Motions.Bang
	)
	local sorted = #both == 6
	for i = 2, #both do
		sorted = sorted and both[i].t >= both[i - 1].t
	end
	ok(sorted, "a step's cues and beats in time order")
end

-- The spinner, the doll and the fish (F-G1e3b): each one noise down the hall, pressed again once
-- it's done. The spinner's arrow ticks into its last three notches and settles; a part coming to
-- rest at its last key is no beat, or the third tick would sound twice.
do
	for key, verb in { FarmSpinner = "Pull", CowboyDoll = "Pull", SingingFish = "Press" } do
		local row = Use.Rows[key]
		ok(row ~= nil and row.verb == verb, `{key}: its word`)
		if row then
			local d = durations(key)
			ok(Use.noiseAt(row, "On", d) == 0, `{key}: heard as it's pressed`)
			ok(Use.lureUntil(row, "On", d) == nil, `{key}: one noise, not a lure`)
			ok(row.heard == 60 and Use.toy(row), `{key}: down the hall, pressed again`)
			local step = row.on[1]
			local cues = Use.timeline(step, Fixture.kit[key].Motions[step.motion])
			ok(#cues > 0 and cues[#cues].t < d[step.motion], `{key}: its sounds inside its motion`)
		end
	end
	local spinner = Use.Rows.FarmSpinner
	local pull = spinner and spinner.on[1]
	local hit = pull and pull.hit
	local ticks = if hit
		then Use.beats(Fixture.kit.FarmSpinner.Motions.Pull, hit.part, hit.channel)
		else {}
	ok(#ticks == 3, `spinner: three ticks into the notches ({#ticks})`)
	ok(
		#ticks == 3
			and math.abs(ticks[1] - 2.3) < 1e-6
			and math.abs(ticks[2] - 2.63) < 1e-6
			and math.abs(ticks[3] - 3.07) < 1e-6,
		"spinner: on the arrow's hops"
	)
	local all = if pull then Use.timeline(pull, Fixture.kit.FarmSpinner.Motions.Pull) else {}
	ok(#all == 4, `spinner: the lever and three ticks before its stop is known ({#all})`)
end

-- The spinner lands on any animal (F-G1e3d): the server picks one of the eight each pull, never
-- the one it's on; every screen bends the art's spin so the arrow sets off from where it rests
-- and ends on that animal, its ticks where the art has them, and its call plays as it stops.
do
	local spinner = Use.Rows.FarmSpinner
	local pull = spinner and Use.lands(spinner)
	local lands = pull and pull.lands
	local motion = Fixture.kit.FarmSpinner.Motions.Pull
	ok(
		lands ~= nil and #lands.calls == 8 and lands.every == 45,
		"spinner: eight animals, an eighth apart"
	)
	if pull and lands then
		ok(
			Use.spins(lands, motion) == 29,
			`spinner: the art spins 29 eighths ({Use.spins(lands, motion)})`
		)
		-- the pick: never where it is, always one of the eight, every other one reachable
		local fair = true
		for on = 0, 7 do
			local seen: { [number]: boolean } = {}
			for k = 0, 69 do
				local to = Use.pick(8, on, k / 70)
				fair = fair and to ~= on and to >= 0 and to <= 7 and to == math.floor(to)
				seen[to] = true
			end
			local n = 0
			for _ in seen do
				n += 1
			end
			fair = fair and n == 7 and Use.pick(8, on, 0.9999999) ~= on
		end
		ok(fair, "spinner: the pick is a new animal, any of the other seven")
		ok(
			Use.stop(nil, 8) == 0
				and Use.stop(3, 8) == 3
				and Use.stop(8, 8) == 0
				and Use.stop(2.5, 8) == 0
				and Use.stop("3", 8) == 0,
			"spinner: a stop read from its attribute is a whole stop or the first"
		)
		-- the bend: from each stop to each other, it sets off where it rests and ends on the pick
		local track = function(m: any): any
			for _, t in m.Tracks do
				if t.Part == lands.part and t.Channel == "turn" then
					return t
				end
			end
			return nil
		end
		local art = track(motion)
		local ticks = Use.beats(motion, lands.part, "turn")
		local bent = true
		for from = 0, 7 do
			for to = 0, 7 do
				if to == from then
					continue
				end
				local m = Use.bend(motion, lands, from, to)
				local keys = track(m).Keys
				local first, last = keys[1][2], keys[#keys][2]
				local spun = last - first
				bent = bent
					and near(first, from * 45)
					and near((last / 45) % 8, to)
					and spun >= art.Keys[#art.Keys][2] - 1e-6
					and spun < art.Keys[#art.Keys][2] + 360
					and #keys == #art.Keys
				local beats = Use.beats(m, lands.part, "turn")
				bent = bent and #beats == #ticks
				for i, t in ticks do
					bent = bent and beats[i] ~= nil and near(beats[i], t)
				end
				-- its other tracks are the art's own; the art itself is untouched
				bent = bent and #m.Tracks == #motion.Tracks and m.Duration == motion.Duration
			end
		end
		ok(bent, "spinner: bent from every animal to every other, ticks unchanged")
		ok(track(motion).Keys[#art.Keys][2] == 1305, "spinner: the art's own keys untouched")
		-- its call: the animal it lands on, as it stops
		for stop = 0, 7 do
			local cues = Use.timeline(pull, motion, stop)
			local call = cues[#cues]
			ok(
				#cues == 5
					and call.sound == lands.calls[stop + 1]
					and near(call.t, lands.at)
					and call.t > ticks[3],
				`spinner: animal {stop}'s call as the arrow stops`
			)
		end
	end
end

-- The one-mesh finds (F-G1e5a): each motion starts and ends where the find rests. The boombox's
-- Play key clacks, its song plays a whole number of thumps and is heard as far as the air horn
-- every 2 s all through it, then its stop key clacks as the song is cut; it can't be pressed
-- mid-song, and plays again after. The teddy's hug is quiet, its squeak at the squash.
do
	local REST = { scale = 1, stretch = 1 }
	for name, entry in OneMesh do
		for motion, m in entry.motions do
			for _, track in m.Tracks do
				local rest = REST[track.Channel] or 0
				local first, last = track.Keys[1], track.Keys[#track.Keys]
				ok(
					track.Part == name and first[1] == 0 and first[2] == rest and last[2] == rest,
					`{name} {motion} {track.Channel}: from rest to rest`
				)
				ok(near(last[1], m.Duration), `{name} {motion} {track.Channel}: keys to its end`)
			end
		end
	end

	local row, d = Use.Rows.Boombox, durations("Boombox")
	local song = row.on[2]
	ok(row.verb == "Play" and Use.toy(row) and row.noise == "Play", "boombox: Play, a toy, noisy")
	ok(Use.loudness(row) == Use.LureReach and row.lure == 2, "boombox: as loud as the horn, 2 s")
	local loops = (song.loop :: number) / d.Play
	ok(math.abs(loops - math.round(loops)) < 1e-6, "boombox: the song ends on a whole thump")
	ok(near(Use.noiseAt(row, "On", d) :: number, d.Key), "boombox: heard once its key is down")
	ok(
		near(Use.lureUntil(row, "On", d) :: number, d.Key + (song.loop :: number)),
		"boombox: lures until the song stops"
	)
	local stamp: Use.Stamp = { state = "On", at = 0, left = Use.Forever }
	local f = Use.frame(row, stamp, 0.1, d)
	ok(f.motion == "Key" and f.step == 1, "boombox: its key pressed")
	f = Use.frame(row, stamp, d.Key + d.Play * 3 + 0.2, d)
	ok(f.motion == "Play" and f.step == 2 and near(f.t, 0.2), "boombox: thumping on, looped")
	ok(Use.press(row, stamp, 8, d) == nil, "boombox: no press mid-song")
	local stop = d.Key + (song.loop :: number)
	f = Use.frame(row, stamp, stop + 0.1, d)
	ok(f.motion == "Stop" and f.step == 3, "boombox: its stop key")
	-- `Tools.play` lets a sound run half a second past its length: cut as the stop key clacks
	-- (0.14 s into its recording)
	local cut = d.Key + (song.sound :: Use.Sound).length + 0.5
	ok(math.abs(cut - (stop + 0.14)) < 0.05, "boombox: the song cut under the stop key")
	ok(Use.press(row, stamp, stop + d.Stop, d) == "Again", "boombox: plays again after")

	-- dropped mid-song (every screen gets a new copy) or walked up to: the song joined where it is
	ok(Use.started(row, "On", 2, d) == d.Key, "boombox: the song starts once its key is down")
	ok(near(Use.started(row, "On", 3, d) :: number, stop), "boombox: the stop key after the song")
	local into = 5
	local joined = Use.join(song.sound :: Use.Sound, into)
	ok(
		joined ~= nil
			and near(joined.from, (song.sound :: Use.Sound).from + into)
			and near(joined.length, (song.sound :: Use.Sound).length - into),
		"boombox: the song joined 5 s in, where it is"
	)
	ok(
		Use.join(song.sound :: Use.Sound, (song.sound :: Use.Sound).length - 0.2) == nil,
		"boombox: not joined in its last moment"
	)
	ok(Use.join(row.on[1].sound :: Use.Sound, 0.1) == nil, "boombox: its key's click never joined")
	local slow = { id = "x", from = 1, length = 6, volume = 1, pitch = 0.5 }
	local j = Use.join(slow, 2)
	ok(j ~= nil and near(j.from, 2) and near(j.length, 5), "a slowed tune joined by its pitch")

	local teddy, td = Use.Rows.Teddy, durations("Teddy")
	ok(teddy.verb == "Hug" and Use.toy(teddy), "teddy: Hug, a toy")
	ok(teddy.noise == nil and Use.noiseAt(teddy, "On", td) == nil, "teddy: quiet")
	local cues = Use.timeline(teddy.on[1], OneMesh.Teddy.motions.Hug)
	ok(#cues == 1 and cues[1].t > 0 and cues[1].t < 0.2, "teddy: its squeak at the squash")
	ok(Use.press(teddy, stamp, td.Hug + 0.01, td) == "Again", "teddy: hugged again once back")
end

print(`finduse: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
