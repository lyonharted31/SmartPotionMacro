local ADDON_NAME = ...
local MACRO_ICON = "INV_Misc_QuestionMark"
local statusText

local defaults = {
    debug = false,
    macroName = "SmartPotion",
    useGeneralMacro = true,
    noPotionBehavior = "leave",
}

local function GetMacroName()
    if SmartPotionMacroDB and SmartPotionMacroDB.macroName then
        return SmartPotionMacroDB.macroName
    end
    return defaults.macroName
end

local POTION_PRIORITY = {
    245898, -- Fleeting Light's Potential (high quality)
    245897, -- Fleeting Light's Potential
    241308, -- Light's Potential (high quality)
    241309, -- Light's Potential
}

local function DebugPrint(message)
    if not SmartPotionMacroDB.debug then return end
    print("|cff66ccff" .. ADDON_NAME .. "|r: " .. message)
end

local function GetBestPotionID()
    for _, itemID in ipairs(POTION_PRIORITY) do
        if C_Item.GetItemCount(itemID) > 0 then
            return itemID
        end
    end

    return nil
end

local function InitializeDB()
    if not SmartPotionMacroDB then
        SmartPotionMacroDB = {}
    end

    for key, value in pairs(defaults) do
        if SmartPotionMacroDB[key] == nil then
            SmartPotionMacroDB[key] = value
        end
    end
end

local function BuildMacroBody(itemID)
    return "#showtooltip item:" .. itemID .. "\n/use [combat] item:" .. itemID
end

local function EnsureMacro(body, icon)
    local macroName = GetMacroName()
    if not macroName or macroName == "" then return end

    local macroIcon = icon or MACRO_ICON
    local macroIndex = GetMacroIndexByName(macroName)

    if macroIndex == 0 then
        local createdIndex = CreateMacro(macroName, macroIcon, body, not SmartPotionMacroDB.useGeneralMacro)
        if createdIndex then
            DebugPrint("Created macro '" .. macroName .. "'.")
        end
        return createdIndex
    end

    local _, existingIcon, existingBody = GetMacroInfo(macroIndex)

    if existingBody == body and existingIcon == macroIcon then
        DebugPrint("Macro already up to date.")
        return macroIndex
    end

    local editedIndex = EditMacro(macroIndex, nil, macroIcon, body)
    if editedIndex then
        DebugPrint("Updated macro '" .. macroName .. "'.")
    end

    return editedIndex
end

local function UpdatePotionMacro(reason)
    if InCombatLockdown() then
        DebugPrint("Skipped update during combat" .. (reason and " (" .. reason .. ")" or "") .. ".")
        return
    end

    local bestPotionID = GetBestPotionID()

    if not bestPotionID then
    DebugPrint("No supported potion found in bags.")

    local behavior = SmartPotionMacroDB.noPotionBehavior

    if behavior == "clear" then
        EnsureMacro("#showtooltip", "INV_Misc_QuestionMark")
    elseif behavior == "placeholder" then
        EnsureMacro(
            "#showtooltip\n/run print('No potion available')",
            "Inv_Potion_Empty"
        )
        print("|cffff4444SmartPotion: No potion available!|r")
    end

    return
end

    local macroBody = BuildMacroBody(bestPotionID)
    EnsureMacro(macroBody)

    local count = C_Item.GetItemCount(bestPotionID)
    DebugPrint("Selected item:" .. bestPotionID .. " x" .. count .. (reason and " after " .. reason or "") .. ".")
end

local function UpdateStatusText()
    if not statusText then return end

    local bestPotionID = GetBestPotionID()

    if bestPotionID then
        local baseName = C_Item.GetItemInfo(bestPotionID) or ("item:" .. bestPotionID)

local qualityLabel = ""
if bestPotionID == 245898 or bestPotionID == 241308 then
    qualityLabel = " (High Quality)"
end

local name = baseName .. qualityLabel
local count = C_Item.GetItemCount(bestPotionID)

statusText:SetText("Status: Using " .. name .. " (x" .. count .. ")")
        statusText:SetTextColor(0.4, 1, 0.4)
    else
        statusText:SetText("Status: No usable potion found")
        statusText:SetTextColor(1, 0.3, 0.3)
    end
