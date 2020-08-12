--=================================================================================================================
-- Suk_ScreenshotMode
--=================================================================================================================
include("Suk_ScreenshotMode_Controls.lua")
--===========================================================================================
--	CONSTANTS/GLOBALS
--===========================================================================================
ExposedMembers.Suk_ScreenshotMode_StoredStates = ExposedMembers.Suk_ScreenshotMode_StoredStates or {}
ExposedMembers.Suk_ScreenshotMode_Options = ExposedMembers.Suk_ScreenshotMode_Options or {
	UseFixedTilt	= false,

	HideUnitFlags	= true,
	HideCityBanners	= true,
	HideBorders		= false,
	HideMapLabels	= false,
	HideMapYields	= true,
}

m_ContextsToHide = {}
m_MapLabels = {
	{"MapLabelOverlay_NationalParks",	"ShowMapLabelsNationalParks"},
	{"MapLabelOverlay_NaturalWonders",	"ShowMapLabelsNaturalWonders"},
	{"MapLabelOverlay_Rivers",			"ShowMapLabelsRivers"},
	{"MapLabelOverlay_Volcanoes",		"ShowMapLabelsVolcanoes"},
	{"MapLabelOverlay_Deserts",			"ShowMapLabelsDeserts"},
	{"MapLabelOverlay_MountainRanges",	"ShowMapLabelsMountainRanges"},
	{"MapLabelOverlay_Lakes",			"ShowMapLabelsLakes"},
	{"MapLabelOverlay_Oceans",			"ShowMapLabelsOceans"},
	{"MapLabelOverlay_Seas",			"ShowMapLabelsSeas"},
}

ExposedMembers.Suk_IsScreenshotMode = ExposedMembers.Suk_IsScreenshotMode or false
m_YieldIcons = UILens.CreateLensLayerHash("Yield_Icons")
m_ToggleVisibilityAction = nil
--===========================================================================================
--	BUTTONS
--===========================================================================================
--	EnterScreenshotMode
------------------------------------------------------------------------------
function EnterScreenshotMode()

	if ExposedMembers.Suk_IsScreenshotMode then return end
	----------------------------
	-- Hide UI Elements
	----------------------------
	-- Handle the general UI Controls
	ExposedMembers.Suk_ScreenshotMode_StoredStates = {}
	for i,pControl in pairs(m_ContextsToHide) do
		ExposedMembers.Suk_ScreenshotMode_StoredStates[pControl] = pControl:IsHidden()
		pControl:SetHide(true)
	end

	-- UnitFlags
	if ExposedMembers.Suk_ScreenshotMode_Options.HideUnitFlags then
		pControl = ContextPtr:LookUpControl("/InGame/UnitFlagManager")
		ExposedMembers.Suk_ScreenshotMode_StoredStates[pControl] = pControl:IsHidden()
		pControl:SetHide(true)
	end

	-- CityBanners
	if ExposedMembers.Suk_ScreenshotMode_Options.HideCityBanners then
		pControl = ContextPtr:LookUpControl("/InGame/CityBannerManager")
		ExposedMembers.Suk_ScreenshotMode_StoredStates[pControl] = pControl:IsHidden()
		pControl:SetHide(true)
	end
	----------------------------
	-- Hide Map Elements
	----------------------------
	-- Borders
	if ExposedMembers.Suk_ScreenshotMode_Options.HideBorders then
		UILens.GetOverlay("CultureBorders"):SetVisible(false)
	end
	-- Map Labels
	if Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68") and ExposedMembers.Suk_ScreenshotMode_Options.HideMapLabels then
		for _,tLabelType in pairs(m_MapLabels) do
			UILens.GetOverlay(tLabelType[1]):SetVisible(false)
		end
	end
	-- Yields
	if ExposedMembers.Suk_ScreenshotMode_Options.HideMapYields then
		UILens.ToggleLayerOff(m_YieldIcons)
	end

	if ExposedMembers.Suk_ScreenshotMode_Options.UseFixedTilt then
		UI.SetFixedTiltMode(true)
		UI.SetFixedTiltAngle(45)
	end

	ExposedMembers.Suk_IsScreenshotMode = true
	ResetConstants()
	UI.PlaySound("UI_Lens_On")
end
------------------------------------------------------------------------------
--	ExitScreenshotMode
------------------------------------------------------------------------------
function ExitScreenshotMode()

	if not ExposedMembers.Suk_IsScreenshotMode then return false end

	for pControl, bHidden in pairs(ExposedMembers.Suk_ScreenshotMode_StoredStates) do
		pControl:SetHide(bHidden)
	end

	-- Restore Borders
	UILens.SetActive("Default")
	UILens.GetOverlay("CultureBorders"):SetVisible(true)
	-- Restore Map Labels
	if Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68") then
		for _,tLabelType in pairs(m_MapLabels) do
			UILens.GetOverlay(tLabelType[1]):SetVisible(UserConfiguration[tLabelType[2]]())
		end
	end
	-- Restore Yields
	if UserConfiguration.ShowMapYield() then
		UILens.ToggleLayerOn(m_YieldIcons)
	end

	UI.SpinMap( 0.0, 0.0 )
	UI.SetFixedTiltMode(false)
	UI.PlaySound("UI_Lens_Off")
	ExposedMembers.Suk_IsScreenshotMode = false
	ResetConstants()
	return true
