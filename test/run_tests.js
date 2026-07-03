const fs = require('fs');
const path = require('path');
const assert = require('assert');
const { LuaFactory } = require('wasmoon');

async function runTests() {
    console.log("Setting up Lua VM via wasmoon...");
    const luaFactory = new LuaFactory();
    const lua = await luaFactory.createEngine();

    // 1. Mock FGU environment globals
    console.log("Mocking FGU environment globals...");
    
    await lua.doString(`
        Interface = {}
        OptionsManager = {}
        Comm = {}
        DB = {}
        ActorManager = {}
        CombatManager = {}
        EffectManager = {}
        StringManager = {}
        User = {}
        
        -- Mock Interface
        function Interface.getVersion() return 4, 2, 0 end

        -- Mock User
        function User.isHost() return true end

        -- Mock StringManager
        StringManager.isBlank = function(s)
            if type(s) ~= "string" then return true end
            return s:gsub("%s+", "") == ""
        end

        -- Mock OptionsManager
        local options = {}
        function OptionsManager.registerOption2() end
        function OptionsManager.isOption(key, val)
            return options[key] == val
        end
        function OptionsManager.setOption(key, val)
            options[key] = val
        end

        -- Default options
        options["ENCUMBRANCETRACKER_VERBOSE"] = "max"
        options["ENCUMBRANCETRACKER_RULE_DETAIL"] = "on"
        options["ENCUMBRANCETRACKER_STATS"] = "on"
        options["ENCUMBRANCETRACKER_USE_EFFECTS"] = "on"
        options["HREN"] = "variant" -- default to variant encumbrance enabled

        -- Mock Comm
        local chatMessages = {}
        function Comm.registerSlashHandler() end
        function Comm.addChatMessage(msg)
            table.insert(chatMessages, msg.text)
        end
        function Comm.deliverChatMessage(msg)
            table.insert(chatMessages, msg.text)
        end
        function Comm.getChatMessages()
            return chatMessages
        end
        function Comm.clearChatMessages()
            chatMessages = {}
        end

        -- Mock CombatManager
        CombatManager.CT_LIST = "combattracker"
        function CombatManager.requestActivation() end

        -- Mock Database structure
        dbData = {}
        
        function DB.setNodeValue(path, val)
            dbData[path] = val
        end
        
        function DB.getValue(node, field, default)
            local nodePath = ""
            if type(node) == "table" and node.path then
                nodePath = node.path
            elseif type(node) == "string" then
                nodePath = node
            end
            
            local fullPath = nodePath .. "." .. field
            if dbData[fullPath] ~= nil then
                return dbData[fullPath]
            end
            return default
        end
        
        function DB.getText(node, field, default)
            return DB.getValue(node, field, default)
        end

        function DB.findNode(nodePath)
            if type(nodePath) == "table" then return nodePath end
            return { path = nodePath }
        end

        local dbChildren = {}
        function DB.setChildren(nodePath, children)
            dbChildren[nodePath] = children
        end

        -- Mock ActorManager
        local actorPC = {}
        function ActorManager.getActor(nodeCT)
            return {
                sCreatureNode = "charsheet.id-00001",
                sName = "Mock Hero"
            }
        end
        function ActorManager.isPC(nodeCT)
            return actorPC[nodeCT.path] == true
        end
        function ActorManager.setPC(nodeCTPath, val)
            actorPC[nodeCTPath] = val
        end
        function ActorManager.getDisplayName(node)
            return "Mock Hero"
        end

        -- Mock EffectManager
        ctEffects = {}
        function EffectManager.addEffect(node1, node2, nodeCT, rEffect, bShow)
            if not ctEffects[nodeCT.path] then
                ctEffects[nodeCT.path] = {}
            end
            local newEffect = {
                path = nodeCT.path .. ".effects.id-" .. (#ctEffects[nodeCT.path] + 1),
                label = rEffect.sName
            }
            newEffect.delete = function()
                newEffect.deleted = true
            end
            table.insert(ctEffects[nodeCT.path], newEffect)
        end

        function DB.getChildren(node, field)
            -- Intercept effects child lookup for CT node
            if type(node) == "table" and field == "effects" then
                local list = {}
                local effects = ctEffects[node.path] or {}
                for i, eff in ipairs(effects) do
                    if not eff.deleted then
                        list[tostring(i)] = eff
                    end
                end
                return list
            end

            -- Default children lookup
            local nodePath = ""
            if type(node) == "table" and node.path then
                nodePath = node.path
            elseif type(node) == "string" then
                nodePath = node
            end
            local fullPath = nodePath
            if field then
                fullPath = nodePath .. "." .. field
            end
            local children = dbChildren[fullPath] or {}
            local list = {}
            for k, v in pairs(children) do
                list[k] = { path = fullPath .. "." .. k }
            end
            return list
        end

        function DB.getValue(node, field, default)
            -- If node is an effect mock
            if type(node) == "table" and node.label and field == "label" then
                return node.label
            end
            
            local nodePath = ""
            if type(node) == "table" and node.path then
                nodePath = node.path
            elseif type(node) == "string" then
                nodePath = node
            end
            
            local fullPath = nodePath .. "." .. field
            if dbData[fullPath] ~= nil then
                return dbData[fullPath]
            end
            return default
        end
    `);

    // 2. Load the actual encumbrancetracker script
    console.log("Loading scripts/encumbrancetracker.lua into VM...");
    const luaCodePath = path.join(__dirname, '../scripts/encumbrancetracker.lua');
    const luaCode = fs.readFileSync(luaCodePath, 'utf8');
    
    await lua.doString(luaCode);
    console.log("EncumbranceTracker loaded successfully inside VM.\n");

    // 3. Define and run test assertions
    console.log("Running Unit Tests...");
    let testsPassed = 0;
    let testsFailed = 0;

    async function runAssert(fnName, expected, luaCodeToRun) {
        try {
            const result = await lua.doString(luaCodeToRun);
            assert.strictEqual(result, expected);
            console.log(`  ✓ PASS: ${fnName} -> got ${result}`);
            testsPassed++;
        } catch (err) {
            console.error(`  ✗ FAIL: ${fnName} -> expected ${expected}, got error or mismatch: ${err.message}`);
            testsFailed++;
        }
    }

    // --- TEST 1: checkNewEncumbranceFGU (FGU check version) ---
    await runAssert("checkNewEncumbranceFGU()", true, "return checkNewEncumbranceFGU()");

    // --- TEST 2: checkVariantEncumbrance ---
    await runAssert("checkVariantEncumbrance() default variant", true, "return checkVariantEncumbrance()");
    await lua.doString("OptionsManager.setOption('HREN', 'standard')");
    await runAssert("checkVariantEncumbrance() set standard", false, "return checkVariantEncumbrance()");

    // --- TEST 3: getEncumbranceMultiplier default ---
    await lua.doString(`
        nodeChar = { path = "charsheet.id-00001" }
        -- Mock empty traits and features list
        DB.setChildren("charsheet.id-00001.traitlist", {})
        DB.setChildren("charsheet.id-00001.featurelist", {})
    `);
    await runAssert("getEncumbranceMultiplier() default", 1, "return getEncumbranceMultiplier(nodeChar)");

    // --- TEST 4: getEncumbranceMultiplier with Equine Build trait ---
    await lua.doString(`
        OptionsManager.setOption("ENCUMBRANCETRACKER_MULTIPLIER_EQUINE", "on")
        DB.setChildren("charsheet.id-00001.traitlist", {
            ["trait1"] = true
        })
        DB.setNodeValue("charsheet.id-00001.traitlist.trait1.name", "Equine Build")
    `);
    await runAssert("getEncumbranceMultiplier() with Equine Build", 2, "return getEncumbranceMultiplier(nodeChar)");

    // --- TEST 5: getEncumbranceMultiplier with Bear Aspect feature ---
    await lua.doString(`
        OptionsManager.setOption("ENCUMBRANCETRACKER_MULTIPLIER_BEAR", "on")
        DB.setChildren("charsheet.id-00001.traitlist", {}) -- clear trait
        DB.setChildren("charsheet.id-00001.featurelist", {
            ["feat1"] = true
        })
        DB.setNodeValue("charsheet.id-00001.featurelist.feat1.name", "Aspect of the Beast: Bear")
    `);
    await runAssert("getEncumbranceMultiplier() with Bear Aspect", 2, "return getEncumbranceMultiplier(nodeChar)");

    // --- TEST 6: processEncumbranceForActor - Unencumbered ---
    await lua.doString(`
        nodeCT = { path = "combattracker.id-00001" }
        ActorManager.setPC(nodeCT.path, true)
        
        -- Reset options and lists to defaults
        OptionsManager.setOption("ENCUMBRANCETRACKER_MULTIPLIER_BEAR", "off")
        OptionsManager.setOption("ENCUMBRANCETRACKER_MULTIPLIER_EQUINE", "off")
        DB.setChildren("charsheet.id-00001.featurelist", {})
        
        -- Strength 10, carrying 20 lbs. Lightly limit is 50 lbs. Max is 150 lbs.
        DB.setNodeValue("charsheet.id-00001.abilities.strength.score", 10)
        DB.setNodeValue("charsheet.id-00001.encumbrance.load", 20)
        
        OptionsManager.setOption("HREN", "variant")
        OptionsManager.setOption("ENCUMBRANCETRACKER_USE_EFFECTS", "on")
        
        -- Clear any active effects
        ctEffects = {}
        
        processEncumbranceForActor(nodeCT, nil)
    `);
    await runAssert("Unencumbered CT effects size", 0, "return #(ctEffects[nodeCT.path] or {})");

    // --- TEST 7: processEncumbranceForActor - Lightly Encumbered ---
    await lua.doString(`
        -- Carrying 60 lbs (above 50 lbs limit)
        DB.setNodeValue("charsheet.id-00001.encumbrance.load", 60)
        ctEffects = {}
        processEncumbranceForActor(nodeCT, nil)
    `);
    await runAssert("Lightly Encumbered CT effects size", 1, "return #ctEffects[nodeCT.path]");
    await runAssert("Lightly Encumbered effect label", "Lightly Encumbered; Speed -10 ft;", "return ctEffects[nodeCT.path][1].label");

    // --- TEST 8: processEncumbranceForActor - Heavily Encumbered ---
    await lua.doString(`
        -- Carrying 110 lbs (above 100 lbs limit)
        DB.setNodeValue("charsheet.id-00001.encumbrance.load", 110)
        ctEffects = {}
        processEncumbranceForActor(nodeCT, nil)
    `);
    await runAssert("Heavily Encumbered CT effects size", 1, "return #ctEffects[nodeCT.path]");
    await runAssert("Heavily Encumbered effect label", "Heavily Encumbered; Speed -20 ft; DISCHK: strength, dexterity, constitution; DISSAV: strength, dexterity, constitution; DISATK;", "return ctEffects[nodeCT.path][1].label");

    // --- TEST 9: processEncumbranceForActor - Over Encumbered ---
    await lua.doString(`
        -- Carrying 160 lbs (above 150 lbs limit)
        DB.setNodeValue("charsheet.id-00001.encumbrance.load", 160)
        ctEffects = {}
        processEncumbranceForActor(nodeCT, nil)
    `);
    await runAssert("Over Encumbered CT effects size", 1, "return #ctEffects[nodeCT.path]");
    await runAssert("Over Encumbered effect label", "Over Encumbered; Speed 5 ft; DISCHK: strength, dexterity, constitution; DISSAV: strength, dexterity, constitution; DISATK;", "return ctEffects[nodeCT.path][1].label");

    // 4. Print Summary
    console.log(`\nTest Summary: ${testsPassed} passed, ${testsFailed} failed.`);
    
    if (testsFailed > 0) {
        process.exit(1);
    }
}

runTests().catch(err => {
    console.error("Test execution failed: ", err);
    process.exit(1);
});
