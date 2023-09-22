--- @class EminentDKP
local addon = select(2, ...)

--- @class EminentDKPSessionFrame : AceTimer-3.0, AceEvent-3.0
local EminentDKPSessionFrame = addon:NewModule("EminentDKPSessionFrame", "AceTimer-3.0", "AceEvent-3.0")

local ST = LibStub("ScrollingTable")
local L = LibStub("AceLocale-3.0"):GetLocale("EminentDKP")

local ROW_HEIGHT = 40
local awardLater = false
local loadingItems = false

--- Lua
local getglobal, ipairs, tinsert =
		getglobal, ipairs, tinsert

-- GLOBALS: CreateFrame, IsModifiedClick, HandleModifiedItemClick, InCombatLockdown, _G

function EminentDKPSessionFrame:OnInitialize()
    addon.Log("Session frame initialized")
    self.scrollCols = {
		{ name = "", width = 30}, 				-- remove item, sort by session number.
		{ name = "", width = ROW_HEIGHT},	-- item icon
		{ name = "", width = 50,}, 	-- item lvl
		{ name = "", width = 160}, 			-- item link
	}
end

function EminentDKPSessionFrame:OnEnable()
    addon.Log("Session frame enabled")
end

function EminentDKPSessionFrame:OnDisable()
end

function EminentDKPSessionFrame:Show(data)
    self.frame = self:GetFrame()
    self.frame:Show()

	if data then

	end
end

function EminentDKPSessionFrame:Hide()
    self.frame:Hide()
end

function EminentDKPSessionFrame.SetCellText(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	if frame.text:GetFontObject() ~= _G.GameFontNormal then
		frame.text:SetFontObject("GameFontNormal") -- We want bigger font
	end
	if not data[realrow].link then
		frame.text:SetText("--".._G.RETRIEVING_ITEM_INFO.."--")
		loadingItems = true
		if not scheduledToShowAgain then -- Dont make unneeded scheduling
			scheduledToShowAgain = true
			RCSessionFrame:ScheduleTimer("Show", 0, ml.lootTable) -- Try again next frame
		end
	else
		frame.text:SetText(data[realrow].link..(data[realrow].owner and "\n"..addon:GetUnitClassColoredName(data[realrow].owner) or ""))
	end
end

function EminentDKPSessionFrame.SetCellDeleteBtn(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	frame:SetNormalTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Up.png")
	frame:SetScript("OnClick", function () print('delete item') end)
	frame:SetSize(20,20)
end

function EminentDKPSessionFrame.SetCellItemIcon(rowFrame, frame, data, cols, rows, realrow, column, fShow, table, ...)
	local texture = data[realrow].texture or "Interface/ICONS/INV_Sigil_Thorim.png"
	local link = data[realrow].link
	frame:SetNormalTexture(texture)
	frame:SetScript("OnEnter", function() print('OnEnter') end)
	frame:SetScript("OnLeave", function() print('hide tooltip') end)
	frame:SetScript("OnClick", function()
		if IsModifiedClick() then
			HandleModifiedItemClick(link)
		end
	end)
end

function EminentDKPSessionFrame:GetFrame()
    if self.frame then return self.frame end

    local f = EminentDKP.UI:NewNamed("EminentDKPFrame", UIParent, "DefaultEminentDKPSessionSetupFrame", "EminentDKP Session Setup", 260)
	addon.UI:RegisterForEscapeClose(f, function() if self:IsEnabled() then self:Disable() end end)
	local tgl = CreateFrame("CheckButton", f:GetName().."Toggle", f.content, "ChatConfigCheckButtonTemplate")
	getglobal(tgl:GetName().."Text"):SetText("Award later?")
	tgl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 40)
	tgl.tooltip = "Check this to loot the items and distribute them later."
	tgl:SetChecked(awardLater)
	tgl:SetScript("OnClick", function() awardLater = not awardLater; end )
	f.toggle = tgl

	-- Start button
	local b1 = addon:CreateButton(_G.START, f.content)
	b1:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
	b1:SetScript("OnClick", function()
		if loadingItems then
			return addon.Log("You can't start a session before all items are loaded!")
		end
		if not ml.lootTable or #ml.lootTable == 0 then
			addon:Print("You cannot start an empty session.")
			addon.Log:D("Player tried to start empty session.")
			return
		end
		if awardLater then
			local sessionAwardDoneCount = 0
			waitingToEndSessions = true
			for session in ipairs(ml.lootTable) do
				ml:Award(session, nil, nil, nil, function()
					sessionAwardDoneCount = sessionAwardDoneCount + 1
					if sessionAwardDoneCount >= #ml.lootTable then
						waitingToEndSessions = false
						ml:EndSession()
					end
				end)
			end
		else
			if InCombatLockdown() and not addon.db.profile.skipCombatLockdown then
				return addon:Print(L["You can't start a loot session while in combat."])
			else
				addon:Print("start session")
			end
		end
		self:Disable()
	end)
	f.startBtn = b1

	-- Cancel button
	local b2 = addon:CreateButton(_G.CANCEL, f.content)
	b2:SetPoint("LEFT", b1, "RIGHT", 15, 0)
	b2:SetScript("OnClick", function()
		-- Modified
		-- if not ml.running then -- Don't clear lootTable on a running session.
		--	ml.lootTable = {}
		-- end
		self:Disable()
	end)
	f.closeBtn = b2

	-- Loot Status
	f.lootStatus = addon.UI:New("Text", f.content, " ")
	f.lootStatus:SetTextColor(1,1,1,1) -- White for now
	f.lootStatus:SetHeight(20)
	f.lootStatus:SetWidth(75)
	-- f.lootStatus:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 14)
	f.lootStatus:SetPoint("LEFT", f.closeBtn, "RIGHT", 13, 1)
	-- MODIFIED
	-- f.lootStatus:SetScript("OnLeave", addon.Utils.HideTooltip)
	f.lootStatus.text:SetJustifyH("LEFT")

	local st = ST:CreateST(self.scrollCols, 5, ROW_HEIGHT, nil, f.content)
	st.head:SetHeight(0)
	st.frame:SetPoint("TOPLEFT",f,"TOPLEFT",10,-20)
	st:RegisterEvents({
		["OnClick"] = function(_, _, _, _, row, realrow)
			if not (row or realrow) then
				return true
			end
		end
	})
	f:SetWidth(st.frame:GetWidth()+20)
	f:SetHeight(305)
	f.rows = {} -- the row data
	f.st = st
	return f
end

function EminentDKPSessionFrame:ExtractData(data)
	self.frame.rows = {}
	for k,v in ipairs(data) do
		tinsert(self.frame.rows, {
			session = k,
			texture = v.texture or nil,
			link = v.link,
			owner = v.owner,
			cols = {
				{ DoCellUpdate = self.SetCellDeleteBtn, },
				{ DoCellUpdate = self.SetCellItemIcon, },
				{ value = "666", },
				{ DoCellUpdate = self.SetCellText }
			}
		})
	end
end