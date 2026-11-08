# Decisions

Durable choices and why, newest last. Add one when a choice would surprise a future session.
Design detail lives in the GDD; this log records the calls that shape the build.

## D-001 · 2026-11-05 · Art is code, built in Blender headless
Every model is a Python script run in Blender 5.2, so an asset can be rebuilt, resized and
re-textured by changing numbers, and the game reads those same numbers from a generated `Specs`
module. Studio's 3D Importer brings the FBX in with its textures as SurfaceAppearances. The
sibling fight project proved the approach (its D-054), with vertex colours for a toy look; this
game's horror wants worn, grounded PBR materials instead (D-007).

## D-002 · 2026-11-05 · The unit's numbers
A 10x10 unit is 12 x 12 studs wall to wall with 10-stud walls and an 8 x 8 doorway, sized so an
R15 avatar (about 5.3 studs) reads like a person (a stud is about 0.28 m). A peek lifts the
door 1.15 studs, the GDD's "a foot". The shut door leaves a 0.06-stud gap for the GDD's line of
hall light. Three sizes come from one spec: S 8x8, M 12x12, L 16x20.

## D-003 · 2026-11-05 · The door is a chain of rigid ribs on a solved coil
38 slats, one corrugation rib each, hinge at the rib valleys and wind onto an Archimedean coil
behind the header, so the door is real from the hallway, from inside and from the wire tops. One
number (rise) poses everything. A skinned mesh was rejected (bounds and culling risk, harder to
pose from code); a sliding slab was rejected (it would poke through the unit's top and look fake
from inside, where kept players watch it).

## D-004 · 2026-11-05 · Paint is the part's Color, through Overlay alpha
The door and corridor-wall colour maps carry alpha: 0 where paint shows, so SurfaceAppearance's
Overlay mode shows MeshPart.Color there. One texture set paints any door colour, so a floor can
repaint its doors for free. `UnitKit.prepare` forces Overlay in case the importer picks another
alpha mode.

## D-005 · 2026-11-05 · The server sends one motion; clients animate
A door move replicates as one string attribute (action, from, to, server start time). Every
client samples the same curve from `Motion`; the server moves only an invisible DoorCollider.
Slats are cloned on each client and never replicated. The GDD's timings live in `Motion`: peek
1 s, open 2 s, close 1.6 s, slam lands in 0.28 s, lift from inside 6 s.

## D-006 · 2026-11-05 · A shut door is one merged mesh
Most doors on a floor are shut, so a shut door shows `CurtainClosed`, the whole curtain merged
into one part, and its client builds the 38-slat chain only while it moves or stands open (from a
code review for low-end Android). A padlocked door refuses to lift, and the bolt only shoots on a
shut door.

## D-007 · 2026-11-05 · The look: after-hours self storage, worn and real
Galvanized partitions with spangle and white rust, enamel doors chalky and chipped, rust from
chips and rib valleys, kick marks and dolly scuffs where people actually hit things, oily concrete
with saw-cut joints, under cold corridor light. Detail stays where it wouldn't repeat visibly
every rib. The owner approved the unit's look on 2026-11-06 (see D-012 for its light).

## D-008 · 2026-11-05 · Systems come from Brix first
Brix, the shared library in `../engine`, is further along than this game, so the game leans on it
for as many components as it can: the lifecycle and clock, Schema, Signal, seeded Random and Zones
now; the keepers' chase (Pursuit) as soon as its system lands; remotes, save data, live config,
telemetry and the round loop as Brix releases them (owner). This game keeps only its policies,
adapters, data and art; `docs/FRAMEWORK.md` maps each need to its Brix piece. A ticket that can't
wait for a planned piece builds the smallest stand-in behind Brix's shape and swaps it out later.

