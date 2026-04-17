local addonName, ns = ...

ns.CONST = {
  ADDON_NAME = addonName,
  CALLER_ID = "HRcraftsim",
  PANEL_WIDTH = 320,
  PANEL_HEIGHT = 420,
  ROW_HEIGHT = 18,
  MAX_ROWS = 10,
  MAX_OPTIONAL_ROWS = 6,
  DEBUG_DEFAULT = false,
  REAGENT_TYPE = {
    OPTIONAL = 0,
    REQUIRED = 1,
    FINISHING = 2,
    AUTOMATIC = 3,
  },
}
