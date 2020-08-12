--=================================================================================================================
-- Suk_ScreenshotMode_Controls
--=================================================================================================================
--	CONSTANTS/GLOBALS
--===========================================================================================
function ResetConstants()
	m_bIsAltDown = false
	m_isMouseDragging = false
	m_isMouseDownInWorld = false
	m_MouseCurrentX = 0
	m_MouseCurrentY = 0
	m_currentRotation = 0
	m_currentTilt = 45
	m_currentPanX = 0
	m_currentPanY = 0
end
local m_PanSpeed = 0.1

local m_RotateDistance = math.pi/2
local m_RotateSpeed = 0.01 * m_RotateDistance

local m_TiltMin	= 20; -- You can technically go beyond this, but just limit it.
local m_TiltMax	= 60; -- If you go too far past this value the game will crash.
local m_TiltDistance = (m_TiltMax - m_TiltMin)/2
local m_TiltSpeed = 0.01 * m_TiltDistance


local m_KeysToCatch = {
	[Keys.VK_ESCAPE] = true,
	[Keys.VK_ALT] = true,

	[Keys.Z] = true,
	[Keys.C] = true,

	[Keys.Q] = true,
	[Keys.E] = true,

	[Keys.A] = true,
	[Keys.S] = true,
	[Keys.D] = true,
	[Keys.F] = true,
}
--===========================================================================================
--	UpdateTilt/Rotation
--===========================================================================================
--	UpdateTilt
--	Tilt needs to be clamped before use
-----------------------------------------------------------
function UpdateTilt(iDelta)
	m_currentTilt = m_currentTilt + iDelta
	m_currentTilt = math.max(m_currentTilt, m_TiltMin)
	m_currentTilt = math.min(m_currentTilt, m_TiltMax)
	UI.SetFixedTiltAngle(m_currentTilt)
end

function UpdateRotation(iDelta)
	m_currentRotation = m_currentRotation + iDelta
	UI.SpinMap(m_currentRotation, 0)
end
--===========================================================================================
--	InputHandlers
--===========================================================================================
-- DefaultKeyDownHandler
-----------------------------------------------------------
function DefaultKeyDownHandler( pInputStruct )
	if not ExposedMembers.Suk_IsScreenshotMode then return false end

	local uiKey	= pInputStruct:GetKey()
	if uiKey == Keys.VK_ALT then
		m_bIsAltDown = true
		return true
	end

	if uiKey == Keys.Z then
		UpdateTilt(-m_TiltSpeed)
	elseif
		uiKey == Keys.C then
		UpdateTilt(m_TiltSpeed)
	end

	if uiKey == Keys.Q then
		UpdateRotation(-m_RotateSpeed)
	elseif uiKey == Keys.E then
		UpdateRotation(m_RotateSpeed)
	end

	if uiKey == Keys.A then
		m_currentPanX = -m_PanSpeed
	elseif uiKey == Keys.D then
		m_currentPanX = m_PanSpeed
	end
	if uiKey == Keys.S then
		m_currentPanY = -m_PanSpeed
	elseif uiKey == Keys.W then
		m_currentPanY = m_PanSpeed
	end
	UI.PanMap(m_currentPanX, m_currentPanY)

	return m_KeysToCatch[uiKey]
end
-----------------------------------------------------------
-- DefaultKeyUpHandler
-----------------------------------------------------------
function DefaultKeyUpHandler( pInputStruct )
	local uiKey	= pInputStruct:GetKey()
	if not ExposedMembers.Suk_IsScreenshotMode then return false end

	------------------------------

	if uiKey == Keys.VK_ESCAPE then
		if ExitScreenshotMode() then return true end
	end
	if uiKey == Keys.VK_ALT  then
		m_bIsAltDown = false
	end

	-----------------------------

	if uiKey == Keys.A or uiKey == Keys.D  then
		m_currentPanX = 0
	end
	if uiKey == Keys.W or uiKey == Keys.S  then
		m_currentPanY = 0
	end
	UI.PanMap(m_currentPanX, m_currentPanY)

	return m_KeysToCatch[uiKey]
end
-----------------------------------------------------------
-- OnMouseStart
-----------------------------------------------------------
function OnMouseStart( pInputStruct)
	if not ExposedMembers.Suk_IsScreenshotMode then return end
	if not m_bIsAltDown then return end

	m_MouseCurrentX, m_MouseCurrentY	= UIManager:GetNormalizedMousePos()
	m_isMouseDownInWorld = true
	m_isMouseDragging = true

	return true
end
-----------------------------------------------------------
-- OnMouseEnd
-----------------------------------------------------------
function OnMouseEnd(pInputStruct)

	if not ExposedMembers.Suk_IsScreenshotMode then return end

	m_MouseCurrentX		= 0
	m_MouseCurrentY		= 0

	if m_isMouseDragging then
		m_isMouseDragging = false
	end
	m_isMouseDownInWorld = false
	return true
end
-----------------------------------------------------------
-- OnMouseMove
-----------------------------------------------------------
function OnMouseMove(pInputStruct)

	if not ExposedMembers.Suk_IsScreenshotMode then return false end
	if not m_isMouseDownInWorld then return false end

	if m_isMouseDragging then
		if m_bIsAltDown then

			local x, y = UIManager:GetNormalizedMousePos()

			UpdateRotation((x - m_MouseCurrentX) * m_RotateDistance)
			m_MouseCurrentX = x

			UpdateTilt((y - m_MouseCurrentY) * m_TiltDistance)
			m_MouseCurrentY = y

			return true
		end
	end

	return false
end
-----------------------------------------------------------
-- DefaultMessageHandler
-----------------------------------------------------------
DefaultMessageHandler = {}
DefaultMessageHandler[KeyEvents.KeyUp]			= DefaultKeyUpHandler
DefaultMessageHandler[KeyEvents.KeyDown]		= DefaultKeyDownHandler
DefaultMessageHandler[MouseEvents.LButtonDown]	= OnMouseStart
DefaultMessageHandler[MouseEvents.LButtonUp]	= OnMouseEnd
DefaultMessageHandler[MouseEvents.MouseMove]	= OnMouseMove
--===========================================================================================
--	OnInputHandler
--===========================================================================================
function OnInputHandler(pInputStruct)
	local uiMsg = pInputStruct:GetMessageType()
	local isHandled = false

	if DefaultMessageHandler[uiMsg] then
		isHandled = DefaultMessageHandler[uiMsg](pInputStruct)
	end
	return isHandled
end
--===========================================================================================
--	OnInputActionTriggered
--===========================================================================================
function OnInputActionTriggered(actionId)
	if m_ToggleVisibilityAction == actionId then
		if ExposedMembers.Suk_IsScreenshotMode then
			ExitScreenshotMode()
		else
			EnterScreenshotMode()
		end
	end
end
--=================================================================================================================
--=================================================================================================================