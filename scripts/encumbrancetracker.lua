-- This extension contains 5e SRD encumbrance rules.  For license details see file: Open Gaming License v1.0a.txt

ENCUMBERED = "Encumbered"
ENCUMBERED_PATTERN_RAW = "[eE][nN][cC][uU][mM][bB][eE][rR][eE][dD]"
ENCUMBERED_PATTERN = "^%W*" .. ENCUMBERED_PATTERN_RAW
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
HEAVILY_ENCUMBERED_PATTERN = "^%W*".. "[hH][eE][aA][vV][iI][lL][yY]" .. "%W+" .. ENCUMBERED_PATTERN_RAW
IS_FGU = true
LIGHTLY = "Lightly"
LIGHTLY_ENCUMBERED = LIGHTLY .. " " .. ENCUMBERED
LIGHTLY_ENCUMBERED_PATTERN = "^%W*".. "[lL][iI][gG][hH][tT][lL][yY]" .. "%W+" .. ENCUMBERED_PATTERN_RAW
MAX = "max"
OFF = "off"
ON = "on"
OVER = "Over"
OVER_ENCUMBERED = OVER .. " " .. ENCUMBERED
OVER_ENCUMBERED_PATTERN = "^%W*".. "[oO][vV][eE][rR]" .. "%W+" .. ENCUMBERED_PATTERN_RAW
WITH_VARIANT_ENCUMBRANCE = "With variant encumbrance, "

ENCUMBRANCE_EFFECT_PATTERNS = {
    [ENCUMBERED] = ENCUMBERED_PATTERN,
    [HEAVILY_ENCUMBERED] = HEAVILY_ENCUMBERED_PATTERN,
    [LIGHTLY_ENCUMBERED] = LIGHTLY_ENCUMBERED_PATTERN,
    [OVER_ENCUMBERED] = OVER_ENCUMBERED_PATTERN
}

local CombatManager_requestActivation = nil

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
        CombatManager_requestActivation = CombatManager.requestActivation
        CombatManager.requestActivation = requestActivation
        Comm.registerSlashHandler("et", processChatCommand)
        Comm.registerSlashHandler("encumbrance", processChatCommand)
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
        addEffect(nodeCTEntry, ENCUMBERED .. "; Speed 5 ft;")
    end
end

function addHeavilyEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    if not hasHeavilyEncumberedEffect(nodeCTEntry) then
        addEffect(nodeCTEntry, HEAVILY_ENCUMBERED .. "; Speed -20 ft; DISCHK: strength, dexterity, constitution; DISSAV: strength, dexterity, constitution; DISATK;")
    end
end

function addLightlyEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    if not hasLightlyEncumberedEffect(nodeCTEntry) then
        addEffect(nodeCTEntry, LIGHTLY_ENCUMBERED .. "; Speed -10 ft;")
    end
end

function addOverEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    if not hasOverEncumberedEffect(nodeCTEntry) then
        addEffect(nodeCTEntry, OVER_ENCUMBERED .. "; Speed 5 ft; DISCHK: strength, dexterity, constitution; DISSAV: strength, dexterity, constitution; DISATK;")
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
    if not nodeCTEntry or not sEffect then return nil end

    local sEffPattern = ENCUMBRANCE_EFFECT_PATTERNS[sEffect]
    if sEffPattern == nil then
        return nil
    end

    for _,nodeEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		if DB.getValue(nodeEffect, "label", ""):match(sEffPattern) then
            -- We matched the explicitly requested pattern, delete the unmatched others (mutually exclusive)
            RemoveEffects(nodeCTEntry, ENCUMBRANCE_EFFECT_PATTERNS, nodeEffect)
			return nodeEffect
		end
	end

    return nil
end

function hasEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    return hasEffect(nodeCTEntry, ENCUMBERED)
end

function hasHeavilyEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    return hasEffect(nodeCTEntry, HEAVILY_ENCUMBERED)
end

function hasLightlyEncumberedEffect(nodeCTEntry)
    if not nodeCTEntry then return end

    return hasEffect(nodeCTEntry, LIGHTLY_ENCUMBERED)
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
        table.insert(aOutput, sMsgText)
    end
end

