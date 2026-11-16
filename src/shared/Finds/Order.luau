--!strict
-- The order each kit-built find's motions were written in its build (F-G1a): a find's rest pose
-- is the first key of the first motion that moves each part (`Pose.rest`), and a Luau table
-- forgets the order the generated set wrote them in. tests/findpose.spec checks this against the
-- generated Finds/Sets text, so a rebuilt set that adds or reorders a motion fails the checks.
return {
	BlobLamp = { "SwitchOn", "Flow", "SwitchOff" },
	CampLantern = { "SwitchOn", "SwitchOff", "RunDown", "Lift" },
	ChatteringTeeth = { "Wind", "Chatter" },
	CymbalMonkey = { "Wind", "Play" },
	DeskLamp = { "SwitchOn", "SwitchOff" },
	DiecastCar = { "Push" },
	DiscoBall = { "Spin", "Spinning", "SpinDown" },
	FairyLights = { "SwitchOn", "SwitchOff" },
	FireflyJar = { "Idle", "Open", "Drift", "Gone" },
	GlowSticks = { "Crack" },
	HardHat = { "SwitchOn", "SwitchOff", "RunDown" },
	JackInTheBox = { "Wind", "Pop", "Shut" },
	MoonLamp = { "SwitchOn", "SwitchOff", "Phase" },
	NeonSign = { "SwitchOn", "Buzz", "SwitchOff" },
	NightLight = { "SwitchOn", "SwitchOff" },
	OilLamp = { "Light", "Burn", "RunDown" },
	RCCar = { "Launch", "Drive", "Stop" },
	Spotlight = { "SwitchOn", "SwitchOff", "Aim" },
	StainedGlassLamp = { "SwitchOn", "SwitchOff" },
	TeaLight = { "Light", "Flicker", "GoOut", "Lift" },
	UnpluggedLamp = { "Switch" },
} :: { [string]: { string } }
