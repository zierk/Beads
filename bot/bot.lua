-- A library of helper functions for writing bots.

debuffs = require('bot/debuffs')
events = require('bot/events')
merits = require('bot/merits')
packets = require('packets')
resources = require('resources')

math.randomseed(os.time())

local bot = {}
bot.CASTING_DISTANCE = 21
bot.MELEE_DISTANCE = 4
bot.forced_delay_end = 0

bot.log_levels = {
  DEBUG = 0,
  INFO = 1,
  WARNING = 2,
  ERROR = 3,
}
bot.log_level = bot.log_levels.ERROR

function bot.debug(msg)
  if bot.log_level <= bot.log_levels.DEBUG then
    print(msg)
  end
end

function bot.info(msg)
  if bot.log_level <= bot.log_levels.INFO then
    print(msg)
  end
end

function bot.warning(msg)
  if bot.log_level <= bot.log_levels.WARNING then
    print(msg)
  end
end

function bot.error(msg)
  if bot.log_level <= bot.log_levels.ERROR then
    print(msg)
  end
end

function bot.warp_ring(start_zone, item_name)
  start_zone = start_zone or windower.ffxi.get_info().zone
  item_name = item_name or 'Warp Ring'

  bot.do_until_zone_change(function()
    windower.send_command('gs disable ring1')
    coroutine.sleep(.1)
    windower.send_command('input /equip ring1 "' .. item_name .. '"')
    coroutine.sleep(10)
    windower.send_command('input /item "' .. item_name .. '" <me>')
    coroutine.sleep(3)
    windower.send_command('gs enable ring1')
  end, 20, start_zone)
end

function bot.holla_ring(start_zone, item_name)
  start_zone = start_zone or windower.ffxi.get_info().zone
  item_name = item_name or 'Dim. Ring (Holla)'

  bot.do_until_zone_change(function()
    windower.send_command('gs disable ring1')
    coroutine.sleep(.1)
    windower.send_command('input /equip ring1 "' .. item_name .. '"')
    coroutine.sleep(10)
    windower.send_command('input /item "' .. item_name .. '" <me>')
    coroutine.sleep(.1)
    windower.send_command('input /item "' .. item_name .. '" <me>')
    coroutine.sleep(3)
    windower.send_command('gs enable ring1')
  end, 20, start_zone)
end

function bot.warp(start_zone)
  start_zone = start_zone or windower.ffxi.get_info().zone

  bot.do_until_zone_change(function()
    bot.cast_spell('Warp', bot.me_id())
  end, 20, start_zone)
end

function bot.merits()
  return merits.lp.number_of_merits
end

function bot.max_merits()
  return 30 + windower.ffxi.get_player().merits.maximum_merit_points
end

function bot.has_debuff(mob_id, buff_id)
  return debuffs.mobs[mob_id] and debuffs.mobs[mob_id][buff_id] ~= nil
end

function bot.print_debuffs(mob_id)
  local debuffs = debuffs.mobs[mob_id]
  if not debuffs then
    print('none')
    return
  end
  for buff_id, _ in pairs(debuffs) do
    local name = resources.buffs:with('id', buff_id).en
    print(name)
  end
end

function bot.run_to_pos(x, y, options)
  options = options or {}
  options.jitter = options.jitter or false
  options.timeout = options.timeout or nil

  -- An optional function for computing new x, y coords on every loop
  -- iteration, ie for running to a moving target.
  options.pos_fn = options.pos_fn or nil

  local threshold = 0.2

  local dist = bot.get_distance(x, y)
  if not dist then
    return false
  end

  if dist <= threshold then
    return true
  end

  local start_secs = os.clock()
  local elapsed_secs = 0

  while bot.get_distance(x, y) and bot.get_distance(x, y) > threshold and
        (not options.timeout or elapsed_secs < options.timeout) do
    -- add some random movement to get around rocks etc.
    if options.jitter and math.random() < 0.05 then
      -- add random deviation between -pi/4 to pi/4
      local rads = (2 * math.random() - 1) * math.pi / 4
      windower.ffxi.run(bot.get_radians(x, y) + rads)
      coroutine.sleep(1)
    else
      windower.ffxi.run(bot.get_radians(x, y))
      coroutine.sleep(0.05)
    end
    elapsed_secs = os.clock() - start_secs

    if options.pos_fn then
      x, y = options.pos_fn()
      if x == nil or y == nil then
        return false
      end
    end
  end

  bot.stop_running()

  if options.timeout and elapsed_secs >= options.timeout then
    bot.warning("Couldn't reach destination in " .. options.timeout .. " seconds, gave up.")
    return false
  end

  return true
