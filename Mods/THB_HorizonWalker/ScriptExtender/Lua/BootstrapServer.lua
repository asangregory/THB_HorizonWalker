Ext.Require("THB_HorizonWalker_General.lua")
Ext.Require("THB_HorizonWalker_PlanarWarrior.lua")
Ext.Require("THB_HorizonWalker_DistantStrike.lua")

if Ext.Mod.IsModLoaded("67fbbd53-7c7d-4cfa-9409-6d737b4d92a9") then
  local subClasses = {
    UltimaHorizonWalker = {
      modGuid = "0f943e12-5044-4602-9e7c-fa065c2330e4",
      subClassGuid = "6603c20e-f82f-4eed-8c4f-931305abe200",
      class = "ranger",
      subClassName = "Horizon Walker"
    }
  }

  local function OnSessionLoaded()
    Mods.SubclassCompatibilityFramework = Mods.SubclassCompatibilityFramework or {}
    Mods.SubclassCompatibilityFramework.API = Mods.SubclassCompatibilityFramework.Api or {}
    Mods.SubclassCompatibilityFramework.API.InsertSubClasses(subClasses)
  end

  Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
end

