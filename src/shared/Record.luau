--!strict
--[[
	Record (S1-02, the GDD's "What the game needs to record"): what the game records about each
	player, and the plan it's recorded against, so that every coin, door, catch, find and floor
	has a known worth before anything is priced (the ride's machine, S1-10). Pure: the server's
	Recording hands in Brix (for the plan's fields) and an Analytics made from the plan, and calls
	a book's methods as things happen; the specs hand in Brix's recorder.

	The plan, everything Brix's Analytics will let through (it refuses any record it doesn't
	declare, so a misspelt name never reaches a dashboard):
	- Coins, earned from a pile on a unit's floor (`pile`) or paid at the gate (`gate`), and spent
	  at the car's machine (`machine`, with the item bought: "Battery" or a tool's key, S1-10c2),
	  each with the floor and the player's count after.
	- Cash (S1-12): as a climb ends, the coins a player has left go out (`cashOut`, the item
	  "Cash", their count after 0) and the cash they made comes in (`climb`, their saved total
	  after), each with the floor it ended on.
	- `batteryTaken`: each battery taken from a unit's floor (S1-07b), with the floor; a bought
	  one is a `machine` spend.
	- `doorOpened`: each unit a player first shows, by lifting its door or sawing into it, with
	  the floor and what it gave (nothing, coins, a find, a tool or a keeper). Doors a minute, and
	  the share that gave something, come from these on the dashboard.
	- `firstDoor`: seconds from joining this server to the first unit a player opens, once a
	  server. `carLeft`: seconds from joining the lobby to their car leaving it, with the team's
	  size. Live, the two plus the trip's load make the GDD's "join to first door" (30 or fewer).
	- `caught`, with the floor. `freed`, with the floor and, as its value, how many floors they
	  were carried up wrapped before a friend cut them free (0 while a kept friend stays put).
	- `findKept`: each find kept at the gate, with which find and the floor.
	- `offerShown`: each time a player is put in front of an offer's Roblox purchase prompt
	  (S3-02b), with which offer. Brix's Purchases records `offerBought` for each one bought, so the
	  two make each offer's share of prompts that sell.
	- `climbEnded`: one for each player as a climb ends: its floor (the value too), how it went
	  for them (`out`, `caught` or `left`) and the team's size. `again`: each press of Again.
	- The `climb` path: each floor started as the team reaches it, completed as its gate shuts
	  with them aboard, failed where a player's climb ends there. Roblox's progression dashboard
	  shows where climbs end.
	- The `climb` funnel, once a climb (its run, an id the server makes): began, door, coins, rode,
	  kept: how many climbs get as far as a first door, first coins, a first ride, a first find
	  kept.

	Names and labels are short (Roblox drops any part over 50 bytes). Floors past `FloorMost`
	share one label, as teams past `TeamMost` do, so a dashboard never folds them into "Other".
]]

local Deal = require("./Deal")
local Products = require("./Products")

local Record = {}

-- Floors with a label of their own; higher ones share "41+". Floor 0 is Studio's test hall.
Record.FloorMost = 40
-- Team sizes with a label of their own; bigger ones share "9+".
Record.TeamMost = 8
-- The currencies, as the dashboard names them: coins in a climb, cash kept between climbs.
Record.Currency = "Coins"
Record.Cash = "Cash"

export type Reason = "pile" | "gate"
-- Why coins went out: the car's machine.
export type SpendReason = "machine"
export type Gave = "nothing" | "coins" | "find" | "tool" | "keeper"
export type Fate = "Out" | "Kept" | "Left"
export type Status = "started" | "completed" | "failed"
-- any: each value is checked by its field as the record is made (Brix's `AnalyticsFields`)
export type Fields = { [string]: any }

-- A field of the plan, Brix's AnalyticsField contract: a value's label, or nil and the problem.
export type Field = {
	label: (self: any, value: unknown) -> (string?, string?), -- self: Brix's contract types it any
}

-- What a book records through: Brix's Analytics, as the server and the specs make it.
export type Analytics<P> = {
	event: (self: any, player: P, name: string, value: number?, fields: Fields?) -> string?,
	earned: (
		self: any,
		player: P,
		change: {
			currency: string,
			amount: number,
			balance: number,
			reason: string,
			item: string?,
			fields: Fields?,
		}
	) -> string?,
	spent: (
		self: any,
		player: P,
		change: {
			currency: string,
			amount: number,
			balance: number,
			reason: string,
			item: string?,
			fields: Fields?,
		}
	) -> string?,
	funnel: (
		self: any,
		player: P,
		funnel: string,
		step: string,
		options: { run: string?, fields: Fields? }?
	) -> string?,
	progress: (
		self: any,
		player: P,
		path: string,
		status: Status,
		level: number,
		fields: Fields?
	) -> string?,
}

-- What a unit held as it was opened: Deal's contents, the parts a record reads.
export type Contents = { kind: Deal.Kind, coins: number }

-- How a climb ended for one player: their fate and the floor it happened on.
export type Ending<P> = { player: P, fate: Fate, floor: number }

-- Each moment the game records, as a method; the server calls them as things happen. Times are
-- seconds on one clock (the server's `os.clock`).
export type Book<P> = {
	-- `player` joined this server at `t`.
	joined: (self: any, player: P, t: number) -> (),
	-- `player` left: everything about them is forgotten.
	gone: (self: any, player: P) -> (),
	-- A climb began on floor `floor` with `players` in it; `run` names it (unique, 50 bytes at most).
	began: (self: any, players: { P }, floor: number, run: string) -> (),
	-- `players` were carried up to floor `floor` and start it.
	reached: (self: any, players: { P }, floor: number) -> (),
	-- `player` opened a unit on floor `floor` at `t`, which held `contents`.
	opened: (self: any, player: P, floor: number, contents: Contents, t: number) -> (),
	-- `player` earned `amount` coins for `reason` on floor `floor`, and has `balance` now.
	earned: (
		self: any,
		player: P,
		amount: number,
		balance: number,
		reason: Reason,
		floor: number
	) -> (),
	-- `player` spent `amount` coins on `item` for `reason` on floor `floor`, and has `balance` now.
	spent: (
		self: any,
		player: P,
		amount: number,
		balance: number,
		item: string,
		reason: SpendReason,
		floor: number
	) -> (),
	-- As a climb ended on floor `floor`, `player`'s `coins` left turned into `cash`; `total` is
	-- their saved cash after (S1-12).
	cashed: (
		self: any,
		player: P,
		coins: number,
		cash: number,
		total: number,
		floor: number
	) -> (),
	-- `player` took a battery from a unit's floor on floor `floor`.
	battery: (self: any, player: P, floor: number) -> (),
	-- The gate of floor `floor` shut with `players` aboard.
	rode: (self: any, players: { P }, floor: number) -> (),
	-- `player` kept `finds` (by name) at the gate of floor `floor`.
	kept: (self: any, player: P, finds: { string }, floor: number) -> (),
	-- A keeper caught `player` on floor `floor`.
	caught: (self: any, player: P, floor: number) -> (),
	-- A friend cut `player` free on floor `floor`.
	freed: (self: any, player: P, floor: number) -> (),
	-- The climb ended: how it went for each player in it.
	ended: (self: any, endings: { Ending<P> }) -> (),
	-- `player` pressed Again.
	again: (self: any, player: P) -> (),
	-- `player` was shown Roblox's purchase prompt for the offer named `offer` (a `Products` name).
	shown: (self: any, player: P, offer: string) -> (),
	-- A lobby car left at `t` with `players` aboard.
	carLeft: (self: any, players: { P }, t: number) -> (),
}

-- A field for whole numbers from `least`, each its own label up to `most`, the rest sharing one.
function Record.counted(least: number, most: number): Field
	local labels: { [number]: string } = {}
	for n = least, most do
		labels[n] = tostring(n)
	end
	local past = `{most + 1}+`
	local field = {}
	function field.label(_: any, value: unknown): (string?, string?)
		if type(value) ~= "number" or value ~= value or value % 1 ~= 0 or value < least then
			return nil, `expected a whole number from {least}, got {tostring(value)}`
		end
		return labels[value] or past, nil
	end
	return field
end

-- What a unit gave as it was opened: a keeper or a find or a tool before any coins beside it.
function Record.gave(contents: Contents): Gave
	local kind = contents.kind
	if kind == "Asleep" or kind == "Awake" then
		return "keeper"
	elseif kind == "Find" then
		return "find"
	elseif kind == "Tool" then
		return "tool"
	elseif contents.coins > 0 then
		return "coins"
	end
	return "nothing"
end

-- The plan, built on the Brix package handed in.
-- any: Brix's package (the server reaches it at ReplicatedStorage.Brix, the specs by path), and
-- the plan is Brix's `AnalyticsPlan`, checked by `Analytics.new`.
function Record.plan(brix: any): any
	local oneOf = brix.AnalyticsField.oneOf
	return {
		fields = {
			floor = Record.counted(0, Record.FloorMost),
			team = Record.counted(1, Record.TeamMost),
			gave = oneOf({ "nothing", "coins", "find", "tool", "keeper" }),
			find = oneOf(Deal.Finds),
			fate = oneOf({ "out", "caught", "left" }),
			offer = oneOf(Products.Names),
		},
		events = {
			doorOpened = { "floor", "gave" },
			firstDoor = { "floor" },
			carLeft = { "team" },
			caught = { "floor" },
			freed = { "floor" },
			findKept = { "find", "floor" },
			batteryTaken = { "floor" },
			climbEnded = { "floor", "fate", "team" },
			again = {},
			-- Brix's Purchases records these two itself (S3-02a): each look at the shop, and each
			-- purchase once it's saved, valued at the Robux spent.
			shopViewed = {},
			offerBought = { "offer" },
			-- Each purchase prompt put up (S3-02b): with offerBought, how many prompts sell.
			offerShown = { "offer" },
		},
		economy = {
			currencies = { Record.Currency, Record.Cash },
			reasons = { "pile", "gate", "machine", "cashOut", "climb" },
			fields = { "floor" },
		},
		funnels = {
			climb = { kind = "repeating", steps = { "began", "door", "coins", "rode", "kept" } },
		},
		paths = { climb = {} },
	}
end

local FATES: { [Fate]: string } = { Out = "out", Kept = "caught", Left = "left" }

-- Seconds to a tenth: what a dashboard shows of a wait.
local function tenths(seconds: number): number
	return math.floor(math.max(seconds, 0) * 10 + 0.5) / 10
end

-- A book recording through `analytics`. Each record's problem, if any, goes to the analytics'
-- own `onProblem`; the book goes on.
function Record.new<P>(analytics: Analytics<P>): Book<P>
	local joinedAt: { [P]: number } = {}
	local opened: { [P]: boolean } = {} -- opened a unit on this server
	local caughtOn: { [P]: number } = {} -- the floor each kept player was caught on
	local run: string? = nil -- the climb under way
	local steps: { [P]: { run: string, done: { [string]: boolean } } } = {}

	-- `player` reached `name` in this climb's funnel, once a climb.
	local function step(player: P, name: string)
		local r = run
		if r == nil then
			return
		end
		local mine = steps[player]
		if mine == nil or mine.run ~= r then
			mine = { run = r, done = {} }
			steps[player] = mine
		end
		if mine.done[name] then
			return
		end
		mine.done[name] = true
		analytics:funnel(player, "climb", name, { run = r })
	end

	local book = {}

	function book.joined(_: any, player: P, t: number)
		joinedAt[player] = t
	end

	function book.gone(_: any, player: P)
		joinedAt[player] = nil
		opened[player] = nil
		caughtOn[player] = nil
		steps[player] = nil
	end

	function book.began(_: any, players: { P }, floor: number, name: string)
		run = name
		table.clear(caughtOn)
		for _, player in players do
			analytics:progress(player, "climb", "started", floor)
			step(player, "began")
		end
	end

	function book.reached(_: any, players: { P }, floor: number)
		for _, player in players do
			analytics:progress(player, "climb", "started", floor)
		end
	end

	function book.opened(_: any, player: P, floor: number, contents: Contents, t: number)
		analytics:event(player, "doorOpened", 1, { floor = floor, gave = Record.gave(contents) })
		local since = joinedAt[player]
		if not opened[player] and since then
			analytics:event(player, "firstDoor", tenths(t - since), { floor = floor })
		end
		opened[player] = true
		step(player, "door")
	end

	function book.earned(
		_: any,
		player: P,
		amount: number,
		balance: number,
		reason: Reason,
		floor: number
	)
		analytics:earned(player, {
			currency = Record.Currency,
			amount = amount,
			balance = balance,
			reason = reason,
			fields = { floor = floor },
		})
		if reason == "pile" then
			step(player, "coins")
		end
	end

	function book.spent(
		_: any,
		player: P,
		amount: number,
		balance: number,
		item: string,
		reason: SpendReason,
		floor: number
	)
		analytics:spent(player, {
			currency = Record.Currency,
			amount = amount,
			balance = balance,
			reason = reason,
			item = item,
			fields = { floor = floor },
		})
	end

	function book.cashed(
		_: any,
		player: P,
		coins: number,
		cash: number,
		total: number,
		floor: number
	)
		if coins > 0 then
			analytics:spent(player, {
				currency = Record.Currency,
				amount = coins,
				balance = 0,
				reason = "cashOut",
				item = Record.Cash,
				fields = { floor = floor },
			})
		end
		if cash > 0 then
			analytics:earned(player, {
				currency = Record.Cash,
				amount = cash,
				balance = total,
				reason = "climb",
				fields = { floor = floor },
			})
		end
	end

	function book.battery(_: any, player: P, floor: number)
		analytics:event(player, "batteryTaken", 1, { floor = floor })
	end

	function book.rode(_: any, players: { P }, floor: number)
		for _, player in players do
			analytics:progress(player, "climb", "completed", floor)
			step(player, "rode")
		end
	end

	function book.kept(_: any, player: P, finds: { string }, floor: number)
		for _, find in finds do
			analytics:event(player, "findKept", 1, { find = find, floor = floor })
		end
		if #finds > 0 then
			step(player, "kept")
		end
	end

	function book.caught(_: any, player: P, floor: number)
		analytics:event(player, "caught", 1, { floor = floor })
		caughtOn[player] = floor
	end

	function book.freed(_: any, player: P, floor: number)
		local from = caughtOn[player] or floor
		caughtOn[player] = nil
		analytics:event(player, "freed", math.max(floor - from, 0), { floor = floor })
	end

	function book.ended(_: any, endings: { Ending<P> })
		local team = #endings
		for _, ending in endings do
			analytics:event(
				ending.player,
				"climbEnded",
				ending.floor,
				{ floor = ending.floor, fate = FATES[ending.fate], team = team }
			)
			if ending.fate ~= "Out" then
				analytics:progress(ending.player, "climb", "failed", ending.floor)
			end
		end
		run = nil
	end

	function book.again(_: any, player: P)
		analytics:event(player, "again")
	end

	function book.shown(_: any, player: P, offer: string)
		analytics:event(player, "offerShown", 1, { offer = offer })
	end

	function book.carLeft(_: any, players: { P }, t: number)
		for _, player in players do
			local since = joinedAt[player]
			if since then
				analytics:event(player, "carLeft", tenths(t - since), { team = #players })
			end
		end
	end

	return book
end

return table.freeze(Record)
