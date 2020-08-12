-- Suk_CustomEventUtils
-- Author: Sukritact

-- RIP Cross-Context LuaEvents, you will be sorely missed.

-- IMPORTANT:
-- IF YOU ARE INCLUDING THIS FILE AND USING ContextPtr:SetShutdown, YOUR SHUTDOWN FUNCTION
-- **MUST** INCLUDE ExposedMembers.SukEvents TO CLEAR THE CACHE ON RELOAD.
--==========================================================================================================================
if ExposedMembers.SukEvents then return end
--==========================================================================================================================
-- Parent Event Container:
-- the equivalent of the LuaEvents table
-- should create and return a custom event on acessing a new index
--==========================================================================================================================
C_SukCustomEvents_Parent = {}
function C_SukCustomEvents_Parent.new()
	self = {}
	setmetatable(self, C_SukCustomEvents_Parent)
	return self
end
function C_SukCustomEvents_Parent:__index(sKey)
	self[sKey] = C_SukCustomEvent.new(sKey)
	return self[sKey]
end
--==========================================================================================================================
-- Custom Event Class
--==========================================================================================================================
C_SukCustomEvent = {}
C_SukCustomEvent.__index = C_SukCustomEvent
function C_SukCustomEvent.new(sName)
	self = {}; setmetatable(self, C_SukCustomEvent)

	self.name = sName;
	self.functions = {}

	return self
end
function C_SukCustomEvent:__call(...)
	for _, ffunc in pairs(self.functions) do
		local status, err = pcall(ffunc, unpack(arg))
		if not status then print(err) end
	end
end
------------------------------------------
-- Mimic the behavior of vanilla functions
------------------------------------------
function C_SukCustomEvent:Call()
	self()
end

function C_SukCustomEvent:Add(ffunc)
	if type(ffunc) ~= "function" then
		error("function expected, got " .. type(ffunc))
		return
	end

	table.insert(self.functions, ffunc)
end

function C_SukCustomEvent:Remove(ffunc)
	if type(ffunc) ~= "function" then
		error("function expected, got " .. type(ffunc))
		return
	end

	for iKey, ffunc2 in pairs(self.functions) do
		if ffunc == ffunc2 then
			table.remove(self.functions, iKey)
			break
		end
	end
end

function C_SukCustomEvent:RemoveAll()
	self.functions = {}
end

function C_SukCustomEvent:Count()
	return #self.functions
end
--==========================================================================================================================
-- Clean ExposedMembers on Hotload
--==========================================================================================================================
function Suk_UtilsOnShutdown()
	ExposedMembers.SukEvents = nil
end
--==========================================================================================================================
-- Initialise
--==========================================================================================================================
ExposedMembers.SukEvents = C_SukCustomEvents_Parent.new()
ContextPtr:SetShutdown(Suk_UtilsOnShutdown)
--==========================================================================================================================
--==========================================================================================================================