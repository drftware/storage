--!strict
-- lune run tests/record.spec
-- Recording (S1-02, the GDD's "What the game needs to record"): the plan passes Brix's checks, and
-- each moment the game records arrives once, as the plan says, through Brix's Analytics: a unit
-- opened and what it gave, the first one's wait, coins from a pile and at the gate, a ride, finds
-- kept, a catch and a freeing, a climb's end for each player, coins turned into cash, Again, a
-- lobby car leaving. The
-- climb funnel steps once a climb; floors past 40 and teams past 8 share a label; every name and
-- label fits Roblox's 50 bytes. Anything the plan doesn't declare is refused.
local Brix = require("../vendor/brix/src")
local Record = require("../src/shared/Record")

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

type Rec = Brix.AnalyticsRecord<string>

-- A record's fields as "name=label, ..." in the plan's order.
local function labels(record: Rec): string
	local parts = {}
	for _, f in record.fields do
		table.insert(parts, `{f.name}={f.label}`)
	end
	return table.concat(parts, ", ")
end

-- A fresh book over a recorder; any problem fails the spec.
local function fresh(): (Record.Book<string>, Brix.AnalyticsRecorder<string>, { string })
	local recorder = Brix.AnalyticsSink.recorder() :: Brix.AnalyticsRecorder<string>
	local problems: { string } = {}
	local analytics = Brix.Analytics.new({
		plan = Record.plan(Brix),
		sink = recorder,
		onProblem = function(problem: string)
			table.insert(problems, problem)
		end,
	})
	return Record.new(analytics), recorder, problems
end

-- The plan is one Brix takes.
do
	local made = pcall(function()
		Brix.Analytics.new({ plan = Record.plan(Brix), sink = Brix.AnalyticsSink.recorder() })
	end)
	ok(made, "the plan passes Analytics.new's checks")
end

-- What a unit gave.
do
	ok(Record.gave({ kind = "Nothing", coins = 0 }) == "nothing", "an empty unit gave nothing")
	ok(Record.gave({ kind = "Nothing", coins = 2 }) == "coins", "a pile alone gave coins")
	ok(Record.gave({ kind = "Find", coins = 1 }) == "find", "a find before the coins beside it")
	ok(Record.gave({ kind = "Tool", coins = 0 }) == "tool", "a tool")
	ok(Record.gave({ kind = "Asleep", coins = 0 }) == "keeper", "a sleeping keeper")
	ok(Record.gave({ kind = "Awake", coins = 3 }) == "keeper", "an awake keeper")
end

-- The counted fields: their own labels up to the most, then one shared, nothing else.
do
	local floor = Record.counted(0, Record.FloorMost)
	ok(floor:label(0) == "0", "the test hall is floor 0")
	ok(floor:label(7) == "7", "floor 7 is 7")
	ok(floor:label(40) == "40", "floor 40 is its own")
	ok(floor:label(41) == "41+" and floor:label(900) == "41+", "past 40 share 41+")
	local bad = { -1, 2.5, 0 / 0, math.huge, "3", nil, true }
	for i = 1, 7 do
		local label, problem = floor:label(bad[i])
		ok(label == nil and type(problem) == "string", `floor refuses bad value {i}`)
	end
	local team = Record.counted(1, Record.TeamMost)
	ok(team:label(1) == "1" and team:label(8) == "8" and team:label(12) == "9+", "teams")
	ok(team:label(0) == nil, "no team of nobody")
end

-- A climb, floor 1 to 2, two friends: every record in order.
do
	local book, recorder, problems = fresh()
	book:joined("ana", 10)
	book:joined("ben", 12)
	book:began({ "ana", "ben" }, 1, "run-a")
	book:opened("ana", 1, { kind = "Nothing", coins = 2 }, 31.26)
	book:earned("ana", 2, 2, "pile", 1)
	book:opened("ana", 1, { kind = "Find", coins = 0 }, 40)
	book:opened("ben", 1, { kind = "Asleep", coins = 0 }, 50)
	book:caught("ben", 1)
	book:freed("ben", 1)
	book:rode({ "ana", "ben" }, 1)
	book:earned("ana", 10, 12, "gate", 1)
	book:earned("ben", 10, 10, "gate", 1)
	book:kept("ana", { "Teddy", "Boombox" }, 1)
	book:reached({ "ana", "ben" }, 2)
	book:earned("ana", 1, 13, "pile", 2)
	book:ended({
		{ player = "ana", fate = "Kept", floor = 2 },
		{ player = "ben", fate = "Left", floor = 2 },
	})
	book:again("ben")

	ok(#problems == 0, `no problems ({problems[1]})`)
	local records = recorder:records()
	local said: { string } = {}
	for _, r in records do
		local line
		if r.kind == "event" then
			line = `{r.player} event {r.name} {r.value} ({labels(r)})`
		elseif r.kind == "economy" then
			line =
				`{r.player} {r.flow} {r.amount} {r.currency} {r.reason} {r.balance} ({labels(r)})`
		elseif r.kind == "funnel" then
			line = `{r.player} funnel {r.funnel} {r.step} {r.stepName} {r.run}`
		else
			line = `{r.player} progress {r.path} {r.status} {r.level}`
		end
		table.insert(said, line)
	end
	local want = {
		"ana progress climb started 1",
		"ana funnel climb 1 began run-a",
		"ben progress climb started 1",
		"ben funnel climb 1 began run-a",
		"ana event doorOpened 1 (floor=1, gave=coins)",
		"ana event firstDoor 21.3 (floor=1)",
		"ana funnel climb 2 door run-a",
		"ana earned 2 Coins pile 2 (floor=1)",
		"ana funnel climb 3 coins run-a",
		"ana event doorOpened 1 (floor=1, gave=find)",
		"ben event doorOpened 1 (floor=1, gave=keeper)",
		"ben event firstDoor 38 (floor=1)",
		"ben funnel climb 2 door run-a",
		"ben event caught 1 (floor=1)",
		"ben event freed 0 (floor=1)",
		"ana progress climb completed 1",
		"ana funnel climb 4 rode run-a",
		"ben progress climb completed 1",
		"ben funnel climb 4 rode run-a",
		"ana earned 10 Coins gate 12 (floor=1)",
		"ben earned 10 Coins gate 10 (floor=1)",
		"ana event findKept 1 (find=Teddy, floor=1)",
		"ana event findKept 1 (find=Boombox, floor=1)",
		"ana funnel climb 5 kept run-a",
		"ana progress climb started 2",
		"ben progress climb started 2",
		"ana earned 1 Coins pile 13 (floor=2)",
		"ana event climbEnded 2 (floor=2, fate=kept, team=2)",
		"ana progress climb failed 2",
		"ben event climbEnded 2 (floor=2, fate=left, team=2)",
		"ben progress climb failed 2",
		"ben event again 1 ()",
	}
	ok(#said == #want, `{#want} records, got {#said}`)
	for i = 1, math.max(#said, #want) do
		ok(said[i] == want[i], `record {i}: want "{want[i]}", got "{said[i]}"`)
	end

	-- every name and label fits Roblox's 50 bytes and isn't empty
	for i, r in records do
		local texts: { string } = {}
		if r.kind == "event" then
			table.insert(texts, r.name)
		elseif r.kind == "economy" then
			table.insert(texts, r.currency)
			table.insert(texts, r.reason)
		elseif r.kind == "funnel" then
			table.insert(texts, r.funnel)
			table.insert(texts, r.stepName)
			table.insert(texts, r.run or "")
		else
			table.insert(texts, r.path)
		end
		for _, f in r.fields do
			table.insert(texts, f.name)
			table.insert(texts, f.label)
		end
		for _, text in texts do
			ok(#text >= 1 and #text <= 50, `record {i}: "{text}" is 1 to 50 bytes`)
		end
	end
end

-- The funnel steps once a climb, again in the next; reaching the top ends without a failure.
do
	local book, recorder = fresh()
	book:began({ "ana" }, 1, "run-a")
	book:earned("ana", 1, 1, "pile", 1)
	book:earned("ana", 2, 3, "pile", 1) -- a second pile: no second step
	book:rode({ "ana" }, 1)
	book:rode({ "ana" }, 2) -- a second ride: no second step
	book:ended({ { player = "ana", fate = "Out", floor = 2 } })
	book:began({ "ana" }, 1, "run-b")
	book:earned("ana", 1, 1, "pile", 1)
	local funnel, failed = {}, 0
	for _, r in recorder:records() do
		if r.kind == "funnel" then
			table.insert(funnel, `{r.stepName}@{r.run}`)
		elseif r.kind == "progress" and r.status == "failed" then
			failed += 1
		end
	end
	local said = table.concat(funnel, " ")
	ok(said == "began@run-a coins@run-a rode@run-a began@run-b coins@run-b", `funnel: {said}`)
	ok(failed == 0, "reaching the top isn't a failure")
end

-- No climb under way: nothing goes to the funnel; the first door is timed once a server.
do
	local book, recorder = fresh()
	book:joined("ana", 0)
	book:opened("ana", 0, { kind = "Nothing", coins = 0 }, 5) -- the test hall
	book:opened("ana", 0, { kind = "Nothing", coins = 0 }, 9)
	local firsts, funnels = 0, 0
	for _, r in recorder:records() do
		if r.kind == "event" and r.name == "firstDoor" then
			firsts += 1
			ok(r.value == 5, "the first door's wait")
		elseif r.kind == "funnel" then
			funnels += 1
		end
	end
	ok(firsts == 1, "the first door is timed once")
	ok(funnels == 0, "no climb, no funnel")
	-- someone who left and came back is timed from their new join
	book:gone("ana")
	book:joined("ana", 100)
	book:opened("ana", 0, { kind = "Nothing", coins = 0 }, 104)
	local last = recorder:records()
	local r = last[#last]
	ok(r.kind == "event" and r.name == "firstDoor" and r.value == 4, "timed again after leaving")
end

-- Carried up wrapped: the floors between the catch and the cut.
do
	local book, recorder = fresh()
	book:began({ "ana" }, 3, "run-a")
	book:caught("ana", 3)
	book:freed("ana", 5)
	local last = recorder:records()
	local r = last[#last]
	ok(r.kind == "event" and r.name == "freed" and r.value == 2, "carried up two floors")
	ok(labels(r) == "floor=5", "freed on floor 5")
end

-- A lobby car leaving: each rider's wait from joining, and the team; past 8 share a label.
do
	local book, recorder = fresh()
	local riders = {}
	for i = 1, 10 do
		local name = `p{i}`
		book:joined(name, i)
		table.insert(riders, name)
	end
	book:carLeft(riders, 20)
	local records = recorder:records()
	ok(#records == 10, "one record a rider")
	local r = records[1]
	ok(r.kind == "event" and r.name == "carLeft" and r.value == 19, "p1 waited 19 s")
	ok(labels(r) == "team=9+", `ten share 9+ ({labels(r)})`)
	-- a rider this server never saw join isn't timed
	book:carLeft({ "stranger" }, 30)
	ok(#recorder:records() == 10, "a stranger isn't timed")
end

-- The coins left at a climb's end turned into cash (S1-12): coins out, cash in, nothing for none.
do
	local book, recorder, problems = fresh()
	book:cashed("ana", 38, 38, 1250, 3)
	book:cashed("ben", 0, 0, 40, 3)
	ok(#problems == 0, `no problems ({problems[1]})`)
	local records = recorder:records()
	ok(#records == 2, "two records for ana, none for ben")
	local out, into = records[1], records[2]
	ok(
		out.kind == "economy"
			and out.flow == "spent"
			and out.currency == "Coins"
			and out.amount == 38
			and out.balance == 0
			and out.reason == "cashOut",
		"ana's coins go out"
	)
	ok(
		into.kind == "economy"
			and into.flow == "earned"
			and into.currency == "Cash"
			and into.amount == 38
			and into.balance == 1250
			and into.reason == "climb",
		"ana's cash comes in, with their saved total"
	)
	ok(labels(into) == "floor=3", `on the floor it ended ({labels(into)})`)
end

-- What the plan doesn't declare is refused: a find no unit holds, a reason not listed.
do
	local book, recorder, problems = fresh()
	book:kept("ana", { "Lamp" }, 1)
	book:earned("ana", 5, 5, "found" :: any, 1) -- any: a reason the type forbids, as a bug would pass
	ok(#recorder:records() == 0, "nothing undeclared reaches the sink")
	ok(#problems == 2, `both refused ({#problems})`)
end

print(`record.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
