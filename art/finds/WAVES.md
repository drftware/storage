# The finds to build: wave 1, plus the RC car

Which finds get made next, and which are done. The bar and the method are in `CRAFT.md`; read it
first. The rows come from the catalog doc, "Unit finds: the item catalog"
(https://claude.ai/artifact/29wkaNXM3Yw86xTMb3sjQQ, read with the docs tools, never WebFetch;
don't read it whole, it is 250,000 characters): its wave 1 is 133 finds, built here in the
order below. Each session works from the Next line and moves it on.

**Next:** F-02c, the bundle of glow sticks, then on down the Lights (string fairy lights,
camping lantern), with the kit (notes below).

## Order

| Ticket | What | Why here |
|---|---|---|
| F-01 | The finds kit (CRAFT.md, "The kit"), proven on the first Lights | Every set after it reuses the kit |
| F-02 | The rest of the Lights, in as many sessions as it takes | The owner's example: a lamp that turns on |
| F-03 | The remote-control car and the die-cast car | The owner named the RC car (Nov 14) |
| F-S1 | Into Studio: upload and insert the Lights and the cars, judge them at phone size in the unit's light, fix what reads badly | Glow and size are only true in Roblox |
| F-04 | Wind-ups and noisemakers | Every one animates |
| F-05 | Squishies | The craze of 2026; squash and stretch |
| F-06 | Plush | Soft forms and fabric; the Huge variant shows here |
| F-07 | Night Shift Minis and their blind box | Our own monsters as collectibles |
| F-08 | Boxes and tins | Lids, flaps and reveals |
| F-09 | Bags and cases | Zips, flaps, straps |
| F-10 | Locked and sealed | Locks that open |
| F-11 | Treasures | The rare end: gold, gems, the Secret key |
| F-12 | The eight big finds | Each is big; about two a session |

A set can take several sessions; split its ticket in ROADMAP (F-02a, F-02b) as you go. Mark a
find built with the date and session (`Nov 15, F-02a`) only when it meets CRAFT.md's bar.

## Notes from the sessions

Newest first. What the next session needs to know: kit changes, traps, what's half done.

- **Nov 15, F-02b (the tea light in a jar).** Built and judged twice (the glass was milky and
  the candle lit the whole jar yellow like a plastic tub: glass wants a dark, glossy colour;
  the bail's arc was faceted; the wire had too many triangles). One find again: this session
  reached 225k context before its first full render (reading the kit's bake, export and render
  code to add glass cost most of it), so start lean and read the kit only by grep. Kit
  changes, all in CRAFT.md's kit list: **glass** (`Part(clear=True)`, `paint(alpha=)`, the
  alpha in the colour PNG, a clear part's own material, occlusion that ignores glass, Gold
  keeping glass), the `scale` and `stretch` channels (stretch is squash and stretch keeping
  volume: F-05's squishies can use it), `lit=` on a Find (how it stands when on), filmstrips
  that keep unmoved parts at rest, and a **first-person held sheet** (the find in your hands
  1.05 studs ahead, the night-light's and the desk lamp's re-rendered with it). A spec for
  `Finds/Art.luau` now exists (`tests/findsart.spec.luau`). Quick sheets for a find with four
  motions take about 5 minutes, full ones about 10: render one find's sheets in the background
  and write notes meanwhile. The tea light is 4,058 triangles; its wire (1,064) could lose its
  eyes' detail on the game mesh if a budget bites. Glass glows dimly from its inside light in
  Cycles; in Roblox it's alpha-blended lighter (docs/STUDIO.md): F-S1 judges the jar there.

- **Nov 15, F-02a (the plug-in night-light).** Built and judged three times (the dome was
  faceted, the lit shade blew out flat white with no hot spot, the shade and base were one
  ivory, and at 4.6 inches it was lost from the doorway, so it's built 1.15 times bigger).
  Only one find: the session started at 120k context. Kit changes, all in CRAFT.md's kit list:
  `Shape.loft` (shells through rings of any shape), `texels=` on a Find, a filmstrip `focus`
  that can be a point plus `distance`, preview lights that honour `shadows=False`, Gold keeping
  every glowing texel whole, and part sizes in the Luau written positive (they came out
  negative on X, the desk lamp's too). The desk lamp's sheets weren't re-rendered after these.
  **The tea light needs see-through glass**, which the kit doesn't do: give `Surface` an alpha,
  bake it into the colour PNG's alpha, and wire it to the material's Alpha so the FBX imports in
  AlphaMode Transparency (docs/STUDIO.md, "AlphaMode Transparency cuts unless the part is a hair
  transparent": the jar part then wants Transparency 0.02 in Studio). Its flame is its own glow
  part; flicker is `glow` keys plus a small `turn` sway (the kit has no scale channel).
  For F-S1: from a unit's doorway a 5 inch find is a speck when off; judge whether small finds
  need help to be seen.

- **Nov 15, F-01 (the kit and the desk lamp).** The kit is in `art/finds/kit/` and CRAFT.md's
  "The kit" says how to use it; the desk lamp (`art/finds/lights/`) proves every piece: parts on
  hinges, the high-to-low bake, glow, two lights, two motions, Gold, the Luau. Its sheets were judged three
  times (framing, the shade made a bell, the nod doubled to 4 degrees, a dark band at the rim
  broken into chips); the switch filmstrips with the bigger nod weren't looked at again.
  Things to know: `quick` sheets take 90 s; look at one composed contact sheet (ffmpeg
  hstack/vstack into the scratchpad), not each PNG, or the context runs out. Triangles came to
  6,564 (the shade 2,272 and the base with its cord 2,276): trim the shade's profile if a medium
  find must stay under 6,000. Packing fills 39 per cent of the square: tighter packing
  (fewer, bigger islands) would buy density. The person in the lineup is the shrink-wrapped
  figure from the unit's sheets. `Finds/Art.luau` has no Lune spec yet: add one (ease ends at 0
  and 1, Back overshoots, a lamp key sampled) when next touched.

## Lights (16) · F-01, F-02

A light set down switched on lights the space round it until it runs down. Whether that holds a Mannequin is a decision.

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Plug-in night-light | Common | Switch on (at home): a soft glow by the floor | Frosted ribbed shade | Nov 15, F-02a |
| Tea light in a jar | Common | Light: a small glow for about a minute |  | Nov 15, F-02b |
| Desk lamp | Common | Switch on (at home): a warm pool of light | Needs a socket, so only at home | Nov 15, F-01 |
| Bundle of glow sticks | Common | Crack: one stick lights a small spot for the rest of the floor; three to a bundle | The glow sticks from the Nov 2 draft | |
| String fairy lights | Uncommon | Switch on: lay them along a hall for a dim line of light |  | |
| Camping lantern | Uncommon | Switch on: a wide light for 90 seconds |  | |
| Moon lamp | Uncommon | At home: it glows; tap it to change its phase |  | |
| Blob lamp | Uncommon | At home: coloured blobs rise and fall |  | |
| Oil lamp | Rare | Light: warm light that runs down slowly | Fragile | |
| Disco ball | Rare | Spin: spots of light race round the walls |  | |
| Neon OPEN sign | Rare | At home: it buzzes and glows pink |  | |
| Miner's hard hat | Rare | Wear: a lamp on your head lights whatever you look at, for a minute | A light that leaves your hands free | |
| Jar of fireflies | Epic | Open: fireflies drift out and light the unit for a minute, then they're gone |  | |
| Theatre spotlight | Epic | At home: point it at your best find | Big find | |
| Stained-glass lamp | Legendary | At home: it throws coloured patterns on your walls | Fragile | |
| A lamp that's on when you find it | Secret | It never runs down | Loose only, floor 25 up. In a power cut it's the only light on the floor | |

## Cars from Figures and models (2 of 14) · F-03

Pulled forward from wave 4 because the owner named the RC car (Nov 14).

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Die-cast car | Common | Push: it rolls off down the hall |  | |
| Remote-control car | Rare | Drive (at home): round your unit and out into the hall of units |  | |

## Wind-ups and noisemakers (14) · F-04

The set that teaches noise. Wind one, drop it, walk away, and see what comes to look.

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Kazoo | Common | Blow: a buzzy note |  | |
| Squeaky rubber duck | Common | Squeeze: a squeak you can hear down the hall |  | |
| Toy siren car | Common | Push: it rolls off, wailing | A noise that moves | |
| Wind-up chattering teeth | Common | Wind: they chatter off across the floor | Monsters come to look | |
| Toy drum | Uncommon | Bang: loud |  | |
| Wind-up mouse | Uncommon | Wind: it zips off and squeaks wherever it stops |  | |
| Wind-up walking robot | Uncommon | Wind: it clanks off in a straight line for 15 seconds | A noise you can send down a hall | |
| Farm-animal spinner | Uncommon | Pull: the arrow spins and an animal noise plays | A throwback toy | |
| Jack-in-the-box | Uncommon | Wind: a tune, then a bang as it pops | The bang comes a few seconds after you let go | |
| Cymbal monkey | Rare | Wind: it bashes its cymbals for 20 seconds, loud | The strongest lure in the set | |
| Pull-string cowboy doll | Rare | Pull: it says one of six lines |  | |
| Singing fish plaque | Rare | Press: its head turns and it sings |  | |
| Clockwork tin bird | Epic | Wind: it hops and whistles | An antique tin toy | |
| Wind-up tin carousel | Epic | Wind: it turns and plays a tune |  | |

## Squishies (14) · F-05

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Stress ball with a face | Common | Squeeze: its eyes bulge out |  | |
| Goo ball | Common | Squeeze: it oozes between your fingers and slowly comes back | The craze of 2026 | |
| Squishy butter stick | Common | Squeeze: leaves a dent that slowly fills back in | A 2026 squishy trend | |
| Mochi bun | Common | Squeeze: a soft puff of a sound |  | |
| Paper squishy with a drawn face | Uncommon | Squeeze: it crinkles | Looks homemade; cheap to build | |
| Squishy toast slice | Uncommon | Squeeze: springs back like real bread |  | |
| Gel bead ball | Uncommon | Squeeze: the beads swirl inside |  | |
| Glitter goo ball | Uncommon | Squeeze: glitter swirls, then settles |  | |
| Jumbo slow-rise strawberry | Uncommon | Squeeze: the dent takes ten seconds to rise back |  | |
| Colour-change goo ball | Rare | Squeeze: it changes colour where your fingers pressed |  | |
| Squishy cake slice | Rare | Squeeze: frosting squishes out of the side |  | |
| Squishy capybara | Rare | Squeeze: it lets out a tiny, happy sigh |  | |
| Mega goo ball | Epic | Squeeze: both hands, and a deep squelch that carries | Loud enough to draw a monster | |
| Galaxy goo ball | Legendary | Squeeze: stars drift and swirl inside |  | |

## Plush (16) · F-06

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Small teddy bear | Common | Hug: a tiny squeak |  | |
| Round cat plush | Common | Squish: it flattens and puffs back up |  | |
| Frog plush | Common | Hug: it croaks |  | |
| Mushroom plush | Common | Squish: its cap wobbles |  | |
| Jellyfish plush | Uncommon | Shake: its legs float and drift |  | |
| Axolotl plush | Uncommon | Hug: its frills wiggle |  | |
| Capybara plush | Uncommon | Hug: it shuts its eyes, content |  | |
| Scented strawberry bear | Uncommon | Hug: a little puff of pink |  | |
| Weighted sloth plush | Uncommon | Hug: heavy, and slow to let go | Weighted plush searches rose 22% in a year | |
| Bean plush with its heart tag | Uncommon |  | A 1990s craze; Sealed means the tag still has its plastic cover | |
| Grumpling | Rare | Squeeze: it pulls a rude face | The 2026 ugly-plush craze | |
| Zipper-mouth plush | Rare | Unzip: a tiny find is inside its mouth |  | |
| Toothy monster plush | Rare | Clip: it hangs from your belt | The 2025 bag-charm craze | |
| Giant shark plush | Epic | Hug: it takes both arms |  | |
| Giant carnival bear | Epic | Hug: it takes both arms |  | |
| Antique teddy with a button in its ear | Legendary |  | The first teddy bears are real collectors' treasures | |

## Night Shift Minis (14) and their blind box · F-07

The monsters as collectibles. Five minis and the Secret come out of the Night Shift Minis blind box; the rest turn up loose. Each one does at home a small, harmless version of what its monster does on a floor.

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Mannequin keychain | Common | Clip: it swings from your belt as you run |  | |
| Packrat keychain | Common | Clip: it swings from your belt as you run |  | |
| Mannequin mini | Uncommon | At home: it turns its head only while you're looking away | The Mannequin's own rule. Blind box | |
| Packrat mini | Uncommon | At home: it stands holding a tiny lamp | The first thing a player sees it carry. Blind box | |
| Mannequin mini, pointing | Uncommon | At home: it points at whoever walked in last | Blind box | |
| Packrat mini, arms full | Uncommon |  | Blind box | |
| Minis display stand | Uncommon | At home: holds eight minis and lights each one |  | |
| Sleeping Packrat mini | Rare | At home: it snores softly | Blind box | |
| Mannequin plush | Rare | Hug: it goes stiff |  | |
| Packrat plush | Rare | At home: once a day it moves one small find from your shelf into its arms | The Packrat's habit, made cute | |
| Mannequin display hand | Epic | At home: it holds whatever find you put in it |  | |
| Mannequin bust | Epic |  |  | |
| Packrat's pile diorama | Legendary | At home: the pile grows with every find a Packrat has ever taken from you | Turns a loss into a trophy | |
| The one nobody's seen | Secret |  | Only an outline of the next monster; the figure changes when that monster arrives. 1 in 144 boxes | |

## Boxes and tins (14) · F-08

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Shoebox | Common | Open: one small find; now and then a pair of sneakers |  | |
| Banker's box of papers | Common | Open: papers spill out; now and then a page from the old storage company | Leads into the Old company set | |
| Taped moving box | Common | Open: one Common or Uncommon find | The most common find in the game | |
| Cookie tin | Common | Open: never cookies. Buttons and thread, or now and then a roll of old coins | A joke the grown-ups will get | |
| Crate of packing peanuts | Common | Open: foam bits burst out across the floor; something is buried in them |  | |
| Rattling box | Common | Shake: you hear a clink, a thud or a jingle, then decide whether to open it | My idea, untested | |
| Hat box | Uncommon | Open: a hat you can wear |  | |
| Gift-wrapped present | Uncommon | Open: a find one grade better than this floor usually gives | Lethal Company's gift box | |
| Nailed-shut wooden crate | Uncommon | Pry: two tugs and a loud creak, then a Rare or better find | Monsters hear the creak | |
| Jewelry box with a dancer | Rare | Open: a tiny dancer turns to a tune; inside is a piece of jewelry | The tune carries a little | |
| Nesting dolls | Rare | Open: each doll holds a smaller one, five times over; the smallest holds something tiny and good |  | |
| Puzzle box | Rare | Open: slide three panels in the right order, each right one clicks; inside is a Rare or better find | Resident Evil's puzzle boxes (from memory) | |
| Old toy chest | Epic | Open: three toys tumble out, Common to Epic, and you carry what fits |  | |
| Steamer trunk | Epic | Open: old clothes and one antique | Big find | |

## Bags and cases (14) · F-09

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Garbage bag of clothes | Common | Open: clothes, and now and then something left in a pocket |  | |
| Duffel bag | Common | Open: gym clothes and one sports find |  | |
| Backpack | Common | Open: school things. Wear: it rides on your back | Looks only; it never adds a slot | |
| Purse | Common | Open: coins spill out, to spend at the machine in the elevator |  | |
| Fanny pack | Uncommon | Open: one small find. Wear: round your waist |  | |
| Wallet | Uncommon | Open: coins, a photo, and now and then a creature card |  | |
| Makeup case | Uncommon | Open: a puff of glitter and a hand mirror |  | |
| Suitcase with travel stickers | Uncommon | Open: holiday clothes and a souvenir snow globe |  | |
| Tackle box | Uncommon | Open: fishing lures; one in ten is a gold lure |  | |
| Toolbox | Uncommon | Open: one of the game's tools (bolt cutters, padlock, saw, bubble wrap or air horn) | Another way to find a tool, rarer than the machine | |
| Doctor's bag | Rare | Open: old instruments and one antique |  | |
| Guitar case | Rare | Open: a guitar, or a stack of comic books someone hid inside |  | |
| Camera bag | Rare | Open: an instant camera or a camcorder |  | |
| Violin case | Rare | Open: usually sheet music; now and then a concert violin |  | |

## Locked and sealed (8) · F-10

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Piggy bank | Common | Throw: it smashes and coins scatter, loudly | Coins to spend now, or quiet: your choice | |
| Locked diary | Uncommon | Open: its tiny key is taped underneath; inside is a page about the building's past | Its words wait for the story | |
| Coin jar | Uncommon | Tip: coins roll everywhere, loud, and take a while to pick up |  | |
| Padlocked lockbox | Uncommon | Open: needs bolt cutters and uses one cut; inside is a Rare or better find | DOORS' locked chests | |
| Ring box | Rare | Open: the lid creaks up on a ring, Rare to Legendary |  | |
| Combination briefcase | Rare | Open: three dials; the numbers are on its luggage tag, somewhere in the same unit | A small version of the floor codes | |
| Floor safe | Legendary | It opens itself on the results screen, dial spinning, with a Legendary or better inside | Big find. The reveal at results is my idea, untested | |
| Time capsule | Secret | Open (at home): a day after you bring it home; inside is a find from a past season | Grow a Garden's waiting at home | |

## Treasures (14) · F-11

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Roll of old coins | Uncommon | Open: coins to spend in the elevator, and now and then a rare one |  | |
| Silver dollar | Uncommon | Flip: it rings as it spins |  | |
| Old treasure map | Rare | Read: X marks a spot on a floor far above |  | |
| Coin album | Rare | Open: one coin in it is the rare one |  | |
| Silver bar | Rare |  |  | |
| Gold coin | Epic | Flip: it rings as it spins |  | |
| Pirate doubloon | Epic |  |  | |
| Stamp printed upside down | Epic |  | Printing errors are real collectors' treasures | |
| Small treasure chest | Legendary | Open: gold coins pour out, with one Rare or better find |  | |
| First-edition book | Legendary |  |  | |
| Gold bar | Legendary |  | Heavy; it lands with a thud | |
| Diamond the size of a marble | Secret |  |  | |
| Jeweled egg | Secret | Open: a tiny gold surprise inside | A scrap dealer really found one (from memory) | |
| Golden elevator key | Secret |  | Loose only, floor 25 up. What it opens is for later | |

## Big finds, wave 1's eight · F-12

Wave 1 takes these eight of the sixteen (catalog build order); the rest come in wave 4. Each is carried in both hands, the floor's big find.

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Phone booth | Epic | At home: now and then it rings |  | |
| Vintage soda machine | Epic | At home: a bottle clunks out once a day |  | |
| Upright piano | Epic | At home: play it |  | |
| Moped | Epic | At home: sit on it; the horn beeps |  | |
| Pinball machine | Legendary | At home: you can play it |  | |
| Arcade cabinet | Legendary | At home: a short game with a high-score board for visitors to beat | Named in the design doc. A decision, because it's a game to build | |
| Jukebox | Legendary | At home: it plays every record you own | Named in the design doc | |
| 1940s motorcycle | Secret | At home: sit on it and it rumbles | A 1940 motorcycle really did turn up in a storage unit | |
