
--- @class EminentDKP
local addon = select(2, ...)
local private = { elements = {}, num = {}, embeds = {}, }
EminentDKP.UI = { CreateFrame = _G.CreateFrame, private = private, minimizeableFrames = {}}

local error, format, type, pairs = error, format, type, pairs

-- Exposed function for creating new UI elements
--- @generic T
--- @param type `T` The type of the element.
--- @param parent UIObject The element's UI parant. Defaults to UIParent
--- @return T UIObject The newly created UI element
function EminentDKP.UI:New(type, parent, ...)
   return private:New(type, parent, nil, ...)
end

--- Exposed function for creating new named UI elements
--- @generic T
--- @param type `T` The type of the element.
--- @param parent UIObject The element's UI parant. Defaults to UIParent
--- @param name string  The global name of the element.
--- @return T UIObject The newly created UI element
function EminentDKP.UI:NewNamed(type, parent, name, ...)
   return private:New(type, parent, name, ...)
end

function EminentDKP.UI.HideTooltip()
   EminentDKP:HideTooltip()
end

-- Registers a new element
function EminentDKP.UI:RegisterElement(object, etype)
   if type(object) ~= "table" then error("RCLootCouncil.UI:RegisterElement() - 'object' isn't a table.") end
   if type(etype) ~= "string" then error("RCLootCouncil.UI:RegisterElement() - 'type' isn't a string.") end
   private.elements[etype] = object
end

function EminentDKP.UI:RegisterForCombatMinimize(frame)
   tinsert(self.minimizeableFrames, frame)
end


function EminentDKP.UI:RegisterForEscapeClose(frame, OnHide)
	if not addon:Getdb().closeWithEscape then return end
   tinsert(UISpecialFrames, frame:GetName())
   frame:SetScript("OnHide", OnHide)
end

---------------------------------------------
-- Internal functions
---------------------------------------------
function private:New(type, parent, name, ...)
   if self.elements[type] then
      parent = parent or _G.UIParent
      if name then
         return self:Embed(self.elements[type]:New(parent, name, ...))
      else
         -- Create a name
         if not self.num[type] then self.num[type] = 0 end
         self.num[type] = self.num[type] + 1
         return self:Embed(self.elements[type]:New(parent, "EminentDKP_UI_"..type..self.num[type], ...))
      end
   else
      error(format("UI Error in :New(): No such element: %s %s", type, name))
   end
end

--- @generic T
--- @param object `T`
--- @return T
function private:Embed(object)
   for k,v in pairs(self.embeds) do
      object[k] = v
   end
   return object
end


--- @class UI.embeds
private.embeds = {
   ---@param object T self
   ---@param scripts table<string,fun(self: T): void>
   SetMultipleScripts = function(object, scripts)
      for k,v in pairs(scripts) do
         object:SetScript(k,v)
      end
   end
}
