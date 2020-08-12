-- ===========================================================================
--	Functions related to finding the yield bonuses (district) plots are given
--	due to some attribute of an adjacent plot.
-- ==========================================================================
include( "Civ6Common" );		-- GetYieldString()
include( "MapEnums" );
-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local START_INDEX	:number = GameInfo.Yields["YIELD_FOOD"].Index;
local END_INDEX		:number = GameInfo.Yields["YIELD_FAITH"].Index;

local m_DistrictsWithAdjacencyBonuses	:table = {};
for row in GameInfo.District_Adjacencies() do
	local districtIndex = GameInfo.Districts[row.DistrictType].Index;
	if (districtIndex ~= nil) then
		m_DistrictsWithAdjacencyBonuses[districtIndex] = true;
	end
end
-- ===========================================================================
--	MODDED ADJACENCY HANDLERS
--
--	Remember to check if the Local Player even needs checking before inserting
--
--	Insert a new entry into g_AdjacencyHandlers with the following format
--	local tTable = {
--		GetAdjacentIconArtdefName = function(pPlayer, pCity, pPlot, eDistrict) return sAdjacentIconArtdefName end,
--		GetAdjacentYieldBonus = function(pPlayer, pCity, tPlots, eDistrict, eYield) return iBonus, sBonusString end,
--	}
--
-- table.insert(g_AdjacencyHandlers[eDistrict][eYield], tTable)
-- ==========================================================================
g_AdjacencyHandlers = {};	-- Modded Adjacency Handlers

for row in GameInfo.Districts() do
	g_AdjacencyHandlers[row.Index] = {}
	for iYieldType = START_INDEX, END_INDEX do
		g_AdjacencyHandlers[row.Index][iYieldType] = {}
	end
end

include("Suk_AdjacencyHandlerItem_", true);
-- for i,tDistrcut in pairs(g_AdjacencyHandlers) do
-- 	for i,tYieldTable in pairs(tDistrcut) do
-- 		for i,tHandler in ipairs(tYieldTable) do
-- 			print(tHandler)
-- 		end
-- 	end
-- end
-- ===========================================================================
--	PlotRingIterator
-- ===========================================================================
function ToHexFromGrid(grid)
    local hex = {
        x = grid.x - (grid.y - (grid.y % 2)) / 2;
        y = grid.y;
    }
    return hex
end

function ToGridFromHex(hex_x, hex_y)
    local grid = {
        x = hex_x + (hex_y - (hex_y % 2)) / 2;
        y = hex_y;
    }
    return grid.x, grid.y
end

function PlotRingIterator(pPlot, r)
  local hex = ToHexFromGrid({x=pPlot:GetX(), y=pPlot:GetY()})
  local x, y = hex.x, hex.y

  local function north(x, y, r, i) return {x=x-r+i, y=y+r} end
  local function northeast(x, y, r, i) return {x=x+i, y=y+r-i} end
  local function southeast(x, y, r, i) return {x=x+r, y=y-i} end
  local function south(x, y, r, i) return {x=x+r-i, y=y-r} end
  local function southwest(x, y, r, i) return {x=x-i, y=y-r+i} end
  local function northwest(x, y, r, i) return {x=x-r, y=y+i} end
  local sides = {north, northeast, southeast, south, southwest, northwest}

  -- This coroutine walks the edges of the hex centered on pPlot at radius r
  local next = coroutine.create(function ()
    for _, side in ipairs(sides) do
      for i=0, r-1, 1 do
        coroutine.yield(side(x, y, r, i))
      end
    end

    return nil
  end)

  -- This function returns the next edge plot in the sequence, ignoring those that fall off the edges of the map
  return function ()
    local pEdgePlot = nil
    local _, hex = coroutine.resume(next)

    while (hex ~= nil and pEdgePlot == nil) do
      pEdgePlot = Map.GetPlot(ToGridFromHex(hex.x, hex.y))
      if (pEdgePlot == nil) then _, hex = coroutine.resume(next) end
    end

    return pEdgePlot
  end
