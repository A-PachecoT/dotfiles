-- Styles System
-- Provides reusable, theme-aware component styles

local styles = {
  -- Component styles
  card = require("styles.components.card"),
  button = require("styles.components.button"),
  badge = require("styles.components.badge"),
  separator = require("styles.components.separator"),
  icon = require("styles.components.icon"),

  -- Layout styles
  bar = require("styles.layouts.bar"),
  popup = require("styles.layouts.popup"),
}

-- Helper to deep merge style objects
function styles.merge(base, override)
  local result = {}
  for k, v in pairs(base) do
    result[k] = v
  end
  if override then
    for k, v in pairs(override) do
      if type(v) == "table" and type(result[k]) == "table" then
        result[k] = styles.merge(result[k], v)
      else
        result[k] = v
      end
    end
  end
  return result
end

return styles
