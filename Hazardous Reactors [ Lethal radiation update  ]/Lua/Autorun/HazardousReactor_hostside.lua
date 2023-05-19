if Game.IsMultiplayer and CLIENT then return end

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Reactor"], "unsentChanges")

local geigerRadsIndex = {}

local function updateGeigerCount(effect, deltaTime, item, targets, worldPosition)
  local c = targets[1]
  if not c then
    item.condition = 100
    return
  end

  geigerRadsIndex[item] = geigerRadsIndex[item] or 0

  local r = c.CharacterHealth.GetAffliction("radiationgeiger")
  local rads = r and r.Strength or 0

  local deltaRads = math.max(rads - geigerRadsIndex[item], 0)
  item.condition = 100 - (deltaRads * 10)
  geigerRadsIndex[item] = rads
end

Hook.Add("geigercount", "geigereffect", updateGeigerCount)

local function replaceEntity(current, prefab, ...)
  local args = {...}

  if not Entity.Spawner then
    Timer.NextFrame(function()
      replaceEntity(current, prefab, unpack(args))
    end)
    return
  end

  Entity.Spawner.AddEntityToRemoveQueue(current)
  Timer.NextFrame(function()
    Entity.Spawner.AddItemToSpawnQueue(prefab, unpack(args))
  end)
end

local function fuelRodSwap(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end

  local prefab = ItemPrefab.GetItemPrefab(rod.Prefab.Identifier.Value .. "_active")
  replaceEntity(rod, prefab, item.ownInventory, rod.Condition, rod.Quality)
end

Hook.Add("fuelrodswap", "rodswap", fuelRodSwap)

local function fulguriumRodSpecial(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  local light = rod.GetComponentString("LightComponent")

  if light.Range > 0 then
    local reactor = item.GetComponentString("Reactor")
    local correctionvalue = reactor.CorrectTurbineOutput - reactor.TargetTurbineOutput
    if math.abs(correctionvalue) < 15 then return end

    if correctionvalue > 0 then
      reactor.TargetTurbineOutput = reactor.TargetTurbineOutput + 5
    else
      reactor.TargetTurbineOutput = reactor.TargetTurbineOutput - 5
    end
    rod.Condition = rod.Condition - 15
    reactor.unsentChanges = true
  end
end

Hook.Add("fulguriumrodspecial", "fulguriumrodspecialed", fulguriumRodSpecial)

local heatspikePrefab = ItemPrefab.GetItemPrefab("heatspikeemitter")

local function incendiumRodSpecial(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end

  local light = rod.GetComponentString("LightComponent")
  local reactor = item.GetComponentString("Reactor")
  local luckynumber = math.random(1000)

  if light.Range < 300 then
    if luckynumber > 950 then
      reactor.Temperature = reactor.Temperature + 30
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 1
    elseif luckynumber > 700 then
      reactor.Temperature = reactor.Temperature + 20
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 0.5
    end
  elseif light.Range < 450 then
    if luckynumber > 995 then
      Entity.Spawner.AddItemToSpawnQueue(heatspikePrefab, rod.ownInventory, nil, nil, nil, false)
      rod.Condition = rod.Condition - 5
    elseif luckynumber > 900 then
      reactor.Temperature = reactor.Temperature + 30
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 1
    elseif luckynumber > 700 then
      reactor.Temperature = reactor.Temperature + 20
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 0.5
    end
  else
    if luckynumber > 950 then
      Entity.Spawner.AddItemToSpawnQueue(heatspikePrefab, rod.ownInventory, nil, nil, nil, false)
      rod.Condition = rod.Condition - 5
    elseif luckynumber > 800 then
      reactor.Temperature = reactor.Temperature + 30
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 1
    elseif luckynumber > 400 then
      reactor.Temperature = reactor.Temperature + 20
      reactor.unsentChanges = true
      rod.Condition = rod.Condition - 0.5
    end
  end
end

Hook.Add("incendiumrodspecial", "incendiumrodspecialed", incendiumRodSpecial)

local moltenRodPrefab = ItemPrefab.GetItemPrefab("molten_rods")

local function meltdownStandard(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  replaceEntity(rod, moltenRodPrefab, item.ownInventory)
end

Hook.Add("meltdownstandard", "rodswap", meltdownStandard)

local criticalFulguriumPrefab = ItemPrefab.GetItemPrefab("supercritical_fulgurium")

local function meltdownVolatile(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  replaceEntity(rod, criticalFulguriumPrefab, item.ownInventory)
end

Hook.Add("meltdownvolatile", "rodswap", meltdownVolatile)

local criticalIncendiumPrefab = ItemPrefab.GetItemPrefab("supercritical_incendium")

local function meltdownIncendium(effect, deltaTime, item, targets, worldPosition)
  local rod = targets[1]
  if not rod then return end
  replaceEntity(rod, criticalIncendiumPrefab, item.ownInventory)
end

Hook.Add("meltdownincendium", "rodswap", meltdownIncendium)
