-- ===========================================================================
--	Plot information 
--	Handles: plot purchasing, resources, etc...
-- ===========================================================================
include("InstanceManager")
include("SupportFunctions")
include("Civ6Common") -- AutoSizeGridButton

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local CITIZEN_BUTTON_HEIGHT		= 64
local PADDING_SWAP_BUTTON		= 24
local YIELD_NUMBER_VARIATION	= "Yield_Variation_"
local YIELD_VARIATION_MANY		= "Yield_Variation_Many"
local YIELD_VARIATION_MAP		= {
	YIELD_FOOD			= "Yield_Food_",
	YIELD_PRODUCTION	= "Yield_Production_",
	YIELD_GOLD			= "Yield_Gold_",
	YIELD_SCIENCE		= "Yield_Science_",
	YIELD_CULTURE		= "Yield_Culture_",
	YIELD_FAITH			= "Yield_Faith_",
}
local CITY_CENTER_DISTRICT_INDEX = GameInfo.Districts["DISTRICT_CITY_CENTER"].Index
-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_PlotIM				= InstanceManager:new("InfoInstance",	"Anchor", Controls.PlotInfoContainer)
local m_uiWorldMap			= {}
local m_uiCitizens			= {}	-- Citizens showing
local m_GrowthPlot					-- GrowthPlot
local m_YieldPlots

local m_PurchasePlot		= UILens.CreateLensLayerHash("Purchase_Plot");
local m_CityYields			= UILens.CreateLensLayerHash("City_Yields");
local m_bLoadScreenClose		= false
-- ===========================================================================
function ClearGrowthTile()
	UILens.ClearHex(m_PurchasePlot, m_GrowthPlot)
	Controls.GrowthHexAnchor:SetHide(true)

	m_GrowthPlot = nil
end

