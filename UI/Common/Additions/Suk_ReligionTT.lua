-- Suk_ReligionTT
-- Author: Sukrit
-- DateCreated: 10/20/2017 4:30:19 PM
--------------------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );

local m_Suk_Religion_TT = {}
TTManager:GetTypeControlTable("Suk_Religion_TT", m_Suk_Religion_TT)
--------------------------------------------------------------
--	Round to X decimal places -- do we have a function for this already?
--------------------------------------------------------------
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult;
end
--------------------------------------------------------------
-- UpdateReligionTooltip
--------------------------------------------------------------
function UpdateReligionTooltip(tControl, pCity)

	local pCityReligion			= pCity:GetReligion()
	local tReligions			= pCityReligion:GetReligionsInCity()

	--

	local iMajorityReligion		= pCityReligion:GetMajorityReligion()
	local iOutwardPressure		= pCityReligion:GetPressureFromCity()	
	local iNextReligion			= pCityReligion:GetNextReligion()
	local iTurnsToNextReligion	= pCityReligion:GetTurnsToNextReligion()

	--

	local iPantheon	= pCityReligion:GetActivePantheon();
	local tPantheon = GameInfo.Beliefs[iPantheon]

	-------------------------------------------------
	-- Extra Info
	-- Start by hiding everything
	-------------------------------------------------
	m_Suk_Religion_TT.PressureReligionIcon:SetHide(true)
	m_Suk_Religion_TT.PressureReligionBannerIconContainer:SetHide(true)
	m_Suk_Religion_TT.PressureString:SetHide(true)	

	m_Suk_Religion_TT.CoversionReligionIcon:SetHide(true)
	m_Suk_Religion_TT.CoversionReligionBannerIconContainer:SetHide(true)
	m_Suk_Religion_TT.CoversionString:SetHide(true)

	m_Suk_Religion_TT.ExtraInfoContainer:SetHide(true)
	m_Suk_Religion_TT.ExtraInfoDivider:SetHide(true)

	m_Suk_Religion_TT.PantheonInfo:SetHide(true)
	-------------------------------------------------
	-- Pantheon
	-------------------------------------------------
	if tPantheon then
		local sLabel = Locale.Lookup("LOC_BELIEF_CLASS_PANTHEON_NAME") .. ":"
		local sName = Locale.Lookup(tPantheon.Name)
		local sIcon = "ICON_" .. tPantheon.BeliefType

		m_Suk_Religion_TT.PantheonInfo:SetHide(false)
		m_Suk_Religion_TT.PantheonLabel:SetText(Locale.ToUpper(sLabel))
		m_Suk_Religion_TT.PantheonName:SetText(sName)
		m_Suk_Religion_TT.PantheonIcon:SetIcon(sIcon)
	end
	-------------------------------------------------
	local bReveal = false
	-------------------------------------------------
	if iMajorityReligion ~= -1 then
		local sIcon = "ICON_" .. GameInfo.Religions[iMajorityReligion].ReligionType
		local iColor = UI.GetColorValue(GameInfo.Religions[iMajorityReligion].Color)		
		local sText = "+" .. iOutwardPressure .. "[Icon_SukPressureRight]"

		m_Suk_Religion_TT.PressureReligionIcon:SetIcon(sIcon)
		m_Suk_Religion_TT.PressureReligionIcon:SetColor(iColor)
		m_Suk_Religion_TT.PressureReligionBannerIconContainer:SetColor(iColor)
		m_Suk_Religion_TT.PressureString:SetText(sText)

		m_Suk_Religion_TT.PressureReligionIcon:SetHide(false)
		m_Suk_Religion_TT.PressureReligionBannerIconContainer:SetHide(false)
		m_Suk_Religion_TT.PressureString:SetHide(false)

		bReveal = true	
	end

	if iNextReligion ~= -1 then
		local sIcon = "ICON_" .. GameInfo.Religions[iNextReligion].ReligionType
		local iColor = UI.GetColorValue(GameInfo.Religions[iNextReligion].Color)		
		local sText = iTurnsToNextReligion .. "[Icon_Turn]"

		m_Suk_Religion_TT.CoversionReligionIcon:SetIcon(sIcon)
		m_Suk_Religion_TT.CoversionReligionIcon:SetColor(iColor)
		m_Suk_Religion_TT.CoversionReligionBannerIconContainer:SetColor(iColor)
		m_Suk_Religion_TT.CoversionString:SetText(sText)

		m_Suk_Religion_TT.CoversionReligionIcon:SetHide(false)
		m_Suk_Religion_TT.CoversionReligionBannerIconContainer:SetHide(false)
		m_Suk_Religion_TT.CoversionString:SetHide(false)		

		bReveal = true
	end

	if bReveal then m_Suk_Religion_TT.ExtraInfoContainer:SetHide(false); m_Suk_Religion_TT.ExtraInfoDivider:SetHide(false); end

	-- Load Constants
	local eSpeed = GameConfiguration.GetGameSpeedType()
	local iSpeedCostMultiplier = GameInfo.GameSpeeds[eSpeed].CostMultiplier

	-- Prep Instance Managers
	if m_Suk_Religion_TT.IM == nil then
		m_Suk_Religion_TT.IM = InstanceManager:new("Suk_ReligionInstance", "BG", m_Suk_Religion_TT.ReligionStack)
	end
	if(m_Suk_Religion_TT.MeterIM == nil) then
		m_Suk_Religion_TT.MeterIM = InstanceManager:new("ReligionMeterNone", "Meter", m_Suk_Religion_TT.Meters)
	end
	m_Suk_Religion_TT.IM:ResetInstances()
	m_Suk_Religion_TT.MeterIM:ResetInstances()	

	--Init Religions
	-- the first Religion provides the icon!
	local bMajority = true

	-- Grab Total Pressure
	--local iTotalFillPercent = 0	
	local iTotalPressure = 0
	local iTotalFillPercent = 1
	for i,tReligion in pairs(tReligions) do
		iTotalPressure = iTotalPressure + tReligion.Pressure
	end

	m_Suk_Religion_TT.TotalString:SetText(
		Locale.ToUpper(
			Locale.Lookup("LOC_HUD_CITY_TOTAL") .. ":[NEWLINE]" ..
			round(iTotalPressure,0) .. "[ICON_Religion]"
		))

	table.sort(tReligions, function(a,b)
	
		if a.Followers == b.Followers then
			return a.Pressure > b.Pressure
		end

		return a.Followers > b.Followers
	end)

	local tInstances ={}
	local iMaxLength = 0
	for i,tReligion in ipairs(tReligions) do
		local tInstance = m_Suk_Religion_TT.IM:GetInstance()
		local tMeter = m_Suk_Religion_TT.MeterIM:GetInstance()
		tInstances[i] = tInstance

		local iReligion = tReligion.Religion
		if iReligion == -1 then iReligion = GameInfo.Religions["RELIGION_PANTHEON"].Index end

		local sIcon = "ICON_" .. GameInfo.Religions[iReligion].ReligionType
		local sName = Game.GetReligion():GetName(iReligion)
		local iColor = UI.GetColorValue(GameInfo.Religions[iReligion].Color)

		local iFollower = tReligion.Followers
		local iPressure = round(tReligion.Pressure, 0)
		local iPPT = pCityReligion:GetTotalPressureOnCity(iReligion)
		iPPT = round(iPPT * 100 / iSpeedCostMultiplier, 1)

		tMeter.Meter:SetPercent(iTotalFillPercent)
		tMeter.Meter:SetColor(iColor)

		iTotalFillPercent = iTotalFillPercent - iPressure/iTotalPressure

		-- Set Icon!
		tInstance.ReligionIcon:SetIcon(sIcon)
		tInstance.ReligionIcon:SetColor(iColor)
		tInstance.ReligionBannerIconContainer:SetColor(iColor)

		tInstance.FollowerNumber:SetText(iFollower)
		tInstance.ReligionString:SetText(Locale.ToUpper(sName))

		tInstance.PressureString:SetText("" .. iPressure .. " [ICON_Religion], +" .. Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", iPPT))

		tInstance.BGStack:CalculateSize()
		tInstance.LabelContainer:CalculateSize()
		local iLength = tInstance.BGStack:GetSizeX() + 25
		if iLength > iMaxLength then iMaxLength = iLength end
	end

	for i,tInstance in pairs(tInstances) do
		tInstance.BG:SetSizeX(iMaxLength)
	end
end

ExposedMembers.UpdateReligionTooltip = UpdateReligionTooltip