end
-- ===========================================================================
--	Obtain the artdef string name that shows an adjacency icon for a plot type.
--	RETURNS: Artdef string name for an icon to display between hexes
-- ===========================================================================
local tTerrainEquivalencies = 
	{
		[g_TERRAIN_TYPE_GRASS] 			= "Terrain_Grass",
		[g_TERRAIN_TYPE_GRASS_HILLS] 	= "Terrain_Grass",
		[g_TERRAIN_TYPE_PLAINS] 		= "Terrain_Plains",
		[g_TERRAIN_TYPE_PLAINS_HILLS] 	= "Terrain_Plains",
		[g_TERRAIN_TYPE_DESERT] 		= "Terrain_Desert",
		[g_TERRAIN_TYPE_DESERT_HILLS] 	= "Terrain_Desert",
		[g_TERRAIN_TYPE_TUNDRA] 		= "Terrain_Tundra",
		[g_TERRAIN_TYPE_TUNDRA_HILLS] 	= "Terrain_Tundra",	
		[g_TERRAIN_TYPE_SNOW] 			= "Terrain_Snow",
		[g_TERRAIN_TYPE_SNOW_HILLS] 	= "Terrain_Snow",
		[g_TERRAIN_TYPE_COAST] 			= "Terrain_Sea",
		[g_TERRAIN_TYPE_OCEAN] 			= "Terrain_Sea",				
	}
---------------------------------------------------------
-- normalize case of words in 'str' to Title Case
---------------------------------------------------------
local function tchelper(first, rest)
	if not rest then
		return first:upper()
	else
		return first:upper()..rest		
	end
end

function Titlecase(str)
	str = str:lower()
    str = str:gsub("([%s_]%a)", tchelper)
    str = str:gsub("(%a)([%w_']*)", tchelper)
    return str
end
---------------------------------------------------------
---------------------------------------------------------
function GetAdjacentIconArtdefName( targetDistrictType:string, plot:table, pkCity:table, direction:number )

	local eDistrict = GameInfo.Districts[targetDistrictType].Index;
	local eType = -1;
	local iSubType = -1;
	eType, iSubType = plot:GetAdjacencyBonusType(Game:GetLocalPlayer(), pkCity:GetID(), eDistrict, direction);

	-- if eType == AdjacencyBonusTypes.NO_ADJACENCY then
	-- 	return "";
	-- elseif eType == AdjacencyBonusTypes.ADJACENCY_DISTRICT then
	if eType == AdjacencyBonusTypes.ADJACENCY_DISTRICT then
		return "Districts_Generic_District";

	-------------------------------------------------------------------------------
	-- Features
	-------------------------------------------------------------------------------
	elseif eType == AdjacencyBonusTypes.ADJACENCY_FEATURE then

		if iSubType == g_FEATURE_JUNGLE then
			return "Terrain_Jungle";
		elseif iSubType == g_FEATURE_FOREST then
			return "Terrain_Forest";
		end

		local tType = GameInfo.Features[iSubType]
		if not tType then return "" end
		if tType.NaturalWonder then return "Wonders_Natural_Wonder" end
		local sType = tType.FeatureType
		return Titlecase(sType)
	-------------------------------------------------------------------------------
	-- Improvements
	-------------------------------------------------------------------------------
	elseif eType == AdjacencyBonusTypes.ADJACENCY_IMPROVEMENT then

		local tType = GameInfo.Improvements[iSubType]
		if not tType then return "" end
		local sType = tType.ImprovementType

		-- The farm has to be handled as a special case cause YOU ADDED AN 'S' FOR SOME REASON!?!?
		if sType == "IMPROVEMENT_FARM" then return "Improvements_Farm" end

		return Titlecase(sType)
	-------------------------------------------------------------------------------
	-- Natural Wonders
	-------------------------------------------------------------------------------
	elseif eType == AdjacencyBonusTypes.ADJACENCY_NATURAL_WONDER then
		return "Wonders_Natural_Wonder";
	elseif eType == AdjacencyBonusTypes.ADJACENCY_RESOURCE then
		return "Terrain_Generic_Resource";
	elseif eType == AdjacencyBonusTypes.ADJACENCY_RIVER then
		return "Terrain_River";
	elseif eType == AdjacencyBonusTypes.ADJACENCY_SEA_RESOURCE then
		return "Terrain_Sea";
	-------------------------------------------------------------------------------
	-- Terrains
	-------------------------------------------------------------------------------		
	elseif eType == AdjacencyBonusTypes.ADJACENCY_TERRAIN then

		-- Sukritact: This was my old code
		-- if tTerrainEquivalencies[iSubType] then
		-- 	return tTerrainEquivalencies[iSubType]
		-- else
		-- 	return "Terrain_Mountain";
		-- end

		-- But it looks like we can make it modular, so let's make it modular!!!
		local sType = GameInfo.Terrains[iSubType].TerrainType
		local tType = GameInfo.Terrains[iSubType]
		if not tType then return "" end
		local sType = tType.TerrainType
		return Titlecase(sType)

	elseif eType == AdjacencyBonusTypes.ADJACENCY_WONDER then
		return "Generic_Wonder";
	end

	-- Modded Adjacencies!!
	--local pPlot = Map.GetAdjacentPlot( plot:GetX(), plot:GetY(), DirectionTypes.DIRECTION_EAST )
	local sIconName = ""
	if g_AdjacencyHandlers[eDistrict] then
		for i,tYieldTable in pairs(g_AdjacencyHandlers[eDistrict]) do
			for i,tHandler in ipairs(tYieldTable) do
				sIconName = tHandler.GetAdjacentIconArtdefName(Players[Game:GetLocalPlayer()], pkCity, plot, eDistrict)

				if sIconName and sIconName ~= "" then return sIconName end
			end
		end
	end
	
	return "";	-- None (or error)
