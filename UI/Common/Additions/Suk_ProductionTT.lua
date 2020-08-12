-- Suk_ReligionTT
-- Author: Sukrit
-- DateCreated: 10/20/2017 4:30:19 PM
--------------------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );
include( "PortraitSupport" );
--------------------------------------------------------------
-- Defines
--------------------------------------------------------------
tFormationInfo = {
	[MilitaryFormationTypes.CORPS_FORMATION] = {
		DOMAIN_SEA = "LOC_UNITFLAG_FLEET_SUFFIX",
		DOMAIN_LAND = "LOC_UNITFLAG_CORPS_SUFFIX",
	},
	[MilitaryFormationTypes.ARMY_FORMATION] = {
		DOMAIN_SEA = "LOC_UNITFLAG_ARMADA_SUFFIX",
		DOMAIN_LAND = "LOC_UNITFLAG_ARMY_SUFFIX",
	},
}

tMethods = {
	[CityProductionDirectives.TRAIN] =
		{
			Progress	= function(pBuildQueue, tDef) return pBuildQueue:GetUnitProgress(tDef.Index) end,
			Cost		= 
				function(pBuildQueue, tDef, iFormation)
					if iFormation == MilitaryFormationTypes.STANDARD_FORMATION then
						return pBuildQueue:GetUnitCost(tDef.Index)
					elseif iFormation == MilitaryFormationTypes.CORPS_FORMATION then
						return pBuildQueue:GetUnitCorpsCost(tDef.Index)
					elseif iFormation == MilitaryFormationTypes.ARMY_FORMATION then
						return pBuildQueue:GetUnitArmyCost(tDef.Index)
					end
				end,
			Turns		= function(pBuildQueue, tDef, iFormation) return pBuildQueue:GetTurnsLeft(tDef.UnitType, iFormation) end,
		},
	[CityProductionDirectives.CONSTRUCT] =
		{
			Progress	= function(pBuildQueue, tDef) return pBuildQueue:GetBuildingProgress(tDef.Index) end,
			Cost		= function(pBuildQueue, tDef) return pBuildQueue:GetBuildingCost(tDef.Index) end,
			Turns		= function(pBuildQueue, tDef) return pBuildQueue:GetTurnsLeft(tDef.BuildingType) end,
		},
	[CityProductionDirectives.ZONE] =
		{
			Progress	= function(pBuildQueue, tDef) return pBuildQueue:GetDistrictProgress(tDef.Index) end,
			Cost		= function(pBuildQueue, tDef) return pBuildQueue:GetDistrictCost(tDef.Index) end,
			Turns		= function(pBuildQueue, tDef) return pBuildQueue:GetTurnsLeft(tDef.DistrictType) end,
		},
	[CityProductionDirectives.PROJECT] =
		{
			Progress	= function(pBuildQueue, tDef) return pBuildQueue:GetProjectProgress(tDef.Index) end,
			Cost		= function(pBuildQueue, tDef) return pBuildQueue:GetProjectCost(tDef.Index) end,
			Turns		= function(pBuildQueue, tDef) return pBuildQueue:GetTurnsLeft(tDef.ProjectType) end,
		},
}

local m_Suk_CityBannerProductionTT = {}; TTManager:GetTypeControlTable("Suk_CityBannerProductionTT", m_Suk_CityBannerProductionTT)
m_Suk_QueueIM = InstanceManager:new("ProductionQueueItem", "Top", m_Suk_CityBannerProductionTT.QueueStack)
--------------------------------------------------------------
-- Utils
--------------------------------------------------------------
function rPrint(s, l, i) -- recursive Print (structure, limit, indent)
	l = (l) or 100; i = i or "";	-- default item limit, indent string
	if (l<1) then print "ERROR: Item limit reached."; return l-1 end;
	local ts = type(s);
	if (ts ~= "table") then print (i,ts,s); return l-1 end
	print (i,ts);           -- print "table"
	for k,v in pairs(s) do  -- print "[KEY] VALUE"
		l = rPrint(v, l, i.."\t["..tostring(k).."]");
		if (l < 0) then break end
	end
	return l
