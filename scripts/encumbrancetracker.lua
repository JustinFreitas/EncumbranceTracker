-- This extension contains 5e SRD encumbrance rules.  For license details see file: Open Gaming License v1.0a.txt

ENCUMBERED = "Encumbered"
ENCUMBERED_PATTERN_RAW = "[eE][nN][cC][uU][mM][bB][eE][rR][eE][dD]"
ENCUMBERED_PATTERN = "^%W*" .. ENCUMBERED_PATTERN_RAW .. "%W*$"
ENCUMBRANCETRACKER_MULTIPLIER_BEAR = "ENCUMBRANCETRACKER_MULTIPLIER_BEAR"
ENCUMBRANCETRACKER_MULTIPLIER_BURDEN = "ENCUMBRANCETRACKER_MULTIPLIER_BURDEN"
ENCUMBRANCETRACKER_MULTIPLIER_EQUINE = "ENCUMBRANCETRACKER_MULTIPLIER_EQUINE"
ENCUMBRANCETRACKER_RULE_DETAIL = "ENCUMBRANCETRACKER_RULE_DETAIL"
ENCUMBRANCETRACKER_STATS = "ENCUMBRANCETRACKER_STATS"
ENCUMBRANCETRACKER_UNCARRIED = "ENCUMBRANCETRACKER_UNCARRIED"
ENCUMBRANCETRACKER_VERBOSE = "ENCUMBRANCETRACKER_VERBOSE"
ENCUMBRANCETRACKER_ZERO_WEIGHT = "ENCUMBRANCETRACKER_ZERO_WEIGHT"
HEAVILY = "Heavily"
HEAVILY_ENCUMBERED = HEAVILY .. " " .. ENCUMBERED
HEAVILY_ENCUMBERED_PATTERN = "^%W*".. "[hH][eE][aA][vV][iI][lL][yY]" .. "%W+" .. ENCUMBERED_PATTERN_RAW .. "%W*$"
IS_FGU = true
MAX = "max"
OFF = "off"
ON = "on"
OVER = "Over"
OVER_ENCUMBERED = OVER .. " " .. ENCUMBERED
OVER_ENCUMBERED_PATTERN = "^%W*".. "[oO][vV][eE][rR]" .. "%W+" .. ENCUMBERED_PATTERN_RAW .. "%W*$"
USER_ISHOST = false

function onInit()
	local option_header = "option_header_encumbrancetracker"
	local option_val_off = "option_val_off"
	local option_val_on = "option_val_on"
	local option_entry_cycler = "option_entry_cycler"
	OptionsManager.registerOption2(ENCUMBRANCETRACKER_VERBOSE, false, option_header, "option_label_ENCUMBRANCETRACKER_VERBOSE", option_entry_cycler,
	{ baselabel = "option_val_max", baseval = MAX, labels = "option_val_standard|" .. option_val_off, values = "standard|" .. OFF, default = MAX })
    OptionsManager.registerOption2(ENCUMBRANCETRACKER_RULE_DETAIL, false, option_header, "option_label_ENCUMBRANCETRACKER_RULE_DETAIL", option_entry_cycler,
    { labels = option_val_off, values = OFF, baselabel = "option_val_on", baseval = ON, default = ON })
    OptionsManager.registerOption2(ENCUMBRANCETRACKER_STATS, false, option_header, "option_label_ENCUMBRANCETRACKER_STATS", option_entry_cycler,
    { labels = option_val_off, values = OFF, baselabel = "option_val_on", baseval = ON, default = ON })
    OptionsManager.registerOption2(ENCUMBRANCETRACKER_ZERO_WEIGHT, false, option_header, "option_label_ENCUMBRANCETRACKER_ZERO_WEIGHT", option_entry_cycler,
    { labels = option_val_off, values = OFF, baselabel = "option_val_on", baseval = ON, default = ON })
    OptionsManager.registerOption2(ENCUMBRANCETRACKER_UNCARRIED, false, option_header, "option_label_ENCUMBRANCETRACKER_UNCARRIED", option_entry_cycler,
    { labels = option_val_off, values = OFF, baselabel = "option_val_on", baseval = ON, default = ON })
    OptionsManager.registerOption2(ENCUMBRANCETRACKER_MULTIPLIER_BEAR, false, option_header, "option_label_ENCUMBRANCETRACKER_MULTIPLIER_BEAR", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = "option_val_off", baseval = OFF, default = OFF })
    OptionsManager.registerOption2(ENCUMBRANCETRACKER_MULTIPLIER_EQUINE, false, option_header, "option_label_ENCUMBRANCETRACKER_MULTIPLIER_EQUINE", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = "option_val_off", baseval = OFF, default = OFF })
    OptionsManager.registerOption2(ENCUMBRANCETRACKER_MULTIPLIER_BURDEN, false, option_header, "option_label_ENCUMBRANCETRACKER_MULTIPLIER_BURDEN", option_entry_cycler,
    { labels = option_val_on, values = ON, baselabel = "option_val_off", baseval = OFF, default = OFF })

    IS_FGU = checkNewEncumbranceFGU()
    USER_ISHOST = User.isHost()

	if USER_ISHOST then
		CombatManager.setCustomTurnStart(onTurnStartEvent)
    end
