--!strict
-- Caught there goes back to the lobby (S4-03c4, D-409): a catch on the floor the team picked with
-- the "back to the lobby" card sends you down the shaft to the lobby car, out of the climb. Only
-- that card's floors send you; your screen's fall runs from the cut to black to the landing; and
-- the climb's end counts you caught on that floor for good, so friends carry on without you and
-- the end still lands once the last of them is caught.
-- Run: lune run tests/tolobby.spec
local Caught = require("../src/shared/Caught")
local ClimbEnd = require("../src/shared/ClimbEnd")
local NextFloor = require("../src/shared/NextFloor")
local ToLobby = require("../src/shared/ToLobby")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- 1. Which floors send you down: the card's alone, and nothing that isn't a version's name.
ok(ToLobby.sends("CaughtToLobby"), "the back-to-the-lobby card's floor sends you down")
local senders = 0
for _, v in NextFloor.Versions do
	if ToLobby.sends(v.name) then
		senders += 1
	end
end
ok(senders == 1, `exactly one version sends you down ({senders})`)
ok(not ToLobby.sends(nil), "a plain floor (no version) keeps you")
ok(not ToLobby.sends(""), "an empty version keeps you")
ok(not ToLobby.sends(7), "a number keeps you")
ok(not ToLobby.sends("Nonsense"), "a name no version has keeps you")

-- 2. The fall: nothing before the cut to black, the picture over black through it, growing
-- faster and faster, and black alone from the landing; the server swaps you after it.
local shown, size, black = ToLobby.fall(Caught.Dark - 0.01)
ok(shown == 0 and black == 0 and size == 1, "nothing of the fall before the cut to black")
shown, size, black = ToLobby.fall(Caught.Dark)
ok(shown == 0 and black == 1, "the cut is black: the picture comes up out of it")
shown = ToLobby.fall(Caught.Dark + ToLobby.Reveal)
ok(shown == 1, "the picture is whole once it has come up")
local lastSize, lastStep = 1, 0
local faster = true
for i = 1, 20 do
	local _, s = ToLobby.fall(Caught.Dark + ToLobby.Fall * i / 21)
	if s - lastSize < lastStep - 1e-9 then
		faster = false
	end
	lastStep, lastSize = s - lastSize, s
end
ok(faster, "the picture grows faster and faster: a fall, not a zoom")
ok(
	lastSize <= ToLobby.Zoom and lastSize > ToLobby.Zoom * 0.8,
	"it nearly fills its zoom by the end"
)
shown, size, black = ToLobby.fall(ToLobby.Land)
ok(shown == 0 and black == 1, "the landing: the picture gone, black")
ok(ToLobby.Swap > ToLobby.Land, "the server swaps you under the landing's black, not before it")
ok(ToLobby.Swap < Caught.Wrap, "and before a catch's wake would have opened your eyes")
ok(ToLobby.lift(0) == 1 and ToLobby.lift(ToLobby.LiftIn) == 0, "the black lifts over LiftIn")
ok(ToLobby.lift(ToLobby.LiftIn / 2) < 1, "the lift has started half way")
ok(ToLobby.fresh(0) and not ToLobby.fresh(ToLobby.Fresh) and not ToLobby.fresh(-1), "fresh")
ok(ToLobby.Most > ToLobby.Swap + 4, "the screen waits long enough for a slow stand")

-- 3. The end counts you: caught on that floor while friends climb, and still caught (not back
-- climbing) once your kept mark is off in the lobby; the climb ends when the last friend's caught.
local state, lost = ClimbEnd.look(nil, 3, true, false, nil, false)
ok(state == "Kept" and lost ~= nil and lost.floor == 3, "caught on floor 3: kept there")
state, lost = ClimbEnd.look(lost, 3, false, false, nil, true)
ok(state == "Kept", `sent down to the lobby: still out of the climb ({state})`)
ok(lost ~= nil and lost.fate == "Kept" and lost.floor == 3, "noted caught on floor 3")
state, lost = ClimbEnd.look(nil, 4, false, false, nil, true)
ok(state == "Kept" and lost ~= nil and lost.floor == 4, "sent down, missed by the look: this floor")
ok(not ClimbEnd.over({ "Kept", "Climbing" }), "a friend still climbing: the climb goes on")
ok(ClimbEnd.over({ "Kept", "Kept" }), "the last friend caught: the end lands")
state = ClimbEnd.look(nil, 3, false, false, nil, false)
ok(state == "Climbing", "neither kept nor sent: climbing")

-- 4. Friends see you taken (S4-03c4b): nothing before the catch; the red up and the body jerked
-- down as the hands close; sinking faster and faster from the cut to black, never rising; under
-- the floor by the landing (when your own fall lands), before the server swaps the body; the red
-- gone after.
local sink, glow = ToLobby.drag(0)
ok(sink == 0 and glow == 0, "nothing at the catch's first instant")
sink, glow = ToLobby.drag(ToLobby.DragGrab - 0.01)
ok(sink == 0 and glow > 0.95, `the red is up before the hands close ({glow}), the body still`)
sink = ToLobby.drag(ToLobby.DragGrab + ToLobby.DragJerkIn)
ok(math.abs(sink - ToLobby.DragJerk) < 1e-9, "the hands close: a yank down")
ok(ToLobby.DragGrab + ToLobby.DragJerkIn <= Caught.Dark, "the yank is over by the cut to black")
local lastSink, lastDrop, downward, quicker = 0, 0, true, true
for i = 1, 40 do
	local s = ToLobby.drag(ToLobby.Land * i / 40)
	if s < lastSink - 1e-9 then
		downward = false
	end
	if i > 33 and s - lastSink < lastDrop - 1e-9 then
		quicker = false -- the drag's last stretch keeps speeding up
	end
	lastDrop, lastSink = s - lastSink, s
end
ok(downward, "the body only ever goes down")
ok(quicker, "it's dragged faster and faster")
sink, glow = ToLobby.drag(ToLobby.Land - 0.001)
ok(sink > ToLobby.DragDepth * 0.99 and glow == 1, "nearly under, still lit, as the fall lands")
sink, glow = ToLobby.drag(ToLobby.Land)
ok(sink == ToLobby.DragDepth and glow == 1, "under by the landing")
ok(ToLobby.DragDepth >= 7, "deep enough that a tall avatar's head is under the floor")
ok(ToLobby.Land < ToLobby.Swap, "under before the server swaps the body")
sink, glow = ToLobby.drag(ToLobby.Land + ToLobby.DragFade)
ok(sink == ToLobby.DragDepth and glow == 0, "the red gone after, the body still under")

print(`tolobby.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