end

function bot.get_distance(x, y)
  local me = windower.ffxi.get_mob_by_target('me')
  if not me then
    return
  end

  return math.sqrt(math.pow(me.x - x, 2) + math.pow(me.y - y, 2))
end

function bot.get_mob_distance(mob_id)
  local mob = bot.get_mob_by_id(mob_id)
  if not mob then
    return
  end
  return bot.get_distance(mob.x, mob.y)
end

function bot.free_inventory_slots()
  local inv = windower.ffxi.get_items().inventory
  return inv.max - inv.count
end

function bot.send_dialog_packet(mob_id, menu_id, option_index, automated, unknown_1, unknown_2)
  local mob = bot.get_mob_by_id(mob_id)
  if not mob then
    return
  end

  automated = automated or false
  unknown_1 = unknown_1 or 0
  unknown_2 = unknown_2 or 0

  packets.inject(packets.new('outgoing', 0x5b, {
      ['Target'] = mob_id,
      ['Target Index'] = mob.index,
      ['Option Index'] = option_index,
      ['_unknown1'] = unknown_1,
      ['_unknown2'] = unknown_2,
      ['Automated Message'] = automated,
      ['Zone'] = windower.ffxi.get_info().zone,
      ['Menu ID'] = menu_id,
  }))
end

-- Used for flaky actions like triggering warp ring that sometimes just doesn't work.
function bot.do_until_zone_change(f, delay, zone)
  delay = delay or 15
  zone = zone or windower.ffxi.get_info().zone

  local start_time = os.clock()

  while zone == windower.ffxi.get_info().zone do
    f()
    coroutine.sleep(delay)
  end
end

function bot.wait_for_zone_change()
  bot.do_until_zone_change(function()
  end, 1)
end

-- Sell an item obtained from windower.ffxi.get_items().inventory.
function bot.sell_item(item)
  -- appraise
  packets.inject(packets.new('outgoing', 0x84, {
      ['Count'] = item.count,
      ['Item'] = item.id,
      ['Inventory Index'] = item.slot,
  }))

  -- sell
  packets.inject(packets.new('outgoing', 0x85, {
      ['_unknown1'] = 65537,
  }))
end

-- Opens a dialog menu with the target mob and returns the menu id.
function bot.start_dialog(mob_id, retries)
  retries = retries or 3

  bot.approach_mob(mob_id)

  for i = 1, retries do
    bot.interact_with_mob(mob_id)
    local menu_id = bot.wait_for_dialog_start()
    if menu_id then
      return menu_id
    end
  end

  bot.print_traceback()
  error('Failed to open dialog with NPC after ' .. retries .. ' tries, we are screwed.')
end

function bot.open_shop(mob_id)
  bot.approach_mob(mob_id, 4)
  bot.interact_with_mob(mob_id)

  bot.wait_for('incoming chunk', function(id, data)
    if id == 0x3c then
      return true
    end
  end)
end

function bot.wait_for_dialog_start()
  local menu_id

  -- Blocks incoming packet to prevent menu from appearing on client - this
  -- is necessary because packet injection stops working while a menu is open.
  bot.wait_for('incoming chunk', function(id, data)
    if id == 0x34 then
      menu_id = packets.parse('incoming', data)['Menu ID']
      return true
    end
  end, true, 1)

  return menu_id
