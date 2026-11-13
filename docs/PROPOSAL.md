# Proposal: one loop, with the store built into it

_A proposal from the Nov 12 and 13 audit, for the owner to accept, change or reject. Nothing here
is decided and nothing here is built. The GDD stays the source of truth: a part moves into the
GDD, ROADMAP and DECISIONS only when the owner says yes to it. The docs and code call the monsters
"keepers"; this says monsters, since no name is picked._

## The idea

The craft is already far above most Roblox games. What's thin is the reason to open the next
door and the reason to climb again. This proposal makes six changes that lean on each other:
every door pays and can be read from the hall; the building does something on a clock that the
whole team reacts to; the gate's 30 seconds catch people because finds and friends are still out
on the floor; nobody is benched for the rest of a climb; a climb is short and different each
time; and what you carry out is appraised, sold or kept, and spent on the next climb.

Each thing sold sits inside one of those changes, at the moment a player would want it, and is
built in the same step as the play it belongs to.

## How it fits together

| When | What you do | Why you do it again | What's sold there |
| --- | --- | --- | --- |
| Every few seconds | Pick a door, lift it | Every door pays, and some pay big | Nothing |
| Every minute | Freeze, or get inside | The building looks, and you all react at once | Nothing |
| Every floor | Find the code, grab finds, make the gate | The last sprint, with something in your hands | Nothing (no Robux beside a timer) |
| When caught | Bang, strain, get cut free | A friend saves you, or you save yourself | Cut Free, Free a Friend, Free Everyone, wrap colours |
| Every ride | Vote a card, spend quarters | This climb plays differently from the last | Beam colours, the extra tool slot |
| After a climb | Watch your finds appraised | The second reveal, and cash to spend | Double cash, cash packs, the starter pack, decor |
| Every day | Open the daily door | A streak, a best floor to beat | The weekly shelf, later a season pass |

## 1. Every door pays, and you can read it before you lift it

**Today.** Of every 100 doors, 40 hold nothing and 25 hold a find you can't take. A floor has 60
to 80 doors that look alike, and the only way to find a note is to open them all.

**Change.**
- **No empty units.** Every unit has a few quarters on its floor, taken with a tap. On top of
  that it may hold a find, a tool, a note or a monster, as now.
- **Quarters are the climb's own money.** They buy from the vending machine in the car (section
  5). What you still hold when the climb ends turns into cash. They are never sold.
- **About half as many units a floor** (about 30 on floors 1 and 2, about 40 above), with plain
  wall between them so the halls keep their length for a chase. Each door matters more.
- **Three kinds of door you can tell apart from the hall:**
  - Plain: quarters, and maybe more.
  - Tagged, with an auction tag on the door: a find for certain, and twice the odds of a monster.
  - Padlocked: the best finds and the worst odds, and it needs bolt cutters, as now.
- **A note gives itself away up close.** Dale's pencil tick on the door's frame shows in your
  torch from a few steps off. The corner map rings each wing that holds a note; the notes are
  already laid one to a wing.
- **A quiet lift** (a bet on fit, see the end). One timing mark as the door rises: tap inside it
  and the door goes up without its rattle, so nothing hears it. Miss, or ignore it, and it's the
  loud open you have now.

**Why.** A bet needs odds you can read and a win you can hold. Today it is a lever pulled 700
times a climb with nothing to take away.

**As in.** DOORS puts a little gold in most drawers. Fortnite's chests glow and hum before you
open them. Escape from Tarkov's marked rooms hold its best loot (already the padlock's precedent
in the deal's rules). DOORS' library books stick out of the shelves and a paper hints at the
order. Dead by Daylight's generators and Dandy's World's machines both put a timing check on the
thing you do most.

**Sold here.** Nothing. This is what makes cash worth having; the double cash pass (section 6)
multiplies what these doors pay.

**Starting numbers.** One to three quarters in a plain unit. About one door in five tagged.

**What it reuses.** The deal's odds and the floor's plans are data, so most of this is numbers.
The padlock, the corner map and its wings exist.

## 2. The building keeps time

**Today.** The lights come on when you move and nothing comes to look: they report every fixture
that wakes and nothing listens. The one monster is stopped by light and your torch never runs
out, so light is only ever your friend. A wrong code lights the whole floor, which freezes that
monster for about seven seconds. The GDD's rule is the opposite, that every lit fixture always
calls a monster, and that would tax walking, which is what a floor is made of. Its four ways to
move (still, crouch-walk, walk, sprint) aren't in the game: there is one speed.