end

-- ===========================================================================
--	Obtain a table of adjacency bonuses
-- ===========================================================================
function AddAdjacentPlotBonuses( kPlot:table, districtType:string, pSelectedCity:table, tCurrentBonuses:table )
	local adjacentPlotBonuses:table = {};
	local x		:number = kPlot:GetX();
	local y		:number = kPlot:GetY();

	for _,direction in pairs(DirectionTypes) do			
		if direction ~= DirectionTypes.NO_DIRECTION and direction ~= DirectionTypes.NUM_DIRECTION_TYPES then
			local adjacentPlot	:table= Map.GetAdjacentPlot( x, y, direction);
			if adjacentPlot ~= nil then
				local artdefIconName:string = GetAdjacentIconArtdefName( districtType, adjacentPlot, pSelectedCity, direction );
			
				if artdefIconName ~= nil and artdefIconName ~= "" then

		
					local districtViewInfo:table = GetViewPlotInfo( adjacentPlot, tCurrentBonuses );
					local oppositeDirection :number = -1;
					if direction == DirectionTypes.DIRECTION_NORTHEAST	then oppositeDirection = DirectionTypes.DIRECTION_SOUTHWEST; end
					if direction == DirectionTypes.DIRECTION_EAST		then oppositeDirection = DirectionTypes.DIRECTION_WEST; end
					if direction == DirectionTypes.DIRECTION_SOUTHEAST	then oppositeDirection = DirectionTypes.DIRECTION_NORTHWEST; end
					if direction == DirectionTypes.DIRECTION_SOUTHWEST	then oppositeDirection = DirectionTypes.DIRECTION_NORTHEAST; end
					if direction == DirectionTypes.DIRECTION_WEST		then oppositeDirection = DirectionTypes.DIRECTION_EAST; end
					if direction == DirectionTypes.DIRECTION_NORTHWEST	then oppositeDirection = DirectionTypes.DIRECTION_SOUTHEAST; end

					table.insert( districtViewInfo.adjacent, {
						direction	= oppositeDirection,
						iconArtdef	= artdefIconName,
						inBonus		= false,
						outBonus	= true					
						}
					);				

					adjacentPlotBonuses[adjacentPlot:GetIndex()] = districtViewInfo;
				end
			end		
		end
	end

	return adjacentPlotBonuses;