function isEncumbranceTrackerDisabledForActor(nodeCTActor)
    return nodeCTActor and DB.getText(nodeCTActor, "speed.special", ""):lower():match("no encumbrancetracker") ~= nil
end

function matchAny(str, pattern_list)
    for _,pattern in pairs(pattern_list) do
        if string.match(str, pattern) then
            return true
        end
    end

    return false
end

function processChatCommand()
    processEncumbranceForAllActors()
end

function processEncumbranceForActor(nodeCurrentCTActor, aOutput)
	local rCurrentActor = ActorManager.resolveActor(nodeCurrentCTActor)
    local nodeCharSheet = DB.findNode(rCurrentActor.sCreatureNode)

    if ActorManager.isPC(nodeCurrentCTActor) then
        local nMultiplier = getEncumbranceMultiplier(nodeCharSheet)
        local strength = DB.getValue(nodeCharSheet, "abilities.strength.score", -1)
        if nMultiplier < 0 or isEncumbranceTrackerDisabledForActor(nodeCharSheet) then return end

        local stats = {
            nMultiplier = nMultiplier,
            load = math.floor(DB.getValue(nodeCharSheet, "encumbrance.load", -1)),
            strength = strength,
            lightlyEncumbered = strength * 5 * nMultiplier,
            heavy = strength * 10 * nMultiplier,
            max = strength * 15 * nMultiplier
        }

        local sMsgText
        if stats.load > stats.max then
            processOverMaxEncumbrance(aOutput, nodeCurrentCTActor, stats)
        elseif checkVariantEncumbrance() and stats.load > stats.heavy then
            processVariantHeavilyEncumbered(aOutput, nodeCurrentCTActor, stats)
        elseif checkVariantEncumbrance() and stats.load > stats.lightlyEncumbered then
            processVariantLightlyEncumbered(aOutput, nodeCurrentCTActor, stats)
        elseif stats.load > -1 then
            processUnencumbered(aOutput, nodeCurrentCTActor, stats)
        elseif aOutput ~= nil then
            sMsgText = "'" .. rCurrentActor.sName .. "' could not be analyzed for encumbrance."
            insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
        end

        if aOutput ~= nil then
            if OptionsManager.isOption(ENCUMBRANCETRACKER_UNCARRIED, ON)
            or OptionsManager.isOption(ENCUMBRANCETRACKER_ZERO_WEIGHT, ON) then
                processUncarriedAndZeroWeight(aOutput, nodeCharSheet)
            end
        end
    end
end

function processEncumbranceForAllActors(bSilent)
    local aOutput
    if not bSilent then
        aOutput = {}
    end

    for _,nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
        processEncumbranceForActor(nodeCT, aOutput)
    end

    if bSilent then return end

    displayTableIfNonEmpty(aOutput)
end

function processOverMaxEncumbrance(aOutput, nodeCurrentCTActor, stats)
    removeAllEncumbranceEffects(nodeCurrentCTActor, hasOverEncumberedEffect(nodeCurrentCTActor))
    if checkVariantEncumbrance() then
        addOverEncumberedEffect(nodeCurrentCTActor)
    else
        addEncumberedEffect(nodeCurrentCTActor)
    end

    if aOutput == nil then return end

    local sMsgText
    local sDisplayName = ActorManager.getDisplayName(nodeCurrentCTActor)
    if checkVariantEncumbrance() then
        sMsgText = "'" .. sDisplayName .. "' is over encumbered."
    else
        sMsgText = "'" .. sDisplayName .. "' is encumbered."
    end

    insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
    insertStatsIfEnabled(aOutput, stats.load, stats.strength, stats.nMultiplier, "Max: " .. stats.max)
end

function processUncarriedAndZeroWeight(aOutput, nodeCharSheet)
    local sMsgText
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
        sMsgText = "'" .. ActorManager.getDisplayName(nodeCharSheet) .. "' has " .. countOfZeroWeightItems .. " zero (or less) weight items."
        table.insert(aOutput, sMsgText)
    end

    if OptionsManager.isOption(ENCUMBRANCETRACKER_UNCARRIED, ON)
        and countOfUncarriedItems > 0 then
        sMsgText = "'" .. ActorManager.getDisplayName(nodeCharSheet) .. "' has " .. countOfUncarriedItems .. " uncarried items."
        table.insert(aOutput, sMsgText)
    end
