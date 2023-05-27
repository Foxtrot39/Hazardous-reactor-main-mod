-- Define constants at the beginning
local REPAIR_THRESHOLD = 80
local MIN_DETERIORATION_CONDITION = 0
local FIX_DURATION_LOW_SKILL = 60
local FIX_DURATION_HIGH_SKILL = 30
local MIN_DETERIORATION_DELAY = 120
local MAX_DETERIORATION_DELAY = 240
local FIRE_DELAY = 15
local MELTDOWN_DELAY = 40

-- Reactor repair speed override
Hook.Add("roundStart", "changeRepairThingyOfReactors", function()
  for _, v in pairs(Item.ItemList) do
     local repairable = v.GetComponentString("Repairable")
     if repairable and v.Submarine == Submarine.MainSub and v.GetComponentString("Reactor") then
        repairable.RepairThreshold = REPAIR_THRESHOLD
        repairable.MinDeteriorationCondition = MIN_DETERIORATION_CONDITION
        repairable.FixDurationLowSkill = FIX_DURATION_LOW_SKILL
        repairable.FixDurationHighSkill = FIX_DURATION_HIGH_SKILL
        repairable.MinDeteriorationDelay = MIN_DETERIORATION_DELAY
        repairable.MaxDeteriorationDelay = MAX_DETERIORATION_DELAY
     end
  end
end)

-- Reactor fire/meltdown delay override
Hook.Add("roundStart", "ChangeReactorMeltdownTimers", function()
   for _, v in pairs(Item.ItemList) do
     local reactor = v.GetComponentString("Reactor")
     if reactor then
        reactor.FireDelay = FIRE_DELAY
        reactor.MeltdownDelay = MELTDOWN_DELAY
     end
  end
end)

-- Define a constant for fuel rod prefab
local thoriumFuelRodPrefab = ItemPrefab.GetItemPrefab("thoriumfuelrod")

-- Remove fuel consumption from outpost reactor
Hook.Add("roundStart", "infinitefuel", function ()
  if not Level.Loaded then return end

  local outpost = Level.Loaded.StartOutpost
  if not outpost then return end

  for _, item in pairs(outpost.GetItems(false)) do
    local reactor = item.GetComponentString("Reactor")
    if reactor then
      reactor.FuelConsumptionRate = 0
      Entity.Spawner.AddItemToSpawnQueue(thoriumFuelRodPrefab, item.OwnInventory)
    end
  end
end)

-- Rod Hazard LightComponent Force Update when Broken
Hook.Patch(
  "Barotrauma.Items.Components.LightComponent",
  "UpdateBroken",
  function (instance, ptable)
    if instance.item.HasTag("reactorfuel") then
      ptable.PreventExecution = true
      instance.Update(ptable["deltaTime"], ptable["cam"])
    end
  end,
  Hook.HookMethodType.Before)

-- Define a constant for additional fuel values
local ADDITIONAL_FUEL_FULGURIUM = 40.0
local ADDITIONAL_FUEL_INCENDIUM_LOW = 180.0
local ADDITIONAL_FUEL_INCENDIUM_MEDIUM = 320.0
local ADDITIONAL_FUEL_INCENDIUM_HIGH = 570.0

-- Fuel Out for Fulgurium Fuel rod
Hook.Add("fulguriumavailablefuel", "fulguriumfuel", function (_, _, item, targets, _)
  local rod = targets[1]
  if not rod then return end

  local light = rod.GetComponentString("LightComponent")
  if light.Range > 0 then
    local reactor = item.GetComponentString("Reactor")
    reactor.AvailableFuel = reactor.AvailableFuel + ADDITIONAL_FUEL_FULGURIUM
  end
end)

-- Fuel Out for Incendium Fuel rod
Hook.Add("incendiumavailablefuel", "incendiumfuel", function (_, _, item, targets, _)
  local rod = targets[1]
  if not rod then return end

  local light = rod.GetComponentString("LightComponent")
  local reactor = item.GetComponentString("Reactor")

  if light.Range < 300 then
    reactor.AvailableFuel = reactor.AvailableFuel + ADDITIONAL_FUEL_INCENDIUM_LOW
  elseif light.Range < 450 then
    reactor.AvailableFuel = reactor.AvailableFuel + ADDITIONAL_FUEL_INCENDIUM_MEDIUM
  else
    reactor.AvailableFuel = reactor.AvailableFuel + ADDITIONAL_FUEL_INCENDIUM_HIGH
  end
end)
