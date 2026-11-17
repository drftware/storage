--!strict
--[[
	JobBoxes: the job box in every home (S5-03c2a, D-287). The moment: the shelf's full, you keep one
	more at the gate, and when you come home the job box's lid sparkles; press Open and the lid swings
	up with a soft steel creak. Precedents: Resident Evil's item box, Animal Crossing's house storage,
	Fortnite's locker marks.

	Each home's JobBox piece (the Starter set, Home.piece tags it) gets an Open button in front of
	it, on a spot of its own in the unit (JobBox.Spot) that HomeCards shows to the home's holder
	alone. The server owns the box's two attributes and every screen draws them (JobBoxView):
	- Fresh: how new what went in since its holder last opened it is (Save's `boxFresh`), brought up
	  to date each time Shelves lays that player's home finds and when the home changes hands.
	- Lid: 0 shut; up, 1 plus how new what was in it as it opened (Save.Fresh), so the opener's
	  screen can chime for a kind they'd never owned. One attribute, so a screen never sees the lid
	  up without what it found.
	Open is for the holder only, as the switch is; opening marks what's in it seen (Save.open, kept
	by the autosave). The lid closes on Close, when its holder walks away (JobBox.Away, looked at
	every JobBox.Every seconds while a lid is up) and when the home changes hands.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Home = require(ReplicatedStorage.Shared.Home)
local Save = require(ReplicatedStorage.Shared.Save)
local FrontOffice = require(script.Parent.FrontOffice)
local Prompts = require(script.Parent.Prompts)
local Saving = require(script.Parent.Saving)
local Shelves = require(script.Parent.Shelves)

local JobBox = Home.JobBox

-- One home's box as wired: its unit, the piece, its button and when it last answered a press.
type Box = { unit: Model, model: Model, prompt: ProximityPrompt, last: number }

local JobBoxes = {}

function JobBoxes.new(): Brix.System
	local boxes: { [Model]: Box } = {} -- by unit
	local open: { [Box]: true } = {}
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local saving: Saving.SavingSystem? = nil
	local untilLook = 0

	local function holderOf(box: Box): Player?
		local id = box.unit:GetAttribute(Door.HolderAttribute)
		return if type(id) == "number" and id > 0 then Players:GetPlayerByUserId(id) else nil
	end

	local function isOpen(box: Box): boolean
		local lid = box.model:GetAttribute(JobBox.LidAttribute)
		return type(lid) == "number" and lid > 0
	end

	-- The box's Fresh from its holder's save (quiet with no holder, or no save yet).
	local function show(box: Box)
		local player = holderOf(box)
		local data = if player and saving then saving:data(player) else nil
		box.model:SetAttribute(
			JobBox.FreshAttribute,
			if data then data.boxFresh else Save.Fresh.Seen
		)
	end

	local function shut(box: Box)
		open[box] = nil
		box.model:SetAttribute(JobBox.LidAttribute, 0)
		box.prompt.ActionText = "Open"
	end

	local function press(box: Box, player: Player)
		if
			Prompts.wrapped(player)
			or box.unit:GetAttribute(Door.HolderAttribute) ~= player.UserId
		then
			return -- the holder's own (its button shows only on their screen, HomeCards)
		end
		local t = os.clock()
		if t - box.last < JobBox.Button.Cooldown then
			return
		end
		box.last = t
		if isOpen(box) then
			shut(box)
			return
		end
		local data = if saving then saving:data(player) else nil
		local found = if data then Save.open(data) else Save.Fresh.Seen
		open[box] = true
		box.model:SetAttribute(JobBox.LidAttribute, 1 + found)
		box.model:SetAttribute(JobBox.FreshAttribute, Save.Fresh.Seen)
		box.prompt.ActionText = "Close"
	end

	-- The box in `unit`'s starter set, its button set in front of it. Nil for a unit with none.
	local function wire(unit: Model): Box?
		local starter = unit:FindFirstChild("Starter")
		local model = if starter then starter:FindFirstChild("JobBox") else nil
		if not (model and model:IsA("Model")) then
			return nil
		end
		-- on a spot of its own in the unit, just in front of the lid: the box's collider would stand
		-- in the way of the line-of-sight check, as the front's wall does for the switch
		local spot = Instance.new("Part")
		spot.Name = JobBox.Spot
		spot.Anchored = true
		spot.CanCollide = false
		spot.CanTouch = false
		spot.CanQuery = false
		spot.CastShadow = false
		spot.Transparency = 1
		spot.Size = Vector3.one * 0.2
		local front = Home.Specs.Parts.JobBox
		spot.CFrame = model.WorldPivot
			* CFrame.new(0, JobBox.Button.Up, -(front.Size[3] / 2 + JobBox.Button.Out))
		spot.Parent = unit
		local at = Instance.new("Attachment")
		at.Name = "JobBoxButton"
		at.Parent = spot
		local prompt = Prompts.make(at, {
			actionText = "Open",
			-- the usual E: the box stands deep in the room, far past the door's own E (Lift)
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = JobBox.Button.Reach,
		})
		local box: Box = { unit = unit, model = model, prompt = prompt, last = -math.huge }
		model:SetAttribute(JobBox.LidAttribute, 0)
		show(box)
		table.insert(
			connections,
			prompt.Triggered:Connect(function(player: Player)
				press(box, player)
			end)
		)
		table.insert(
			connections,
			unit:GetAttributeChangedSignal(Door.HolderAttribute):Connect(function()
				shut(box) -- a home changing hands never keeps the last one's lid up
				show(box)
			end)
		)
		return box
	end

	-- Shut each open lid whose holder has walked away from it, or gone.
	local function look()
		for box in open do
			local player = holderOf(box)
			local character = if player then player.Character else nil
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if
				not (root and root:IsA("BasePart"))
				or (root.Position - box.model.WorldPivot.Position).Magnitude > JobBox.Away
			then
				shut(box)
			end
		end
	end

	return {
		name = "JobBoxes",
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			local frontOffice = (registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice
			saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
			local shelves = (registry:get("shelves") :: any) :: Shelves.ShelvesSystem -- any: as above
			local laid = frontOffice:laid()
			if not laid then
				return -- no lobby in this place: no homes
			end
			for _, unit in laid.units do
				local box = wire(unit)
				if box then
					boxes[unit] = box
				end
			end
			-- the box follows each lay of a player's home finds (a load, a home handed over, a keep)
			table.insert(
				signals,
				shelves.laid:connect(function(player: Player)
					for _, box in boxes do
						if box.unit:GetAttribute(Door.HolderAttribute) == player.UserId then
							show(box)
						end
					end
				end)
			)
			table.insert(
				connections,
				RunService.Heartbeat:Connect(function(dt: number)
					if next(open) == nil then
						return
					end
					untilLook -= dt
					if untilLook <= 0 then
						untilLook = JobBox.Every
						look()
					end
				end)
			)
		end,
		stop = function(_: any)
			for _, s in signals do
				s:disconnect()
			end
			table.clear(signals)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, box in boxes do
				local spot = box.prompt.Parent and box.prompt.Parent.Parent
				if spot then
					spot:Destroy()
				end
			end
			table.clear(boxes)
			table.clear(open)
		end,
	}
end

return JobBoxes