end

-- ===========================================================================
--	Adds a plot and all the adjacencent plots, unless already added.
--	ARGS:		kPlot,			gamecore plot object
--	ARGS:		kExistingTable,	table of existing plot into to check if we already have info about this plot
--	RETURNS:	A new/updated plotInfo table
-- ===========================================================================
function GetViewPlotInfo( kPlot:table, kExistingTable:table )
	local plotId	:number = kPlot:GetIndex();
	local plotInfo	:table = kExistingTable[plotId];
	if plotInfo == nil then 
		plotInfo = {
			index	= plotId, 
			x		= kPlot:GetX(), 
			y		= kPlot:GetY(),
			adjacent= {},				-- adjacent edge bonuses
			selectable = false,			-- change state with mouse over?
			purchasable = false
		}; 
	end
	--print( "   plot: " .. plotInfo.x .. "," .. plotInfo.y..": " .. tostring(plotInfo.iconArtdef) );
	return plotInfo;
end

-- ===========================================================================
--	RETURNS: true or false, indicating whether this placement option should be 
--	shown when the player can purchase the plot.
-- ===========================================================================
function IsShownIfPlotPurchaseable(eDistrict:number, pkCity:table, plot:table)
	local yieldBonus:string = GetAdjacentYieldBonusString(eDistrict, pkCity, plot);

	-- If we would get a bonus for placing here, then show it as an option
	if (yieldBonus ~= nil and yieldBonus ~= "") then
		return true;
	end

	-- If there are no adjacency bonuses for this district type (and so no bonuses to be had), then show it as an option
	if (m_DistrictsWithAdjacencyBonuses[eDistrict] == nil or m_DistrictsWithAdjacencyBonuses[eDistrict] == false) then
		return true;
	end

	return false;
end

-- ===========================================================================
--	RETURNS: "" if no bonus or...
--		1. Text with the bonuses for a district if added to the given plot,
--		2. parameter is a tooltip with detailed bonus informatin
--		3. NIL if can be used or a string explaining what needs to be done for plot to be usable.
-- ===========================================================================
g_tAppealHousingDistricts = {}
for row in GameInfo.AppealHousingChanges() do
	g_tAppealHousingDistricts[row.DistrictType] = true
	--print(row.DistrictType)
end

