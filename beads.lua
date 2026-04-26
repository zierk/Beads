_addon.name = 'Beads'
_addon.author = 'Omni'
_addon.version = '1.1'
_addon.commands = {'beads'}
windower.add_to_chat(204, "Beads - Set HP to Northen San'doria #2 - Start in DI area - Requires SuperWarp addon")
bot = require('bot/bot')
config = require 'config'
windower.send_command('config BattleAutoTarget false')
require('tables')
packets = require('packets')
setting_utils = require('setting_utils')

local settings = setting_utils.load()
local packets = require('packets')
local zone = windower.ffxi.get_info().zone


windower.register_event('addon command', function (...)
  local args = T{...}
  local command = args[1] and args[1]:lower()
  
  if args[1] == 'start' then
    while true do
      main()
      coroutine.sleep(1)
    end
  elseif args[1] == 'pause' then
    windower.send_command('lua reload beads')
  elseif args[1] == 'reload' then
    settings = setting_utils.load()
  elseif command == 'drk' then
    local toggle_arg = args[2] and args[2]:lower()
    if toggle_arg == 'on' then
      drk = true
      windower.add_to_chat(207, "Beads: DRK enabled (Last Resort, Hasso, Meditate).")
    elseif toggle_arg == 'off' then
      drk = false
      windower.add_to_chat(207, "Beads: DRK disabled.")
    else
      windower.add_to_chat(123, "Beads: Usage - //drk on|off")
    end
  elseif command == 'thf' then
    local toggle_arg = args[2] and args[2]:lower()
    if toggle_arg == 'on' then
      thf = true
      windower.add_to_chat(207, "Beads: THF enabled (Sneak Attack, Conspirator, Bully).")
    elseif toggle_arg == 'off' then
      thf = false
      windower.add_to_chat(207, "Beads: THF disabled.")
    else
      windower.add_to_chat(123, "Beads: Usage - //thf on|off")
    end
  elseif command == 'war' then
    local toggle_arg = args[2] and args[2]:lower()
    if toggle_arg == 'on' then
      war = true
      windower.add_to_chat(207, "Beads: WAR enabled (Berserk, Warcry, Agressor, Blood Rage, Restraint).")
    elseif toggle_arg == 'off' then
      war = false
      windower.add_to_chat(207, "Beads: WAR disabled.")
    else
      windower.add_to_chat(123, "Beads: Usage - //war on|off")
    end
  elseif command == 'sam' then
    local toggle_arg = args[2] and args[2]:lower()
    if toggle_arg == 'on' then
      sam = true
      windower.add_to_chat(207, "Beads: SAM enabled (Hasso, Meditate, Sekkanoki).")
    elseif toggle_arg == 'off' then
      sam = false
      windower.add_to_chat(207, "Beads: SAM disabled.")
    else
      windower.add_to_chat(123, "Beads: Usage - //sam on|off")
    end
  else
    help_command()
  end
end)

function help_command()
  print('Valid commands:')
  print('  start  : starts Beads')
  print('  pause  : stops Beads')
  print('  reload : reloads settings.xml')
  print('  drk on/off : enables or disables DRK ability usage')
  print('  thf on/off : enables or disables THF ability usage')
  print('  war on/off : enables or disables WAR ability usage')
  print('  sam on/off : enables or disables SAM ability usage')
  print("NOTE: auto-lockon must be disabled, homepoint must be set to N.Sandy #2") -- //config BattleAutoTarget false always
end

function main()
  local zone = windower.ffxi.get_info().zone

  if zone == 288 then -- escha-zitah
    windower.add_to_chat(204, "Starting Zi'tah")
    zitah()
  elseif zone == 289 then -- escha-ru'aun
    windower.add_to_chat(204, "Starting Ru'Aun")
    ruuan()
  elseif zone == 291 then -- reisenjima
    windower.add_to_chat(204, "Starting Reisenjima")
    reisenjima()
  else
    windower.add_to_chat(204, "Wrong Zone: " .. zone)
  end
  coroutine.sleep(5)
end

function move_to_zitah()
  bot.warp_ring()

  local mob_id = bot.wait_for_mob_by_name('Home Point #2', false)
  local menu_id = bot.start_dialog(mob_id)
  bot.send_dialog_packet(mob_id, menu_id, 8, true)
  bot.send_dialog_packet(mob_id, menu_id, 2, true, 114)
  bot.send_dialog_packet(mob_id, menu_id, 2, false, 114) -- Qufim
  bot.wait_for_zone_change()

  coroutine.sleep(15)

  mob_id = bot.wait_for_mob_by_name('Undulating Confluence', false)
  menu_id = bot.start_dialog(mob_id)
  bot.send_dialog_packet(mob_id, menu_id, 0, true, 0, 0)
  bot.send_dialog_packet(mob_id, menu_id, 1, false, 0, 0)
  bot.wait_for_zone_change()

  zitah()
end

function zitah()
  mob_id = bot.wait_for_mob_by_name('Affi', false)
  bot.run_to_pos(-355.43, -170.50)
  coroutine.sleep(1)
  windower.send_command('ew domain')
  wait_for_elvorseal_ready()
end

