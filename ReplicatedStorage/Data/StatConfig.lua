--!strict
-- Module defining which DataStores to display in player overhead GUIs.
-- Each entry in this table corresponds to a stat you want to show above
-- players' heads. It contains:
--   datastoreName: the name of the DataStore in DataStoreService
--   displayName: the text that appears after the number (lowercase)
--   leaderstatName: (optional) the name of the leaderstat value.

local StatConfig = {
    {
        datastoreName = "WoodStore",
        displayName = "wood",
        leaderstatName = "Wood",
    },
    -- Example additional entry:
    -- {
    --     datastoreName = "StoneStore",
    --     displayName = "stone",
    --     leaderstatName = "Stone",
    -- },
}

return StatConfig
