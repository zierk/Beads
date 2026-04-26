local setting_utils = {}

local default_settings = {
  merit_farm_area = 'dragon',
  weaponskill = nil,  -- deprecated
  skillchain = {'Torcleaver'},
  ambu_buffs = {},
  ambu_debuffs = {},
  merit_buffs = {},
  pull_spell_or_ability = nil,
  tp_on_gyves = true,
  difficulty = 'VD',
  di_trusts = {
    {
      party_name = 'Koru-Moru',
      spell_name = 'Koru-Moru',
    },
    {
      party_name = "Lilisette II",
      spell_name = "Lilisette II",
    },
    {
      party_name = 'Joachim',
      spell_name = 'Joachim',
    },
    {
      party_name = 'Pieuje',
      spell_name = 'Pieuje (UC)',
    },
    {
      party_name = "Yoran-Oran",
      spell_name = "Yoran-Oran (UC)",
    },
  },
  merit_trusts = {
    {
      party_name = 'Apururu',
      spell_name = 'Apururu (UC)',
    },
    {
      party_name = 'Apururu',
      spell_name = 'Apururu (UC)',
    },
    {
      party_name = 'Apururu',
      spell_name = 'Apururu (UC)',
    },
    {
      party_name = 'Apururu',
      spell_name = 'Apururu (UC)',
    },
    {
      party_name = 'Apururu',
      spell_name = 'Apururu (UC)',
    },
  },
}

function setting_utils.load()
  settings = config.load(default_settings)

  if settings.weaponskill then
    settings.skillchain = {settings.weaponskill}
  end

  -- config.lua parses array indices as string values (except for 1 for some reason)
  for k, v in pairs(settings.skillchain) do
    if type(k) == 'string' then
      settings.skillchain[tonumber(k)] = v
      settings.skillchain[k] = nil
    end
  end

  validate(settings)
  print('Reloaded settings.')

  return table.copy(settings)
end

function validate(settings)
  local valid_areas = S{
    'outer_rakaznar',
    'dragon',
    'inner_rakaznar',
    'morimar_1',
    'morimar_3',
  }

  -- validate merit_farm_area
  if not valid_areas:contains(settings.merit_farm_area) then
    error('Unsupported merit_farm_area: ' .. settings.merit_farm_area .. '. Supported options: ' .. table.concat(valid_areas, ', '))
  end

  if not S{'nil', 'string'}:contains(type(settings.pull_spell_or_ability)) then
    error('pull_spell_or_ability must be empty or a string.')
  end
end

return setting_utils