**Change.** Events on a clock, each with a warning and one rule.
- **Inspection** (from floor 1). The PA clicks, every sensor dome turns red and the hall tubes go
  out. For five seconds, any dome that sees you move sends the nearest monster to that spot. Stand
  still, or be inside a unit, where there are no domes. The Mannequin walks in that dark while you
  can't, so you turn on the spot and hold it with your torch. About every 75 seconds.
- **The clock strikes** (from floor 3). A clock winds for four seconds, louder each second. On
  the strike every light flashes on, and anyone standing in a hall is seen: every loose monster
  comes for them. Be inside a unit with its door down. Once or twice a floor. This is the
  "Grandfather's rule" from your roster note in `OWNER.md`, built as the building's own event so
  it needs no new monster.
- **Closing time.** After a floor's fair share of time (4 minutes on short floors, 6 on full
  ones) the PA calls closing time: inspections come twice as often, and a sleeping monster wakes
  each minute. A team that keeps moving never hears it. It is what makes "one more unit" a gamble
  once doors pay.
- **A wrong code costs you.** The halls go dark for the alarm instead of bright, every loose
  monster comes, and the keypad's dead time doubles with each wrong code on that floor (3.5, 7,
  14 seconds). Today, with three digits found, ten cheap guesses skip the guarded note.
- **One speed stays.** Drop the GDD's crouch-walk and sprint table.
- **The next monster is one that light doesn't stop,** so there is something to run from, and it
  is the one that answers an inspection. Which monster is yours to pick (the roster note).

**Why.** A rule that is always on stops being scary and slows the search to a crawl. A rule that
arrives with a warning is a moment the whole team shares, and "Don't move. The lights are
watching." becomes something a player feels in the first two minutes.

**As in.** Red Light, Green Light, the most played rule on Roblox. DOORS' Rush: a warning, then
seconds to hide. Lethal Company's day, where more comes out the later it gets and the ship leaves
at midnight. DOORS' library, where guessing the last digit is allowed but Figure makes it cost.

**Sold here.** Nothing, ever. No product touches these rules.

**What it reuses.** The domes already have three looks (watching, seen, blind). The lights
already report each fixture that wakes. The alarm already reaches every fixture on a floor.

**If you'd rather keep the lights always watching,** build it as the GDD says and judge it in the
friends' run. My worry is only that the safe way to play becomes creeping everywhere.

## 3. The gate bites

**Today.** The keypad is beside the car, so a careful team gathers first and then types, and the
30 seconds rarely catch anyone. Finds can't be carried out.