end

function addEffect(nodeCTEntry, sEffect)
    local rEffect = {
		sName = sEffect,
		nInit = 0,
		nDuration = 0,
		nGMOnly = 0
	}

    EffectManager.addEffect("", "", nodeCTEntry, rEffect, true)
end

function addEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    if not hasEncumberedEffect(nodeCTEntry) then
        addEffect(nodeCTEntry, ENCUMBERED)
    end
end

function addHeavilyEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    if not hasHeavilyEncumberedEffect(nodeCTEntry) then
        addEffect(nodeCTEntry, HEAVILY_ENCUMBERED)
    end
end

function addOverEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    if not hasOverEncumberedEffect(nodeCTEntry) then
        addEffect(nodeCTEntry, OVER_ENCUMBERED)
    end
end

function checkNewEncumbranceFGU()
	local nMajor, nMinor, nPatch = Interface.getVersion()
	if nMajor >= 5 then return true end
	if nMajor == 4 and nMinor >= 2 then return true end
	return nMajor == 4 and nMinor == 1 and nPatch >= 14
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

	local msg = {
        font = "msgfont",
        icon = "encumbrance_icon",
        secret = bSecret,
        text = sFormattedText
    }

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

function getEncumbranceMultiplier(nodeChar)
	local nMultiplier
    -- TODO: Getting from the ruleset multiplier will automatically account for Equine Build, Aspect of the Beast: Bear, and Beast of Burden (assuming Equine Build ext update).
    if IS_FGU then
        nMultiplier = CharEncumbranceManager5E.getEncumbranceMult(nodeChar)
    else
        nMultiplier = CharManager.getEncumbranceMult(nodeChar)
    end

	for _, nodeTrait in pairs(DB.getChildren(nodeChar, "traitlist")) do
		local name = DB.getValue(nodeTrait, "name", ""):lower()
        -- Have Equine Build and Beast of Burden be mutually exclusive.
		if (OptionsManager.isOption(ENCUMBRANCETRACKER_MULTIPLIER_EQUINE, ON)
                and string.match(name, "^%W*equine%W+build%W*$"))
            or
            (OptionsManager.isOption(ENCUMBRANCETRACKER_MULTIPLIER_BURDEN, ON)
                and string.match(name, "^%W*beast%W+of%W+burden%W*$")) then -- TODO: Make Beast of Burden optional.  Also, or or and here?
			nMultiplier = nMultiplier * 2
		end

        nMultiplier = getNoEncumbranceMultiplierOrDefault(name, nMultiplier)
	end

	for _, nodeTrait in pairs(DB.getChildren(nodeChar, "featurelist")) do
		local name = DB.getValue(nodeTrait, "name", ""):lower()
		if OptionsManager.isOption(ENCUMBRANCETRACKER_MULTIPLIER_BEAR, ON)
            and (string.match(name, "^%W*aspect%W+of%W+the%W+beast%W*bear%W*$")
                or string.match(name, "^%W*aspect%W+of%W+the%W+bear%W*$")) then
			nMultiplier = nMultiplier * 2
		end

        nMultiplier = getNoEncumbranceMultiplierOrDefault(name, nMultiplier)
	end

	return nMultiplier