end

-- windower.ffxi.get_mob_by_id throws an error if we pass nil, so we
-- have to wrap it.
function bot.get_mob_by_id(mob_id)
  return mob_id and windower.ffxi.get_mob_by_id(mob_id)
end

function bot.interact_with_mob(mob_id)
  local mob = bot.get_mob_by_id(mob_id)
  if not mob then
    return
  end

  packets.inject(packets.new('outgoing', 0x1a, {
      ['Target'] = mob_id,
      ['Target Index'] = mob.index,
      ['Category'] = 0,  -- interact
  }))
end

function bot.silence_mob(mob_id)
  while not bot.has_debuff(mob_id, resources.buffs:with('name', 'silence').id) do
    bot.approach_mob(mob_id, bot.CASTING_DISTANCE)
    bot.cast_spell('Silence', mob_id)
    coroutine.sleep(0.1)
  end
end

function bot.sleep_mob(mob_id)
  while not bot.has_debuff(mob_id, resources.buffs:with('name', 'sleep').id) do
    bot.approach_mob(mob_id, bot.CASTING_DISTANCE)

    local recasts = windower.ffxi.get_spell_recasts()
    local sleep_recast = recasts[resources.spells:with('name', 'Sleep').id]
    local sleep_ii_recast = recasts[resources.spells:with('name', 'Sleep II').id]

    if sleep_ii_recast == 0 then
      bot.cast_spell('Sleep II', mob_id)
    elseif sleep_recast == 0 then
      bot.cast_spell('Sleep', mob_id)
    end
    coroutine.sleep(0.1)
  end
end

function bot.nuke_mob(mob_id, spell)
  spell = spell or 'Blizzard II'
  while bot.can_attack_mob(mob_id) do
    bot.approach_mob(mob_id, bot.CASTING_DISTANCE)
    bot.cast_spell(spell, mob_id)
    coroutine.sleep(0.1)
  end
end

function bot.wait_for_mob_to_approach(mob_id)
  local start_secs = os.clock()
  local elapsed_secs = 0

  while bot.can_attack_mob(mob_id) and bot.get_mob_distance(mob_id) > bot.MELEE_DISTANCE and elapsed_secs < 10 do
    bot.turn_to_mob(mob_id)
    coroutine.sleep(0.1)
    elapsed_secs = os.clock() - start_secs
  end
  if elapsed_secs >= 10 then
    bot.warning('Gave up waiting for mob to approach.')
    return false
  end
  return true
end

function bot.camp_mob(mob_id, start_x, start_y, options)  
  if not bot.pull(mob_id, options.pull_spell_or_ability) then
    return false
  end

  options.pull_spell_or_ability = nil

  bot.run_to_pos(start_x, start_y)
  bot.wait_for_mob_to_approach(mob_id)
  bot.kill_mob(mob_id, options)

  return true
end

function bot.pull(mob_id, pull_spell_or_ability)
  pull_spell_or_ability = pull_spell_or_ability or 'Dia III'

  if not bot.can_attack_mob(mob_id) then
    return false
  end

  if not bot.approach_mob(mob_id, bot.CASTING_DISTANCE) then
    return false
  end

  if not bot.engage_mob(mob_id) then
    return false
  end

  if resources.job_abilities:with('name', pull_spell_or_ability) then
    return bot.use_ability(pull_spell_or_ability, mob_id)
  elseif resources.spells:with('name', pull_spell_or_ability) then
    return bot.cast_spell(pull_spell_or_ability, mob_id)
  elseif pull_spell_or_ability == '/ra' then
    return bot.ranged_attack(mob_id)
  end

  error('Could not find a spell or ability called ' .. pull_spell_or_ability)
end