**Change.**
- **Small finds** are taken with a tap and belong to the team. No slot, no weight.
- **One big find a floor,** from floor 2: carried in both hands, and slower than a monster while
  you hold it (the GDD's speed rule). Set it down in the car to count it. One a floor, never a
  cart-load, so the climb stays an escape and not a haul.
- **What's in the car when the gate shuts belongs to everyone aboard:** each rider gets their own
  copy. Nobody fights over a find, and being left behind costs you that floor's finds.
- Closing time (section 2) is what keeps people out on the floor when the code goes in.

**As in.** Lethal Company's ship leaves with or without you, and what's aboard is what counts.
DOORS' gold is a tap. Dandy's World pays every player for the floor, not the one who did the work.

**Sold here.** Nothing. Your rule holds: Robux never sit beside a timer.

## 4. Kept, never benched

**Today.** A friend cuts you free in a second; after two and a half minutes your door is
padlocked. When the gate shuts without you, you watch the rest of the climb or pay. Alone, one
catch ends the climb. In a ten-floor climb, a friend caught on floor 2 could watch for 40 minutes.

**Change.**
- **Why it got you.** One line on the kept screen names the cause ("You stood still in the dark").
  Losing teaches the rule.
- **Strain free.** Hold to strain against the wrap: 25 seconds the first time in a climb, 15 more
  each time after, and loud the whole way. It stops working once your door is padlocked. A
  friend's cut is still one second. A hold, not mashing.
- **Everything it keeps goes up** (the GDD's own line). Left behind, kept or just late, you watch
  as now. When your friends reach the next floor you are there, wrapped, in one of its units, and
  banging marks your door. They cut you free as on any floor. Not found before that gate shuts,
  you go up again. You come back with empty hands and without the floor you missed.
- **A job while you watch.** The GDD's light board becomes the watcher's view: the floor plan
  with a lamp for every fixture, and a tap marks a spot on your friends' corner maps. Nobody
  alive would choose to sit in an office; someone waiting would.
- The whole team kept still ends the climb.

**Why.** The game's best moments need friends together. A rule that sends one home for half an
hour, or lets a stranger's fourth digit put a price on staying, works against that.

**As in.** R.E.P.O.: a dead friend's head is carried to the extraction point and they're back.
Lethal Company: the dead return when the ship takes off. Dead by Daylight: a slow, risky escape
from the hook on your own. DOORS explains each death. Among Us gives ghosts tasks.

**Sold here, in the kept view only, never as a pop-up.**
- **Cut Free** (45, then 75 in the same climb): out now, quietly, on this floor. Left behind, it
  stands you in the car on the next floor with your tools.
- **Free a Friend** (49) and **Free Everyone** (149). On a team wipe, Free Everyone carries the
  climb on from that floor.
- **Wrap colours** (99 to 499): your wrap is what friends see when they find you.
- Gift versions of each.

**What it does to revenue, honestly.** A free way back means fewer forced buys. What's sold
becomes time, your tools and your place in this floor's finds. I think friends who stay together
are worth more than the lost revives, but it is a real trade and yours to make.

## 5. A shorter climb that changes every time

**Today.** The plan is ten floors in about 50 minutes. What's built is three floors, a ride of
under ten seconds with nothing to do, and one difficulty. The card vote and the vending machine
are in the GDD but on no ticket.

**Change.**
- **The first roof is on floor 5,** about 20 to 25 minutes. Floors 1 and 2 teach doors and the
  inspection. Floors 3 and 4 add the clock's strike, tagged and padlocked notes and the second
  monster. Floor 5 is Dale's: trap him for the last digit, so the hole trap has an exam. Then the
  roof.
- **The building grows,** as the GDD already says: floors 6 to 10, the stairwell and the breaker
  finale arrive as chapters, with Unit 0 always on top.
- **The ride is about 20 seconds and has a job.** Before odd floors the team votes one of three
  cards, a buff for the rest of the climb. After even floors the vending machine takes quarters.
- **First cards:** five more seconds on the gate; a wider beam; your first lift each floor is
  silent; strain free twice as fast; tagged doors show on the corner map.
- **Trapping earns its place.** The first time you trap each monster stamps the Catalog (in the
  GDD) and unlocks a perk to buy (section 6). And a trapped monster keeps its place under the
  floor's limit, so trapping buys quiet instead of making room for a fresh one.
- **A weekly rule** on the lobby's board (the power's out, inspections come double) instead of a
  new monster every week. A new monster comes with each chapter.

**Why.** A good team should reach the roof in one sitting, and a second climb should not be the
first one again.

**As in.** Dandy's World's card vote and shop on the ride, the GDD's own precedent. DOORS' door
50, a code hunt with one thing hunting you. DOORS' modifiers. Dandy's World's research, where
meeting a monster often enough unlocks something to buy.

**Sold here.**
- **The Bring slot:** your starting tool, cash only, in the car (the GDD's).
- **The extra tool slot** pass (199 to 299). Your note sells six slots; I'd sell one more, so
  which tools to carry stays a choice.
- **Beam colours** (49 to 299): in the dark your light is what everyone sees.
- **Nothing on the cards.** A paid reroll of a random draw is a paid random item.

## 6. After the climb: appraise, sell, keep, spend

**Today.** The results show your floor and your time. Nothing is saved.

**Change.**
- **The results appraise your finds** one at a time: its name, its tier stamped on, its worth,
  and the cash counting up. Unspent quarters turn to cash. Then a line per player: rescues, doors
  opened, "shut a friend in".
- **A find's first time fills a Catalog page** with a "New" stamp. Sets (the 1980s bedroom) pay a
  display piece when finished.
- **About 1 find in 20 comes shrink-wrapped:** worth three times as much, and shown wrapped.
- **Sell or keep, with no menu.** Duplicates and common finds sell on the spot. New and rare ones
  go to your unit, and you can sell from there later.
- **Your unit grows** from small to medium to large for cash; the three sizes are already
  modelled. Until the hall of units exists, a shelf in the host's car shows the host's best three
  finds, where friends see them on every ride.
- **Cash buys:** the Bring slot's tool; perks; a bigger unit; cosmetics.
- **Perks:** equip two, fixed when the climb starts. Each is unlocked by a deed in the Catalog and
  then bought. Small edges, never a must-have: cut holds half as long; your beam reaches a little
  further; carry the big find a little faster; your doors rattle half as far.

**Why.** Cash with nothing to spend on makes selling pointless, and a find on a shelf nobody
visits is worth nothing. Perks make the collection change how the next climb plays.

**As in.** DOORS turns a run's gold into Knobs for a 30-second shop before the next one. Dandy's
World's trinkets: two equipped, fixed at the start, bought with Ichor after a deed. Fisch's
bestiary pays for each finished page. Fisch and Grow a Garden both multiply a thing's worth with
rare versions of it. Lethal Company's ship is where the crew's purchases are shown off.

**Sold here.**
- **Double cash** pass (299 to 399). Your default is not at launch; I'd ship it the day selling
  does, since it harms nobody in co-op and it is the clearest thing to want.
- **Cash packs** (49 to 1,499), only once perks and the Bring slot give cash a use.
- **The starter pack** (99), shown after your first climb: a beam colour, a wrap colour, cash.
- **Car and unit decor** (99 to 499).

## 7. Reasons to come back tomorrow

- **A saved profile comes first** (from Brix): cash, finds, the Catalog, best floor, purchases.
  Everything in section 6 and every product depends on it.
- **Best floor** on your plaque and the car's dial; the **Missing board** with your photo and the
  floor it kept you on; Roblox **badges** for the first roof, each monster trapped, each set.
- **The daily door** (the GDD's free sealed lot): the slow, loud open once a day, with a better
  tier on the seventh day in a row. Never sold.
- **A weekly rule and a weekly shelf:** three cosmetics that change each week.
- **A season pass, after launch:** a free and a paid track, moved along by floors climbed, every
  reward shown up front.
- **Private servers cheap or free.** Friends are how this game grows.

## The store on one page

| Product | Robux | Where it shows | Ships with |
| --- | --- | --- | --- |
| Cut Free | 45, then 75 | The kept view | Step 3 |
| Free a Friend | 49 | The kept view, the watcher's view | Step 3 |
| Free Everyone | 149 | A team wipe, before the results | Step 3 |
| Wrap colours | 99 to 499 | The counter | Step 3 |
| Extra tool slot | 199 to 299 | The counter | Step 4 |
| Beam colours | 49 to 299 | The counter | Step 4 |
| Double cash | 299 to 399 | The counter, the results | Step 5 |
| Cash packs | 49 to 1,499 | The counter | Step 5 |
| Starter pack | 99 | After your first climb | Step 5 |
| Car and unit decor | 99 to 499 | The counter, the weekly shelf | Step 5 |
| Season pass | not priced | The lobby | After launch |
| Gift versions | same | Beside each product | With each |

Prices are the GDD's draft ranges. The Bring slot, perks and a bigger unit cost cash, not Robux.

**Rules, all the GDD's or D-112's.** Nothing random is ever sold, for Robux or for cash. No Robux
beside a timer. No product hurts another player. Quarters, the daily door and the cards are never
sold. No floor skips. The shop never interrupts play. A purchase survives a failed save and a
server hop; every offer can be switched off without an update; prices are read from Roblox.

## What I'd cut or shelve

- The crouch-walk and sprint table. One speed, and the building's clock.
- Trading, until well after launch: scams, real-money selling and young players.
- Mimics, fake notes, the Mover and the dolly. Fake notes can come with floors 6 to 10.
- Floors 6 to 10, the stairwell and the breaker finale at launch. They become chapters.
- A new monster every week. A weekly rule is far cheaper to make well.
- The light board as a living player's post. It becomes the watcher's job.
- The hall of lobby units, until after launch. The car's shelf first.

## Build order: each step ships play and store together

| Step | Play | Store | It works when |
| --- | --- | --- | --- |
| 0 | A first run with friends on what's built (only you can run it) | None | They ask for another run, or say why not |
| 1 | Doors pay: quarters, small finds, three kinds of door, half the units, results that count cash; the saved profile | Log what's earned and spent | Players open more doors a minute and skip plain ones for tagged |
| 2 | The building's clock: inspection, the wrong code, closing time; then the strike and the next monster | None | Someone shouts "don't move" unprompted |
| 3 | Kept, never benched: the cause line, strain free, going up, the watcher's board | Cut Free, Free a Friend, Free Everyone, wrap colours; purchases made safe | Nobody leaves a climb because they were caught |
| 4 | The climb's shape: the roof on floor 5, cards, the vending machine, the big find | The Bring slot, beam colours, the extra tool slot | Two climbs in a row feel different |
| 5 | After the climb: appraisal, the Catalog, sets, the car's shelf, perks | Double cash, cash packs, the starter pack, decor | Players stay through the results and change perks between climbs |
| 6 | Coming back: the daily door, best floor, the Missing board, badges, a weekly rule, Captures | The weekly shelf; later the season pass | Players return the next day without being asked |

## What to measure

- Seconds from joining to your first door (the GDD wants 30).
- Doors opened a minute, and the share that paid something.
- Catches a floor, and what caused each.
- The share of players left behind, and the minutes they spent watching.
- How often "Again" is pressed after a climb.
- Buyers of each product, and where they stood when they bought.

None of this can be read today: the game logs nothing.

## What this changes in the GDD, if you say yes

- **Lights:** always watching becomes the inspection; the four ways to move go.
- **Doors:** "nothing" leaves the deal; quarters and tagged doors join it; about half the units.
- **Getting kept:** left behind is no longer out of the climb; strain free is new; the light
  board moves to the watcher.
- **Codes:** a wrong code darkens the floor and its cost doubles.
- **The building:** the roof at floor 5 for launch, growing by chapters.
- **Tools and traps:** a trapped monster keeps its place under the floor's limit; trapping
  unlocks a perk. Whether the GDD's limit rule was ever your choice, I don't know.
- **Meta:** everyone aboard gets a copy of each find; appraisal at the results; perks; the car's
  shelf; trading shelved.
- **Monetization:** double cash and the season pass added; the rest moved to where it's used.

## Things you cut before that this brings back

- **Left behind, carried up.** Cut on Nov 2 for having no precedent. I think R.E.P.O.'s head
  revive is one, checked Nov 13. Your call.
- **A clock that makes things worse.** A night clock across the whole climb was cut on Nov 2.
  Closing time is one floor's clock, as Lethal Company's day is.
- **A reward for trapping.** You dropped a cash bonus on Nov 9. This is not cash: the Catalog
  stamp the GDD already has, unlocking a perk you then buy.

## Bets with no precedent I can name

These go to `OWNER.md` if any is taken up, and are never built quietly.
- The quiet lift. Timing checks are proven, but not on a door you open 300 times a climb.
- The Mannequin walking during an inspection. Each half is proven; the pairing is ours.
- The appraisal as a second reveal at the results.
- Shrink-wrapped finds as the rare version.
- The watcher marking spots for the team.

## How sure I am of each precedent

**Checked on the web, Nov 13:** R.E.P.O.'s head carried to the extraction point; Dandy's World's
two trinkets, fixed at the start, bought with Ichor after a deed, and its skill checks; DOORS'
gold turning into Knobs, its 30-second shop before a run and its library's eight books and hint
paper; Lethal Company's ship leaving at midnight and more coming out as the day goes on; Fisch's
bestiary rewards; Fisch's and Grow a Garden's rare versions multiplying worth.

**From memory, not checked:** Lethal Company's dead returning on take-off; DOORS explaining each
death; Dead by Daylight's escape from the hook; Among Us' ghost tasks; Fortnite's chests humming;
Lethal Company's ship furniture. Check each before it is leaned on.

**Sources.**
[R.E.P.O. revive, PC Gamer](https://www.pcgamer.com/games/horror/repo-how-to-heal-and-revive/) ·
[R.E.P.O. revive, GamesRadar](https://www.gamesradar.com/games/horror/repo-revive) ·
[Dandy's World trinkets, wiki](https://dandys-world-robloxhorror.fandom.com/wiki/Trinkets) ·
[Dandy's World trinkets, Pro Game Guides](https://progameguides.com/roblox/all-trinkets-in-dandys-world-and-how-to-get-them/) ·
[DOORS Knobs, wiki](https://doors-game.fandom.com/wiki/Knobs) ·
[Lethal Company spawn times, Steam](https://steamcommunity.com/app/1966720/discussions/0/3958162152971622445) ·
[Fisch mutations, Roblox Den](https://robloxden.com/game-codes/fisch/guides/fisch-mutations-guide-types-multipliers-and-how-to-get-them) ·
[Grow a Garden mutations, Sportskeeda](https://www.sportskeeda.com/roblox-news/all-mutations-grow-garden)