function DisplayGrowthTile(pCity)

	ClearGrowthTile()

	if pCity ~= nil then
		local cityCulture = pCity:GetCulture()
		if cityCulture ~= nil then
			local newGrowthPlot = cityCulture:GetNextPlot()
			if(newGrowthPlot ~= -1 and newGrowthPlot ~= m_GrowthPlot) then
				m_GrowthPlot = newGrowthPlot
				
				local cost				= cityCulture:GetNextPlotCultureCost()
				local currentCulture	= cityCulture:GetCurrentCulture()
				local currentYield		= cityCulture:GetCultureYield()
				local currentGrowth		= math.max(math.min(currentCulture / cost, 1.0), 0)
				local nextTurnGrowth	= math.max(math.min((currentCulture + currentYield) / cost, 1.0), 0)

				UILens.SetLayerGrowthHex(m_PurchasePlot, Game.GetLocalPlayer(), m_GrowthPlot, 1, "GrowthHexBG")
				UILens.SetLayerGrowthHex(m_PurchasePlot, Game.GetLocalPlayer(), m_GrowthPlot, nextTurnGrowth, "GrowthHexNext")
				UILens.SetLayerGrowthHex(m_PurchasePlot, Game.GetLocalPlayer(), m_GrowthPlot, currentGrowth, "GrowthHexCurrent")

				local turnsRemaining = cityCulture:GetTurnsUntilExpansion()
				Controls.TurnsLeftDescription:SetText(Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_BORDER_GROWTH", turnsRemaining)))
				Controls.TurnsLeftLabel:SetText(turnsRemaining)
				Controls.GrowthHexStack:CalculateSize()
				m_GrowthHexTextWidth = Controls.GrowthHexStack:GetSizeX()

				local plotX, plotY = Map.GetPlotLocation(m_GrowthPlot)
				local worldX, worldY, worldZ = UI.GridToWorld(plotX, plotY)
				Controls.GrowthHexAnchor:SetWorldPositionVal(worldX, worldY+15, worldZ)

				Controls.GrowthHexAnchor:SetHide(false)
				Controls.GrowthHexAlpha:SetToBeginning()
				Controls.GrowthHexAlpha:Play()
			end
		end
	end
end
-- ===========================================================================
-- ===========================================================================
function ShowCityYields(tPlots)

	m_YieldPlots = tPlots
	local yields = {}

	for _, plotId in ipairs(tPlots) do
		local plot = Map.GetPlotByIndex(plotId)
		for row in GameInfo.Yields() do
			local yieldAmt = plot:GetYield(row.Index)
			if yieldAmt > 0 then
				table.insert(yields, plotId)
			end			
		end			
	end

	UILens.SetLayerHexesArea(m_CityYields, Game.GetLocalPlayer(), yields)
	UILens.ToggleLayerOn(m_CityYields)	
end
-- ===========================================================================
--	Obtain an existing instance of plot info or allocate one if it doesn't
--	already exist.
--	plotIndex	Game engine index of the plot
-- ===========================================================================
function GetInstanceAt(plotIndex)
	local pInstance = m_uiWorldMap[plotIndex]
	if pInstance == nil then
		pInstance = m_PlotIM:GetInstance()
		m_uiWorldMap[plotIndex] = pInstance
		local worldX, worldY = UI.GridToWorld(plotIndex)
		pInstance.Anchor:SetWorldPositionVal(worldX, worldY, 20)
		pInstance.Anchor:SetHide(false)
	end
	return pInstance
end
-- ===========================================================================
function ReleaseInstanceAt(plotIndex)
	local pInstance = m_uiWorldMap[plotIndex]
	if pInstance ~= nil then
		pInstance.Anchor:SetHide(true)
		m_uiWorldMap[plotIndex] = nil
	end
end
-- ===========================================================================
-- ===========================================================================
function ShowCitizens(iPlayer, iCity)

	if iPlayer ~= Game.GetLocalPlayer() then return end
	if UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT then return end -- Check to see if a city is selected

	local pPlayer = Players[iPlayer]
	local pCity =  pPlayer:GetCities():FindID(iCity)
	local tPlots = Map.GetCityPlots():GetPurchasedPlots(pCity)
	local pCitizens = pCity:GetCitizens()	

	DisplayGrowthTile(pCity)
	ShowCityYields(tPlots)
end
-- ===========================================================================
-- ===========================================================================
function HideCitizens()
	if UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT then return end -- Check to see if a city is selected

	for iIndex, pInstance in pairs(m_uiWorldMap) do
		ReleaseInstanceAt(iIndex)
	end
	-- if m_GrowthPlot then 
	ClearGrowthTile()
	-- end
	if m_YieldPlots then
		UILens.ClearLayerHexes(m_CityYields)
		m_YieldPlots = nil
	end
	--UILens.ToggleLayerOff(m_CityYields)
end
--===========================================================================================
--	Initialize/Shutdown
--===========================================================================================
--	OnInit
------------------------------------------------------------------------------
function OnInit(bIsReload)
	if not ContextPtr:LookUpControl("/InGame/WorldViewControls") then
		Events.LoadScreenClose.Add(OnInit)
		m_bLoadScreenClose = true
		return
	end

	LuaEvents.CityBannerButton_OnEnter.Add(ShowCitizens)
	LuaEvents.CityBannerButton_OnExit.Add(HideCitizens)

	local pWorldView = ContextPtr:LookUpControl("/InGame/WorldViewControls")
	ContextPtr:ChangeParent(pWorldView)
end
------------------------------------------------------------------------------
--	OnShutdown
------------------------------------------------------------------------------
function OnShutdown()
	if m_bLoadScreenClose then
		Events.LoadScreenClose.Remove(OnInit)
	end
	LuaEvents.CityBannerButton_OnEnter.Remove(ShowCitizens)
	LuaEvents.CityBannerButton_OnExit.Remove(HideCitizens)
end
-- ===========================================================================
--	Initialize
-- ===========================================================================
function Initialize()
	ContextPtr:SetInitHandler(OnInit)
	ContextPtr:SetShutdown(OnShutdown)
	ContextPtr:SetHide(false)
end
Initialize()
-- ===========================================================================
-- ===========================================================================