end

function getNoEncumbranceMultiplierOrDefault(name, multiplier)
    if string.match(name, "^%W*no%W+encumbrance%W*$") then
        return 0
    else
        return multiplier
    end
end

function hasEffect(nodeCTEntry, sEffect)
    if not nodeCTEntry or not sEffect then return end

    local aEncumbranceEffectPatterns = {
        ENCUMBERED_PATTERN,
        HEAVILY_ENCUMBERED_PATTERN,
        OVER_ENCUMBERED_PATTERN
    }

    local sEffPattern
    if sEffect == ENCUMBERED then
        sEffPattern = ENCUMBERED_PATTERN
        removeKey(aEncumbranceEffectPatterns, ENCUMBERED_PATTERN)
    elseif sEffect == HEAVILY_ENCUMBERED then
        sEffPattern = HEAVILY_ENCUMBERED_PATTERN
        removeKey(aEncumbranceEffectPatterns, HEAVILY_ENCUMBERED_PATTERN)
    elseif sEffect == OVER_ENCUMBERED then
        sEffPattern = OVER_ENCUMBERED_PATTERN
        removeKey(aEncumbranceEffectPatterns, OVER_ENCUMBERED_PATTERN)
    else
        return false
    end

    for _,nodeEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		if DB.getValue(nodeEffect, "label", ""):match(sEffPattern) then
            -- We matched the explicitly requested pattern, delete the unmatched others (mutually exclusive)
            RemoveEffects(nodeCTEntry, aEncumbranceEffectPatterns, sEffPattern)
			return true
		end
	end

    return false
end

function hasEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    return hasEffect(nodeCTEntry, ENCUMBERED)
end

function hasHeavilyEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    return hasEffect(nodeCTEntry, HEAVILY_ENCUMBERED)
end

function hasOverEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    return hasEffect(nodeCTEntry, OVER_ENCUMBERED)
end

function insertBlankSeparatorIfNotEmpty(aTable)
	if #aTable > 0 then table.insert(aTable, "") end
end

function insertFormattedTextWithSeparatorIfNonEmpty(aTable, sFormattedText)
	insertBlankSeparatorIfNotEmpty(aTable)
	table.insert(aTable, sFormattedText)
end