end
------------------------------------------------------------------------------
--	ToggleScreenshotOptionsPanel
------------------------------------------------------------------------------
function ToggleScreenshotOptionsPanel()
	UI.PlaySound("Play_UI_Click");
	Controls.ScreenshotOptionsPanel:SetHide(
		not Controls.ScreenshotOptionsPanel:IsHidden()
	)
end
------------------------------------------------------------------------------
--	ToggleScreenshotOption
------------------------------------------------------------------------------
function ToggleScreenshotOption(sOption)
	ExposedMembers.Suk_ScreenshotMode_Options[sOption] = not ExposedMembers.Suk_ScreenshotMode_Options[sOption]
	Controls[sOption]:SetCheck(ExposedMembers.Suk_ScreenshotMode_Options[sOption])
end
--===========================================================================================
--	Initialize/Shutdown
--===========================================================================================
--	OnInit
------------------------------------------------------------------------------
function OnInit( bIsReload)
	Events.LoadScreenClose.Add(OnInit)
	if not ContextPtr:LookUpControl("/InGame/MinimapPanel/OptionsStack") then return end

	------------------------------------
	-- Hotkey
	------------------------------------
	m_ToggleVisibilityAction = Input.GetActionId("Suk_ScreenshotMode");
	if m_ToggleVisibilityAction ~= nil then
		Events.InputActionTriggered.Add(OnInputActionTriggered)
	end
	----------------------------
	-- Hookup Buttons
	----------------------------
	-- Minimap Panel Button
	Controls.ScreenshotButton:RegisterCallback(Mouse.eRClick, ToggleScreenshotOptionsPanel)
	Controls.ScreenshotButton:RegisterCallback(Mouse.eLClick, EnterScreenshotMode)

	-- Enter Screenshot Mode Button
	Controls.EnterScreenShotMode:RegisterCallback(Mouse.eLClick, EnterScreenshotMode)

	-- Option Checkboxes
	for sOption, bBool in pairs(ExposedMembers.Suk_ScreenshotMode_Options) do
		Controls[sOption]:SetCheck(bBool)
		Controls[sOption]:RegisterCallback(Mouse.eLClick,
			function()
				ToggleScreenshotOption(sOption)
			end
		)
	end
	Controls.HideMapLabels:SetHide(not Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"))
	----------------------------
	-- Get Contexts to Hide
	----------------------------
	m_ContextsToHide = {
		ContextPtr:LookUpControl("/InGame/HUD"),
		ContextPtr:LookUpControl("/InGame/PartialScreens"),
		ContextPtr:LookUpControl("/InGame/Screens"),
		ContextPtr:LookUpControl("/InGame/TopLevelHUD"),
		ContextPtr:LookUpControl("/InGame/WorldPopups"),
		ContextPtr:LookUpControl("/InGame/Civilopedia"),
	}
	-- We can't hide all of WorldViewControls
	-- Unit Flags and City Banners are children of this container
	local pWorldViewControls = ContextPtr:LookUpControl("/InGame/WorldViewControls")
	for i,pChild in pairs(pWorldViewControls:GetChildren()) do
		if pChild:GetID() ~= "BannerAndFlags" then
			table.insert(m_ContextsToHide, pChild)
		end
	end
	----------------------------
	-- Re-Parent
	----------------------------
	local pOptionsStack	= ContextPtr:LookUpControl("/InGame/MinimapPanel/OptionsStack")

	Controls.ScreenshotButton:ChangeParent(pOptionsStack)
	pOptionsStack:CalculateSize()
	pOptionsStack:ReprocessAnchoring()
	----------------------------
	-- ExitScreenshotMode
	----------------------------
	if bIsReload then
		ExitScreenshotMode()
	end
end
------------------------------------------------------------------------------
--	OnShutdown
------------------------------------------------------------------------------
function OnShutdown()
	Controls.ScreenshotButton:ChangeParent(ContextPtr)
	Events.LoadScreenClose.Remove(OnInit)
end
------------------------------------------------------------------------------
--	Initialize
------------------------------------------------------------------------------
function Initialize()
	ContextPtr:SetInitHandler(OnInit)
	ContextPtr:SetShutdown(OnShutdown)
	ContextPtr:SetInputHandler(OnInputHandler, true)
	ContextPtr:SetHide(false)
end
Initialize()
--=================================================================================================================
--=================================================================================================================