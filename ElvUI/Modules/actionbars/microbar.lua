local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:GetModule('ActionBars');

--Cache global variables
--Lua functions
local _G = _G
local pairs = pairs
local assert = assert
local unpack = unpack
--WoW API / Variables
local CreateFrame = CreateFrame
local C_StorePublic_IsEnabled = C_StorePublic.IsEnabled
local UpdateMicroButtonsParent = UpdateMicroButtonsParent
local GetCurrentRegionName = GetCurrentRegionName
local RegisterStateDriver = RegisterStateDriver
local InCombatLockdown = InCombatLockdown

local function onLeaveBar()
	if AB.db.microbar.mouseover then
		E:UIFrameFadeOut(_G.ElvUI_MicroBar, 0.2, _G.ElvUI_MicroBar:GetAlpha(), 0)
	end
end

local watcher = 0
local function onUpdate(self, elapsed)
	if watcher > 0.1 then
		if not self:IsMouseOver() then
			self.IsMouseOvered = nil
			self:SetScript("OnUpdate", nil)
			onLeaveBar()
		end
		watcher = 0
	else
		watcher = watcher + elapsed
	end
end

local function onEnter(button)
	if AB.db.microbar.mouseover and not _G.ElvUI_MicroBar.IsMouseOvered then
		_G.ElvUI_MicroBar.IsMouseOvered = true
		_G.ElvUI_MicroBar:SetScript("OnUpdate", onUpdate)
		E:UIFrameFadeIn(_G.ElvUI_MicroBar, 0.2, _G.ElvUI_MicroBar:GetAlpha(), AB.db.microbar.alpha)
	end

	if button.backdrop then
		button.backdrop:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
	end
end

local function onLeave(button)
	if button.backdrop then
		button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end

function AB:HandleMicroButton(button)
	assert(button, 'Invalid micro button name.')

	local pushed = button:GetPushedTexture()
	local normal = button:GetNormalTexture()
	local disabled = button:GetDisabledTexture()

	local f = CreateFrame("Frame", nil, button)
	f:SetFrameLevel(1)
	f:SetFrameStrata("BACKGROUND")
	f:SetTemplate("Default", true)
	f:SetOutside(button)
	button.backdrop = f

	button:SetParent(_G.ElvUI_MicroBar)
	button:GetHighlightTexture():Kill()
	button:HookScript('OnEnter', onEnter)
	button:HookScript('OnLeave', onLeave)
	button:SetHitRectInsets(0, 0, 0, 0)

	if button.Flash then
		button.Flash:SetInside()
		button.Flash:SetTexture()
	end

	pushed:SetTexCoord(0.22, 0.81, 0.26, 0.82)
	pushed:SetInside(f)

	normal:SetTexCoord(0.22, 0.81, 0.21, 0.82)
	normal:SetInside(f)

	if disabled then
		disabled:SetTexCoord(0.22, 0.81, 0.21, 0.82)
		disabled:SetInside(f)
	end
end

function AB:MainMenuMicroButton_SetNormal()
	_G.MainMenuBarPerformanceBar:Point("TOPLEFT", _G.MainMenuMicroButton, "TOPLEFT", 9, -36);
end

function AB:MainMenuMicroButton_SetPushed()
	_G.MainMenuBarPerformanceBar:Point("TOPLEFT", _G.MainMenuMicroButton, "TOPLEFT", 8, -37);
end

function AB:UpdateMicroButtonsParent()
	for _, x in pairs(_G.MICRO_BUTTONS) do
		_G[x]:SetParent(_G.ElvUI_MicroBar)
	end
end

-- we use this table to sort the micro buttons on our bar to match Blizzard's button placements.
local __buttonIndex = {
	[8] = "CollectionsMicroButton",
	[9] = "EJMicroButton",
	[10] = (not C_StorePublic_IsEnabled() and GetCurrentRegionName() == "CN") and "HelpMicroButton" or "StoreMicroButton",
	[11] = "MainMenuMicroButton"
}

function AB:UpdateMicroBarVisibility()
	if InCombatLockdown() then
		AB.NeedsUpdateMicroBarVisibility = true
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end

	local visibility = self.db.microbar.visibility
	if visibility and visibility:match('[\n\r]') then
		visibility = visibility:gsub('[\n\r]','')
	end

	RegisterStateDriver(_G.ElvUI_MicroBar.visibility, "visibility", (self.db.microbar.enabled and visibility) or "hide");
end

