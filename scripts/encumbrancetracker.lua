-- This extension contains 5e SRD encumbrance rules.  For license details see file: Open Gaming License v1.0a.txt

MAX = "max"
ENCUMBRANCETRACKER_VERBOSE = "ENCUMBRANCETRACKER_VERBOSE"
OFF = "off"
USER_ISHOST = false

function onInit()
	local option_header = "option_header_encumbrancetracker"
	local option_val_off = "option_val_off"
	local option_entry_cycler = "option_entry_cycler"
	OptionsManager.registerOption2(ENCUMBRANCETRACKER_VERBOSE, false, option_header, "option_label_ENCUMBRANCETRACKER_VERBOSE", option_entry_cycler,
	{ baselabel = "option_val_max", baseval = MAX, labels = "option_val_standard|" .. option_val_off, values = "standard|" .. OFF, default = MAX })

	USER_ISHOST = User.isHost()

	if USER_ISHOST then
		CombatManager.setCustomTurnStart(onTurnStartEvent)

	end
end

function checkVariantEncumbrance()
    return OptionsManager.isOption("HREN", "variant")
end

function checkVerbosityMax()
	return OptionsManager.isOption(ENCUMBRANCETRACKER_VERBOSE, MAX)
end

function checkVerbosityOff()
	return OptionsManager.isOption(ENCUMBRANCETRACKER_VERBOSE, OFF)
end

-- Puts a message in chat that is broadcast to everyone attached to the host (including the host) if bSecret is true, otherwise local only.
function displayChatMessage(sFormattedText, bSecret)
	if not sFormattedText then return end

	local msg = {font = "msgfont", icon = "encumbrance_icon", text = sFormattedText}

	-- deliverChatMessage() is a broadcast mechanism, addChatMessage() is local only.
	if bSecret then
        msg.secret = true
		Comm.addChatMessage(msg)
	else
        msg.secret = false
		Comm.deliverChatMessage(msg, "")
	end
end

function displayTableIfNonEmpty(aTable)
	aTable = validateTableOrNew(aTable)
	if #aTable > 0 then
		local sDisplay = table.concat(aTable, "\r")
		displayChatMessage(sDisplay, true)
	end
end

-- This function is one that the Combat Tracker calls if present at the start of a creatures turn.  Wired up in onInit() for the host only.
function onTurnStartEvent(nodeCurrentCTActor) -- arg is CT node
	if checkVerbosityOff() then return end

    processEncumbranceForActor(nodeCurrentCTActor)
end

function processEncumbranceForActor(nodeCurrentCTActor)
	local rCurrentActor = ActorManager.resolveActor(nodeCurrentCTActor)
    local nodeCharSheet = DB.findNode(rCurrentActor.sCreatureNode)

    if rCurrentActor.sType == "charsheet" then
        local load = DB.getValue(nodeCharSheet, "encumbrance.load", -1)
        local strength = DB.getValue(nodeCharSheet, "abilities.strength.score", -1)
        local encumbered = strength * 5
        local heavy = strength * 10
        local max = strength * 15
        local aOutput = {}
        local sMsgText
        if load > max then
            sMsgText = "'" .. rCurrentActor.sName .. "' is over encumbered."
            table.insert(aOutput, sMsgText)
            sMsgText = "Load: " .. load .. " Max: " .. max
            table.insert(aOutput, sMsgText)
        elseif checkVariantEncumbrance() and load > heavy then
            sMsgText = "'" .. rCurrentActor.sName .. "' is heavily encumbered."
            table.insert(aOutput, sMsgText)
            sMsgText = "Load: " .. load .. " Heavy: " .. heavy
            table.insert(aOutput, sMsgText)
        elseif checkVariantEncumbrance() and load > encumbered then
            sMsgText = "'" .. rCurrentActor.sName .. "' is encumbered."
            table.insert(aOutput, sMsgText)
            sMsgText = "Load: " .. load .. " Encumbered: " .. encumbered
            table.insert(aOutput, sMsgText)
        elseif load > -1 then
            if checkVerbosityMax() then
                sMsgText = "'" .. rCurrentActor.sName .. "' is unencumbered."
                table.insert(aOutput, sMsgText)
            end
        else
            sMsgText = "'" .. rCurrentActor.sName .. "' could not be analyzed for encumbrance."
            table.insert(aOutput, sMsgText)
        end

        displayTableIfNonEmpty(aOutput)
    end
end

function validateTableOrNew(aTable)
	if aTable and type(aTable) == "table" then
		return aTable
	else
		return {}
	end
end