function bot.kill_mob(mob_id, options)
  -- Default options.
  options = options or {}
  options.stay_behind = options.stay_behind or false
  options.skillchain = options.skillchain or {'Torcleaver'}
  options.weaponskill_hpp_threshold = options.weaponskill_hpp_threshold or 0
  options.debuffs = options.debuffs or {}
  options.buffs = options.buffs or {}
  options.heal_with_sanguine_blade = options.heal_with_sanguine_blade or false

  local skillchain_index = 1

  if options.pull_spell_or_ability and not bot.pull(mob_id, options.pull_spell_or_ability) then
    return false
  end

  -- Make sure trusts engage before we do anything else.
  bot.land_attack(mob_id)

  while bot.can_attack_mob(mob_id) do
    if options.stay_behind then
      bot.run_behind_mob(mob_id)
    else
      bot.approach_mob(mob_id)
    end

    -- We might have gotten charmed or something.
    if windower.ffxi.get_player().status ~= 1 or bot.get_current_target_id() ~= mob_id then
      bot.engage_mob(mob_id)
    end

    local mob = bot.get_mob_by_id(mob_id)
    if windower.ffxi.get_player().vitals.tp >= 1000 and
       mob.hpp >= options.weaponskill_hpp_threshold then
      if options.heal_with_sanguine_blade and windower.ffxi.get_player().vitals.hpp < 50 then
        bot.use_weaponskill('Sanguine Blade', mob_id)
      else
        bot.use_weaponskill(options.skillchain[skillchain_index], mob_id)

        skillchain_index = skillchain_index + 1
        if skillchain_index > #options.skillchain then
          skillchain_index = 1
        end
      end
    end

    for _, buff in pairs(options.buffs) do
      bot.buff(buff.name, buff.buff_id)
    end

    for _, debuff in pairs(options.debuffs) do
      bot.debuff(debuff.name, debuff.buff_id, mob_id)
    end

    coroutine.sleep(0.1)
  end

  return true
end

function bot.debuff(name, buff_id, mob_id)
  if not bot.can_attack_mob(mob_id) then
    return
  end

  if bot.has_debuff(mob_id, buff_id) then
    return
  end

  bot.cast_spell(name, mob_id)
end

function bot.engage_mob(mob_id)
  local mob = bot.get_mob_by_id(mob_id)
  if not mob then
    return false
  end

  if not bot.can_attack_mob(mob_id) then
    return false
  end

  bot.wait_for_forced_delay()

  local category
  local status = windower.ffxi.get_player().status
  if status == 0 then  -- unengaged
    category = 2  -- attack
  elseif status == 1 then  -- engaged
    category = 15  -- switch target
  else
    return false
  end

  p = packets.new('outgoing', 0x1a, {
      ['Target'] = mob_id,
      ['Target Index'] = mob.index,
      ['Category'] = category,
  })
  packets.inject(p)
  return true
end

function bot.get_current_target_id()
  local mob = windower.ffxi.get_mob_by_target('t')
  return mob and mob.id
end

-- Engages a mob and waits for an autoattack to land before
-- returning. Useful for making sure trusts engage.
function bot.land_attack(mob_id)
  bot.engage_mob(mob_id)

  local start_time = os.clock()

  local function did_attack_mob()
    return events.last_attacked_target == mob_id and events.last_attacked_time > start_time
  end

  while bot.can_attack_mob(mob_id) and not did_attack_mob() do
    bot.approach_mob(mob_id)

    -- Maybe we were stunned or something when we tried to engage.
    if windower.ffxi.get_player().status ~= 1 or bot.get_current_target_id() ~= mob_id then
      bot.engage_mob(mob_id)
    end
    coroutine.sleep(0.1)
  end
end

