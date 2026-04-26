-- Taken from pointwatch. Tracks merit info and exposes it for bot.lua to use.

texts = require 'texts'
config = require 'config'
require 'sets'
res = require 'resources'
require 'pack'

local merits = {}

merits.lp = {
    current = 0,
    tnm = 10000,
    number_of_merits = 0,
    maximum_merits = 30,
}

windower.register_event('incoming chunk',function(id,org,modi,is_injected,is_blocked)
    if is_injected then return end
    if id == 0x29 then -- Action Message, used in Abyssea for xp
        local val = org:unpack('I',0xD)
        local msg = org:unpack('H',0x19)%1024
        merits.exp_msg(val,msg)
    elseif id == 0x2D then
        local val = org:unpack('I',0x11)
        local msg = org:unpack('H',0x19)%1024
        merits.exp_msg(val,msg)
    elseif id == 0x63 and org:byte(5) == 2 then
        merits.lp.current = org:unpack('H',9)
        merits.lp.number_of_merits = org:byte(11)%128
        merits.lp.maximum_merits = org:byte(0x0D)%128
    end
end)

function merits.exp_msg(val,msg)
    if not S{371, 372}:contains(msg) then
        return
    end

    merits.lp.current = merits.lp.current + val

    if merits.lp.number_of_merits < merits.lp.maximum_merits then
        merits.lp.number_of_merits = merits.lp.number_of_merits + math.floor(merits.lp.current / merits.lp.tnm)
        merits.lp.current = merits.lp.current % merits.lp.tnm
        merits.lp.number_of_merits = math.min(merits.lp.number_of_merits, merits.lp.maximum_merits)
    else
        merits.lp.current = math.min(merits.lp.current, merits.lp.tnm - 1)
    end
end

return merits