function GetAdjacentYieldBonusString( eDistrict:number, pkCity:table, plot:table )

	local tooltipText	:string = "";
	local totalBonuses	:string = "";
	local requiredText	:string = "";
	local isFirstEntry	:boolean = true;	
	local iconString:string = "";

	local tRequiredText = {}
	local bAdjacency = false

	------------------------------------------------------
	-- Special handling for Neighborhoods
	------------------------------------------------------
	if g_tAppealHousingDistricts[GameInfo.Districts[eDistrict].DistrictType] then

		tooltipText, requiredText = plot:GetAdjacencyBonusTooltip(Game:GetLocalPlayer(), pkCity:GetID(), eDistrict, 0);

		if requiredText ~= nil then
			tRequiredText[requiredText] = true
		end

		local iAppeal = plot:GetAppeal();
		local iBaseHousing = GameInfo.Districts[eDistrict].Housing;

		-- Default is Mbanza case (no appeal change)
		iconString = "+" .. tostring(iBaseHousing);

		for row in GameInfo.AppealHousingChanges() do
			if (row.DistrictType == GameInfo.Districts[eDistrict].DistrictType) then
				local iMinimumValue = row.MinimumValue;
				local iAppealChange = row.AppealChange;
				local szDescription = row.Description;
				if (iAppeal >= iMinimumValue) then
					iconString = "+" .. tostring(iBaseHousing + iAppealChange);
					tooltipText = Locale.Lookup("LOC_DISTRICT_ZONE_NEIGHBORHOOD_TOOLTIP", iBaseHousing + iAppealChange, szDescription);
					break;
				end
			end
		end
		iconString =  "[ICON_Housing]" .. iconString;
		bAdjacency = true
	end
	------------------------------------------------------
	-- Normal handling for all other districts
	-- This modification allows more than one yield type in Adjacencies
	-- Did you not think to allow Neighborhoods with adjacency bonuses BTW?

	-- This has been further modified to allow for custom modifiers!
	------------------------------------------------------
	local tPlots = {}
	for pPlot in PlotRingIterator(plot, 1) do
		table.insert(tPlots, pPlot)
	end

	for iYieldType = START_INDEX, END_INDEX do

		-------------------------------------------------
		-- Modded Adjacency Text!
		-------------------------------------------------
		local iModdedBonus = 0
		local sModdedTooltip = ""
		local bNewline = false
		
		for i,tHandler in ipairs(g_AdjacencyHandlers[eDistrict][iYieldType]) do
			local iBonus, sTooltip = tHandler.GetAdjacentYieldBonus(Players[Game:GetLocalPlayer()], pkCity, tPlots, eDistrict, iYieldType)

			if iBonus and iBonus > 0 then
				iModdedBonus = iModdedBonus + iBonus
			end

			if sTooltip and sTooltip ~= "" then
				if bNewline then sModdedTooltip = sModdedTooltip .. "[NEWLINE]" end
				sModdedTooltip = sModdedTooltip .. sTooltip
				bNewline = true
			end
		end

		-------------------------------------------------
		-- Standard Adjacency Text
		-------------------------------------------------
		local iBonus = plot:GetAdjacencyYield(Game:GetLocalPlayer(), pkCity:GetID(), eDistrict, iYieldType);
		if iBonus + iModdedBonus > 0 then

			if bAdjacency then
				iconString = iconString .. "[NEWLINE]"
				tooltipText = tooltipText .. "[NEWLINE]"
			end

			iconString = iconString .. GetYieldString(GameInfo.Yields[iYieldType].YieldType, iBonus + iModdedBonus)

			if iBonus > 0 then
				local sTooltip, sRequired = plot:GetAdjacencyBonusTooltip(Game:GetLocalPlayer(), pkCity:GetID(), eDistrict, iYieldType);
				tooltipText = tooltipText .. sTooltip
			end

			if sRequired ~= nil then
				if not(tRequiredText[sRequired]) then
					
					if bAdjacency then requiredText = requiredText .. "[NEWLINE]" end
					requiredText = requiredText .. sRequired
					tRequiredText[sRequired] = true

				end
			end

			bAdjacency = true

			if iBonus > 0 and sModdedTooltip ~= "" then
				tooltipText = tooltipText .. "[NEWLINE]"
			end
			tooltipText = tooltipText .. sModdedTooltip

		end
	end
	
	------------------------------------------------------
	-- Ensure required text is NIL if none was returned.
	------------------------------------------------------
	if requiredText ~= nil and string.len(requiredText) < 1 then
		requiredText = nil;
	end		

	return iconString, tooltipText, requiredText;
end



-- ===========================================================================
--	Obtain all the owned (or could be owned) plots of a city.
--	ARGS: pCity, the city to obtain plots from
--	RETURNS: table of plot indices
-- ===========================================================================
function GetCityRelatedPlotIndexes( pCity:table )
	
	print("GetCityRelatedPlotIndexes() isn't updated with the latest purchaed plot if one was just purchased and this is being called on Event.CityMadePurchase !");
	local plots:table = Map.GetCityPlots():GetPurchasedPlots( pCity );

	-- Plots that arent't owned, but could be (and hence, could be a great spot for that district!)
	local tParameters :table = {};
	tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
	local tResults = CityManager.GetCommandTargets( pCity, CityCommandTypes.PURCHASE, tParameters );
	if (tResults[CityCommandResults.PLOTS] ~= nil and table.count(tResults[CityCommandResults.PLOTS]) ~= 0) then
		for _,plotId in pairs(tResults[CityCommandResults.PLOTS]) do
			table.insert(plots, plotId);
		end
	end

	return plots;