function AB:UpdateMicroPositionDimensions()
	if not _G.ElvUI_MicroBar then return end

	local numRows = 1
	local prevButton = _G.ElvUI_MicroBar
	local offset = E:Scale(E.PixelMode and 1 or 3)
	local spacing = E:Scale(offset + self.db.microbar.buttonSpacing)

	for i=1, #_G.MICRO_BUTTONS-1 do
		local button = _G[__buttonIndex[i]] or _G[_G.MICRO_BUTTONS[i]]
		local lastColumnButton = i-self.db.microbar.buttonsPerRow;
		lastColumnButton = _G[__buttonIndex[lastColumnButton]] or _G[_G.MICRO_BUTTONS[lastColumnButton]]

		button:Size(self.db.microbar.buttonSize, self.db.microbar.buttonSize * 1.4);
		button:ClearAllPoints();

		if prevButton == _G.ElvUI_MicroBar then
			button:Point('TOPLEFT', prevButton, 'TOPLEFT', offset, -offset)
		elseif (i - 1) % self.db.microbar.buttonsPerRow == 0 then
			button:Point('TOP', lastColumnButton, 'BOTTOM', 0, -spacing);
			numRows = numRows + 1
		else
			button:Point('LEFT', prevButton, 'RIGHT', spacing, 0);
		end

		prevButton = button
	end

	if AB.db.microbar.mouseover and not _G.ElvUI_MicroBar:IsMouseOver() then
		_G.ElvUI_MicroBar:SetAlpha(0)
	else
		_G.ElvUI_MicroBar:SetAlpha(self.db.microbar.alpha)
	end

	AB.MicroWidth = (((_G["CharacterMicroButton"]:GetWidth() + spacing) * self.db.microbar.buttonsPerRow) - spacing) + (offset * 2)
	AB.MicroHeight = (((_G["CharacterMicroButton"]:GetHeight() + spacing) * numRows) - spacing) + (offset * 2)
	_G.ElvUI_MicroBar:Size(AB.MicroWidth, AB.MicroHeight)

	if _G.ElvUI_MicroBar.mover then
		if self.db.microbar.enabled then
			E:EnableMover(_G.ElvUI_MicroBar.mover:GetName())
		else
			E:DisableMover(_G.ElvUI_MicroBar.mover:GetName())
		end
	end

	self:UpdateMicroBarVisibility()
end

function AB:UpdateMicroButtons()
	local GuildMicroButton = _G.GuildMicroButton
	local GuildMicroButtonTabard = _G.GuildMicroButtonTabard

	GuildMicroButtonTabard:SetInside(GuildMicroButton)

	GuildMicroButtonTabard.background:SetInside(GuildMicroButton)
	GuildMicroButtonTabard.background:SetTexCoord(0.17, 0.87, 0.5, 0.908)

	GuildMicroButtonTabard.emblem:ClearAllPoints()
	GuildMicroButtonTabard.emblem:Point("TOPLEFT", GuildMicroButton, "TOPLEFT", 4, -4)
	GuildMicroButtonTabard.emblem:Point("BOTTOMRIGHT", GuildMicroButton, "BOTTOMRIGHT", -4, 8)

	self:UpdateMicroPositionDimensions()
end

function AB:SetupMicroBar()
	local microBar = CreateFrame('Frame', 'ElvUI_MicroBar', E.UIParent)
	microBar:Point('TOPLEFT', E.UIParent, 'TOPLEFT', 4, -48)
	microBar:EnableMouse(false)

	microBar.visibility = CreateFrame('Frame', nil, E.UIParent, 'SecureHandlerStateTemplate')
	microBar.visibility:SetScript("OnShow", function() microBar:Show() end)
	microBar.visibility:SetScript("OnHide", function() microBar:Hide() end)

	E.FrameLocks["ElvUI_MicroBar"] = true
	for _, x in pairs(_G.MICRO_BUTTONS) do
		self:HandleMicroButton(_G[x])
	end

	_G.MicroButtonPortrait:SetInside(_G.CharacterMicroButton.backdrop)

	self:SecureHook('MainMenuMicroButton_SetPushed')
	self:SecureHook('MainMenuMicroButton_SetNormal')
	self:SecureHook('UpdateMicroButtonsParent')
	self:SecureHook('MoveMicroButtons', 'UpdateMicroPositionDimensions')
	self:SecureHook('UpdateMicroButtons')
	UpdateMicroButtonsParent(microBar)
	self:MainMenuMicroButton_SetNormal()
	self:UpdateMicroPositionDimensions()

	-- With this method we might don't taint anything. Instead of using :Kill()
	_G.MainMenuBarPerformanceBar:SetAlpha(0)
	_G.MainMenuBarPerformanceBar:SetScale(0.00001)

	_G.CollectionsMicroButtonAlert:EnableMouse(false)
	_G.CollectionsMicroButtonAlert:SetAlpha(0)
	_G.CollectionsMicroButtonAlert:SetScale(0.00001)

	_G.CharacterMicroButtonAlert:EnableMouse(false)
	_G.CharacterMicroButtonAlert:SetAlpha(0)
	_G.CharacterMicroButtonAlert:SetScale(0.00001)

	E:CreateMover(microBar, 'MicrobarMover', L["Micro Bar"], nil, nil, nil, 'ALL,ACTIONBARS', nil, 'actionbar,microbar');
end