end

function processUnencumbered(aOutput, nodeCurrentCTActor, stats)
    removeAllEncumbranceEffects(nodeCurrentCTActor)
    if aOutput ~= nil and checkVerbosityMax() then
        local sMsgText = "'" .. ActorManager.getDisplayName(nodeCurrentCTActor) .. "' is unencumbered."
        insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
        if checkVariantEncumbrance() then
            insertStatsIfEnabled(aOutput, stats.load, stats.strength, stats.nMultiplier, "Lightly: " .. stats.lightlyEncumbered)
        else
            insertStatsIfEnabled(aOutput, stats.load, stats.strength, stats.nMultiplier, "Encumbered: " .. stats.max)
        end
    end
end

function processVariantHeavilyEncumbered(aOutput, nodeCurrentCTActor, stats)
    removeAllEncumbranceEffects(nodeCurrentCTActor, hasHeavilyEncumberedEffect(nodeCurrentCTActor))
    addHeavilyEncumberedEffect(nodeCurrentCTActor)
    if aOutput == nil then return end

    local sMsgText = "'" .. ActorManager.getDisplayName(nodeCurrentCTActor) .. "' is heavily encumbered."
    insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
    insertStatsIfEnabled(aOutput, stats.load, stats.strength, stats.nMultiplier, "Heavy: " .. stats.heavy)
    if OptionsManager.isOption(ENCUMBRANCETRACKER_RULE_DETAIL, ON) then
        sMsgText = WITH_VARIANT_ENCUMBRANCE .. "if you carry weight in excess of 10 times your Strength score (pre-multiplier), up to your maximum carrying capacity, you are instead heavily encumbered, which means your speed drops by 20 feet and you have disadvantage on ability checks, attack rolls, and saving throws that use Strength, Dexterity, or Constitution."
        table.insert(aOutput, sMsgText)
    end
end

function processVariantLightlyEncumbered(aOutput, nodeCurrentCTActor, stats)
    removeAllEncumbranceEffects(nodeCurrentCTActor, hasLightlyEncumberedEffect(nodeCurrentCTActor))
    addLightlyEncumberedEffect(nodeCurrentCTActor)
    if aOutput == nil then return end

    local sMsgText = "'" .. ActorManager.getDisplayName(nodeCurrentCTActor) .. "' is lightly encumbered."
    insertFormattedTextWithSeparatorIfNonEmpty(aOutput, sMsgText)
    insertStatsIfEnabled(aOutput, stats.load, stats.strength, stats.nMultiplier, "Lightly: " .. stats.lightlyEncumbered)
    if OptionsManager.isOption(ENCUMBRANCETRACKER_RULE_DETAIL, ON) then
        sMsgText = WITH_VARIANT_ENCUMBRANCE .. "if you carry weight in excess of 5 times your Strength score (pre-multiplier), you are encumbered, which means your speed drops by 10 feet."
        table.insert(aOutput, sMsgText)
    end
end

function removeAllEncumbranceEffects(nodeCTEntry, nodeEffectToKeep)
    if not nodeCTEntry then return end

    RemoveEffects(nodeCTEntry, ENCUMBRANCE_EFFECT_PATTERNS, nodeEffectToKeep)
end

function RemoveEffects(nodeCTEntry, aEffects, nodeEffectToKeep)
    for _,nodeEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
        local sEffectLabel = DB.getValue(nodeEffect, "label", "")
		if nodeEffect ~= nodeEffectToKeep and matchAny(sEffectLabel, aEffects) then
            nodeEffect.delete()
		end
	end
end

function requestActivation(nodeCurrentCTActor, bSkipBell)
    CombatManager_requestActivation(nodeCurrentCTActor, bSkipBell)
	if checkVerbosityOff() then return end

    processEncumbranceForAllActors(true)
    local aOutput = {}
    processEncumbranceForActor(nodeCurrentCTActor, aOutput)
    displayTableIfNonEmpty(aOutput)
end

function validateTableOrNew(aTable)
	if aTable and type(aTable) == "table" then
		return aTable
	else
		return {}
	end
end
