--!strict
-- lune run tests/caught.spec
-- A keeper's catch on the caught player's screen (L-06b3c, L-06c2): the view is seized round to
-- its face and holds still through the dread; its face twitches back and rushes your eye, ever
-- faster, arriving as the dread and the rush end, while the view tunnels in and then crash-zooms;
-- the screen stays clear until the cut to black at `Dark` (when the server stores them), stays
-- black for `Hold`, then wakes through its keys without a jump, darkening only as the eyes drop
-- shut once; "Caught" is up only in the dark; the haze clears by the end; the sting's layers are
-- real asset ids played on the rush.
local Caught = require("../src/shared/Caught")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-9)
end

local lifts = Caught.Dark + Caught.Hold
local hits = Caught.Dread + Caught.Lunge

-- the order of it
ok(Caught.Seize > 0 and Caught.Seize < Caught.Dread, "the view is seized before the dread ends")
ok(Caught.Dread - Caught.Seize >= 0.2, "a breath of stillness on its face before the rush")
ok(Caught.Lunge >= 0.2 and Caught.Lunge <= 0.5, `the rush is a blur, not a walk ({Caught.Lunge})`)
ok(Caught.Hit > 0 and Caught.Hit <= 0.3, "its face holds the screen only a moment")
ok(near(Caught.Dark, Caught.Dread + Caught.Lunge + Caught.Hit), "the black follows the hit at once")
ok(
	near(Caught.Lift, Caught.Wake[#Caught.Wake][1]) and Caught.Wake[1][1] == 0,
	"the wake runs its keys"
)
ok(Caught.Wrap >= 3 and Caught.Wrap <= 5, `a consequence, not a reset ({Caught.Wrap} s)`)
ok(Caught.Kick > 0 and Caught.Kick <= 1 and Caught.HitKick > Caught.Kick, "the hit kicks harder")
ok(Caught.HitKick <= 1, "a kick CameraShake can take")

-- the seize
ok(Caught.turn(0) == 0, "the view starts where you looked")
ok(near(Caught.turn(Caught.Seize), 1) and Caught.turn(Caught.Dread) == 1, "and ends on its face")
ok(Caught.turn(Caught.Seize / 3) > 1 / 3, "it turns fastest at the start, a hand on your head")

-- the rush
ok(Caught.reach(0) == 0 and Caught.reach(Caught.Dread) == 0, "it holds still through the dread")
ok(near(Caught.reach(hits), 1) and Caught.reach(Caught.Dark) == 1, "its face is at your eye")
local low, wasReach = 0, 0
for i = 1, 200 do
	local t = Caught.Dread + Caught.Lunge * i / 200
	local r = Caught.reach(t)
	low = math.min(low, r)
	if t > Caught.Dread + Caught.Lunge * 0.6 then
		ok(r - wasReach >= 0, `it only comes once it has wound up, at {t}`)
	end
	wasReach = r
end
ok(low < 0 and low > -0.15, `a twitch back before it comes ({low})`)
local early = Caught.reach(Caught.Dread + Caught.Lunge * 0.8)
	- Caught.reach(Caught.Dread + Caught.Lunge * 0.7)
local late = Caught.reach(hits) - Caught.reach(Caught.Dread + Caught.Lunge * 0.9)
ok(late > early, "faster and faster: it doesn't slow as it reaches you")

-- the lens
ok(Caught.lens(0) == 1 and Caught.lens(-1) == 1, "your own view at the catch")
ok(near(Caught.lens(Caught.Dread), Caught.Tunnel, 1e-6), "tunnelled by the end of the dread")
ok(near(Caught.lens(hits), Caught.Crash, 1e-6), "crashed in as its face lands")
ok(near(Caught.lens(Caught.Dark - 0.01), Caught.Crash, 1e-6), "held through the hit")
ok(Caught.lens(Caught.Dark) == 1, "your own view again under the black")
ok(Caught.Crash < Caught.Tunnel and Caught.Tunnel < 1, "it closes in, then crashes in")
ok(Caught.lunging(0) and Caught.lunging(Caught.Dark - 0.01), "its face is up until the black")
ok(not Caught.lunging(Caught.Dark) and not Caught.lunging(-0.01), "and not after")

-- the hit: it pushes in, the view is knocked, and its face is lit
ok(Caught.Close < Caught.Near and Caught.Close > 0.5, "it presses in, never through your eye")
ok(
	Caught.press(hits - 0.01) == 0 and near(Caught.press(Caught.Dark), 1),
	"pressed in through the hit"
)
ok(Caught.press(hits + Caught.Hit / 2) > 0.5, "fast, then settling")
ok(Caught.knock(hits - 0.01) == 0, "no knock before it lands")
ok(near(Caught.knock(hits + Caught.KnockIn), 1), "the knock lands at once")
ok(Caught.knock(Caught.Dark - 0.01) < 0.3, "and has mostly died by the black")
ok(Caught.knock(Caught.Dark) == 0, "none under the black")
ok(Caught.KnockIn <= 0.05, "a blow, not a push")
ok(
	Caught.glow(0) == Caught.GlowDread and near(Caught.glow(hits), Caught.GlowHit),
	"lit as it comes"
)
ok(Caught.glow(Caught.Dark) == 0 and Caught.glow(-1) == 0, "no light outside the lunge")
ok(Caught.GlowHit > Caught.GlowDread and Caught.GlowRange > Caught.GlowAhead, "its face in reach")

-- the black and the wake
ok(Caught.blackout(-0.01) == 0 and Caught.headline(-0.01) == 0, "nothing before the catch")
ok(Caught.blackout(Caught.Dark - 0.01) == 0, "clear through the lunge: you see it all")
ok(Caught.blackout(Caught.Dark) == 1, "cut to black, not faded")
ok(Caught.blackout(lifts) == 1, "black through the hold")
ok(Caught.blackout(Caught.Wrap) == 0, "clear once it's over")
ok(Caught.headline(Caught.Dark) == 0, "a beat of plain black before the word")
ok(Caught.headline(Caught.Dark + 0.5) == 1 and Caught.headline(lifts) == 1, '"Caught" in the dark')
ok(near(Caught.headline(lifts + 0.3), 0, 1e-9), "gone as your eyes first open")
ok(Caught.haze(Caught.Dark - 0.01) == 0, "no haze over its face")
ok(Caught.haze(lifts) == 1 and Caught.haze(Caught.Wrap) == 0, "hazy as you wake, clear by the end")
ok(Caught.Blur > 0 and Caught.Grey < 0 and Caught.Grey >= -1, "a blur and a grey a screen can show")
ok(Caught.showing(0) and Caught.showing(Caught.Wrap - 0.01), "on screen the whole time")
ok(not Caught.showing(Caught.Wrap) and not Caught.showing(-0.01), "and not after")

-- the wake at 60 frames a second: no jump, and it darkens once (the eyes dropping shut)
local was = Caught.blackout(lifts)
local darkenings, darkening = 0, false
local hazeWas = Caught.haze(lifts)
for i = 1, math.ceil(Caught.Lift * 60) + 10 do
	local t = lifts + i / 60
	local b = Caught.blackout(t)
	ok(b >= 0 and b <= 1, `between clear and black at {t}`)
	ok(math.abs(b - was) <= 0.1, `no jump at {t} ({was} to {b})`)
	if b > was + 1e-9 and not darkening then
		darkenings += 1
	end
	darkening = b > was + 1e-9
	ok(Caught.headline(t) <= Caught.blackout(t) + 1e-9, `the word never outlasts the dark at {t}`)
	local h = Caught.haze(t)
	ok(h <= hazeWas + 1e-9, `the haze only clears at {t}`)
	was, hazeWas = b, h
end
ok(darkenings == 1, `the eyes drop shut once ({darkenings})`)

-- the sting
for i, clip in Caught.Sting do
	ok(string.match(clip.id, "^rbxassetid://%d+$") ~= nil, `sting {i} is an asset id`)
	ok(clip.length > 0 and clip.from >= 0 and clip.pitch > 0, `sting {i} plays a stretch`)
	ok(clip.volume > 0 and clip.volume <= 3, `sting {i} is loud, not driven into mush`)
	ok(clip.fade >= 0 and clip.fade <= clip.length / clip.pitch, `sting {i} fades within itself`)
	ok(near(clip.at, Caught.Dread), `sting {i} lands as the rush starts`)
end

print(string.format("caught: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("caught spec failed")
end
