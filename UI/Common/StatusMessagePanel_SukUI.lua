-- StatusMessagePanel_SukUI
-- Author: Sukrit
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
include("StatusMessagePanel.lua");
-- ===========================================================================
-- OnWorldTextMessage
-- Format for calling this is Game.AddWorldViewText(iType, iSubType, -1, -1, sMessage)
-- ===========================================================================
function OnWorldTextMessage(iType, iSubType, iX, iY, sMessage)
	--print(iType, sMessage, iX, iY, iSubType)
	OnStatusMessage(sMessage, 7, iType, iSubType)
end
-- ===========================================================================
-- LateInitialize
-- ===========================================================================
BASE_LateInitialize = LateInitialize

function LateInitialize()
	if LateInitialize then BASE_LateInitialize() end
	Events.WorldTextMessage.Add(OnWorldTextMessage)
	LuaEvents.Custom_StatusMessage.Add(OnStatusMessage)
end
-- ===========================================================================
-- OnShutdown
-- ===========================================================================
BASE_OnShutdown = OnShutdown
function OnShutdown()
	if BASE_OnShutdown then BASE_OnShutdown() end
	Events.WorldTextMessage.Remove(OnWorldTextMessage)
	LuaEvents.Custom_StatusMessage.Remove(OnStatusMessage)

end
ContextPtr:SetShutdown(OnShutdown)
-- ===========================================================================
-- ===========================================================================