--!strict
-- lune run tests/keepermotion.spec
-- How a keeper's movement reaches screens (L-06b4a): a record reads back as it was sent and
-- garbage is refused; a record carries it on only as far as it stops; the server sends one only
-- when its motion changes (a straight walk is its start and its stop) and never more than one each
-- `Gap` while it walks on. A screen shown records on time (or early) shows it within a hair of
-- where it truly was at the time it shows, turns and stops included. Late, jittered or on a slow
-- phone, a screen never shows it walking past where it stops, eases every correction out without
-- a hop, never walks its pose backward, and settles exactly where it stopped, facing the way it
-- faces, then needs no more steps. A big jump snaps; a turn eases without overshooting.
local KeeperMotion = require("../src/shared/KeeperMotion")

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

local SERVER_DT = 1 / 60
local function v(x: number, z: number): vector
	return vector.create(x, 0, z)
end
local function dist(a: vector, b: vector): number
	return vector.magnitude(a - b)
end

-- Records: they read back as sent, garbage is refused, endless trips are capped.
do
	local r = KeeperMotion.record()
	local s = KeeperMotion.encode(
		1762732800.1234,
		vector.create(-90.123, 3.5, -700.456),
		vector.create(0.6, 0, -0.8),
		12.8,
		math.huge,
		4321.567,
		"Hunting"
	)
	ok(KeeperMotion.decode(s, r), "a record reads")
	ok(r.state == "Hunting", "its state reads back")
	ok(math.abs(r.t - 1762732800.123) < 1e-3, "its time reads back to the millisecond")
	ok(dist(r.at, vector.create(-90.12, 3.5, -700.46)) < 0.01, "where it is reads back")
	ok(dist(r.facing, vector.create(0.6, 0, -0.8)) < 1e-4, "the way it faces reads back")
	ok(math.abs(vector.magnitude(r.facing) - 1) < 1e-5, "its facing reads back length 1")
	ok(r.speed == 12.8 and r.left == 999, "its pace reads back; an endless trip is capped")
	ok(math.abs(r.travelled - 4321.57) < 1e-6, "how far it walked reads back")
	local before = r.t
	for _, bad in
		{ "", "Hunting", "Hunting 1 2 3", "Hunting a b c d e f g h i", "1 1 1 1 1 1 1 1 1 1" }
	do
		ok(not KeeperMotion.decode(bad, r), `refuses "{bad}"`)
	end
	ok(not KeeperMotion.decode("Roaming 1 0 0 0 0 0 1 1 1", r), "refuses a record facing nowhere")
	ok(r.t == before and r.state == "Hunting", "a refused record leaves the last as it was")
end

-- Predicting: on the way it walks, never past where it stops; standing, where it stands.
do
	local r = KeeperMotion.record()
	r.t, r.at, r.facing, r.speed, r.left, r.travelled = 10, v(0, 0), v(1, 0), 8, 5, 100
	local at, travelled = KeeperMotion.predict(r, 10.5)
	ok(dist(at, v(4, 0)) < 1e-5 and math.abs(travelled - 104) < 1e-9, "carries it on")
	at, travelled = KeeperMotion.predict(r, 30)
	ok(dist(at, v(5, 0)) < 1e-5 and math.abs(travelled - 105) < 1e-9, "never past its stop")
	at = KeeperMotion.predict(r, 9)
	ok(dist(at, v(0, 0)) < 1e-6, "never before its record")
	r.speed = 0
	at = KeeperMotion.predict(r, 20)
	ok(dist(at, v(0, 0)) < 1e-6, "standing, it stands")
	ok(KeeperMotion.how("Asleep", 0) == "Still", "asleep, it's slack")
	ok(KeeperMotion.how("Roaming", 4) == "Walk", "walking, it walks")
	ok(KeeperMotion.how("Waiting", 0) == "Stop", "standing, it's stopped mid-stride")
	ok(KeeperMotion.how("Hunting", 0) == "Stop", "at arm's length, it's stopped mid-stride")
end