function insertStatsIfEnabled(aOutput, load, strength, multiplier, levelStat)
    if OptionsManager.isOption(ENCUMBRANCETRACKER_STATS, ON) then
        local sMsgText = "Load: " .. load .. ", Str: " .. strength .. ", Mult: " .. multiplier .. ", " .. levelStat
        insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
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
        local nMultiplier = getEncumbranceMultiplier(nodeCharSheet)
        if nMultiplier > 0 then
            local aOutput = {}
            local load = DB.getValue(nodeCharSheet, "encumbrance.load", -1)
            local strength = DB.getValue(nodeCharSheet, "abilities.strength.score", -1)
            local encumbered = strength * 5 * nMultiplier
            local heavy = strength * 10 * nMultiplier
            local max = strength * 15 * nMultiplier
            local sMsgText
            if load > max and strength >= 0 then
                sMsgText = "'" .. rCurrentActor.sName .. "' is over encumbered."
                table.insert(aOutput, sMsgText)
                insertStatsIfEnabled(aOutput, load, strength, nMultiplier, "Max: " .. max)
                addOverEncumberedEffect(nodeCurrentCTActor)
            elseif checkVariantEncumbrance() and load > heavy and strength >= 0 then
                sMsgText = "'" .. rCurrentActor.sName .. "' is heavily encumbered."
                table.insert(aOutput, sMsgText)
                insertStatsIfEnabled(aOutput, load, strength, nMultiplier, "Heavy: " .. heavy)
                addHeavilyEncumberedEffect(nodeCurrentCTActor)
                if OptionsManager.isOption(ENCUMBRANCETRACKER_RULE_DETAIL, ON) then
                    sMsgText = "If you carry weight in excess of 10 times your Strength score (pre-multiplier), up to your maximum carrying capacity, you are instead heavily encumbered, which means your speed drops by 20 feet and you have disadvantage on ability checks, attack rolls, and saving throws that use Strength, Dexterity, or Constitution."
                    insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
                end
            elseif checkVariantEncumbrance() and load > encumbered and strength >= 0 then
                sMsgText = "'" .. rCurrentActor.sName .. "' is encumbered."
                table.insert(aOutput, sMsgText)
                insertStatsIfEnabled(aOutput, load, strength, nMultiplier, "Encumbered: " .. encumbered)
                addEncumberedEffect(nodeCurrentCTActor)
                if OptionsManager.isOption(ENCUMBRANCETRACKER_RULE_DETAIL, ON) then
                    sMsgText = "If you carry weight in excess of 5 times your Strength score (pre-multiplier), you are encumbered, which means your speed drops by 10 feet."
                    insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
                end
            elseif load > -1 and strength >= 0 then
                removeAllEncumbranceEffects(nodeCurrentCTActor)
                if checkVerbosityMax() then
                    sMsgText = "'" .. rCurrentActor.sName .. "' is unencumbered."
                    table.insert(aOutput, sMsgText)
                    insertStatsIfEnabled(aOutput, load, strength, nMultiplier, "Encumbered: " .. encumbered)
                end
            else
                sMsgText = "'" .. rCurrentActor.sName .. "' could not be analyzed for encumbrance."
                table.insert(aOutput, sMsgText)
            end

            if OptionsManager.isOption(ENCUMBRANCETRACKER_UNCARRIED, ON)
               or OptionsManager.isOption(ENCUMBRANCETRACKER_ZERO_WEIGHT, ON) then
                local countOfZeroWeightItems = 0
                local countOfUncarriedItems = 0
                for _,vNode in pairs(DB.getChildren(nodeCharSheet, "inventorylist")) do
                    local nWeight = DB.getValue(vNode, "weight", 0)
                    if nWeight <= 0 then
                        countOfZeroWeightItems = countOfZeroWeightItems + 1
                    end

                    local nUncarried = DB.getValue(vNode, "carried", 0)
                    if nUncarried == 0 then
                        countOfUncarriedItems = countOfUncarriedItems + 1
                    end
                end

                if OptionsManager.isOption(ENCUMBRANCETRACKER_ZERO_WEIGHT, ON)
                    and countOfZeroWeightItems > 0 then
                    sMsgText = "'" .. rCurrentActor.sName .. "' has " .. countOfZeroWeightItems .. " zero (or less) weight items."
                    insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
                end

                if OptionsManager.isOption(ENCUMBRANCETRACKER_UNCARRIED, ON)
                    and countOfUncarriedItems > 0 then
                    sMsgText = "'" .. rCurrentActor.sName .. "' has " .. countOfUncarriedItems .. " uncarried items."
                    insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
                end
            end

            displayTableIfNonEmpty(aOutput)
        end
    end
end

function removeAllEncumbranceEffects(nodeCTEntry)
    if not nodeCTEntry then return end

    local aEffects = {
        ENCUMBERED_PATTERN,
        HEAVILY_ENCUMBERED_PATTERN,
        OVER_ENCUMBERED_PATTERN
    }

    RemoveEffects(nodeCTEntry, aEffects)
end

function MatchAny( str, pattern_list )
    for _, pattern in ipairs( pattern_list ) do
        local w = string.match( str, pattern )
        if w then return w end
    end
end

function RemoveEffects(nodeCTEntry, aEffects, sKeepOnlyOnePattern)
    local bFoundKeepOnlyOneElement = false
    for _,nodeEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
        local sEffectLabel = DB.getValue(nodeEffect, "label", "")
		if MatchAny(sEffectLabel, aEffects) then
            nodeEffect.delete()
		end

        if string.match(sEffectLabel, sKeepOnlyOnePattern) then
            if bFoundKeepOnlyOneElement then
                nodeEffect.delete()
            else
                bFoundKeepOnlyOneElement = true
            end
        end
	end
end

function removeKey(aTable, key)
    for i,v in ipairs(aTable) do
        if v == key then
            return table.remove(aTable, i)
        end
    end

    return nil
end

function validateTableOrNew(aTable)
	if aTable and type(aTable) == "table" then
		return aTable
	else
		return {}
	end
end