## D-009 · 2026-11-05 · The unit template lives in the place, not in Rojo's tree
Rojo's live sync can't set the mesh on an imported MeshPart (Studio won't let plugins write it),
so a unit model synced from a file would arrive in Studio with blank parts. The prepared unit
therefore lives in the place itself at `ReplicatedStorage.Units.<Size>`, where Rojo leaves it
alone (ReplicatedStorage has no `$path`, so Rojo keeps children it didn't make). A fresh place gets
the template back from its asset ID (D-010 replaced the saved `.rbxm` copy planned here).

## D-010 · 2026-11-05 · Art goes up through Open Cloud, not the 3D Importer
The owner's porch-pirates ships every model this way, so no art waits on someone clicking a
dialog. `scripts/upload_art.luau` (with `scripts/lib/OpenCloud.luau`, taken from porch-pirates)
sends each changed FBX as a Model asset, updating the same ID in place after the first upload, and
records the hash and ID in `art/unit/assets.json`. The key lives in the git-ignored `.config/.env`.
A session then inserts the asset through Studio's MCP and prepares it (art/unit/README.md, "Into
Studio"). The asset ID is the durable record, so the planned `assets/units/<Size>.rbxm` copy is
dropped. Not taken: building meshes from repo data at run time, as the owner's fight game does,
because a game script can't set SurfaceAppearance's normal and roughness maps and the unit's look
depends on them.


## D-011 · 2026-11-05 · First-person camera
The owner's call: players see the building through their own eyes, as in Pressure. It keeps the
dark close and a keeper's arrival sudden, and it fixes what P0-02b found: Roblox's third-person
camera backed through the shut door behind you into the unit across the 8-stud hall, because a
unit has no part that stops it (docs/STUDIO.md, "Camera and prompts"). With the camera locked at
the head, the units keep their invisible box colliders as the only collision and need no
camera-blocking walls. Not taken: third person with solid unit walls, which would also need the
facade remodelled in three pieces so the doorway stays open. The owner confirmed first person
again on 2026-11-06, and it was built that day (P0-02c).

## D-012 · 2026-11-06 · The game is lit like the look sheets
The owner's call after the two-player test: the storage units look right, and the light in the look
sheets (`art/sheets/unit-hall.png`, `unit-hero.png`, `unit-inside.png`, the door videos) is the
light the game should have. The MCP's captures show the game as it really renders (the owner's
darker shot was dimmed by the pause menu), and today the hall and units read flat and near white
next to the sheets. P0-02d does it.

## D-013 · 2026-11-06 · A shut door hides whoever is behind it
Measured in Play (P0-02e): Roblox's run animation keeps playing while you push into a wall, so a
hand swings up to 1.25 studs through a 0.4-deep door collider and still 0.8 through a 1.2-deep one.
Hiding it with collision alone takes a collider about 3 deep, which would stand an invisible bump a
full stud out from every door in the hall. Instead the collider is 1.2 deep (a hall player stops
flush with the facade) and each client stops drawing anyone a shut door stands between it and
(`BehindDoors`, rule in `ShutIn`): the door is solid metal, so that is what you'd see anyway, and it
covers every avatar, accessory and tool. Footsteps still play. Not taken: a client guard that stops
your walk into a door (Roblox's control script moves the character through flag-gated internal
paths, so it would be fragile, and the swing on the last stride still crosses), or a custom run
animation (feel the owner hasn't asked for).

## D-014 · 2026-11-06 · Left Alt frees the mouse, through a Modal button
First person pins the mouse to the middle of the screen, so a computer player couldn't take a
screenshot or reach another window. Left Alt (Option on a Mac) toggles a free cursor for mouse
players; phones and gamepads get no key and no hint. It works the way Roblox documents: a visible
GuiButton with `Modal` set leaves the mouse unlocked, and the right mouse button still looks around
while it's free. The mouse is either the view or a cursor, never both (owner, Nov 6): no cursor is
drawn while it turns the view, the way first-person shooters hide theirs. Not taken: writing `MouseBehavior` ourselves (the camera script puts LockCenter back
every frame), or a fork of the PlayerModule. The key is a default the owner can change (`OWNER.md`).

## D-015 · 2026-11-06 · The hall's light: fixtures every two units, tuned at full quality
The look sheets' light comes from a few fixtures, one every 24 studs, hanging 2 studs over the
wire tops, each pooling hard cold light on the doors below with the dark between; the stairwell's
exit sign tints the far end red. `HallLight` holds those numbers for the corridor kit (P0-03) and
the motion lights (L-03). Tuned where Roblox draws its full lighting (graphics quality about 11 and
up in Studio's levels): there the hall, the hero door and a shut unit's dark inside match the
sheets. D-012's "captures are accurate" was wrong in one way: Studio on Automatic quality, like a
low-end phone, falls back to coarse lighting that ignores a light's cone and shines through thin
walls, which is where the flat, near-white facades came from. P0-02g takes on that fallback. A
default until the owner says otherwise: at most 6 real lights awake on one client at once; the
test hall uses 3. Not taken: matching the sheets' haze with Atmosphere (it stays black indoors at
midnight) or classic fog (barely shows in a dark hall).

## D-016 · 2026-11-06 · Shut in, the client keeps the hall's light out
Below graphics quality about 10 (Studio's levels; a low-graphics phone), the hall's lights cast no
shadows at all: a 2-stud concrete roof and a 2-stud block in front of the door changed nothing
inside a shut unit, and range barely matters there. So no wall thickness keeps a unit dark. The
door does it on the shut-in player's own screen instead: `BehindDoors` scales every light tagged
`HallLight.Tag` by `ShutIn.light` (6% while shut, about half at a friend's peek, full when open,
cut as fast as a slam falls) and draws the line under the door as a thin glowing strip on the hall
floor. Full quality gets the same treatment, so the moment looks the same on every device; its
real shadows already kept the room dark. Not taken: thicker walls or a unit roof (no effect),
guessing the device's quality (Roblox doesn't say on Automatic), a light under the door (one more
real light, and it would leak in too). The hall's own low-graphics look is P0-02h.

## D-017 · 2026-11-07 · A fixture is two lights: a short tube and a fill at door height
Studio's Automatic quality (and a phone's) switches between low graphics and full quality
mid-play. Measured from the spawn: floors came out the same at both, but low graphics lit upright
walls, facades and an open unit's insides 2 to 3 times brighter, so the hall flickered between
two looks and an open unit between lit and black. Neither exposure nor brightness separates the
two (both move together; low graphics doesn't cap a light). Range does: low graphics ignores
shadows, so a 22-stud tube flooded the units, while 14 reaches only the floor and doors under it.
So each fixture is now the tube, shadowed, 14 studs, for the pool on the floor, plus a
shadowless PointLight 5 studs up (`HallLight.FillHeight`) standing in for light bounced off that
pool: level with the walls, it lights them at full quality as low graphics does, and it reaches
into an open unit at both. Result: low graphics about 1.7x full quality, an open unit dimly
readable at both (the owner's pick, Nov 6). Cost: two real lights per lit fixture, so the 6-light
budget (D-015) holds three lit fixtures; the fill is tagged like the tube, so `BehindDoors` dims
it for a player shut in. Not taken: a fill at the tube's height (lit the units' tops, closed less
of the gap), guessing the device's quality (Roblox doesn't say on Automatic).

## D-018 · 2026-11-07 · The haze is a few dust puffs under each lit tube, mostly self-lit
The look sheets show grey air glowing around a lit fixture. Roblox has no light shafts or
volumetric fog indoors, so each lit tube carries a ParticleEmitter with Roblox's built-in smoke
texture: about six slow puffs, 4 to 6 studs wide, gathered 2.5 studs under the tube
(`HallLight.HazeHeight`). Measured in Play: low graphics draws a hard line where a puff cuts into
the ceiling (full quality softens it), so the puffs hang low enough to miss it, and spread in a
flat fan along the hall. A puff fully lit by the hall (LightInfluence 1) dims with its fixture but
reads about twice as bright at low graphics as at full quality, like the walls (D-017), and faint
at full quality; at 0.4 the two looks sit within about 1.3x from the spawn. The self-lit part
can't dim with the light, so a fixture's level scales the puffs' colour, a dead fixture hides
them at once (transparency is read live), and a fixture coming on throws a burst of five
(`Emit` on the server reaches players already watching). Shut in a unit you can't see the hall's
air, so `BehindDoors` needn't dim it (checked at Level08). Not tried, since the puffs did it: a
glow part, more bloom (it already smears bright neon into blobs at low graphics), a thicker
Atmosphere (it would fog dead stretches as much as lit ones).

## D-019 · 2026-11-07 · Each player's screen emits the haze's puffs
Measured in Play (P0-02j): Roblox thins a ParticleEmitter's steady puffs with graphics quality,
to about (level ÷ 21) of its Rate: 7% at Level01, 35% at Level08, all of it at Level21. The haze
held about six puffs per lit tube at full quality, two at Level08, and under one at the levels a
cheap phone plays at, where the look sheets' grey air simply wasn't there. The P0-02i shots hid
it: each was taken on a fresh burst, and `Emit` is never thinned. So the server leaves each haze
emitter's Rate at 0 and tags it `HallLight.HazeTag`, and the client system `HallHaze` emits one
puff at a time at `HallLight.HazeRate` (`Pace` carries the timing between frames, and a hitch
never dumps a cloud). Now about eleven puffs hang under the two lit tubes at Level01, Level08 and
Level21 alike. The cost of keeping them on weak phones is small: the puffs add 24 triangles and
3 draw calls. The haze is only for looks, so the client owning its timing breaks nothing the
server must own. The same client bursts a tube already lit when it first gets it (joining late,
or the tube streaming in), which fixes the haze starting clear for a late joiner. Not chosen:
raising Rate to match the player's quality level, which Automatic changes mid-play; emitting
directly needs no level at all.

## D-020 · 2026-11-07 · The corridor kit: 24-stud pieces on the unit's textures, a steel ceiling
The hall becomes pieces a floor is laid from (GDD tech plan: one tile graph). The straight piece
is 24 studs: two M units a side, three S, and one hall light's stretch. Its length is set by the
floor's texture: the unit's Concrete set repeats every 8 studs with a saw-cut joint on its edge,
so a piece a multiple of 8 long, with UVs starting on that edge, meets the next on a joint and
never shows a seam (12-stud pieces would land mid-texture). The ceiling is a corrugated steel deck
on open-web joists, the look of a real storage building and of the look sheets, reaching over
the hall and a row of units each side (32 across), so back-to-back unit rows between two halls
meet under one continuous ceiling. Its deck sits at 14 (was 13.4) so the joists can be 1.2 deep
and still stop at 12.8, clear of the haze's 12.6. The kit bakes nothing: the floor wears the
unit's Concrete and the ceiling its TrimSheet (painted and raw-steel strips), and a piece is two
MeshParts, so a hall of identical pieces draws in two calls. Templates live in the place at
`ReplicatedStorage.Corridor.<Piece>`, beside the units' (D-009). Not chosen: a MaterialVariant
floor on plain parts (seamless at any length, but a second way of shipping art, outside the
Blender pipeline); I-beams (cheaper, but read as a parking garage, not a storage building).

## D-021 The hall light is a hung strip light whose sensor dome is the building's eye (P0-03b, 2026-11-07)

The fixture is a steel strip light on two jack chains from the deck, midway between two joists,
with an occupancy sensor on one end: the GDD's "motion lights are its eyes" made literal. Its own
FBX and template (`ReplicatedStorage.Corridor.Fixture`), not part of the straight piece, so the
floor generator places lights through L-03's system rather than every 24 studs by default. Three
MeshParts: the Housing (TrimSheet: painted channel, galvanized chain, clips and junction box, a
rubber cord) and two untextured parts the game colours, the Diffuser (the lens `HallLight.light`
lights, its place and size read from `HallLight.Height` and `TubeSize`, so the art follows the
tuned light) and the Eye. The eye has three looks: Watching (a red glow, so a dark hall is dotted
with eyes), Seen (full red, the flare L-03 shows when it trips) and Blind (dead plastic, the
breaker room's zone). Its dome is a half-sphere 0.36 across, about twice a real sensor's, because
at 0.26 only the nearest eye in a dark hall read on a phone. Neon only, no light of its own: the
light budget stays at two per lit fixture (D-017). Not chosen: a separate pinprick LED beside a
white dome (real, but a pixel or two on a phone); the sensor mid-lens (it would split the tube
the light was tuned on).

## D-022 · 2026-11-07 · The hall's walls are a unit's front without the door
Where no unit stands, and at a hall's dead end, the wall is the corridor wall the units' fronts
are: the same painted Facade panels (painted per floor, like the units), posts, diamond kick plate
and cap at 10, so the hall reads as one building and a stretch with no doors reads as a blank wall,
nothing to hide behind. Above the cap an R-panel (the units' Partition set) rises to the deck: a
unit is open over its wire top, a wall isn't, which is what a real building has where a room or the
outside lies behind. The plain wall is one M unit wide (12) and its frame is a unit's door face, so
a hall side is a row of 12-stud slots, each a unit or a plain wall (L-01). The dead end is a wall
placed at a piece's open end, not a piece of its own: it spans the whole deck (32), so any hall end
can be closed, and a dead-end tile is a straight piece plus one. Its panel's valleys sit flush with
the deck's end, so no gap opens where the flutes stop. Three MeshParts each (Facade, Trim, Panel);
a wall's frame is found from its flat Facade and the Panel behind it. Not chosen: concrete block
walls (a second material the building doesn't otherwise have); a plain wall full height in the
facade paint (its texture is drawn for a 10-stud wall); a dead end with its own floor and ceiling
(a second straight piece's worth of mesh for one wall).

## D-023 · 2026-11-07 · Junctions: 24-stud squares, the deck turns on a girder
The corner, T and cross are 24-stud squares, a straight's length, so they sit on the straights'
grid (D-020): a junction's floor is the whole square mapped like a straight's, so every arm meets
it on a saw-cut joint, and its joists keep the 6-stud beat along its X arms. Halls stay on 24-stud
centres; a turned straight's floor meets a junction rotated, on a joint. Every straight keeps its
deck running along its own hall (option b of the ticket); a junction's deck continues its X arms
and a joist girder, as deep as a joist (clear of the haze) with heavier chords and a closure plate
on top, carries the seam across each Z arm's mouth. Not chosen: one deck direction for the whole
floor (option a), which needed a second straight for halls along Z, joists running along those
halls instead of across, junction ceilings that can't turn with their floors, and joists 2 studs
apart over the back-to-back rows of parallel Z halls (32 apart, not a multiple of 6). Not chosen
either: 32-stud junctions covering the whole span, which break the floor joints (16 is not 4 off a
joint) and the 24-stud grid. What a junction leaves of a hall side is whole slots: 8 (the new
short wall, an S unit's width) beside its blocks of wall and along a corner's outer sides, and two
12s across a T's stub. A steel column covers each corner where two walls meet (the posts' notch,
the caps' overlap that would flicker, the R-panels' slit). A junction's frame is its floor part's
own: Roblox's importer keeps each part's FBX axes (docs/STUDIO.md), so a square floor still knows
its turn.


## D-024 · 2026-11-07 · Motion lights: the server keeps state, each screen draws it
Every hall fixture is a motion light the server owns (L-03, GDD "Lights"). Ten times a second the
server hands a pure watch (`MotionLight`, Lune-tested) where every body that trips lights is; it
wakes the fixtures whose watch area someone moved in and darkens those that saw nothing move for
5 s, and only those changes reach players, as a string attribute on the fixture's model. A body
"moves" at 1 stud a second or more, so holding still under a light puts you in the dark (the GDD's
"hold still and you go dark to it"). A watch area is a Brix box zone under the fixture: 32 studs
down the hall (the next light wakes about 16 studs before you reach it), 10 across (the hall and a
stud into each doorway, so a unit's inside is unseen), floor to deck. Fixtures sit in a spatial
hash on the 24-stud grid. A fixture is a motion light by its tag; players' root parts trip lights
by theirs, which keepers will carry too, all but the Mannequin's. Each screen draws the state
(HallLights): the eye flares hot and settles red, the sensor's relay clicks (Pro Sound Effects,
from Roblox's audio library), the tube flickers twice and holds; falling dark, it cuts out with a
softer click and the eye sinks back; cut by the breaker, tube and eye die silently. Real light only
for the three lit fixtures nearest the camera (two lights each, D-017), with 8 studs of
stickiness against swapping; the rest glow, with no dust. Not chosen: the server lighting fixtures
itself (every Light instance replicated, and a client couldn't budget or flicker them without
fighting the server), and a fixture staying lit while anyone stands in it (a real sensor, but it
would kill the freeze). The hold, the speed and the areas are first guesses for the owner to tune.

## D-025 · 2026-11-07 · The lights follow you: your screen predicts your own
The owner played L-03: right, but the light lagged, so you could step into the dark before it
came on, and it went out too soon. A real storage hall's lights follow you. So: each screen runs
the same pure watch on its own character and shows a light lit the moment either it or the
server says so; the server's word alone puts it dark or blind, and only the server's state is what
the building sees (keepers, the light board). Other players' and keepers' lights still wait for
the server, now ticking at 20 a second (was 10). The watch area is 40 studs long (was 32), so the
light ahead wakes as you pass under the one you're at; the hold is 7.5 s (was 5; the owner said
7 to 8); the tube lights at once and holds within a tenth of a second (one stutter, was 0.3 s).
Real light goes to the lit fixtures nearest a point 12 studs ahead of the camera, so the light
you walk into wins over the one behind you. Every stretch of the test hall now has a fixture
watching it, junctions included: a junction's middle is midway between its joists, so L-01 can
hang one there. Not chosen: the server alone with a longer reach (your own first step after a
freeze would still wait a round trip).

## D-026 · 2026-11-07 · A door sounds like its motion: a rattle that follows its speed, hits on its strikes
Each player's screen plays a door's sounds from the motion the server already replicates, so no new
traffic. While it moves, one looping roll-up door rattle (Pro Sound Effects' truck rear door)
takes its volume and pitch from the door's speed every frame: the curve can't drift from the
sound, and a lift from inside's three heaves surge on their own. Hits are one-shots timed off
`Motion.strikes` (when a slam lands and bounces, a close settles, a lift meets the stop bolts), on
the server's clock, so every player hears the slam when they see it. Loudness and reach per
action follow the GDD's noise column and live in `DoorSound` for keepers to share. The slam
shakes the camera with trauma that drains (squared on screen, smooth noise), layered on Roblox's
camera by taking last frame's offset off before it updates, so aim never drifts; a stand-in for
Brix's ENG-15. Recordings are Pro Sound Effects only (licensed, load in any game); their stretches
were found by measuring loudness in Studio, since no one here can listen. Not chosen: one recorded
open and close per action (its timing would fight the curve, and Peek and LiftInside have none).

## D-027 · 2026-11-07 · The floor: halls grown from the lobby on a grid of junction points
A floor is pure data from a seed (`Floor`, L-01a). Junctions and the lobby stand only on every
other point of the 24-stud grid, 48 studs apart, with one straight on each link between two: the
D-023 rule (a straight between two junctions) holds by construction, and parallel halls stand 48
apart with both rows of units. A point with two arms in line is a straight; one with a single arm
is a straight closed by a dead end. The halls grow from the lobby as a tree (from the newest point
half the time, otherwise any; carrying straight on 60% of the time, for long aisles), so every
hall is reachable, then loops join near halls, closing a dead end first. The lobby is the grid's
first row's middle, at the origin, its one hall leading into the floor (-Z) and the elevator
behind it, so every floor's elevator stands in the same spot. Each straight's side is two M slots
or three S (25%); the kit fixes a junction's (two M across a T's stub, two S on each outer side of
a corner). Where two halls leave one junction side by side, an M slot at that end is always a plain
wall: both of them, not one, since either unit's wire top would show the decks' overlap; half such
sides are three S instead, which stop short of it, so a hall between two junctions isn't all
wall. Units are numbered floor then two digits in the order you meet them walking out (left, ahead,
right at each fork), units across the hall back to back, your left first; a floor holds at most
99, and past that units picked at random become walls (1 floor in 1,000 at today's sizes). Each
floor's doors wear one colour, in turn. A light hangs over every hall piece's middle; with the
40-stud watch every stud of hall is watched (the spec checks each one). Power zones: "Lobby" to
the first fork, then a letter per wing. Short floors (1, 2): 5 by 3 points, 8 halls and a loop,
about 60 units; full ones: 5 by 4, 11 halls and two loops, about 80. The module takes Brix's Random
through its call (the contract's rule) and stays free of Roblox paths; Brix Schema checks the
plans in the spec, and moves to their loader when live config (ENG-11) can change them. Not chosen:
junctions on every grid point (two could touch and parallel halls collide, needing a repair pass);
odd numbers on one side and even on the other, as the test hall does (with mixed S and M rows the
sides don't pair up, and gaps would run a floor past 99); numbering by distance from the lobby
(numbers would hop between wings).

## D-028 · 2026-11-07 · The small unit wears the M's textures, cropped, not squashed
The S (8 by 8, a 6-wide door) is built from the same scripts as the M and wears the same five
texture sets (L-01b). Two things made that true, and neither was before. The slats, the bottom
bar and the drum span the door's width, and their texture was laid across the whole M door, so a
narrower door squashed the paint's grain to 77%; a narrower door now shows the middle of the
texture at the M's grain (`Spec.u_across`). And Blender's smart project packs the small hardware
(the padlock, latch, plates, drum ends) differently once a part moves, so the S's pack sampled
the wrong texels of the M's bake; another size now copies the M's pack face for face from the M's
scene (`bake.copy_atlas`), and the build stops if any of those faces differs in shape from the M's.
`art.sh` never bakes for another size and rebuilds its scene before every stage, so an export
never ships stale geometry. The curtain is identical at every size (the door height is common), so
the rig, the motion and every sound cue are the M's. In the test hall the short hall past the
corner holds three S a side, numbered 109 to 114, 112 padlocked: the cramped part of the building,
apart from the M rows the owner's earlier tests use. Not chosen: baking a texture set per size
(five more sets to stream and keep in step); the S door squashing the M's texture (the grain reads
finer than the M's beside it); the S row replacing two M units in the main hall (it would move
units the open tests in `OWNER.md` name).

## D-029 · 2026-11-07 · Laying a floor: piece by piece from the lobby, inside a frame's share
`FloorBuilder.lay` (server) turns `Floor` data into the building (L-01c). It lays the lobby, then
the hall pieces nearest the lobby first, each piece with everything on it (the kit's straight or
junction, its units and plain walls, a dead end, its light) dressed in an unparented folder and
parented once; between units, and after each piece, it waits a frame once 4 ms of that frame are
spent. Floor 3 of seed 7 (67 units) took 65 ms of work over 15 frames, at most 6.2 ms in one, so
L-08 can lay the next floor while the elevator rides without a stutter. A junction is laid with
its own walls except where a unit stands (`CorridorKit.junction`'s `units`, faces in the
junction's frame), so the unit's door is the hall's side; a junction's plain-wall slots keep the
kit's wall. A unit's `drops` (floor Dirs) pick WallLeft or WallRight by whichever stands toward
that way, so it holds at any turn of the floor. Each light's power zone is named for its floor
(`Floor3.A`), so two floors laid at once never share a breaker. The lobby is a stand-in until
L-05: one plain room, its square and the elevator's space behind it, lit only by a warm lamp in
the car, the one light on a floor that is always on, so you arrive in a glow and the hall's mouth
stays dark. The door's test prompts moved from the test hall to `DoorPrompts`, for any laid unit,
until L-02 replaces them. In Studio the test hall lays floor 3 of seed 7 (Workspace's
`DevFloorSeed` and `DevFloorNumber` change it) 600 studs off, and prints its map; "Walk a floor"
by the spawn goes there. Not chosen: the floor replacing the test hall (the owner's open tests in
`OWNER.md` name its units); a fixed count of pieces a frame (a piece holds none to six units, and
six can take a whole frame); padlocks on a laid floor (L-04 deals those).

## D-030 · 2026-11-07 · The door as a state machine: buttons for its state, each in a fixed place
The door is the GDD's state machine in a pure module (`Door`), read from what it's doing (its
Motion) and its padlock: closed, peeking, opening, lifting (from inside), open, closing, slamming,
locked. The GDD's list had no closing or lifting; both are needed, closing because a door pulled
down by hand can be turned back, lifting so nobody outside can shut a door while a friend heaves it
up from inside (the GDD: lifting from inside is always possible, a clip and never griefing). The
server's `Doors` system (on the Host clock, only doors in motion stepped) shows only the buttons
the state allows, each in a fixed place on screen (`Door.Slots`, `UIOffset` 150 px apart): Peek
left, Open middle, Slam right; Close shares the left spot with Peek as a toggle, so after any tap
the spot it hit holds nothing else and a double tap can't misfire. A press is checked for reach
(plus 4 studs of lag), side (Lift only from inside the unit's doorway, Peek and Open only from the
hall while the door is down), tools and rate (0.3 s a player), then decided by `Door`. A padlocked
door tried from either side rattles: a new door motion (`Rattle`, three jerks of a few
centimetres against the bolt, the light under the door flickering) whose sound is Pro Sound
Effects "Door Shake 4" (its first shake, 0.14 to 0.9 s), so motion and sound ride one attribute
and keepers hear it as far as players (`DoorSound.Actions.Rattle`). Every door event fires the
system's `acted` signal with that reach. Not chosen: a Lock button on every door (server prompts
show to everyone, so a padlock button would sit on every shut door for a tool few carry; the
padlock tool will call `Doors:lock`); hiding Cut from players without bolt cutters (no per-player
prompts without a client-side layer; "Need bolt cutters" teaches the tool exists); buttons stacked
vertically (a landscape phone has room across, not down); Lift on T (inside, Lift is the only
button, so it takes E). Tools are a stand-in: a player's `Carries<Tool>` attribute until Phase 2.