function move_to_ruuan()
  bot.warp_ring()
  local mob_id = bot.wait_for_mob_by_name('Home Point #2', false)
  local menu_id = bot.start_dialog(mob_id)
  bot.send_dialog_packet(mob_id, menu_id, 8, true)
  bot.send_dialog_packet(mob_id, menu_id, 2, true, 117)
  bot.send_dialog_packet(mob_id, menu_id, 2, false, 117) -- miseraux
  bot.wait_for_zone_change()
  bot.wait_for_mob_by_name('Home Point #1', false)
  bot.run_to_pos(-62.93, 570.09)
  bot.run_to_pos(-49.62, 569.80)
  local mob_id = bot.wait_for_mob_by_name('Undulating Confluence', false)
  local menu_id = bot.start_dialog(mob_id)
  bot.send_dialog_packet(mob_id, menu_id, 0, true, 0, 0)
  bot.send_dialog_packet(mob_id, menu_id, 1, false, 0, 0)
  bot.wait_for_zone_change()
  coroutine.sleep(1)
  ruuan()
end

function ruuan()
  mob_id = bot.wait_for_mob_by_name('Dremi', false)
  bot.run_to_pos(-8.5, -461.25)
  coroutine.sleep(1)
  windower.send_command('ew domain')
  wait_for_elvorseal_ready()
end

function move_to_reisenjima()
  bot.holla_ring()
  local mob_id = bot.wait_for_mob_by_name('Dimensional Portal', false)
  local menu_id = bot.start_dialog(mob_id)
  bot.send_dialog_packet(mob_id, menu_id, 0, true, 0, 0)
  bot.send_dialog_packet(mob_id, menu_id, 2, false, 0, 0)
  bot.wait_for_zone_change()
  reisenjima()
end

function reisenjima()
  local mob_id = bot.wait_for_mob_by_name('Shiftrix', false)
  coroutine.sleep(.1)
  windower.send_command('ew domain')
  wait_for_elvorseal_ready()
end

function clear_domain()
  local zone = windower.ffxi.get_info().zone
  if zone == 288 then 
    bot.run_to_pos(10.19, 40.60)
    coroutine.sleep(.5)
    summon_trusts(settings.di_trusts)
  elseif zone == 289 then 
    bot.run_to_pos(-5.3, -212)
    coroutine.sleep(.5)
    summon_trusts(settings.di_trusts)
  elseif zone == 291 then
    bot.run_to_pos(627, -952)
    coroutine.sleep(.5)
    summon_trusts(settings.di_trusts)
  end

  local dominion_id = bot.wait_for_mob_by_name(S{'Quetzalcoatl', 'Azi Dahaka', 'Naga Raja', 'Mireu'})
  local skillchain_index = 1

  while windower.ffxi.get_info().zone == zone and bot.player_is_alive() do
    -- change tp to 1000 or 2999 for weaponskill use, turned off by default
    if windower.ffxi.get_player().vitals.tp > 3000 then
      bot.approach_mob(dominion_id)
      bot.use_weaponskill(settings.skillchain[skillchain_index], dominion_id)
      skillchain_index = (skillchain_index == #settings.skillchain) and 1 or (skillchain_index + 1)
    else
      bot.land_attack(dominion_id)
    end

    if drk then 
      bot.use_ability("Hasso", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Meditate", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Last Resort", bot.me_id())
      coroutine.sleep(0.3)
    end

    if war then 
      bot.use_ability("Berserk", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Warcry", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Aggressor", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Blood Rage", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Restraint", bot.me_id())
      coroutine.sleep(0.3)
    end

    if thf then
      bot.use_ability("Sneak Attack", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Bully", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Conspirator", bot.me_id())
      coroutine.sleep(0.3)
    end

    if sam then
      bot.use_ability("Meditate", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Hasso", bot.me_id())
      coroutine.sleep(0.3)
      bot.use_ability("Sekkanoki", bot.me_id())
      coroutine.sleep(0.3)
    end

    local mob = windower.ffxi.get_mob_by_id(dominion_id)
    if mob and mob.hpp == 0 then
      windower.add_to_chat(204, "Boss defeated.")
    if zone == 288 then
      windower.add_to_chat(204, "Moving to Ru'Aun")
      move_to_ruuan()
    elseif zone == 289 then
      windower.add_to_chat(204, "Moving to Reisenjima")
     move_to_reisenjima()
    elseif zone == 291 then
     windower.add_to_chat(204, "Moving to Zitah")
      move_to_zitah()
    end
    break
    elseif not bot.player_is_alive() then
      bot.accept_death()
    end
  end
end





function wait_for_elvorseal_ready(dominion_id)
  local retry_count = 0
  local elvorseal_obtained = false
  local start_pos = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)

  while not elvorseal_obtained and retry_count < 40 do
    windower.send_command('ew domain') -- try using Elvorseal
    windower.add_to_chat(204, "Attempting to obtain Elvorseal...")

    coroutine.sleep(10)  -- allow time for teleport to happen

    local me = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
    if me and start_pos then
      local dx = me.x - start_pos.x
      local dy = me.y - start_pos.y
      local dist_sq = dx * dx + dy * dy

      if dist_sq > 10000 then
        windower.add_to_chat(204, string.format("Teleport Detected, Elvorseal obtained."))
        coroutine.sleep(5)
        clear_domain()
        return
      end
    end

    retry_count = retry_count + 1
    windower.add_to_chat(204, string.format("Waiting 60s before retrying..."))
    coroutine.sleep(60)
  end

  windower.add_to_chat(204, "Failed to get Elvorseal after 40 attempts. We're doomed")
  return false
end



function summon_trusts(trusts)
  for _, t in pairs(trusts) do
    bot.summon_trust(t.party_name, t.spell_name)
  end
end

function buff(buffs)
  for _, buff in pairs(buffs) do
    bot.buff(buff.name, buff.buff_id)
  end
end