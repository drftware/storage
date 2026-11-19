--!strict
--[[
	Settle (S5-03j2b2c, D-338): how the things standing on a piece settle as it lands in Arrange,
	the room editor (D-436). The moment: you set the pallet down and the moon lamp on it jolts up
	off its boards and drops back, then the cup beside it a beat later, each with its own little
	clink, the way things on a table hop when The Sims 4 drops the table, or a cup jumps when a
	fist hits the table. It tells you, without a word, that they came along and are still on it.

	Pure: the hop's height at a time, by each rider's place in line. Who calls it: ArrangeHand,
	the frame after a carried piece lands (Place, or set back where it stood), stepping only the
	riders' copies in the ghost until `length` has gone by. Its spec: tests/settle.spec.luau.
]]

local Settle = {}

-- How high (studs) a rider jumps off its piece as the piece lands: a jolt you see from the far
-- wall at phone size, never so high it reads as thrown.
Settle.Hop = 0.16
-- How long (seconds) the first hop is in the air: quick, so it reads as the landing's jolt.
Settle.Air = 0.16
-- The second, smaller bounce: this share of the first hop's height, and of its time in the air.
Settle.Again = 0.3
Settle.AgainAir = 0.6
-- The beat (seconds) between one rider's hop and the next's, in the order they stand on the
-- piece: a little ripple across its top, not a single jump.
Settle.Beat = 0.07

-- One parabola: 0 at the start and end of `air` seconds, `high` halfway.
local function arc(s: number, air: number, high: number): number
	local f = s / air
	return 4 * high * f * (1 - f)
end

-- How high (studs) rider `order` (1 for the first in line) stands off its piece `t` seconds
-- after the piece landed: still before its beat, a hop, a smaller bounce, then still for good.
function Settle.height(t: number, order: number): number
	local s = t - (order - 1) * Settle.Beat
	if s <= 0 then
		return 0
	elseif s < Settle.Air then
		return arc(s, Settle.Air, Settle.Hop)
	end
	s -= Settle.Air
	local again = Settle.Air * Settle.AgainAir
	if s < again then
		return arc(s, again, Settle.Hop * Settle.Again)
	end
	return 0
end

-- When (seconds after the piece landed) rider `order` first comes down: its clink.
function Settle.landsAt(order: number): number
	return (order - 1) * Settle.Beat + Settle.Air
end

-- How long (seconds) until the last of `count` riders is still: nothing to step after this.
function Settle.length(count: number): number
	if count <= 0 then
		return 0
	end
	return (count - 1) * Settle.Beat + Settle.Air * (1 + Settle.AgainAir)
end

return Settle
