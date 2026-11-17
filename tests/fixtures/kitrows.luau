--!strict
--[[
	Every kit find's game row as it was hand-written in `Tools.Catalog` and `Finds/Use` before its
	art spec took it over (F-G1f, D-265, Nov 17): a frozen snapshot, written once by Lune from the
	hand-written rows, that tests/kitrows.spec holds the generated rows (`Finds/Rows`) to. `order`
	is the deal's order of the kit finds (`Deal.Finds`, after the bedroom set); each row its
	catalog fields (`hold` stands for its size in your view) and its press (none: no press).

	A deliberate change to one of these finds (a new worth, a press reworked) changes its line here
	in the same commit. A press added where there was none needs nothing here.
]]

return {
	order = {
		"NightLight",
		"TeaLight",
		"DeskLamp",
		"GlowSticks",
		"FairyLights",
		"CampLantern",
		"MoonLamp",
		"BlobLamp",
		"OilLamp",
		"DiscoBall",
		"NeonSign",
		"HardHat",
		"FireflyJar",
		"StainedGlassLamp",
		"UnpluggedLamp",
		"DiecastCar",
		"RCCar",
		"CymbalMonkey",
		"JackInTheBox",
		"Kazoo",
		"RubberDuck",
		"SirenCar",
		"ChatteringTeeth",
		"ToyDrum",
		"WindupMouse",
		"WalkingRobot",
		"FarmSpinner",
		"CowboyDoll",
		"SingingFish",
		"TinBird",
		"TinCarousel",
		"StressBall",
		"ButterStick",
		"MochiBun",
		"PaperSquishy",
		"ToastSlice",
		"GelBeadBall",
		"GlitterGooBall",
		"JumboStrawberry",
		"Capybara",
		"GalaxyGooBall",
	},
	rows = {
		BlobLamp = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9114008989",
					length = 1.4,
					pitch = 1.2,
					volume = 0.65,
				},
				grade = "Uncommon",
				grip = { -0.09, 0.75, 0.23 },
				heft = 0.5,
				hold = { -1.2, -0.72, -2 },
				name = "Blob lamp",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116657808",
					length = 0.3,
					pitch = 0.9,
					volume = 0.7,
				},
				verb = "Switch",
				worth = 18,
			},
			press = {
				lasts = 6e+01,
				off = {
					motion = "SwitchOff",
					sound = {
						from = 0.1,
						id = "rbxassetid://9114480269",
						length = 0.14,
						volume = 1.4,
					},
				},
				on = {
					{
						motion = "SwitchOn",
						sound = {
							from = 0.38,
							id = "rbxassetid://9114480271",
							length = 0.14,
							volume = 1.4,
						},
					},
					{
						loop = math.huge,
						motion = "Flow",
					},
				},
				out = {
					{
						motion = "SwitchOff",
					},
				},
				verb = "Switch",
			},
		},
		ButterStick = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.15,
					volume = 0.5,
				},
				grade = "Common",
				grip = { 0, 0.08, 0 },
				heft = 0.04,
				hold = { -0.95, -0.62, -1.7 },
				name = "Butter stick",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.45,
					volume = 0.75,
				},
				worth = 4,
			},
		},
		CampLantern = {
			catalog = {
				drop = {
					from = 0.22,
					id = "rbxassetid://9113768847",
					length = 0.9,
					pitch = 1.15,
					volume = 0.8,
				},
				grade = "Uncommon",
				grip = { 0, 0.66, 0.05 },
				heft = 0.35,
				hold = { -1.2, -0.72, -2 },
				name = "Lantern",
				pickUp = {
					from = 0,
					id = "rbxassetid://9117544893",
					length = 0.42,
					pitch = 1.15,
					volume = 0.8,
				},
				verb = "Switch",
				worth = 15,
			},
			press = {
				lasts = 9e+01,
				off = {
					motion = "SwitchOff",
					sound = {
						from = 0.1,
						id = "rbxassetid://9114480269",
						length = 0.14,
						volume = 1.4,
					},
				},
				on = {
					{
						motion = "SwitchOn",
						sound = {
							from = 0.38,
							id = "rbxassetid://9114480271",
							length = 0.14,
							volume = 1.4,
						},
					},
				},
				out = {
					{
						motion = "RunDown",
					},
				},
				verb = "Switch",
			},
		},
		Capybara = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1,
					volume = 0.55,
				},
				grade = "Rare",
				grip = { 0, 0.14, 0 },
				heft = 0.04,
				hold = { -0.95, -0.62, -1.7 },
				name = "Squishy capybara",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.3,
					volume = 0.75,
				},
				worth = 55,
			},
		},
		ChatteringTeeth = {
			catalog = {
				drop = {
					from = 0.22,
					id = "rbxassetid://9113768847",
					length = 0.9,
					pitch = 1.9,
					volume = 0.5,
				},
				grade = "Common",
				grip = { 0, 0.12, 0 },
				heft = 0.05,
				hold = { -0.95, -0.62, -1.7 },
				name = "Chattering teeth",
				pickUp = {
					from = 0.15,
					id = "rbxassetid://9119728830",
					length = 0.35,
					pitch = 1.75,
					volume = 0.85,
				},
				worth = 6,
			},
		},
		CowboyDoll = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 0.75,
					volume = 0.6,
				},
				grade = "Rare",
				grip = { 0, 0.75, 0 },
				heft = 0.25,
				hold = { -1.2, -0.72, -2 },
				name = "Cowboy doll",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					volume = 0.75,
				},
				worth = 45,
			},
		},
		CymbalMonkey = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					pitch = 1.15,
					volume = 0.75,
				},
				grade = "Rare",
				grip = { 0, 0.55, 0 },
				heft = 0.3,
				hold = { -1.2, -0.72, -2 },
				name = "Cymbal monkey",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116460746",
					length = 0.42,
					pitch = 1.5,
					volume = 0.6,
				},
				verb = "Wind",
				worth = 4e+01,
			},
			press = {
				lure = 2,
				noise = "Play",
				on = {
					{
						motion = "Wind",
						sound = {
							from = 0,
							id = "rbxassetid://9120219923",
							length = 2.4,
							volume = 1,
						},
					},
					{
						hit = {
							part = "CymbalMonkey_ArmL",
							sound = {
								from = 0,
								id = "rbxassetid://867306119",
								length = 0.35,
								pitch = 1.9,
								volume = 0.9,
							},
						},
						motion = "Play",
					},
				},
				toy = true,
				verb = "Wind",
			},
		},
		DeskLamp = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9114008989",
					length = 1.4,
					pitch = 1.3,
					volume = 0.65,
				},
				grade = "Common",
				grip = { 0, 0.7, 0.4 },
				heft = 0.45,
				hold = { -1.55, -0.8, -2.4 },
				name = "Desk lamp",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116657808",
					length = 0.3,
					pitch = 1,
					volume = 0.7,
				},
				verb = "Switch",
				worth = 4,
			},
			press = {
				lasts = 6e+01,
				off = {
					motion = "SwitchOff",
					sound = {
						from = 0.1,
						id = "rbxassetid://9114480269",
						length = 0.14,
						volume = 1.4,
					},
				},
				on = {
					{
						motion = "SwitchOn",
						sound = {
							from = 0.38,
							id = "rbxassetid://9114480271",
							length = 0.14,
							volume = 1.4,
						},
					},
				},
				out = {
					{
						motion = "SwitchOff",
					},
				},
				verb = "Switch",
			},
		},
		DiecastCar = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9114008989",
					length = 1.4,
					pitch = 2.2,
					volume = 0.45,
				},
				grade = "Common",
				grip = { 0, 0.06, 0 },
				heft = 0.02,
				hold = { -0.95, -0.62, -1.7 },
				name = "Toy car",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116175991",
					length = 0.5,
					pitch = 1.8,
					volume = 0.55,
				},
				verb = "Push",
				worth = 4,
			},
			press = {
				down = true,
				on = {
					{
						motion = "Push",
						sound = {
							from = 0,
							id = "rbxassetid://99838569349900",
							length = 3.4,
							volume = 0.6,
						},
					},
				},
				toy = true,
				verb = "Push",
			},
		},
		DiscoBall = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					volume = 0.75,
				},
				grade = "Rare",
				grip = { 0, 0.25, 0 },
				heft = 0.45,
				hold = { -1.2, -0.72, -2 },
				name = "Disco ball",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116175991",
					length = 0.5,
					volume = 0.7,
				},
				verb = "Spin",
				worth = 45,
			},
			press = {
				off = {
					motion = "SpinDown",
				},
				on = {
					{
						motion = "Spin",
					},
					{
						loop = math.huge,
						motion = "Spinning",
					},
				},
				verb = "Spin",
			},
		},
		FairyLights = {
			catalog = {
				drop = {
					from = 0.22,
					id = "rbxassetid://9113768847",
					length = 0.9,
					pitch = 1.6,
					volume = 0.55,
				},
				grade = "Uncommon",
				grip = { 0, 0.06, 0.03 },
				heft = 0.08,
				hold = { -0.95, -0.62, -1.7 },
				name = "Fairy lights",
				pickUp = {
					from = 0.2,
					id = "rbxassetid://9125745465",
					length = 0.45,
					volume = 0.7,
				},
				verb = "Switch",
				worth = 12,
			},
			press = {
				off = {
					motion = "SwitchOff",
					sound = {
						from = 0.1,
						id = "rbxassetid://9114480269",
						length = 0.14,
						volume = 1.4,
					},
				},
				on = {
					{
						motion = "SwitchOn",
						sound = {
							from = 0.38,
							id = "rbxassetid://9114480271",
							length = 0.14,
							volume = 1.4,
						},
					},
				},
				verb = "Switch",
			},
		},
		FarmSpinner = {
			catalog = {
				drop = {
					from = 0.22,
					id = "rbxassetid://9113768847",
					length = 0.9,
					pitch = 1,
					volume = 0.8,
				},
				grade = "Uncommon",
				grip = { 0, 1, 0 },
				heft = 0.35,
				hold = { -1.55, -0.8, -2.4 },
				name = "Farm spinner",
				pickUp = {
					from = 0,
					id = "rbxassetid://9117544893",
					length = 0.42,
					pitch = 1,
					volume = 0.8,
				},
				worth = 16,
			},
		},
		FireflyJar = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					pitch = 1.5,
					volume = 0.65,
				},
				grade = "Epic",
				grip = { 0, 0.6, 0 },
				heft = 0.2,
				hold = { -0.95, -0.62, -1.7 },
				name = "Firefly jar",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116175991",
					length = 0.5,
					pitch = 1.45,
					volume = 0.7,
				},
				verb = "Open",
				worth = 1.1e+02,
			},
			press = {
				lasts = 6e+01,
				on = {
					{
						motion = "Open",
					},
					{
						loop = math.huge,
						motion = "Drift",
					},
				},
				out = {
					{
						motion = "Gone",
					},
				},
				verb = "Open",
			},
		},
		GalaxyGooBall = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 0.95,
					volume = 0.55,
				},
				grade = "Legendary",
				grip = { 0, 0.14, 0 },
				heft = 0.05,
				hold = { -0.95, -0.62, -1.7 },
				name = "Galaxy goo ball",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.25,
					volume = 0.75,
				},
				worth = 3.5e+02,
			},
		},
		GelBeadBall = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.05,
					volume = 0.55,
				},
				grade = "Uncommon",
				grip = { 0, 0.13, 0 },
				heft = 0.05,
				hold = { -0.95, -0.62, -1.7 },
				name = "Gel bead ball",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.35,
					volume = 0.75,
				},
				worth = 12,
			},
		},
		GlitterGooBall = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.05,
					volume = 0.55,
				},
				grade = "Uncommon",
				grip = { 0, 0.12, 0 },
				heft = 0.05,
				hold = { -0.95, -0.62, -1.7 },
				name = "Glitter goo ball",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.35,
					volume = 0.75,
				},
				worth = 15,
			},
		},
		GlowSticks = {
			catalog = {
				drop = {
					from = 0.22,
					id = "rbxassetid://9113768847",
					length = 0.9,
					pitch = 1.9,
					volume = 0.45,
				},
				grade = "Common",
				grip = { 0, 0.06, 0 },
				heft = 0.03,
				hold = { -0.95, -0.62, -1.7 },
				name = "Glow sticks",
				pickUp = {
					from = 0.2,
					id = "rbxassetid://9125745465",
					length = 0.45,
					volume = 0.7,
				},
				verb = "Crack",
				worth = 5,
			},
			press = {
				on = {
					{
						motion = "Crack",
					},
				},
				verb = "Crack",
			},
		},
		HardHat = {
			catalog = {
				drop = {
					from = 0.22,
					id = "rbxassetid://9113768847",
					length = 0.9,
					pitch = 0.95,
					volume = 0.8,
				},
				grade = "Rare",
				grip = { 0, 0.75, 0 },
				heft = 0.3,
				hold = { -1.2, -0.72, -2 },
				name = "Hard hat",
				pickUp = {
					from = 0,
					id = "rbxassetid://9117544893",
					length = 0.42,
					volume = 0.8,
				},
				verb = "Switch",
				worth = 7e+01,
			},
			press = {
				lasts = 6e+01,
				off = {
					motion = "SwitchOff",
					sound = {
						from = 0.1,
						id = "rbxassetid://9114480269",
						length = 0.14,
						volume = 1.4,
					},
				},
				on = {
					{
						motion = "SwitchOn",
						sound = {
							from = 0.38,
							id = "rbxassetid://9114480271",
							length = 0.14,
							volume = 1.4,
						},
					},
				},
				out = {
					{
						motion = "RunDown",
					},
				},
				verb = "Switch",
			},
		},
		JackInTheBox = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					volume = 0.75,
				},
				grade = "Uncommon",
				grip = { 0, 0.45, 0 },
				heft = 0.3,
				hold = { -1.2, -0.72, -2 },
				name = "Jack-in-the-box",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116657808",
					length = 0.3,
					pitch = 1.1,
					volume = 0.7,
				},
				verb = "Wind",
				worth = 18,
			},
			press = {
				noise = "Pop",
				on = {
					{
						motion = "Wind",
						sound = {
							from = 0,
							id = "rbxassetid://9117044359",
							length = 9,
							volume = 1.1,
						},
					},
					{
						motion = "Pop",
						sound = {
							from = 0,
							id = "rbxassetid://9116460746",
							length = 0.42,
							pitch = 0.75,
							volume = 1.3,
						},
					},
				},
				reset = {
					motion = "Shut",
				},
				verb = "Wind",
			},
		},
		JumboStrawberry = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 0.9,
					volume = 0.55,
				},
				grade = "Uncommon",
				grip = { 0, 0.25, 0 },
				heft = 0.08,
				hold = { -1.2, -0.72, -2 },
				name = "Jumbo strawberry",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.15,
					volume = 0.75,
				},
				worth = 18,
			},
		},
		Kazoo = {
			catalog = {
				drop = {
					from = 0.22,
					id = "rbxassetid://9113768847",
					length = 0.9,
					pitch = 2.1,
					volume = 0.4,
				},
				grade = "Common",
				grip = { 0, 0.05, 0.05 },
				heft = 0.02,
				hold = { -0.95, -0.62, -1.7 },
				name = "Kazoo",
				pickUp = {
					from = 0.15,
					id = "rbxassetid://9119728830",
					length = 0.35,
					pitch = 1.9,
					volume = 0.6,
				},
				worth = 2,
			},
		},
		MochiBun = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.3,
					volume = 0.45,
				},
				grade = "Common",
				grip = { 0, 0.09, 0 },
				heft = 0.02,
				hold = { -0.95, -0.62, -1.7 },
				name = "Mochi bun",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.6,
					volume = 0.75,
				},
				worth = 4,
			},
		},
		MoonLamp = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9119075637",
					length = 0.7,
					pitch = 1.1,
					volume = 0.8,
				},
				grade = "Uncommon",
				grip = { 0, 0.3, 0 },
				heft = 0.25,
				hold = { -1.2, -0.72, -2 },
				name = "Moon lamp",
				pickUp = {
					from = 0,
					id = "rbxassetid://9117544893",
					length = 0.42,
					pitch = 1.3,
					volume = 0.8,
				},
				verb = "Switch",
				worth = 16,
			},
			press = {
				lasts = 6e+01,
				off = {
					motion = "SwitchOff",
					sound = {
						from = 0.1,
						id = "rbxassetid://9114480269",
						length = 0.14,
						volume = 1.4,
					},
				},
				on = {
					{
						motion = "SwitchOn",
						sound = {
							from = 0.38,
							id = "rbxassetid://9114480271",
							length = 0.14,
							volume = 1.4,
						},
					},
				},
				out = {
					{
						motion = "SwitchOff",
					},
				},
				verb = "Switch",
			},
		},
		NeonSign = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9119075637",
					length = 0.7,
					pitch = 0.85,
					volume = 0.8,
				},
				grade = "Rare",
				grip = { 0, 0.98, 0.05 },
				heft = 0.55,
				hold = { -1.55, -0.8, -2.4 },
				name = "Neon sign",
				pickUp = {
					from = 0,
					id = "rbxassetid://9117544893",
					length = 0.42,
					pitch = 0.9,
					volume = 0.8,
				},
				verb = "Switch",
				worth = 6e+01,
			},
			press = {
				lasts = 6e+01,
				off = {
					motion = "SwitchOff",
					sound = {
						from = 0.1,
						id = "rbxassetid://9114480269",
						length = 0.14,
						volume = 1.4,
					},
				},
				on = {
					{
						motion = "SwitchOn",
						sound = {
							from = 0.38,
							id = "rbxassetid://9114480271",
							length = 0.14,
							volume = 1.4,
						},
					},
					{
						loop = math.huge,
						motion = "Buzz",
					},
				},
				out = {
					{
						motion = "SwitchOff",
					},
				},
				verb = "Switch",
			},
		},
		NightLight = {
			catalog = {
				drop = {
					from = 0.22,
					id = "rbxassetid://9113768847",
					length = 0.9,
					pitch = 1.7,
					volume = 0.55,
				},
				grade = "Common",
				grip = { 0, 0.3, 0 },
				heft = 0.04,
				hold = { -0.95, -0.62, -1.7 },
				name = "Night-light",
				pickUp = {
					from = 0.15,
					id = "rbxassetid://9119728830",
					length = 0.35,
					pitch = 1.5,
					volume = 0.85,
				},
				verb = "Switch",
				worth = 2,
			},
			press = {
				lasts = 6e+01,
				off = {
					motion = "SwitchOff",
					sound = {
						from = 0.1,
						id = "rbxassetid://9114480269",
						length = 0.14,
						volume = 1.4,
					},
				},
				on = {
					{
						motion = "SwitchOn",
						sound = {
							from = 0.38,
							id = "rbxassetid://9114480271",
							length = 0.14,
							volume = 1.4,
						},
					},
				},
				out = {
					{
						motion = "SwitchOff",
					},
				},
				verb = "Switch",
			},
		},
		OilLamp = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					pitch = 1.1,
					volume = 0.75,
				},
				grade = "Rare",
				grip = { 0, 0.45, 0 },
				heft = 0.4,
				hold = { -1.2, -0.72, -2 },
				name = "Oil lamp",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116175991",
					length = 0.5,
					pitch = 1.2,
					volume = 0.7,
				},
				verb = "Light",
				worth = 4e+01,
			},
			press = {
				lasts = 1.5e+02,
				on = {
					{
						motion = "Light",
						sound = {
							from = 0,
							id = "rbxassetid://71757268954484",
							length = 2.4,
							volume = 0.9,
						},
					},
					{
						loop = math.huge,
						motion = "Burn",
					},
				},
				out = {
					{
						motion = "RunDown",
					},
				},
				verb = "Light",
			},
		},
		PaperSquishy = {
			catalog = {
				drop = {
					from = 0.2,
					id = "rbxassetid://9125745465",
					length = 0.45,
					pitch = 0.8,
					volume = 0.5,
				},
				grade = "Uncommon",
				grip = { 0, 0.2, 0 },
				heft = 0.01,
				hold = { -0.95, -0.62, -1.7 },
				name = "Paper squishy",
				pickUp = {
					from = 0.2,
					id = "rbxassetid://9125745465",
					length = 0.45,
					volume = 0.7,
				},
				worth = 1e+01,
			},
		},
		RCCar = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9119075637",
					length = 0.7,
					pitch = 1.15,
					volume = 0.8,
				},
				grade = "Rare",
				grip = { 0, 0.45, 0 },
				heft = 0.45,
				hold = { -1.55, -0.8, -2.4 },
				name = "RC car",
				pickUp = {
					from = 0.15,
					id = "rbxassetid://9119728830",
					length = 0.35,
					volume = 0.85,
				},
				verb = "Drive",
				worth = 6e+01,
			},
		},
		RubberDuck = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9117544893",
					length = 0.42,
					pitch = 1.4,
					volume = 0.55,
				},
				grade = "Common",
				grip = { 0, 0.15, 0 },
				heft = 0.04,
				hold = { -0.95, -0.62, -1.7 },
				name = "Rubber duck",
				pickUp = {
					from = 0,
					id = "rbxassetid://9117544893",
					length = 0.42,
					pitch = 1.7,
					volume = 0.6,
				},
				worth = 3,
			},
		},
		SingingFish = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9119075637",
					length = 0.7,
					pitch = 0.9,
					volume = 0.8,
				},
				grade = "Rare",
				grip = { 0, 0.8, 0 },
				heft = 0.4,
				hold = { -1.55, -0.8, -2.4 },
				name = "Singing fish",
				pickUp = {
					from = 0,
					id = "rbxassetid://9117544893",
					length = 0.42,
					pitch = 0.95,
					volume = 0.8,
				},
				worth = 5e+01,
			},
		},
		SirenCar = {
			catalog = {
				drop = {
					from = 0.22,
					id = "rbxassetid://9113768847",
					length = 0.9,
					pitch = 1.8,
					volume = 0.5,
				},
				grade = "Common",
				grip = { 0, 0.14, 0 },
				heft = 0.06,
				hold = { -0.95, -0.62, -1.7 },
				name = "Siren car",
				pickUp = {
					from = 0.15,
					id = "rbxassetid://9119728830",
					length = 0.35,
					pitch = 1.6,
					volume = 0.85,
				},
				worth = 5,
			},
		},
		StainedGlassLamp = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9114008989",
					length = 1.4,
					volume = 0.65,
				},
				grade = "Legendary",
				grip = { 0, 0.8, 0 },
				heft = 0.8,
				hold = { -1.55, -0.8, -2.4 },
				name = "Glass lamp",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116175991",
					length = 0.5,
					pitch = 0.9,
					volume = 0.7,
				},
				verb = "Switch",
				worth = 4.8e+02,
			},
			press = {
				lasts = 6e+01,
				off = {
					motion = "SwitchOff",
					sound = {
						from = 0.1,
						id = "rbxassetid://9114480269",
						length = 0.14,
						volume = 1.4,
					},
				},
				on = {
					{
						motion = "SwitchOn",
						sound = {
							from = 0.38,
							id = "rbxassetid://9114480271",
							length = 0.14,
							volume = 1.4,
						},
					},
				},
				out = {
					{
						motion = "SwitchOff",
					},
				},
				verb = "Switch",
			},
		},
		StressBall = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.2,
					volume = 0.5,
				},
				grade = "Common",
				grip = { 0, 0.14, 0 },
				heft = 0.04,
				hold = { -0.95, -0.62, -1.7 },
				name = "Stress ball",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.5,
					volume = 0.75,
				},
				worth = 2,
			},
		},
		TeaLight = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					pitch = 1.7,
					volume = 0.6,
				},
				grade = "Common",
				grip = { 0, 0.4, 0 },
				heft = 0.12,
				hold = { -0.95, -0.62, -1.7 },
				name = "Tea light",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116175991",
					length = 0.5,
					pitch = 1.6,
					volume = 0.7,
				},
				verb = "Light",
				worth = 3,
			},
			press = {
				lasts = 6e+01,
				on = {
					{
						motion = "Light",
						sound = {
							from = 0,
							id = "rbxassetid://71757268954484",
							length = 1.3,
							volume = 0.9,
						},
					},
					{
						loop = math.huge,
						motion = "Flicker",
					},
				},
				out = {
					{
						motion = "GoOut",
					},
				},
				verb = "Light",
			},
		},
		TinBird = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					pitch = 1.85,
					volume = 0.55,
				},
				grade = "Epic",
				grip = { 0, 0.12, 0 },
				heft = 0.06,
				hold = { -0.95, -0.62, -1.7 },
				name = "Tin bird",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116175991",
					length = 0.5,
					pitch = 1.6,
					volume = 0.7,
				},
				worth = 1.4e+02,
			},
		},
		TinCarousel = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					pitch = 1,
					volume = 0.75,
				},
				grade = "Epic",
				grip = { 0, 0.75, 0 },
				heft = 0.4,
				hold = { -1.2, -0.72, -2 },
				name = "Tin carousel",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116460746",
					length = 0.42,
					pitch = 1.3,
					volume = 0.6,
				},
				worth = 2e+02,
			},
		},
		ToastSlice = {
			catalog = {
				drop = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.1,
					volume = 0.5,
				},
				grade = "Uncommon",
				grip = { 0, 0.22, 0 },
				heft = 0.02,
				hold = { -0.95, -0.62, -1.7 },
				name = "Toast slice",
				pickUp = {
					from = 0.4,
					id = "rbxassetid://9117373366",
					length = 0.4,
					pitch = 1.4,
					volume = 0.75,
				},
				worth = 11,
			},
		},
		ToyDrum = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					pitch = 0.95,
					volume = 0.75,
				},
				grade = "Uncommon",
				grip = { 0, 0.3, 0 },
				heft = 0.3,
				hold = { -1.2, -0.72, -2 },
				name = "Toy drum",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116657808",
					length = 0.3,
					pitch = 1.15,
					volume = 0.7,
				},
				worth = 1e+01,
			},
		},
		UnpluggedLamp = {
			catalog = {
				drop = {
					from = 0,
					id = "rbxassetid://9114008989",
					length = 1.4,
					pitch = 0.95,
					volume = 0.65,
				},
				from = 25,
				grade = "Secret",
				grip = { 0, 0.9, 0 },
				heft = 0.6,
				hold = { -1.55, -0.8, -2.4 },
				name = "Old lamp",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116175991",
					length = 0.5,
					pitch = 0.85,
					volume = 0.7,
				},
				worth = 7e+03,
			},
		},
		WalkingRobot = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					pitch = 1.35,
					volume = 0.75,
				},
				grade = "Uncommon",
				grip = { 0, 0.45, 0 },
				heft = 0.15,
				hold = { -0.95, -0.62, -1.7 },
				name = "Wind-up robot",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116657808",
					length = 0.3,
					pitch = 1.35,
					volume = 0.7,
				},
				worth = 15,
			},
		},
		WindupMouse = {
			catalog = {
				drop = {
					from = 0.36,
					id = "rbxassetid://9116546109",
					length = 0.9,
					pitch = 1.75,
					volume = 0.55,
				},
				grade = "Uncommon",
				grip = { 0, 0.09, 0 },
				heft = 0.04,
				hold = { -0.95, -0.62, -1.7 },
				name = "Wind-up mouse",
				pickUp = {
					from = 0,
					id = "rbxassetid://9116657808",
					length = 0.3,
					pitch = 1.6,
					volume = 0.55,
				},
				worth = 12,
			},
		},
	},
}
