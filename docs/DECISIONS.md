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
every rib. Awaiting the owner's look (OWNER.md).