-- A keeper on the server walking `points` at `speed`, starting at `start` and stopping at the
-- last, every SERVER_DT; what it sends; and where it truly was at each step.
type Sent = { t: number, s: string }
type Run = {
	sent: { Sent },
	truth: { vector },
	stopAt: vector,
	stopFacing: vector,
	lastLeg: number, -- when it set off on its last leg
	ends: number,
}
local function serve(
	points: { vector },
	speed: number,
	start: number,
	until_: number,
	hunting: number?
): Run
	local last = KeeperMotion.record()
	local have = false
	local sent: { Sent } = {}
	local truth: { vector } = {}
	local at = points[1]
	local facing = vector.normalize(points[2] - points[1])
	local seg, travelled = 1, 0
	local step = 0
	local lastLeg = math.huge
	local stopFacing = facing
	for i = #points, 2, -1 do
		if dist(points[i], points[i - 1]) > 1e-6 then
			stopFacing = vector.normalize(points[i] - points[i - 1])
			break
		end
	end
	while step * SERVER_DT <= until_ do
		local t = step * SERVER_DT
		local moved = 0
		if t > start then
			local studs = speed * SERVER_DT
			while studs > 1e-9 and seg < #points do
				local d = points[seg + 1] - at
				local len = vector.magnitude(d)
				if len > 1e-9 then
					facing = d / len
				end
				if len <= studs then
					at, studs, moved, seg = points[seg + 1], studs - len, moved + len, seg + 1
				else
					at, moved, studs = at + facing * studs, moved + studs, 0
				end
			end
		end
		travelled += moved
		if seg >= #points - 1 and moved > 0 then
			lastLeg = math.min(lastLeg, t)
		end
		local pace = if moved > 1e-9 then speed else 0
		local state = if hunting then "Hunting" elseif pace > 0 then "Roaming" else "Waiting"
		local left = if seg < #points then dist(at, points[seg + 1]) else 0
		for j = seg + 1, #points - 1 do
			left += dist(points[j], points[j + 1])
		end
		if hunting then
			-- it stops at arm's length from where you are now: `hunting` studs on, or its trip's end
			left = math.min(left, hunting)
		end
		truth[step + 1] = at
		if KeeperMotion.due(if have then last else nil, t, at, facing, pace, state) then
			local s = KeeperMotion.encode(t, at, facing, pace, left, travelled, state)
			KeeperMotion.decode(s, last)
			have = true
			table.insert(sent, { t = t, s = s })
		end
		step += 1
	end
	return {
		sent = sent,
		truth = truth,
		stopAt = points[#points],
		stopFacing = stopFacing,
		lastLeg = lastLeg,
		ends = until_,
	}
end

-- Where it truly was at server time `t`.
local function truthAt(run: Run, t: number): vector
	local i = math.clamp(t / SERVER_DT, 0, #run.truth - 1)
	local lo = math.floor(i)
	local hi = math.min(lo + 1, #run.truth - 1)
	return run.truth[lo + 1] + (run.truth[hi + 1] - run.truth[lo + 1]) * (i - lo)
end

-- A screen shown `run`'s records `latency` seconds after they're sent (plus up to `jitter` more,
-- but in order, as attributes are), drawing a frame each `frame` seconds.
type Watch = {
	worstOff: number, -- furthest from where it truly was at the time shown
	worstPast: number, -- furthest past its stop, along the way it stopped facing
	fastest: number, -- the most it moved in one frame, over its speed's move
	backward: boolean, -- its pose ever went back
	settledAt: vector,
	settledFacing: vector,
	settled: boolean,
}
local function watch(run: Run, speed: number, latency: number, jitter: number, frame: number): Watch
	local f = KeeperMotion.follow()
	local seed = 7
	local function random(): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
	local arrivals: { number } = {}
	local lastArrival = -math.huge
	for i, s in run.sent do
		lastArrival = math.max(lastArrival, s.t + latency + jitter * random())
		arrivals[i] = lastArrival
	end
	local w: Watch = {
		worstOff = 0,
		worstPast = -math.huge,
		fastest = 0,
		backward = false,
		settledAt = vector.zero,
		settledFacing = vector.zero,
		settled = false,
	}
	local next = 1
	local now = 0
	local shown: vector? = nil
	local travelled = -math.huge
	local moving = true
	while now <= run.ends + 1.5 do
		local t = now - KeeperMotion.Delay
		while next <= #run.sent and arrivals[next] <= now do
			KeeperMotion.receive(f, run.sent[next].s, t)
			next += 1
		end
		moving = KeeperMotion.update(f, t, frame)
		if f.count > 0 then
			if t >= 0 then
				w.worstOff = math.max(w.worstOff, dist(f.at, truthAt(run, t)))
			end
			if t >= run.lastLeg then
				w.worstPast = math.max(w.worstPast, vector.dot(f.at - run.stopAt, run.stopFacing))
			end
			if shown then
				w.fastest = math.max(w.fastest, dist(f.at, shown) / (speed * frame))
			end
			shown = f.at
			if f.travelled < travelled then
				w.backward = true
			end
			travelled = f.travelled
		end
		now += frame
	end
	w.settledAt, w.settledFacing, w.settled = f.at, f.facing, not moving
	return w
end

local SPEED = 16 -- a hunt at a player's full run
local ROUTES: { [string]: { vector } } = {
	straight = { v(0, 0), v(40, 0) },
	corner = { v(0, 0), v(30, 0), v(30, 24) },
	["two corners"] = { v(0, 0), v(20, 0), v(20, 20), v(44, 20) },
	["back on itself"] = { v(0, 0), v(20, 0), v(20, 8), v(4, 8) },
}

for name, points in ROUTES do
	local run = serve(points, SPEED, 0.5, 6)
	-- only when its motion changes: standing, starting, each turn, stopping, and once or twice as
	-- it nears its stop
	ok(
		#run.sent >= #points + 1 and #run.sent <= #points + 3,
		`{name}: sent {#run.sent} records, not {#points + 1} to {#points + 3}`
	)
	for _, case in
		{
			{ latency = 0, jitter = 0, frame = 1 / 60, on = true },
			{ latency = 0.05, jitter = 0.03, frame = 1 / 60, on = true },
			{ latency = 0.08, jitter = 0, frame = 1 / 30, on = true },
			{ latency = 0.15, jitter = 0.05, frame = 1 / 60, on = false },
			{ latency = 0.2, jitter = 0, frame = 1 / 30, on = false },
			{ latency = 0.3, jitter = 0.1, frame = 1 / 60, on = false },
		}
	do
		local what = `{name}, {case.latency * 1000} ms late, {math.round(1 / case.frame)} fps`
		local w = watch(run, SPEED, case.latency, case.jitter, case.frame)
		if case.on then
			ok(w.worstOff < 0.3, `{what}: within {w.worstOff} studs of where it truly was`)
			ok(w.fastest < 1.1, `{what}: never faster than it walks ({w.fastest})`)
		elseif case.latency <= 0.2 then
			ok(w.fastest < 3, `{what}: eases corrections out, no hop ({w.fastest})`)
		end
		ok(w.worstPast < 0.01, `{what}: never past where it stops ({w.worstPast})`)
		ok(not w.backward, `{what}: its walk never goes backward`)
		ok(dist(w.settledAt, run.stopAt) < 0.01, `{what}: settles where it stopped`)
		ok(dist(w.settledFacing, run.stopFacing) < 0.01, `{what}: settles facing its way`)
		ok(w.settled, `{what}: then needs no more steps`)
	end
end

-- Hunting, it stops and starts in one state, so its stop may go up to a Gap late: never walked
-- past. Each record says it stops at arm's length from where you are now, 2 studs on, and you keep
-- running: screens never stall at those stops while it walks on.
for name, points in ROUTES do
	local run = serve(points, SPEED, 0.5, 6, 2)
	local length = 0
	for i = 2, #points do
		length += dist(points[i], points[i - 1])
	end
	ok(
		#run.sent <= length / SPEED / KeeperMotion.Gap + 4,
		`{name}, hunting: sent {#run.sent} records`
	)
	for _, case in { { latency = 0, frame = 1 / 60 }, { latency = 0.05, frame = 1 / 60 } } do
		local what = `{name}, hunting, {case.latency * 1000} ms late`
		local w = watch(run, SPEED, case.latency, 0, case.frame)
		-- a turn may wait up to a Gap behind the last renewal, so a corner is cut a little
		ok(w.worstOff < 0.6, `{what}: within {w.worstOff} studs of where it truly was`)
		ok(w.fastest < 1.25, `{what}: never much faster than it walks ({w.fastest})`)
	end
	for _, latency in { 0, 0.1, 0.25 } do
		local w = watch(run, SPEED, latency, 0.02, 1 / 60)
		local what = `{name}, hunting, {latency * 1000} ms late`
		ok(w.worstPast < 0.01, `{what}: never past where it stops ({w.worstPast})`)
		ok(dist(w.settledAt, run.stopAt) < 0.01, `{what}: settles where it stopped`)
		ok(w.settled, `{what}: then needs no more steps`)
	end
end

-- A hunter at arm's length stepping in and stopping every step as you shuffle: one record each
-- Gap at most.
do
	local f = KeeperMotion.record()
	local have, sent = false, 0
	local at = v(0, 0)
	for step = 0, 119 do
		local moving = step % 2 == 0
		if moving then
			at += v(0.05, 0)
		end
		local pace = if moving then SPEED else 0
		if KeeperMotion.due(if have then f else nil, step / 60, at, v(1, 0), pace, "Hunting") then
			KeeperMotion.decode(
				KeeperMotion.encode(step / 60, at, v(1, 0), pace, 0.05, 0, "Hunting"),
				f
			)
			have = true
			sent += 1
		end
	end
	ok(sent <= 2 / KeeperMotion.Gap + 1, `shuffling at arm's length, {sent} records in 2 s`)
end

-- Walking a curve (a hunt after a player who keeps turning): no more than one record each Gap.
do
	local points: { vector } = {}
	for i = 0, 200 do
		local a = i / 200 * math.pi * 1.5
		table.insert(points, v(30 * math.sin(a), 30 - 30 * math.cos(a)))
	end
	local run = serve(points, SPEED, 0, 9)
	local walked = 0
	local gaps = true
	for i = 2, #run.sent do
		local s, p = run.sent[i], run.sent[i - 1]
		local startsOrStops = string.find(s.s, "^Waiting") or string.find(p.s, "^Waiting")
		if s.t - p.t < KeeperMotion.Gap - 1e-9 and not startsOrStops then
			gaps = false
		end
		if string.find(s.s, "^Roaming") then
			walked += 1
		end
	end
	local seconds = 1.5 * math.pi * 30 / SPEED
	ok(gaps, "on a curve, one record each Gap at most while it walks on")
	ok(walked <= seconds / KeeperMotion.Gap + 2, `on a curve, {walked} records in {seconds} s`)
	local w = watch(run, SPEED, 0.05, 0.02, 1 / 60)
	ok(w.worstOff < 0.6, `on a curve, within {w.worstOff} studs of where it truly was`)
	ok(w.fastest < 1.3, `on a curve, never much faster than it walks ({w.fastest})`)
	ok(dist(w.settledAt, run.stopAt) < 0.01, "on a curve, settles where it stopped")
end

-- A big jump snaps, a small one eases; stale records and garbage change nothing.
do
	local f = KeeperMotion.follow()
	local function rec(t: number, at: vector, facing: vector, state: string): string
		return KeeperMotion.encode(t, at, facing, 0, 0, 0, state)
	end
	ok(not KeeperMotion.update(f, 0, 1 / 60), "with nothing yet, nothing to step")
	ok(KeeperMotion.receive(f, rec(1, v(0, 0), v(0, 1), "Waiting"), 1), "takes a first record")
	ok(dist(f.at, v(0, 0)) < 1e-6 and dist(f.facing, v(0, 1)) < 1e-6, "the first is shown as it is")
	ok(
		not KeeperMotion.receive(f, rec(1, v(5, 0), v(0, 1), "Waiting"), 1),
		"refuses a stale record"
	)
	ok(not KeeperMotion.receive(f, "nonsense", 1), "refuses garbage")
	ok(dist(f.at, v(0, 0)) < 1e-6, "neither moved it")
	KeeperMotion.receive(f, rec(2, v(30, 0), v(0, 1), "Waiting"), 3)
	KeeperMotion.update(f, 3, 1 / 60)
	ok(dist(f.at, v(30, 0)) < 1e-6, "a jump of 30 studs snaps")
	KeeperMotion.receive(f, rec(3, v(31, 0), v(0, 1), "Waiting"), 4)
	KeeperMotion.update(f, 4, 1 / 60)
	ok(dist(f.at, v(30, 0)) < 0.2 and f.at.x > 30, "a jump of 1 stud eases")
	for i = 1, 60 do
		KeeperMotion.update(f, 4 + i / 60, 1 / 60)
	end
	ok(dist(f.at, v(31, 0)) < 0.01, "and has eased out within a second")

	-- a turn eases toward the way it faces, never past it
	KeeperMotion.receive(f, rec(5, v(31, 0), v(1, 0), "Waiting"), 6)
	local angle = 0
	local over = false
	local still = 0
	for i = 1, 60 do
		local moving = KeeperMotion.update(f, 6 + i / 60, 1 / 60)
		local a = math.atan2(f.facing.x, f.facing.z)
		if a < angle - 1e-6 or a > math.pi / 2 + 1e-6 then
			over = true
		end
		angle = a
		if not moving then
			still += 1
		end
	end
	ok(not over, "a turn never overshoots")
	ok(dist(f.facing, v(1, 0)) < 1e-6, "a quarter turn is done within a second")
	ok(still > 20, "then it needs no more steps")
end

-- Your own beam (L-06b4b3): the screen holds it the frame the beam lands, exactly where and as
-- it was shown, while the server's stop comes a little further on; it never slides while held,
-- lets go only once the screen reaches the server letting it go, and then makes the gap up as it
-- walks, never stepping back, a little quicker than it walks, until it's where the records say.
-- No stop within its patience (a wall the screen missed), it walks on the same way.
do
	ok(math.abs(KeeperMotion.patience(0) - KeeperMotion.Patience) < 1e-9, "patience, no ping")
	ok(
		math.abs(KeeperMotion.patience(0.1) - (KeeperMotion.Patience + 0.2)) < 1e-9,
		"plus two pings"
	)
	ok(KeeperMotion.patience(5) == KeeperMotion.MostPatience, "never past the most")
	ok(KeeperMotion.patience(0 / 0) == KeeperMotion.Patience, "a broken ping counts as none")

	local SPEED, LATENCY, FRAME = 10, 0.05, 1 / 60
	local function walking(t: number, x: number, travelled: number): string
		return KeeperMotion.encode(t, v(x, 0), v(1, 0), SPEED, 999, travelled, "Hunting")
	end
	local function standing(t: number, x: number, travelled: number): string
		return KeeperMotion.encode(t, v(x, 0), v(1, 0), 0, 0, travelled, "Hunting")
	end
	-- Plays the screen from server time `from` to `to`, a frame at a time, handing it each of
	-- `sends` ({server time, record}) `LATENCY` after it was sent; calls `each(t)` after each frame.
	local function play(
		f: KeeperMotion.Follow,
		sends: { { any } },
		from: number,
		to: number,
		each: (t: number) -> ()
	)
		local n = math.floor((to - from) / FRAME + 0.5)
		for i = 1, n do
			local now = from + i * FRAME
			for _, s in sends do
				if s[1] + LATENCY <= now and not s[3] then
					s[3] = true
					KeeperMotion.receive(f, s[2], now - KeeperMotion.Delay)
				end
			end
			KeeperMotion.update(f, now - KeeperMotion.Delay, FRAME)
			each(now - KeeperMotion.Delay)
		end
	end

	-- held, answered by the server's stop 1.6 studs on, let go a second later
	local f = KeeperMotion.follow()
	local sends = {
		{ 0, walking(0, 0, 0) },
		{ 1.16, standing(1.16, 11.6, 11.6) }, -- it froze when your look reached the server
		{ 2.2, walking(2.2, 11.6, 11.6) }, -- the light left
	}
	play(f, sends, -0.2, 1, function() end)
	ok(f.speed > 0 and math.abs(f.at.x - 9) < 0.2, "walking, shown a Delay behind")
	ok(not KeeperMotion.hold(KeeperMotion.follow(), 0.9, 0.2), "nothing to hold with no record")
	ok(KeeperMotion.hold(f, 1 - KeeperMotion.Delay, 0.2), "your beam lands: it holds")
	ok(f.speed == 0 and KeeperMotion.how(f.state, f.speed) == "Stop", "posed stopped at once")
	ok(not KeeperMotion.hold(f, 1 - KeeperMotion.Delay, 0.2), "held already")
	local heldAt, heldTravelled = f.at, f.travelled
	local slid, heldUntil = 0, -1
	play(f, sends, 1, 2.5, function(t)
		if f.held then
			slid = math.max(slid, dist(f.at, heldAt), math.abs(f.travelled - heldTravelled))
			heldUntil = t
		end
	end)
	ok(slid == 0, `never slides or steps while held ({slid})`)
	ok(
		heldUntil >= 2.2 - 2 * FRAME and heldUntil < 2.2,
		`held until the let-go shows ({heldUntil})`
	)
	ok(f.stopped > 1.15 and f.stopped < 1.17, "the server's stop answered it")
	local back, fastest, lastX, lastWalk = 0, 0, f.at.x, f.travelled
	play(f, sends, 2.5, 8, function()
		back = math.max(back, lastX - f.at.x, lastWalk - f.travelled)
		fastest = math.max(fastest, (f.at.x - lastX) / FRAME)
		lastX, lastWalk = f.at.x, f.travelled
	end)
	ok(back <= 0, "walking on, never a step back")
	ok(fastest < SPEED * 1.4, `makes the gap up a little quicker than it walks ({fastest})`)
	ok(fastest > SPEED * 1.1, "but does make it up")
	local truth = 11.6 + SPEED * (8 - KeeperMotion.Delay - 2.2)
	ok(math.abs(f.at.x - truth) < 0.01, `and is where the records say ({f.at.x} vs {truth})`)
	ok(f.behind == vector.zero and f.behindWalk == 0, "with nothing left to make up")

	-- no stop comes within its patience: it walks on, the same way
	local g = KeeperMotion.follow()
	local alone = { { 0, walking(0, 0, 0) } }
	play(g, alone, -0.2, 1, function() end)
	ok(KeeperMotion.hold(g, 1 - KeeperMotion.Delay, 0.2), "held on your beam's word")
	local heldFor = 0
	play(g, alone, 1, 1.5, function()
		if g.held then
			heldFor += FRAME
		end
	end)
	ok(heldFor > 0.2 - 2 * FRAME and heldFor < 0.2 + FRAME, `held its patience only ({heldFor})`)
	local x = g.at.x
	local stepBack = 0
	play(g, alone, 1.5, 7, function()
		stepBack = math.max(stepBack, x - g.at.x)
		x = g.at.x
	end)
	ok(stepBack <= 0, "walks on from where it held, never back")
	ok(math.abs(g.at.x - SPEED * (7 - KeeperMotion.Delay)) < 0.01, "and catches up with its walk")

	-- a stop far from where it's held (it was stood somewhere new): lets go and is shown there
	local h = KeeperMotion.follow()
	local far = { { 0, walking(0, 0, 0) }, { 1.05, standing(1.05, 30, 30) } }
	play(h, far, -0.2, 1, function() end)
	KeeperMotion.hold(h, 1 - KeeperMotion.Delay, 0.2)
	play(h, far, 1, 1.5, function() end)
	ok(not h.held and dist(h.at, v(30, 0)) < 1e-6, "a far stop lets go at once, a jump")

	-- let go just short of where its record stops it (a hunter at arm's length): the gap is made
	-- up by the time it stops, so it never stands short of where it truly stands
	local c = KeeperMotion.follow()
	local short = {
		{ 0, walking(0, 0, 0) },
		{ 1.16, standing(1.16, 11.6, 11.6) },
		{ 2.2, KeeperMotion.encode(2.2, v(11.6, 0), v(1, 0), SPEED, 1.5, 11.6, "Hunting") },
	}
	play(c, short, -0.2, 1, function() end)
	KeeperMotion.hold(c, 1 - KeeperMotion.Delay, 0.2)
	local cx, cBack = 0, 0
	play(c, short, 1, 3, function()
		cBack = math.max(cBack, cx - c.at.x)
		cx = c.at.x
	end)
	ok(cBack <= 0, "it closes the gap without a step back")
	ok(math.abs(c.at.x - 13.1) < 1e-3, `and stands where it stops ({c.at.x})`)
	ok(c.behind == vector.zero, "nothing left behind")

	-- standing, asleep: nothing to hold
	local s = KeeperMotion.follow()
	KeeperMotion.receive(s, standing(0, 0, 0), 0)
	KeeperMotion.update(s, 0.1, FRAME)
	ok(not KeeperMotion.hold(s, 0.1, 0.2), "a body standing isn't held")
	local a = KeeperMotion.follow()
	KeeperMotion.receive(a, KeeperMotion.encode(0, v(0, 0), v(1, 0), 5, 9, 0, "Asleep"), 0)
	KeeperMotion.update(a, 0.1, FRAME)
	ok(not KeeperMotion.hold(a, 0.1, 0.2), "nor one asleep")
end

print(`keepermotion: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
