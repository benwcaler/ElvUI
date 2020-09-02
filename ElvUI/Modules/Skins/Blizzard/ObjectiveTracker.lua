local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule('Skins')

local _G = _G
local pairs, unpack = pairs, unpack
local hooksecurefunc = hooksecurefunc

local headers = {
	_G.ObjectiveTrackerBlocksFrame.QuestHeader,
	_G.ObjectiveTrackerBlocksFrame.AchievementHeader,
	_G.ObjectiveTrackerBlocksFrame.ScenarioHeader,
	_G.ObjectiveTrackerBlocksFrame.CampaignQuestHeader,
	_G.BONUS_OBJECTIVE_TRACKER_MODULE.Header,
	_G.WORLD_QUEST_TRACKER_MODULE.Header,
	_G.ObjectiveTrackerFrame.BlocksFrame.UIWidgetsHeader
}

local function SkinOjectiveTrackerHeaders()
	local frame = _G.ObjectiveTrackerFrame.MODULES
	if frame then
		for i = 1, #frame do
			local modules = frame[i]
			if modules then
				modules.Header.Background:SetAtlas(nil)

				local text = modules.Header.Text
				text:FontTemplate()
				text:SetParent(modules.Header)
			end
		end
	end
end

local function ColorProgressBars(self, value)
	if not (self.Bar and self.isSkinned and value) then return end
	S:StatusBarColorGradient(self.Bar, value, 100)
end

-- 9.0 Needs Update
local function SkinItemButton(_, block)
	local item = block.itemButton
	if item and not item.skinned then
		item:Size(25, 25)
		item:CreateBackdrop('Transparent')
		item:StyleButton()
		item:SetNormalTexture(nil)
		item.icon:SetTexCoord(unpack(E.TexCoords))
		item.icon:SetInside()
		item.Cooldown:SetInside()
		item.Count:ClearAllPoints()
		item.Count:Point('TOPLEFT', 1, -1)
		item.Count:FontTemplate(nil, 14, 'OUTLINE')
		item.Count:SetShadowOffset(5, -5)
		E:RegisterCooldown(item.Cooldown)
		item.skinned = true
	end
end

-- 9.0 Needs Update
local function SkinProgressBars(_, _, line)
	local progressBar = line and line.ProgressBar
	local bar = progressBar and progressBar.Bar
	if not bar then return end
	local icon = bar.Icon
	local label = bar.Label

	if not progressBar.isSkinned then
		if bar.BarFrame then bar.BarFrame:Hide() end
		if bar.BarFrame2 then bar.BarFrame2:Hide() end
		if bar.BarFrame3 then bar.BarFrame3:Hide() end
		if bar.BarGlow then bar.BarGlow:Hide() end
		if bar.Sheen then bar.Sheen:Hide() end
		if bar.IconBG then bar.IconBG:SetAlpha(0) end
		if bar.BorderLeft then bar.BorderLeft:SetAlpha(0) end
		if bar.BorderRight then bar.BorderRight:SetAlpha(0) end
		if bar.BorderMid then bar.BorderMid:SetAlpha(0) end

		bar:Height(18)
		bar:StripTextures()
		bar:CreateBackdrop('Transparent')
		bar:SetStatusBarTexture(E.media.normTex)
		E:RegisterStatusBar(bar)

		if label then
			label:ClearAllPoints()
			label:Point('CENTER', bar, 0, 1)
			label:FontTemplate(nil, 14, 'OUTLINE')
		end

		if icon then
			icon:ClearAllPoints()
			icon:Point('LEFT', bar, 'RIGHT', E.PixelMode and 3 or 7, 0)
			icon:SetMask('')
			icon:SetTexCoord(unpack(E.TexCoords))

			if not progressBar.backdrop then
				progressBar:CreateBackdrop()
				progressBar.backdrop:SetOutside(icon)
				progressBar.backdrop:SetShown(icon:IsShown())
			end
		end

		_G.BonusObjectiveTrackerProgressBar_PlayFlareAnim = E.noop
		progressBar.isSkinned = true

		ColorProgressBars(progressBar, bar:GetValue())
	elseif icon and progressBar.backdrop then
		progressBar.backdrop:SetShown(icon:IsShown())
	end
end

local function SkinTimerBars(_, _, line)
	local timerBar = line and line.TimerBar
	local bar = timerBar and timerBar.Bar

	if not timerBar.isSkinned then
		bar:Height(18)
		bar:StripTextures()
		bar:CreateBackdrop('Transparent')
		bar:SetStatusBarTexture(E.media.normTex)
		E:RegisterStatusBar(bar)

		timerBar.isSkinned = true
	end
end

local function PositionFindGroupButton(block, button)
	if button and button.GetPoint then
		local a, b, c, d, e = button:GetPoint()
		if block.groupFinderButton and b == block.groupFinderButton and block.itemButton and button == block.itemButton then
			-- this fires when there is a group button and a item button to the left of it
			-- we push the item button away from the group button (to the left)
			button:Point(a, b, c, d-(E.PixelMode and -1 or 1), e);
		elseif b == block and block.groupFinderButton and button == block.groupFinderButton then
			-- this fires when there is a group finder button
			-- we push the group finder button down slightly
			button:Point(a, b, c, d, e-(E.PixelMode and 2 or -1));
		end
	end
end

local function SkinFindGroupButton(block)
	if block.hasGroupFinderButton and block.groupFinderButton then
		if block.groupFinderButton and not block.groupFinderButton.skinned then
			S:HandleButton(block.groupFinderButton)
			block.groupFinderButton:Size(20)
			block.groupFinderButton.skinned = true
		end
	end
end