end

-- ===========================================================================
--	Same as above but specific to districts and works despite the cache not having an updated value.
-- ===========================================================================
function GetCityRelatedPlotIndexesDistrictsAlternative( pCity:table, districtHash:number )

	local district		:table = GameInfo.Districts[districtHash];
	local plots			:table = {};
	local tParameters	:table = {};

	tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtHash;


	-- Available to place plots.
	local tResults :table = CityManager.GetOperationTargets( pCity, CityOperationTypes.BUILD, tParameters );
	if (tResults[CityOperationResults.PLOTS] ~= nil and table.count(tResults[CityOperationResults.PLOTS]) ~= 0) then			
		local kPlots:table = tResults[CityOperationResults.PLOTS];			
		for i, plotId in ipairs(kPlots) do
			table.insert(plots, plotId);
		end	
	end	

	--[[
	-- antonjs: Removing blocked plots from the UI display. Now that district placement can automatically remove features, resources, and improvements,
	-- as long as the player has the tech, there is not much need to show blocked plots and they end up being confusing.
	-- Plots that eventually can hold a district but are blocked by some required operation.
	if (tResults[CityOperationResults.BLOCKED_PLOTS] ~= nil and table.count(tResults[CityOperationResults.BLOCKED_PLOTS]) ~= 0) then			
		for _, plotId in ipairs(tResults[CityOperationResults.BLOCKED_PLOTS]) do
			table.insert(plots, plotId);		
		end
	end
	--]]

	-- Plots that arent't owned, but if they were, would give a bonus.
	tParameters = {};
	tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
	local tResults = CityManager.GetCommandTargets( pCity, CityCommandTypes.PURCHASE, tParameters );
	if (tResults[CityCommandResults.PLOTS] ~= nil and table.count(tResults[CityCommandResults.PLOTS]) ~= 0) then
		for _,plotId in pairs(tResults[CityCommandResults.PLOTS]) do
			
			local kPlot	:table = Map.GetPlotByIndex(plotId);	
			if kPlot:CanHaveDistrict(district.Index, pCity:GetOwner(), pCity:GetID()) then
				local isValid :boolean = IsShownIfPlotPurchaseable(district.Index, pCity, kPlot);
				if isValid then
					table.insert(plots, plotId);
				end
			end
			
		end
	end
	return plots;
end

-- ===========================================================================
--	Same as above but specific to wonders and works despite the cache not having an updated value.
-- ===========================================================================
function GetCityRelatedPlotIndexesWondersAlternative( pCity:table, buildingHash:number )

	local building		:table = GameInfo.Buildings[buildingHash];
	local plots			:table = {};
	local tParameters	:table = {};

	tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = buildingHash;


	-- Available to place plots.
	local tResults :table = CityManager.GetOperationTargets( pCity, CityOperationTypes.BUILD, tParameters );
	if (tResults[CityOperationResults.PLOTS] ~= nil and table.count(tResults[CityOperationResults.PLOTS]) ~= 0) then			
		local kPlots:table = tResults[CityOperationResults.PLOTS];			
		for i, plotId in ipairs(kPlots) do
			table.insert(plots, plotId);
		end	
	end	

	-- Plots that aren't owned, but if they were, would give a bonus.
	tParameters = {};
	tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
	local tResults = CityManager.GetCommandTargets( pCity, CityCommandTypes.PURCHASE, tParameters );
	if (tResults[CityCommandResults.PLOTS] ~= nil and table.count(tResults[CityCommandResults.PLOTS]) ~= 0) then
		for _,plotId in pairs(tResults[CityCommandResults.PLOTS]) do
			
			local kPlot	:table = Map.GetPlotByIndex(plotId);	
			if kPlot:CanHaveWonder(building.Index, pCity:GetOwner(), pCity:GetID()) then
				table.insert(plots, plotId);
			end
			
		end
	end
	return plots;
end
