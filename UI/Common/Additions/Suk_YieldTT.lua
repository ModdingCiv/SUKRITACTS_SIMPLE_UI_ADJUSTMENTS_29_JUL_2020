-- Suk_ReligionTT
-- Author: Sukrit
-- DateCreated: 10/20/2017 4:30:19 PM
--------------------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );


local m_Suk_Yield_TT = {}; TTManager:GetTypeControlTable("Suk_Yield_TT", m_Suk_Yield_TT)
m_Suk_EntriesIM = InstanceManager:new("Suk_EntryInstance", "BG", m_Suk_Yield_TT.EntriesStack)
--------------------------------------------------------------
-- Utils
--------------------------------------------------------------
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

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
-- TTtoTable
--------------------------------------------------------------
function TTtoTable(sTT)
	local tTT = {}

	for _, sLine in ipairs(split(sTT, "%s*%[NEWLINE%]%s*")) do
		tLine = {}

		local bBullet = false
		if string.find(sLine, "^%[ICON_Bullet%]") then
			table.insert(tLine, "")
			sLine = string.gsub(sLine, "^%[ICON_Bullet%]%s*", "")
			bBullet = true
		end

		local sPercentPattern = "(%+*%-*%d*%.?%d+)%%%s*%((%+*%-*%d*%.?%d+)%)%s*"
		local sPercentOnlyPattern = "(%+*%-*%d*%.?%d+)%%%s*(.*)"
		local sPattern = "(%+*%-*%d*%.?%d+)%s*(.*)"
		if string.find(sLine, sPercentPattern) then
			iPercent, iNum = string.match(sLine, sPercentPattern)

			table.insert(tLine, iNum)
			table.insert(tLine, iPercent .. "%")

			sLine = string.gsub(sLine, sPercentPattern, "")
			table.insert(tLine, sLine)
		elseif string.find(sLine, sPercentOnlyPattern) then
			iNum, sString = string.match(sLine, sPercentOnlyPattern)
			table.insert(tLine, "")
			table.insert(tLine, iNum .. "%")
			table.insert(tLine, sString)
		else
			iNum, sString = string.match(sLine, sPattern)

			table.insert(tLine, iNum)
			if not bBullet then table.insert(tLine, "") end
			table.insert(tLine, sString)
		end

		table.insert(tTT, tLine)
	end

	return tTT
end
--------------------------------------------------------------
-- UpdateSuk_YieldTooltip
--------------------------------------------------------------
function UpdateSuk_YieldTooltip(tControl, iYieldFilter, iYieldIncome, sTooltip_Base)

	tEntries = TTtoTable(sTooltip_Base)
	m_Suk_EntriesIM:ResetInstances()

	local tInstances = {}
	local sYieldName = string.match(tControl:GetID(), "(.+)Grid")
	local tYieldData = GameInfo.Yields["YIELD_" .. string.upper(sYieldName)]
	local sFontIcon = " [ICON_" .. sYieldName .. "]"
	local tYieldState = {
		"LOC_HUD_CITY_YIELD_CITIZENS",
		"LOC_HUD_CITY_YIELD_FOCUSING",
		"LOC_HUD_CITY_YIELD_IGNORING",
	}

	m_Suk_Yield_TT.YieldLabel:SetText(iYieldIncome.." [ICON_"..sYieldName.."large] "..Locale.ToUpper(Locale.Lookup(tYieldData.Name)))
	m_Suk_Yield_TT.FocusLabel:LocalizeAndSetText(tYieldState[iYieldFilter + 1], tYieldData.Name)

	local iCol1, iCol2, iCol3 = 0,0,0
	local bFirst = true
	for iIndex, tEntry in ipairs(tEntries) do
		if #tEntry > 1 then
			tInstance = m_Suk_EntriesIM:GetInstance()

			if bFirst or string.len(tEntry[1] or "") < 1 then 
				bFirst = false
				tInstance.Divider_H:SetHide(true)
			else
				tInstance.Divider_H:SetHide(false)
			end

			if string.len(tEntry[1] or "") > 0 then tEntry[1] = tEntry[1] .. sFontIcon end
			if string.len(tEntry[2] or "") > 0 then
				if string.find(tEntry[2], "%%") then
					tEntry[2] = "("..tEntry[2]..")"
				else
					tEntry[2] = tEntry[2]..sFontIcon
				end
			end

			tInstance.Col1:SetText(tEntry[1]); iCol1 = math.max(iCol1, tInstance.Col1:GetSizeX());
			tInstance.Col2:SetText(tEntry[2]); iCol2 = math.max(iCol2, tInstance.Col2:GetSizeX());
			tInstance.Col3:SetText(tEntry[3]); iCol3 = math.max(iCol3, tInstance.Col3:GetSizeX());

			iRow = math.max(tInstance.Col1:GetSizeY(), tInstance.Col2:GetSizeY(), tInstance.Col3:GetSizeY()) + 4;
			tInstance.Col1Box:SetSizeY(iRow)
			tInstance.Col2Box:SetSizeY(iRow)
			tInstance.Col3Box:SetSizeY(iRow)

			tInstance.Divider_V:SetSizeY(iRow+4)
			tInstance.Divider_V2:SetSizeY(iRow+4)

			table.insert(tInstances, tInstance)
		end
	end

	local iPadding = (280 - (iCol1 + iCol2 + iCol3))/4
	for _, tInstance in pairs(tInstances) do
		tInstance.Col1Box:SetSizeX(iCol1); tInstance.Col1Box:SetOffsetX(iPadding); 
		tInstance.Col2Box:SetSizeX(iCol2); tInstance.Col2Box:SetOffsetX(iPadding); 
		tInstance.Col3Box:SetSizeX(iCol3 + iPadding); tInstance.Col3Box:SetOffsetX(iPadding);

		tInstance.Divider_V:SetOffsetX(-iPadding/2)
		tInstance.Divider_V2:SetOffsetX(-iPadding/2)
	end
end

LuaEvents.UpdateSuk_YieldTooltip.Add(UpdateSuk_YieldTooltip)
--------------------------------------------------------------
-- SetSuk_YieldTooltip
--------------------------------------------------------------
function SetSuk_YieldTooltip(tControl, iYieldFilter, iYieldIncome, sTooltip_Base)
	tControl:SetToolTipType("Suk_Yield_TT")
	tControl:ClearToolTipCallback()
	tControl:SetToolTipCallback(
		function()
			LuaEvents.UpdateSuk_YieldTooltip(tControl, iYieldFilter, iYieldIncome, sTooltip_Base)
		end
	);
end

LuaEvents.SetSuk_YieldTooltip.Add(SetSuk_YieldTooltip)
-- ===========================================================================
--	Initialise
-- ===========================================================================
function Initialise()
	ContextPtr:SetHide(false)
end
Events.LoadScreenClose.Add(Initialise)
-- ===========================================================================
-- ===========================================================================