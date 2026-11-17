--!strict
--[[
	HomeCards: the names over the homes' doors on this player's screen (S5-03a3b, D-274). The server
	letters a holder's name on their home's card (FrontOffice); this plays its arrival, the
	moment you're handed your home:

	- A name going up is sprayed on through the stencil: the lettering comes up from nothing,
	  shrinking onto the card from a touch big as it lands, the fresh ink glowing and settling to
	  the card's own over Holding.Card.Settle, with a can's short hiss at the card that carries
	  across the floor (friends hear a home taken).
	- A name blanked as its holder leaves fades off the card.
	- A home's light switch shows only on its holder's screen (D-263): the server answers only
	  their press, so nobody else sees a button that does nothing.

	A card already lettered as it streams in shows as it is, with no spray. Tweens only, no step.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Home = require(ReplicatedStorage.Shared.Home)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

local CARD = Home.Holding.Card
local SPRAY = TweenInfo.new(CARD.Spray, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SETTLE = TweenInfo.new(CARD.Settle, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local FADE = TweenInfo.new(CARD.Fade, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

export type HomeCards = Brix.System

local HomeCards = {}

function HomeCards.new(): HomeCards
	local conns: { [Instance]: { RBXScriptConnection } } = {}
	local top: { RBXScriptConnection } = {}

	local function hiss(at: BasePart)
		local s = Instance.new("Sound")
		s.SoundId = CARD.Sound
		s.Volume = CARD.Volume
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = CARD.Near
		s.RollOffMaxDistance = CARD.Reach
		s.TimePosition = CARD.Start
		s.Parent = at
		s:Play()
		task.delay(CARD.Stop - CARD.Start, function()
			s:Destroy()
		end)
	end

	-- Sprays `label`'s new name on.
	local function spray(card: BasePart, label: TextLabel, gui: SurfaceGui, settled: number)
		local scale = label:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		scale.Scale = CARD.Swell
		scale.Parent = label
		label.TextTransparency = 1
		gui.LightInfluence = 0 -- the fresh ink glows
		TweenService:Create(label, SPRAY, { TextTransparency = 0 }):Play()
		TweenService:Create(scale, SPRAY, { Scale = 1 }):Play()
		TweenService:Create(gui, SETTLE, { LightInfluence = settled }):Play()
		hiss(card)
	end

	-- Fades `old`, the name just blanked, off the card.
	local function fadeOff(label: TextLabel, old: string)
		local ghost = label:Clone()
		ghost:ClearAllChildren()
		ghost.Text = old
		ghost.Parent = label.Parent
		local t = TweenService:Create(ghost, FADE, { TextTransparency = 1 })
		t.Completed:Once(function()
			ghost:Destroy()
		end)
		t:Play()
	end

	local function addCard(inst: Instance)
		if not inst:IsA("BasePart") or conns[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local gui = inst:FindFirstChildOfClass("SurfaceGui")
		local label = gui and gui:FindFirstChildOfClass("TextLabel")
		if not (gui and label) then
			return
		end
		local settled = gui.LightInfluence
		local shown = label.Text
		conns[inst] = {
			label:GetPropertyChangedSignal("Text"):Connect(function()
				local now = label.Text
				if now == shown then
					return
				end
				if now ~= "" then
					spray(inst, label, gui, settled)
				elseif shown ~= "" then
					fadeOff(label, shown)
				end
				shown = now
			end),
		}
	end

	-- A home's switch button, shown only to its holder.
	local function showSwitch(unit: Model)
		local spot = unit:FindFirstChild("SwitchSpot")
		local prompt = spot and spot:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			local me = Players.LocalPlayer
			prompt.Enabled = me ~= nil and unit:GetAttribute(Door.HolderAttribute) == me.UserId
		end
	end

	local function addUnit(inst: Instance)
		if
			not inst:IsA("Model")
			or conns[inst]
			or inst:GetAttribute(Door.HolderAttribute) == nil
		then
			return
		end
		local unit = inst
		conns[unit] = {
			unit:GetAttributeChangedSignal(Door.HolderAttribute):Connect(function()
				showSwitch(unit)
			end),
			-- the button streams in after its unit
			unit.DescendantAdded:Connect(function(d: Instance)
				if d:IsA("ProximityPrompt") then
					showSwitch(unit)
				end
			end),
		}
		showSwitch(unit)
	end

	local function remove(inst: Instance)
		local list = conns[inst]
		if list then
			for _, c in list do
				c:Disconnect()
			end
			conns[inst] = nil
		end
	end

	return {
		name = "HomeCards",
		start = function(_: any)
			local function watch(tag: string, add: (Instance) -> ())
				table.insert(top, CollectionService:GetInstanceAddedSignal(tag):Connect(add))
				table.insert(top, CollectionService:GetInstanceRemovedSignal(tag):Connect(remove))
				for _, inst in CollectionService:GetTagged(tag) do
					add(inst)
				end
			end
			watch(Home.CardTag, addCard)
			watch(UnitKit.Tag, addUnit)
		end,
		stop = function(_: any)
			for _, c in top do
				c:Disconnect()
			end
			table.clear(top)
			for inst in conns do
				remove(inst)
			end
		end,
	}
end

return HomeCards