end
--------------------------------------------------------------
-- UpdateSuk_CityBannerProductionTT
--------------------------------------------------------------
function UpdateSuk_CityBannerProductionTT(tControl, pCity)

	m_Suk_QueueIM:ResetInstances()
	local pBuildQueue = pCity:GetBuildQueue()

	for i = 0, 5 do
		local tEntry = pBuildQueue:GetAt(i)
		
		local tProduction	= nil
		local tIcons		= {}
		local sName			= ""
		local sDesc			= ""
		local iFormation	= MilitaryFormationTypes.STANDARD_FORMATION
		local sDomain		= "DOMAIN_LAND"

		if tEntry then

			-- print(i .. "	--------------------------")
			-- rPrint(tEntry)

			if tEntry.Directive == CityProductionDirectives.TRAIN and tEntry.UnitType then
				tProduction = GameInfo.Units[tEntry.UnitType]

				tIcons = {GetUnitPortraitIconNamesFromDefinition(pCity:GetOwner(), tProduction)}
				sName = tProduction.Name
				sDesc = tProduction.Description

				iFormation = tEntry.MilitaryFormationType
				if tProduction.Domain == "DOMAIN_SEA" then sDomain = "DOMAIN_SEA" end
				if iFormation ~= MilitaryFormationTypes.STANDARD_FORMATION then
					sName = "{"..sName.."} {"..tFormationInfo[iFormation][sDomain].."}"
				end
			elseif tEntry.Directive == CityProductionDirectives.CONSTRUCT and tEntry.BuildingType then
				tProduction = GameInfo.Buildings[tEntry.BuildingType]

				tIcons = {"ICON_" .. tProduction.BuildingType}
				sName = tProduction.Name
				sDesc = tProduction.Description
			elseif tEntry.Directive == CityProductionDirectives.ZONE and tEntry.DistrictType then
				tProduction = GameInfo.Districts[tEntry.DistrictType]

				tIcons = {"ICON_" .. tProduction.DistrictType}
				sName = tProduction.Name
				sDesc = tProduction.Description
			elseif tEntry.Directive == CityProductionDirectives.PROJECT and tEntry.ProjectType then
				tProduction = GameInfo.Projects[tEntry.ProjectType]

				tIcons = {"ICON_" .. tProduction.ProjectType}
				sName = tProduction.Name
				sDesc = tProduction.Description
			end
		end

		---------------------------------
		
		if i == 0 then

			---------------------------------
			-- Setup Icon 
			---------------------------------
			if (tEntry.Directive == CityProductionDirectives.ZONE) or (tEntry.Directive == CityProductionDirectives.PROJECT) then
				m_Suk_CityBannerProductionTT.ProductionIcon:SetSizeVal(50,50)
			else
				m_Suk_CityBannerProductionTT.ProductionIcon:SetSizeVal(80,80)
			end

			for _,sIcon in ipairs(tIcons) do m_Suk_CityBannerProductionTT.ProductionIcon:TrySetIcon(sIcon) end
			---------------------------------
			-- Setup Text 
			---------------------------------
			m_Suk_CityBannerProductionTT.CurrentProductionName:LocalizeAndSetText(Locale.ToUpper(sName))
			if sDesc then
				m_Suk_CityBannerProductionTT.CurrentProductionDescription:SetHide(false)
				m_Suk_CityBannerProductionTT.CurrentProductionDescription:LocalizeAndSetText(sDesc)
			else
				m_Suk_CityBannerProductionTT.CurrentProductionDescription:SetHide(true)
			end

			local iProgress = tMethods[tEntry.Directive].Progress(pBuildQueue, tProduction)
			local iCost 	= tMethods[tEntry.Directive].Cost(pBuildQueue, tProduction, iFormation)
			local iTurns	= tMethods[tEntry.Directive].Turns(pBuildQueue, tProduction, iFormation)

			m_Suk_CityBannerProductionTT.CurrentProductionProgress:SetText("[ICON_Production]"..iProgress.." / "..iCost)
			if iTurns <= 0 then
				m_Suk_CityBannerProductionTT.CurrentProductionTurns:SetText(Locale.Lookup("LOC_CITY_BANNER_TURNS_LEFT_UNTIL_COMPLETE", "-"))
			else
				m_Suk_CityBannerProductionTT.CurrentProductionTurns:SetText(Locale.Lookup("LOC_CITY_BANNER_TURNS_LEFT_UNTIL_COMPLETE", iTurns))
			end
		else
			tInstance = m_Suk_QueueIM:GetInstance()

			if tEntry then
				tInstance.Num:SetHide(true)

				tInstance.ProductionIcon:SetHide(false)
				for _,sIcon in ipairs(tIcons) do tInstance.ProductionIcon:TrySetIcon(sIcon) end

				tInstance.CorpsMarker:SetHide(not(iFormation == MilitaryFormationTypes.CORPS_FORMATION))
				tInstance.ArmyMarker:SetHide(not(iFormation == MilitaryFormationTypes.ARMY_FORMATION))
			else
				tInstance.Num:SetHide(false)
				tInstance.Num:SetText(i + 1)

				tInstance.ProductionIcon:SetHide(true)
				tInstance.CorpsMarker:SetHide(true)
				tInstance.ArmyMarker:SetHide(true)
			end
		end
	end
end

LuaEvents.UpdateSuk_CityBannerProductionTT.Add(UpdateSuk_CityBannerProductionTT)
--------------------------------------------------------------
-- Suk_CityBannerProductionTT
--------------------------------------------------------------
function Suk_CityBannerProductionTT(tControl, pCity)
	local pBuildQueue = pCity:GetBuildQueue()

	-- The build queue is empty
	if not pBuildQueue:GetAt(0)then
		tControl.Button:SetToolTipType()
		tControl.Button:ClearToolTipCallback()
		tControl.Button:SetToolTipString(Locale.Lookup("LOC_CITY_BANNER_NO_PRODUCTION"))
	else
		tControl.Button:SetToolTipType("Suk_CityBannerProductionTT")
		tControl.Button:ClearToolTipCallback()
		tControl.Button:SetToolTipCallback(
			function()
				LuaEvents.UpdateSuk_CityBannerProductionTT(tControl, pCity)
			end
		);
	end
end

LuaEvents.Suk_CityBannerProductionTT.Add(Suk_CityBannerProductionTT)
-- ===========================================================================
--	Initialise
-- ===========================================================================
function Initialise()
	ContextPtr:SetHide(false)
end
Events.LoadScreenClose.Add(Initialise)
-- ===========================================================================
-- ===========================================================================