function bot.approach_mob(mob_id, max_distance)
  max_distance = max_distance or bot.MELEE_DISTANCE

  local mob = bot.get_mob_by_id(mob_id)
  if not mob then
    return false
  end

  local distance
  if math.sqrt(mob.distance) > max_distance then
    distance = max_distance
  elseif math.sqrt(mob.distance) < bot.MELEE_DISTANCE then
    distance = bot.MELEE_DISTANCE
  else
    bot.turn_to_mob(mob_id)
    return true
  end

  local me = windower.ffxi.get_mob_by_target('me')
  if not me then
    return false
  end

  local function get_pos()
    local mob = bot.get_mob_by_id(mob_id)
    if not mob then
      return
    end

    local me = windower.ffxi.get_mob_by_target('me')
    if not me then
      return
    end

    local x_diff = me.x - mob.x
    local y_diff = me.y - mob.y
    local angle = math.atan2(x_diff, y_diff) + math.pi / 2
    local x = mob.x - distance * math.cos(angle)
    local y = mob.y + distance * math.sin(angle)
    return x, y
  end

  local x, y = get_pos()
  
  if not bot.run_to_pos(x, y, {timeout = 10, pos_fn = get_pos}) then
    return false
  end

  bot.turn_to_mob(mob_id)
  return true
end

function bot.run_behind_mob(mob_id, distance)
  distance = distance or bot.MELEE_DISTANCE

  local mob = bot.get_mob_by_id(mob_id)
  if not mob then
    return
  end

  local facing = mob.facing
  local x = mob.x - distance * math.cos(facing)
  local y = mob.y + distance * math.sin(facing)
  bot.run_to_pos(x, y)
  bot.turn_to_mob(mob_id)
end

function bot.print_traceback()
  windower.send_command('console_log 1')
  print(debug.traceback())
  windower.send_command('console_log 0')
end

function bot.player_is_alive()
  local status = windower.ffxi.get_player().status
  return not S{2, 3}:contains(status)
end

function bot.can_attack_mob(mob_id)
  local me = windower.ffxi.get_mob_by_target('me')
  if not me or not bot.player_is_alive() then
    return false
  end
  
  local mob = bot.get_mob_by_id(mob_id)
  if not mob or mob.id == 0 or not mob.is_npc or mob.in_party or not mob.valid_target then
    return false
  end
  if mob.spawn_type ~= 16 then
    return false
  end
  if mob.hpp <= 0 then
    return false
  end

  local di_mobs = S{
    'Azi Dahaka',
    "Azi Dahaka's Dragon",
    'Naga Raja',
    "Naga Raja's Lamia",
    'Quetzalcoatl',
    "Quetzalcoatl's Sibilus",
    'Mireu'
  }

  -- hack - we don't care about claim ID on DI mobs
  if not di_mobs:contains(mob.name) then
    if mob.claim_id ~= 0 and mob.claim_id ~= me.id then
      return false
    end
  end

  if math.abs(me.z - mob.z) > 5 then
    return false
  end

  return true
end

function bot.wait_for_mob_by_name(names, attackable_only)
  if type(names) == 'string' then
    names = S{names}
  elseif type(names) == 'table' then
    names = S(names)
  end

  local mob_id = bot.get_nearest_mob_by_name(names, attackable_only)

  if not mob_id then
    windower.add_to_chat(204, 'Waiting for target to load...')
  end

  while mob_id == nil do
    coroutine.sleep(3)
    mob_id = bot.get_nearest_mob_by_name(names, attackable_only)
  end

  return mob_id
end


function bot.get_nearest_mob_by_name(names, attackable_only)
  if type(names) == 'string' then
    names = S{names}
  end

  if attackable_only == nil then
    attackable_only = true
  end

  local ret = nil
  for index, mob in pairs(windower.ffxi.get_mob_array()) do
    if (not names or names:contains(mob.name)) and
       (not attackable_only or bot.can_attack_mob(mob.id)) then
      if ret == nil or mob.distance < ret.distance then
        ret = mob
      end
    end
  end

  return ret and ret.id
end

function bot.get_nearest_mobs_by_name(name, attackable_only)
  if attackable_only == nil then
    attackable_only = true
  end

  local mobs = {}
  for index, mob in pairs(windower.ffxi.get_mob_array()) do
    if (not name or mob.name == name) and
       (not attackable_only or bot.can_attack_mob(mob.id)) then
        table.insert(mobs, mob)
    end
  end

  -- sort by distance
  table.sort(mobs, function(a, b) return a.distance < b.distance end)

  local mob_ids = {}

  for i, mob in pairs(mobs) do
    table.insert(mob_ids, mob.id)
  end

  return mob_ids
