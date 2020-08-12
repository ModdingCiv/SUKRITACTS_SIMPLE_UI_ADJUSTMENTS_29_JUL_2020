-- CityBannerManager_Suk_UI
-- Author: Sukrit
-- DateCreated: 9/8/2018
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
g_IS_CQUI = Modding.IsModActive("1d44b5e7-753e-405b-af24-5ee634ec8a01")
local tCityBannerVersions = {
	"citybannermanager_CQUI_expansions.lua",
	"citybannermanager_CQUI_basegame.lua",
	"CityBannerManager.lua",
}

for _,sVersion in ipairs(tCityBannerVersions) do
	include(sVersion)
	if CityBanner then
		print("--------- CityBannerManager_Suk_UI---------")
		print('Loading ' .. sVersion .. " as base file")
		print("-------------------------------------------")
		break
	end
end
-- ===========================================================================
-- CityBanner.Initialize
-- ===========================================================================
BASE_CityBanner_Initialize = CityBanner.Initialize

function CityBanner:Initialize( playerID: number, cityID : number, districtID : number, bannerType : number, bannerStyle : number)

	BASE_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle)

	if not self.m_Instance.CityBannerButton then return end
	--------------------------
	--- Trigger Citizen Overlay on hover
	--------------------------
	if not g_IS_CQUI then
		self.m_Instance.CityBannerButton:RegisterCallback( Mouse.eMouseEnter, function()
			LuaEvents.CityBannerButton_OnEnter(playerID, cityID)
		end );
		self.m_Instance.CityBannerButton:RegisterCallback( Mouse.eMouseExit, function()
			LuaEvents.CityBannerButton_OnExit(playerID, cityID)
		end );
	end
	--------------------------
	--- City management on right click
	--------------------------
	self.m_Instance.CityBannerButton:RegisterCallback( Mouse.eRClick, function(playerID, cityID)
		local pPlayer = Players[playerID];
		if (pPlayer == nil) then
			return;
		end

		local pCity = pPlayer:GetCities():FindID(cityID);
		if (pCity == nil) then
			return;
		end

		if playerID == Game.GetLocalPlayer() then

			LuaEvents.CityBannerButton_OnExit()

			if (UI.GetHeadSelectedCity() == nil) or (UI.GetHeadSelectedCity() == pCity) then
				UI.SelectCity(pCity)
				--LuaEvents.ToggleCityManagement()
				OnPopulationIconClicked(playerID, cityID)
			else
				UI.SelectCity(pCity)
			end
		end
	end)
end

if not OnPopulationIconClicked then
	function OnPopulationIconClicked(playerID: number, cityID: number)
		OnCityBannerClick(playerID, cityID);
		if (playerID == Game.GetLocalPlayer()) then
			LuaEvents.CityPanel_ToggleManageCitizens();
		end
	end
end

function SetReligionTooltip(tControl, pCity)
	tControl:SetToolTipType("Suk_Religion_TT")
	tControl:ClearToolTipCallback()
	tControl:SetToolTipCallback(
		function()
			ExposedMembers.UpdateReligionTooltip(tControl, pCity)
		end
	)
end
-- ===========================================================================
-- CityBanner.UpdateReligion
-- ===========================================================================
BASE_CityBanner_UpdateReligion = CityBanner.UpdateReligion

function CityBanner.UpdateReligion(self)

	BASE_CityBanner_UpdateReligion(self)

	local pCity		= self:GetCity()
	local pCityRel	= pCity:GetReligion()
	local iReligion	= self.m_eMajorityReligion
	local iPantheon	= pCityRel:GetActivePantheon();	local tPantheon = GameInfo.Beliefs[iPantheon]
	if (iReligion < 0) and (iPantheon < 0) then return end

	--------------------------
	-- Base Games
	-- Meh, this is easy
	--------------------------
	if self.m_Instance.ReligionBannerIconContainer then
		SetReligionTooltip(self.m_Instance.ReligionBannerIconContainer, pCity)
	--------------------------
	-- XP1+
	-- Get the exitsing button by identifying the religion button via its tooltip
	-- Loop directly through the InfoConditionIM to get the instances
	--------------------------
	else
		local sTTMatch_Rel = Locale.Lookup("LOC_HUD_CITY_RELIGION_TT", Game.GetReligion():GetName(iReligion))

		local tInstanceManager = self.m_InfoConditionIM
		local tSuk_ReligionInstanceButton = nil

		for iKey, tInstance in pairs(tInstanceManager.m_AllocatedInstances) do
			if (tInstance.Button:GetToolTipString() == sTTMatch_Rel) then
				tSuk_ReligionInstanceButton = tInstance.Button
			end
		end

		if not(tSuk_ReligionInstanceButton) then
			local sTTMatch_Pan = Locale.Lookup("LOC_HUD_CITY_PANTHEON_TT", tPantheon and tPantheon.Name or "")
			local tInstanceManager = self.m_InfoIconIM
			for iKey, tInstance in pairs(tInstanceManager.m_AllocatedInstances) do
				if (tInstance.Button:GetToolTipString() == sTTMatch_Pan) then
					tSuk_ReligionInstanceButton = tInstance.Button
				end
			end
		end

		if tSuk_ReligionInstanceButton then
			SetReligionTooltip(tSuk_ReligionInstanceButton, pCity)
		end
	end
end
-- ===========================================================================
-- CityBanner.UpdateProduction
-- ===========================================================================
BASE_CityBanner_UpdateProduction = CityBanner.UpdateProduction

function CityBanner.UpdateProduction(self, pCity)
	BASE_CityBanner_UpdateProduction(self, pCity)

	tControl = nil
	--------------------------
	-- Base Games
	--------------------------
	if self.m_Instance.CityProduction then
		tControl = self.m_Instance.CityProduction
	else
	--------------------------
	-- XP1+
	-- Just grab the first instance
	-- Loop directly through the m_StatProductionIM to get the instances
	--------------------------
		local pStatProductionIM = self.m_StatProductionIM
		for _, tInstance in pairs(pStatProductionIM.m_AllocatedInstances) do
			tControl = tInstance
			break
		end
	end

	if tControl then
		LuaEvents.Suk_CityBannerProductionTT(tControl, pCity)
	end
end
-- ===========================================================================
-- CityBanner.UpdateRangeStrike
-- ===========================================================================
if not g_IS_CQUI then
	BASE_CityBanner_UpdateRangeStrike = CityBanner.UpdateRangeStrike

	function CityBanner.UpdateRangeStrike(self)
		BASE_CityBanner_UpdateRangeStrike(self)

		local tBanner = self.m_Instance
		if tBanner.CityStrike == nil then return end

		tBanner.CityStrike:SetTexture("Suk_CityBannerRangeAttackRimHorizontal")
		tBanner.CityStrike:SetSizeVal(45,36)
		tBanner.CityStrike:SetAnchor("R,C")
		tBanner.CityStrike:SetOffsetVal(-36,0)

		tBanner.CityStrikeButton:SetAnchor("L,C")
		tBanner.CityStrikeButton:SetOffsetVal(11,0)
	end
end