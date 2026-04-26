-- Taken from Debuffed plugin. Tracks debuffs for use by bot.lua.

packets = require('packets')
res = require('resources')

local debuffs = {}
debuffs.mobs = {}

function handle_overwrites(target, new, t)
    if not debuffs.mobs[target] then
        return true
    end
    
    for effect, spell in pairs(debuffs.mobs[target]) do
        local old = res.spells[spell.id].overwrites or {}
        
        -- Check if there isn't a higher priority debuff active
        if table.length(old) > 0 then
            for _,v in ipairs(old) do
                if new == v then
                    return false
                end
            end
        end
        
        -- Check if a lower priority debuff is being overwritten
        if table.length(t) > 0 then
            for _,v in ipairs(t) do
                if spell.id == v then
                    debuffs.mobs[target][effect] = nil
                end
            end
        end
    end
    return true
end

function apply_debuff(target, effect, spell, actor)
    if not debuffs.mobs[target] then
        debuffs.mobs[target] = {}
    end
    
    -- Check overwrite conditions
    local overwrites = res.spells[spell].overwrites or {}
    if not handle_overwrites(target, spell, overwrites) then
        return
    end
    
    -- Create timer
    debuffs.mobs[target][effect] = {id=spell, timer=(os.clock() + (res.spells[spell].duration or 0)), actor=actor}
end

function apply_effect(target, effect)
    if not debuffs.mobs[target] then
        debuffs.mobs[target] = {}
    end

    debuffs.mobs[target][effect] = {}
end

function handle_shot(target)
    if not debuffs.mobs[target] or not debuffs.mobs[target][134] then
        return true
    end
    
    local current = debuffs.mobs[target][134].id
    if current < 26 then
        debuffs.mobs[target][134].id = current + 1
    end
end

function inc_action(act)
    if act.category ~= 4 then
        if act.category == 6 and act.param == 131 then
            handle_shot(act.targets[1].id)
        end
        return
    end
    
    -- Damaging spells
    local message_id = act.targets[1].actions[1].message
    if S{2,252}:contains(message_id) then
        local target = act.targets[1].id
        local spell = act.param
        local effect = res.spells[spell].status
        local actor = act.actor_id

        if effect then
            apply_debuff(target, effect, spell, actor)
        end
        
    -- Non-damaging spells
    elseif S{236,237,268,271}:contains(message_id) then
        local target = act.targets[1].id
        local effect = act.targets[1].actions[1].param
        local spell = act.param
        local actor = act.actor_id
        
        if res.spells[spell].status and res.spells[spell].status == effect then
            apply_debuff(target, effect, spell, actor)
        end
    -- elseif S{166, 186, 194, 205, 230, 266, 280, 319}:contains(message_id) then
    --     local target = act.targets[1].id
    --     local effect = act.targets[1].actions[1].param

    --     apply_effect(target, effect)
    --     debuffs.mobs[target][effect] = true        
    end
end

function inc_action_message(arr)
    -- Unit died
    if S{6,20,113,406,605,646}:contains(arr.message_id) then
        debuffs.mobs[arr.target_id] = nil
        
    -- Debuff expired
    elseif S{64,204,206,350,531}:contains(arr.message_id) then
        if debuffs.mobs[arr.target_id] then
            debuffs.mobs[arr.target_id][arr.param_1] = nil
        end
    end
end

windower.register_event('logout','zone change', function()
    debuffs.mobs = {}
end)

windower.register_event('incoming chunk', function(id, data)
    if id == 0x028 then
        inc_action(windower.packets.parse_action(data))
    elseif id == 0x029 then
        local arr = {}
        arr.target_id = data:unpack('I',0x09)
        arr.param_1 = data:unpack('I',0x0D)
        arr.message_id = data:unpack('H',0x19)%32768
        
        inc_action_message(arr)
    end
end)

return debuffs