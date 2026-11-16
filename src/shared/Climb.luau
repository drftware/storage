--!strict
--[[
	The climb (L-08b): floor after floor, as Dandy's World's elevator opens on a new floor at every
	stop. The next floor is dealt and laid while the team rides up to it, and the gate opens on a
	floor nobody has seen; the one below is cleared away. There is no top floor (S4-01a, D-226):
	the climb goes on until nobody is left climbing, each floor a little harder (`FloorRules`).

	- Every floor has its own seed, drawn from the climb's (`seedOf`): floor 1's is the climb's own,
	  so a seed's first floor is the one `lune run scripts/floor-map <seed> 1` prints, and every
	  floor above gets a layout, a code and a deal of its own (with one seed for every floor, floor
	  2 came out as floor 1 again, its units numbered 2xx).
	- Each floor is laid at its own spot, `Spacing` studs on from the last along -Z, so a phone
	  near one never streams in the other (the streaming target radius is 256 studs), and nothing
	  left on a cleared floor can turn up on a later one.
	- The hand-off: the car never moves (D-103), so riders are moved from the car that left into the
	  new floor's car, at the same spot in it, while the shaft hides everything through the gate:
	  `HandOff` seconds into the ride, on the cable's second knock, so the frame the move costs a
	  screen lands under a jolt you already feel and hear (cut on the bump, as a film cuts on
	  action). If the next floor is still being laid then, the hand-off waits for it, up to
	  `Latest`; after that the car arrives back at the floor it left, as the stand-in did.

	Pure numbers, so Lune checks them; the server runs the climb (Climbs).
]]
local Floor = require("./Floor")
local Ride = require("./Elevator/Ride")

local Climb = {}

-- Studs along -Z from one floor's lobby to the next one's. A floor spans under 300 studs, so two
-- floors' nearest halls stand over 700 apart, far past the 256-stud streaming radius.
Climb.Spacing = 1000

-- Seconds into the ride that riders are moved into the next floor's car: the cable's last knock,
-- late in the cruise, with the hall you left long black and the next one's dark not yet lifting.
-- The move costs a screen a long frame (0.2 to 0.4 s in Studio at 15 frames a second), and the
-- floor below is cleared in the same frame; the knock and its clank cover it.
Climb.HandOff = Ride.Clanks[#Ride.Clanks]

-- The last moment a hand-off may start when laying runs late: 2 s before the car levels, so the
-- move has landed on every screen well before the next hall's dark lifts.
Climb.Latest = Ride.arrives() - 2

-- Seconds before riders are moved that the next floor's car takes the ride over, so every rider's
-- screen has laid the shaft outside that car too before they stand in it: whichever car a frame
-- draws you in, the gate shows the shaft.
Climb.Lead = 0.5

-- Seconds the server waits on a rider's screen to stream in the next floor's lobby before it
-- moves them anyway (they stream in around the car once they're in it).
Climb.StreamWait = 3

-- A floor's own seed, from the climb's: floor 1's is the climb's, each one above a different
-- whole number (Brix's Random mixes every bit of a seed, so neighbours share nothing).
local STRIDE = 1000003
function Climb.seedOf(seed: number, number: number): number
	return seed + (math.floor(number) - 1) * STRIDE
end

-- Studs along -Z from the climb's first floor to floor `number`'s lobby.
function Climb.offset(first: number, number: number): number
	return (number - first) * Climb.Spacing
end

-- How far floor `floor` reaches in its own frame (its lobby's middle at 0, its halls along -Z):
-- the lowest and highest X, then Z, of its halls, the units off them and the elevator behind
-- its lobby, in studs. Whoever stands inside it is on that floor.
local MEDIUM: Floor.Size = "M"
local REACH = Floor.Span / 2 + Floor.Sizes[MEDIUM].depth
function Climb.reach(floor: Floor.Floor): (number, number, number, number)
	local half = Floor.LobbySize / 2
	local lowX, highX, lowZ, highZ = -half, half, -half, half + Floor.ElevatorDepth
	for _, c in floor.cells do
		lowX, highX = math.min(lowX, c.x - REACH), math.max(highX, c.x + REACH)
		lowZ, highZ = math.min(lowZ, c.z - REACH), math.max(highZ, c.z + REACH)
	end
	return lowX, highX, lowZ, highZ
end

-- Whether a point at (x, z) in a floor's own frame is on it (`reach`), with a little to spare.
function Climb.on(floor: Floor.Floor, x: number, z: number): boolean
	local lowX, highX, lowZ, highZ = Climb.reach(floor)
	return x >= lowX - 4 and x <= highX + 4 and z >= lowZ - 4 and z <= highZ + 4
end

-- Studs above or below a floor's own level that a player's feet still count as standing on it.
Climb.FeetSlack = 4

-- Whether feet at (x, feet, z) in floor `floor`'s own frame stand on it: at its level (within
-- `FeetSlack`) and inside its `reach`. A climb's floors all stand at one height, `Spacing` apart,
-- so height alone would count a player on the floor below as on the one above (D-157's clock
-- starts on the first step onto a floor, not as it's laid).
function Climb.stands(floor: Floor.Floor, x: number, feet: number, z: number): boolean
	return math.abs(feet) <= Climb.FeetSlack and Climb.on(floor, x, z)
end

-- Whether a hand-off may start `since` seconds into the ride: from `HandOff` to `Latest`.
function Climb.mayHandOff(since: number): boolean
	return since >= Climb.HandOff and since <= Climb.Latest
end

return Climb
