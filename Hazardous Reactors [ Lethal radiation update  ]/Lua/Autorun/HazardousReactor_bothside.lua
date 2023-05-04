-- Reactor repair speed override
Hook.Add("roundStart", "changeRepairThingyOfReactors", function()
  for k, v in pairs(Item.ItemList) do
     local repairable = v.GetComponentString("Repairable")
     if repairable and v.Submarine == Submarine.MainSub and  v.GetComponentString("Reactor") then
        repairable.RepairThreshold = 80
        repairable.MinDeteriorationCondition = 0
        repairable.FixDurationLowSkill = 60
        repairable.FixDurationHighSkill = 30
        repairable.MinDeteriorationDelay = 120
        repairable.MaxDeteriorationDelay = 240
     end
  end
end)

-- Reactor fire/meltdown delay override
Hook.Add("roundStart", "ChangeReactorMeltdownTimers", function()
   for k, v in pairs(Item.ItemList) do
     local reactor = v.GetComponentString("Reactor")
     if reactor then
        reactor.FireDelay = 15
        reactor.MeltdownDelay= 40
     end
  end
end)

-- Remove fuel consumption from outpost reactor
Hook.Add("roundStart", "infinitefuel", function ()
  if not Level.Loaded then return end

  local outpost = Level.Loaded.StartOutpost
  if not outpost then return end

  for _, item in pairs(outpost.GetItems(false)) do
    local reactor = item.GetComponentString("Reactor")
    if reactor then
      reactor.FuelConsumptionRate = 0
      local prefab = ItemPrefab.GetItemPrefab("thoriumfuelrod")
      Entity.Spawner.AddItemToSpawnQueue(prefab, item.OwnInventory)
    end
  end
end)

-- Rod Hazard LightComponent Force Update when Broken
Hook.Patch(
  "Barotrauma.Items.Components.LightComponent",
  "UpdateBroken",
  function (instance, ptable)
    -- Only force update if reactorfuel tag is here
    if instance.item.HasTag("reactorfuel") then
      ptable.PreventExecution = true
      local light = instance.item.GetComponentString("LightComponent")
      light.Update(ptable["deltaTime"], ptable["cam"])
    end
    return nil
  end,
  Hook.HookMethodType.Before)

-- Fuel Out for Fulgurium Fuel rod
Hook.Add("fulguriumavailablefuel", "fulguriumfuel", function (effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end

  local light = rod.GetComponentString("LightComponent")

  if light.Range > 0 then
    local reactor = item.GetComponentString("Reactor")
    reactor.AvailableFuel = reactor.AvailableFuel + 40.0
  end
end)

-- Fuel Out for Fulgurium Fuel rod
Hook.Add("incendiumavailablefuel", "incendiumfuel", function (effect, deltaTime, item, targets, worldPosition)
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
