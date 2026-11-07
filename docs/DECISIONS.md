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