local function TrackerStateChanged()
	local minimizeButton = _G.ObjectiveTrackerFrame.HeaderMenu.MinimizeButton
	if _G.ObjectiveTrackerFrame.collapsed then
		minimizeButton.tex:SetTexture(E.Media.Textures.PlusButton)
	else
		minimizeButton.tex:SetTexture(E.Media.Textures.MinusButton)
	end
end

local function UpdateMinimizeButton(button, collapsed)
	if collapsed then
		button.tex:SetTexture(E.Media.Textures.PlusButton)
	else
		button.tex:SetTexture(E.Media.Textures.MinusButton)
	end
end

function S:ObjectiveTrackerFrame()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.objectiveTracker) then return end

	local minimize = _G.ObjectiveTrackerFrame.HeaderMenu.MinimizeButton
	minimize:StripTextures()
	minimize:Size(16, 16)
	minimize:SetHighlightTexture([[Interface\Buttons\UI-PlusButton-Hilight]], 'ADD')
	minimize.tex = minimize:CreateTexture(nil, 'OVERLAY')
	minimize.tex:SetTexture(E.Media.Textures.MinusButton)
	minimize.tex:SetInside()

	hooksecurefunc('ObjectiveTracker_Expand',TrackerStateChanged)
	hooksecurefunc('ObjectiveTracker_Collapse',TrackerStateChanged)
	hooksecurefunc('BonusObjectiveTrackerProgressBar_SetValue',ColorProgressBars)			--[Color]: Bonus Objective Progress Bar
	hooksecurefunc('ObjectiveTrackerProgressBar_SetValue',ColorProgressBars)				--[Color]: Quest Progress Bar
	hooksecurefunc('ScenarioTrackerProgressBar_SetValue',ColorProgressBars)					--[Color]: Scenario Progress Bar
	hooksecurefunc('QuestObjectiveSetupBlockButton_AddRightButton',PositionFindGroupButton)	--[Move]: The eye & quest item to the left of the eye
	hooksecurefunc('ObjectiveTracker_Update',SkinOjectiveTrackerHeaders)					--[Skin]: Module Headers
	hooksecurefunc('QuestObjectiveSetupBlockButton_FindGroup',SkinFindGroupButton)			--[Skin]: The eye
	hooksecurefunc(_G.BONUS_OBJECTIVE_TRACKER_MODULE,'AddProgressBar',SkinProgressBars)		--[Skin]: Bonus Objective Progress Bar
	hooksecurefunc(_G.WORLD_QUEST_TRACKER_MODULE,'AddProgressBar',SkinProgressBars)			--[Skin]: World Quest Progress Bar
	hooksecurefunc(_G.DEFAULT_OBJECTIVE_TRACKER_MODULE,'AddProgressBar',SkinProgressBars)	--[Skin]: Quest Progress Bar
	hooksecurefunc(_G.SCENARIO_TRACKER_MODULE,'AddProgressBar',SkinProgressBars)			--[Skin]: Scenario Progress Bar
	hooksecurefunc(_G.CAMPAIGN_QUEST_TRACKER_MODULE,'AddProgressBar',SkinProgressBars)		--[Skin]: Campaign Progress Bar
	hooksecurefunc(_G.QUEST_TRACKER_MODULE,'AddProgressBar',SkinProgressBars)				--[Skin]: Quest Progress Bar
	hooksecurefunc(_G.QUEST_TRACKER_MODULE,'AddTimerBar',SkinTimerBars)						--[Skin]: Quest Timer Bar
	hooksecurefunc(_G.SCENARIO_TRACKER_MODULE,'AddTimerBar',SkinTimerBars)					--[Skin]: Scenario Timer Bar
	hooksecurefunc(_G.ACHIEVEMENT_TRACKER_MODULE,'AddTimerBar',SkinTimerBars)				--[Skin]: Achievement Timer Bar
	hooksecurefunc(_G.QUEST_TRACKER_MODULE,'SetBlockHeader',SkinItemButton)					--[Skin]: Quest Item Buttons
	hooksecurefunc(_G.WORLD_QUEST_TRACKER_MODULE,'AddObjective',SkinItemButton)				--[Skin]: World Quest Item Buttons
	hooksecurefunc(_G.CAMPAIGN_QUEST_TRACKER_MODULE,'AddObjective',SkinItemButton)			--[Skin]: Campaign Quest Item Buttons

	for _, header in pairs(headers) do
		local minimize = header.MinimizeButton
		if minimize then
			minimize:GetNormalTexture():SetAlpha(0)
			minimize:GetPushedTexture():SetAlpha(0)

			minimize.tex = minimize:CreateTexture(nil, 'OVERLAY')
			minimize.tex:SetTexture(E.Media.Textures.MinusButton)
			minimize.tex:SetInside()

			hooksecurefunc(minimize, 'SetCollapsed', UpdateMinimizeButton)
		end
	end

	-- The Maw - Torghast: Scenario Tracker Buff Block
	_G.ScenarioBlocksFrame.MawBuffsBlock.Container.List:HookScript('OnShow', function(frame)
		if not frame.buffPool then return end
		for mawBuff in frame.buffPool:EnumerateActive() do
			if mawBuff:IsShown() and not mawBuff.IsSkinned then
				mawBuff.Border:SetAlpha(0)
				mawBuff.CircleMask:Hide()
				mawBuff.CountRing:SetAlpha(0)
				mawBuff.HighlightBorder:SetColorTexture(1, 1, 1, .25)
				S:HandleIcon(mawBuff.Icon)

				mawBuff.IsSkinned = true
			end
		end
	end)
end

S:AddCallback('ObjectiveTrackerFrame')