end

local settingsCategory

local function CreateSettingsPanel()
    local categoryName = "Smart Potion Macro"

    local canvas = CreateFrame("Frame")
    canvas.name = categoryName

    local title = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(categoryName)

    local subtitle = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Options for the SmartPotion macro updater.")
	
	local note = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	note:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -8)
	note:SetText("Note: Macro updates only occur outside of combat.")
	note:SetTextColor(1, 0.82, 0) -- soft yellow

    local debugCheck = CreateFrame("CheckButton", nil, canvas, "InterfaceOptionsCheckButtonTemplate")
    debugCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    debugCheck.Text:SetText("Enable debug output")
    debugCheck:SetChecked(SmartPotionMacroDB.debug)
    debugCheck:SetScript("OnClick", function(self)
        SmartPotionMacroDB.debug = self:GetChecked()
    end)

    local generalCheck = CreateFrame("CheckButton", nil, canvas, "InterfaceOptionsCheckButtonTemplate")
    generalCheck:SetPoint("TOPLEFT", debugCheck, "BOTTOMLEFT", 0, -12)
    generalCheck.Text:SetText("Create as General macro")
    generalCheck:SetChecked(SmartPotionMacroDB.useGeneralMacro)
    generalCheck:SetScript("OnClick", function(self)
        SmartPotionMacroDB.useGeneralMacro = self:GetChecked()
    end)
	
	local dropdownLabel = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
dropdownLabel:SetPoint("TOPLEFT", generalCheck, "BOTTOMLEFT", 0, -24)
dropdownLabel:SetText("No potion behavior:")

local dropdown = CreateFrame("Frame", nil, canvas, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", -16, -4)

local options = {
    { text = "Leave unchanged", value = "leave" },
    { text = "Clear macro", value = "clear" },
    { text = "Show placeholder", value = "placeholder" },
}

UIDropDownMenu_SetWidth(dropdown, 160)

UIDropDownMenu_Initialize(dropdown, function(self, level)
    for _, option in ipairs(options) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.text
        info.value = option.value
        info.func = function()
            SmartPotionMacroDB.noPotionBehavior = option.value
            UIDropDownMenu_SetSelectedValue(dropdown, option.value)
        end
        UIDropDownMenu_AddButton(info)
    end
end)

UIDropDownMenu_SetSelectedValue(dropdown, SmartPotionMacroDB.noPotionBehavior)

    local updateButton = CreateFrame("Button", nil, canvas, "UIPanelButtonTemplate")
    updateButton:SetSize(140, 24)
    updateButton:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 20, -12)
    updateButton:SetText("Update Macro Now")
    updateButton:SetScript("OnClick", function()
        UpdatePotionMacro("settings button")
		UpdateStatusText()
    end)

statusText = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statusText:SetPoint("TOPLEFT", updateButton, "BOTTOMLEFT", 0, -16)
statusText:SetText("Status: Unknown")

    local category = Settings.RegisterCanvasLayoutCategory(canvas, categoryName, categoryName)
    Settings.RegisterAddOnCategory(category)
    settingsCategory = category
	
	UpdateStatusText()
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        InitializeDB()
        CreateSettingsPanel()
    end

    UpdatePotionMacro(event)
	UpdateStatusText()
end)

SLASH_SMARTPOTION1 = "/smartpotion"
SlashCmdList.SMARTPOTION = function(msg)
    msg = msg and msg:lower() or ""

    if msg == "debug" then
        SmartPotionMacroDB.debug = not SmartPotionMacroDB.debug
        print("|cff66ccff" .. ADDON_NAME .. "|r: Debug " .. (SmartPotionMacroDB.debug and "enabled." or "disabled."))
    elseif msg == "update" then
        UpdatePotionMacro("manual slash command")
    elseif msg == "" and settingsCategory then
        Settings.OpenToCategory(settingsCategory:GetID(), settingsCategory:GetID())
    else
        print("|cff66ccff" .. ADDON_NAME .. "|r commands:")
        print("  /smartpotion           - Open settings")
        print("  /smartpotion update    - Force macro update")
        print("  /smartpotion debug     - Toggle debug output")
    end
end