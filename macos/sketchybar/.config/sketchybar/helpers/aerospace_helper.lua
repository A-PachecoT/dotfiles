-- AeroSpace helper for updating workspace app icons

local function update_space_apps()
  -- Update apps for each workspace
  for i = 1, 10 do
    local handle = io.popen("aerospace list-windows --workspace " .. i .. " --format '%{app-name}' 2>/dev/null | sort -u")
    local apps = {}

    if handle then
      for app in handle:lines() do
        if app and app ~= "" then
          apps[app] = 1
        end
      end
      handle:close()
    end

    -- Trigger the space_windows_change event with proper structure
    sbar.trigger("space_windows_change", {
      INFO = {
        space = tostring(i),
        apps = apps
      }
    })
  end
end

-- Export the function
return {
  update_space_apps = update_space_apps
}