end

function bot.wait_for_mob_by_prefix(prefix, attackable_only)
  local mob_id = bot.get_nearest_mob_by_prefix(prefix, attackable_only)

  if not mob_id then
    windower.add_to_chat(204, 'Waiting for target to load...')
  end

  while mob_id == nil do
    coroutine.sleep(3)
    mob_id = bot.get_nearest_mob_by_prefix(prefix, attackable_only)
  end

  return mob_id
end

function bot.get_nearest_mob_by_prefix(prefix, attackable_only)
  if attackable_only == nil then
    attackable_only = true
  end

  local function starts_with(str, start)
    return str:sub(1, #start) == start
  end

  local ret = nil

  for index, mob in pairs(windower.ffxi.get_mob_array()) do
    if starts_with(mob.name, prefix) and
       (not attackable_only or bot.can_attack_mob(mob.id)) then
      if ret == nil or mob.distance < ret.distance then
        ret = mob
      end
    end
  end

  return ret and ret.id
end

function bot.has_key_item(name)
  local key_item_id = res.key_items:with('name', name).id

  for index, id in pairs(windower.ffxi.get_key_items()) do
    if id == key_item_id then
      return true
    end
  end

  return false
end

-- Get number of radians to turn to face towards position given by x, y.
function bot.get_radians(x, y)
  local player = bot.get_mob_by_id(windower.ffxi.get_player().id)
  local x_diff = player.x - x
  local y_diff = player.y - y
  return math.atan2(x_diff, y_diff) + math.pi / 2
end

function bot.turn_to_mob(mob_id, away)
  away = away or false

  local mob = bot.get_mob_by_id(mob_id)
  if not mob then
    return
  end

  local start_secs = os.clock()
  local elapsed_secs = 0

  while mob and bot.angle_to_mob(mob_id, away) > 0.5 and elapsed_secs < 5 do
    windower.ffxi.turn(bot.get_radians(mob.x, mob.y) + (away and math.pi or 0))
    coroutine.sleep(0.2)
    mob = bot.get_mob_by_id(mob_id)
    elapsed_secs = os.clock() - start_secs
  end
  if elapsed_secs >= 5 then
    bot.warning('Gave up on turning towards mob.')
    return false
  end
  return true
end

function bot.angle_to_mob(mob_id, away)
  away = away or false

  local mob = bot.get_mob_by_id(mob_id)
  if not mob then
    return
  end

  local me = windower.ffxi.get_mob_by_target('me')
  if not me then
    return
  end

  local facing = me.facing

  if away then
    facing = facing > 0 and facing - math.pi or facing + math.pi
  end

  local diff = math.abs(facing - bot.get_radians(mob.x, mob.y))
  
  if diff > math.pi then
    return (2 * math.pi) - diff
  end
  return diff
end

function bot.wait_for_forced_delay()
  local wait_time = bot.forced_delay_end - os.clock()
  if wait_time > 0 then
    coroutine.sleep(wait_time)
  end
end

function bot.can_cast(name, mob_id)
  local mob = bot.get_mob_by_id(mob_id)

  if not mob or mob.hpp <= 0 then
    return false
  end

  if not bot.me_id() or bot.has_buff(resources.buffs:with('name', 'silence').id) or bot.player_is_incapacitated() then
    return false
  end

  return true
end

function bot.player_is_incapacitated()
  local me_id = bot.me_id()

  if not me_id then
    return true
  end

  if not bot.player_is_alive() then
    return true
  end

  if bot.has_buff(resources.buffs:with('name', 'stun').id) or
     bot.has_buff(resources.buffs:with('name', 'sleep').id) then
    return true
  end

  return false
end

function bot.me_id()
  local me = windower.ffxi.get_mob_by_target('me')
  return me and me.id
end

function bot.cast_spell(name, mob_id)
  if not bot.can_cast(name, mob_id) then
    return false
  end

  bot.wait_for_forced_delay()

  -- We have to send text rather than building a packet to get Gearswap to trigger.
  windower.send_command(string.format('input /magic "%s" %d', name, mob_id))

  -- Wait for spell cast to end (or be interrupted).
  local success = false
  bot.wait_for('incoming chunk', function(id, data)
    local me_id = bot.me_id()
    if not me_id then
      return true  -- We're zoning or something so the packet isn't coming.
    end

    if id == 0x28 then
      local action = packets.parse('incoming', data)
      if action['Actor'] ~= me_id then
        return
      end

      if action['Category'] == 4 then  -- finished casting
        success = true
        return true
      end
      if action['Category'] == 8 and action['Param'] == 28787 then  -- interrupted
        return true
      end
    elseif id == 0x29 then
      local action_message = packets.parse('incoming', data)
      if action_message['Actor'] ~= me_id then
        return
      end

      -- already claimed (12), unable to cast spells at this time, can't perform that action (71), too far away
      if S{12, 17, 18, 71, 78, 313}:contains(action_message['Message']) then
        return true
      else
        return action_message['Message']  -- for debugging
      end
    end
  end)

  if success then
    bot.forced_delay_end = os.clock() + 4  -- extra 1s for lag
  end
  return success
end

function bot.use_ability(name, mob_id)
  local ability_id = res.job_abilities:with('name', name).recast_id
  if windower.ffxi.get_ability_recasts()[ability_id] ~= 0 then
    return false
  end

  if bot.player_is_incapacitated() then
    return false
  end

  bot.wait_for_forced_delay()

  -- We have to send text rather than building a packet to get Gearswap to trigger.
  windower.send_command(string.format('input /jobability "%s" %d', name, mob_id))

  -- Wait for ability.
  local success = false
  bot.wait_for('incoming chunk', function(id, data)
    local me_id = bot.me_id()
    if not me_id then
      return true  -- We're zoning or something so the packet isn't coming.
    end

    if id == 0x28 then
      local action = packets.parse('incoming', data)
      if action['Actor'] ~= me_id then
        return
      end

      if action['Category'] == 6 then  -- job ability
        success = true
        return true
      end
    elseif id == 0x29 then
      local action_message = packets.parse('incoming', data)
      if action_message['Actor'] ~= me_id then
        return
      end

      -- unable to use job ability
      if S{87, 88}:contains(action_message['Message']) then
        return true
      end
    end
  end)

  if success then
    bot.forced_delay_end = os.clock() + 3  -- extra 1s for lag
  end
  return success
end

function bot.ranged_attack(mob_id)
  if not bot.can_attack_mob(mob_id) then
    return false
  end

  bot.turn_to_mob(mob_id)
  windower.send_command('input /ra '.. mob_id)

  local success = false
  bot.wait_for('incoming chunk', function(id, data)
    local me_id = bot.me_id()
    if not me_id then
      return true  -- We're zoning or something so the packet isn't coming.
    end

    if id == 0x28 then
      local action = packets.parse('incoming', data)
      if action['Actor'] ~= me_id then
        return
      end

      if action['Category'] == 2 then  -- finish ranged attack
        success = true
        return true
      end
    end
  end, false, 10)

  return success
end

function bot.use_weaponskill(name, mob_id)
  if not name or
     not bot.me_id() or
     bot.has_buff(resources.buffs:with('name', 'amnesia').id) or
     bot.player_is_incapacitated() then
    return false
  end

  if not bot.can_attack_mob(mob_id) then
    return false
  end

  -- We have to send text rather than building a packet to get Gearswap to trigger.
  windower.send_command(string.format('input /weaponskill "%s" %d', name, mob_id))

  -- Wait for ability.
  local success = false
  bot.wait_for('incoming chunk', function(id, data)
    local me_id = bot.me_id()
    if not me_id then
      return true  -- We're zoning or something so the packet isn't coming.
    end

    if id == 0x28 then
      local action = packets.parse('incoming', data)
      if action['Actor'] ~= me_id then
        return
      end

      if action['Category'] == 3 then  -- weaponskill
        success = true
        return true
      elseif action['Category'] == 4 and action['Target 1 Action 1 Message'] == 78 then  -- out of range
        return true
      else
        return 'action: ' .. action['Category']
      end
    elseif id == 0x29 then
      local action_message = packets.parse('incoming', data)
      if action_message['Actor'] ~= me_id then
        return
      end

      -- out of range, unable to use weapon skill, cannot see target
      if S{78, 89, 90, 219}:contains(action_message['Message']) then
        return true
      else
        return 'action_message: ' .. action_message['Message']  -- for debugging
      end
    end
  end)

  if success then
    bot.forced_delay_end = os.clock() + 3  -- extra 1s for lag
  end
  return success
end

-- Blocks until the callback function for the given event_type returns true.
function bot.wait_for(event_type, f, block, threshold)
  block = block or false
  threshold = threshold or 5
  local debug_info = {}

  local success = false

  local function handler(...)
    local ret = f(...)
    if type(ret) == 'boolean' and ret then
      success = true
      return block
    elseif ret then
      table.insert(debug_info, ret)
    end
  end
  events.register_event(event_type, handler)

  -- Safety valve - bail after X seconds if our callback is never
  -- triggered.
  local start_secs = os.clock()
  local elapsed_secs = 0

  while not success and elapsed_secs < threshold do
    coroutine.sleep(0.1)
    elapsed_secs = os.clock() - start_secs
  end

  if elapsed_secs > threshold then
    bot.warning('Timed out waiting for ' .. event_type)

    if bot.log_level <= bot.log_levels.DEBUG then
      print(debug.traceback())
      print('Debug info:')
      for _, v in pairs(debug_info) do
        print(v)
      end
    end
  end

  events.unregister_event(event_type, handler)
  return success
end

function bot.stop_running()
  windower.ffxi.run(false)
  bot.forced_delay_end = os.clock() + 2
end

function bot.accept_death()
  -- Just in case.
  bot.stop_running()
  events.unregister_all()

  coroutine.sleep(10)

  local me = windower.ffxi.get_mob_by_target('me')
  packets.inject(packets.new('outgoing', 0x1a, {
      ['Target'] = me.id,
      ['Target Index'] = me.index,
      ['Category'] = 11,
  }))
  packets.inject(packets.new('outgoing', 0x1a, {
      ['Target'] = me.id,
      ['Target Index'] = me.index,
      ['Category'] = 11,
  }))

  bot.wait_for_zone_change()
end

function bot.buff(name, buff_id)
  local me_id = bot.me_id()
  if not me_id then
    return
  end

  if bot.has_buff(buff_id) then
    return
  end

  if resources.job_abilities:with('name', name) then
    bot.use_ability(name, me_id)
  elseif resources.spells:with('name', name) then
    bot.cast_spell(name, me_id)
  else
    error('Could not find a spell or ability called ' .. name)
  end
end

-- Some buffs have the same name but different IDs so we have to check
-- for them explicitly.
function bot.has_buff(buff_id)
  local buffs = windower.ffxi.get_player().buffs

  for index, id in pairs(buffs) do
    if id == buff_id then
      return true
    end
  end

  return false
end

function bot.is_in_party(name)
  local party = windower.ffxi.get_party()

  for i=0, 5 do
    local key = 'p' .. i
    if party[key] and party[key].name == name then
      return true
    end
  end

  return false
end

function bot.summon_trust(party_name, spell_name)
  if windower.ffxi.get_party().party1_count == 6 then
    return
  end

  local me = windower.ffxi.get_mob_by_target('me')
  if not me then
    return
  end

  if not bot.is_in_party(party_name) then
    bot.cast_spell(spell_name, me.id)
  end
end

return bot