-- Suk_CQUI_CityPanel
-- Author: Sukrit
-- DateCreated: 6/26/2020 3:56:36 AM
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
include("CityPanel_Expansion2.lua");
if not g_growthPlotId then include("CityPanel_Expansion1.lua") end
if not g_growthPlotId then include("CityPanel.lua") end
-- ===========================================================================
-- ===========================================================================
tYieldControls = {
	FoodGrid		= 0,
	ProductionGrid	= 1,
	GoldGrid		= 2,
	ScienceGrid		= 3,
	CultureGrid		= 4,
	FaithGrid		= 5,
}

SortYieldControls = function(tA, tB)
	return(tYieldControls[tA:GetID()] < tYieldControls[tB:GetID()])
end
------------------------------
OLD_ViewMain = ViewMain
------------------------------
function ViewMain( kData )
	if OLD_ViewMain then OLD_ViewMain(kData) end

	Controls.YieldStack:SortChildren(SortYieldControls);

	local toPlusMinus = function(value) return Locale.ToNumber(value, "+#,###.#;-#,###.#") end
	LuaEvents.SetSuk_YieldTooltip(Controls.CultureGrid,		kData.YieldFilters[YieldTypes.CULTURE],		toPlusMinus(kData.CulturePerTurn),		kData.CulturePerTurnToolTip);
	LuaEvents.SetSuk_YieldTooltip(Controls.FaithGrid,		kData.YieldFilters[YieldTypes.FAITH],		toPlusMinus(kData.FaithPerTurn),		kData.FaithPerTurnToolTip);
	--LuaEvents.SetSuk_YieldTooltip(Controls.FoodGrid,		kData.YieldFilters[YieldTypes.FOOD],		toPlusMinus(totalFood),					realFoodPerTurnToolTip); -- different here
	LuaEvents.SetSuk_YieldTooltip(Controls.GoldGrid,		kData.YieldFilters[YieldTypes.GOLD],		toPlusMinus(kData.GoldPerTurn),			kData.GoldPerTurnToolTip);
	LuaEvents.SetSuk_YieldTooltip(Controls.ProductionGrid,	kData.YieldFilters[YieldTypes.PRODUCTION],	toPlusMinus(kData.ProductionPerTurn),	kData.ProductionPerTurnToolTip);
	LuaEvents.SetSuk_YieldTooltip(Controls.ScienceGrid,		kData.YieldFilters[YieldTypes.SCIENCE],		toPlusMinus(kData.SciencePerTurn),		kData.SciencePerTurnToolTip);

	if kData.FoodSurplus >= 0 then
		local iGrowthModifier =  math.max(1 + (kData.HappinessGrowthModifier/100) + kData.OtherGrowthModifiers, 0) -- This is unintuitive but it's in parity with the logic in City_Growth.cpp
		local iModifiedFood_A = Round(kData.FoodSurplus * iGrowthModifier, 2)
		local iModifiedFood_H = iModifiedFood_A * kData.HousingMultiplier

		Controls.FoodCheck:GetTextButton():SetText("[ICON_Food]"..toPlusMinusString(iModifiedFood_H))

		local tToolTip = {}
		table.insert(tToolTip, kData.FoodPerTurnToolTip)
		table.insert(tToolTip, Locale.Lookup(
			"LOC_SUK_CITY_YIELD_FROM_POPULATION_TOOLTIP",
			toPlusMinus(kData.FoodSurplus - kData.FoodPerTurn)
		))
		table.insert(tToolTip, Locale.Lookup(
			"LOC_SUK_CITY_YIELD_FROM_HAPPINESS_TOOLTIP",
			toPlusMinus(iGrowthModifier * 100 - 100),
			toPlusMinus(iModifiedFood_A - kData.FoodSurplus)
		))
		table.insert(tToolTip, Locale.Lookup(
			"LOC_SUK_CITY_YIELD_FROM_HOUSING_TOOLTIP",
			toPlusMinus(kData.HousingMultiplier * 100 - 100),
			toPlusMinus(iModifiedFood_H - iModifiedFood_A)
		))

		local sFoodTT = table.concat(tToolTip, "[NEWLINE]");
		RealizeYield3WayCheck( kData.YieldFilters[YieldTypes.FOOD], YieldTypes.FOOD, sFoodTT)
		LuaEvents.SetSuk_YieldTooltip(Controls.FoodGrid, kData.YieldFilters[YieldTypes.FOOD], toPlusMinus(iModifiedFood_H), sFoodTT)
	else
		Controls.FoodCheck:GetTextButton():SetText("[ICON_Food]"..toPlusMinusString(kData.FoodSurplus))

		local tToolTip = {}
		table.insert(tToolTip, kData.FoodPerTurnToolTip)
		table.insert(tToolTip, Locale.Lookup("LOC_SUK_CITY_YIELD_FROM_POPULATION_TOOLTIP", toPlusMinusString(-(kData.FoodPerTurn - kData.FoodSurplus)) ))

		local sFoodTT = table.concat(tToolTip, "[NEWLINE]");
		RealizeYield3WayCheck( kData.YieldFilters[YieldTypes.FOOD], YieldTypes.FOOD, sFoodTT)
		LuaEvents.SetSuk_YieldTooltip(Controls.FoodGrid, kData.YieldFilters[YieldTypes.FOOD], toPlusMinus(kData.FoodSurplus), sFoodTT)
	end
end
-- ===========================================================================
-- ===========================================================================