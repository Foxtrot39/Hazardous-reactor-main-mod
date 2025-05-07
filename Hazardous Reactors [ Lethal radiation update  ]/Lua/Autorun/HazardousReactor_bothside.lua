-- Reactor repair speed override
Hook.Add("roundStart", "changeRepairThingyOfReactors", function()
  for k, v in pairs(Item.ItemList) do
    local repairable = v.GetComponentString("Repairable")
    if repairable and v.Submarine == Submarine.MainSub and v.GetComponentString("Reactor") then
      repairable.RepairThreshold = 80
      repairable.MinDeteriorationCondition = 0
      repairable.FixDurationLowSkill = 60
      repairable.FixDurationHighSkill = 30
      repairable.MinDeteriorationDelay = 120
      repairable.MaxDeteriorationDelay = 240
    end
  end
end)

-- Reactor fire/meltdown delay/ unlimited fuel override
Hook.Add("roundStart", "ChangeReactorMeltdownTimers", function()
   for k, v in pairs(Item.ItemList) do -- loop through items
      if v.HasTag("reactor") and v.HasTag("luaoverride") then -- check if item has 'reactor' tag and 'luaoverride' tag
         local reactor = v.GetComponentString("Reactor") -- get reactor component
         -- edit stuff
         reactor.FireDelay = 15
         reactor.MeltdownDelay= 60
     end
  end
   for k, v in pairs(Item.ItemList) do -- loop through items
      if v.HasTag("reactor") and v.Submarine ~= Submarine.MainSub then -- check if item has 'reactor' tag and is not player sub
         local reactor = v.GetComponentString("Reactor") -- get reactor component
         -- edit stuff
      reactor.FuelConsumptionRate = 0
     end
  end
end)

-- Remove fuel consumption from outpost reactor
local thoriumFuelRodPrefab = ItemPrefab.GetItemPrefab("thoriumfuelrod")
Hook.Add("roundStart", "infinitefuel", function()
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
  function(instance, ptable)
    -- Only force update if reactorfuel tag is present
    if instance.item.HasTag("reactorfuel") then
      ptable.PreventExecution = true
      instance.Update(ptable["deltaTime"], ptable["cam"])
    end
  end,
  Hook.HookMethodType.Before
)

-- Fuel Out for Fulgurium Fuel rod
Hook.Add("fulguriumavailablefuel", "fulguriumfuel", function(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end

  local light = rod.GetComponentString("LightComponent")

  if light.Range > 0 then
    local reactor = item.GetComponentString("Reactor")
    reactor.AvailableFuel = reactor.AvailableFuel + 70.0
  end
end)

-- Fuel Out for Incendium Fuel rod
Hook.Add("incendiumavailablefuel", "incendiumfuel", function(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end

  local light = rod.GetComponentString("LightComponent")
  local reactor = item.GetComponentString("Reactor")

  if light.Range < 300 then
    reactor.AvailableFuel = reactor.AvailableFuel + 180.0
  elseif light.Range < 450 then
    reactor.AvailableFuel = reactor.AvailableFuel + 320.0
  else
    reactor.AvailableFuel = reactor.AvailableFuel + 570.0
  end
end)