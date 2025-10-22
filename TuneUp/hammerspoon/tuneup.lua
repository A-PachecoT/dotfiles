-- TuneUp - Audio Profile Manager
-- Gestión de perfiles de ecualización para macOS

local tuneup = {}

-- Configuración
tuneup.profiles = {
    normal = {
        name = "Normal",
        icon = "🎵",
        description = "Audio sin modificaciones (passthrough)",
        eq_settings = nil  -- nil = passthrough, sin EQ
    },
    bass_boosted = {
        name = "Bass Boosted",
        icon = "🔊",
        description = "Énfasis en frecuencias bajas",
        eq_settings = {
            -- Configuración de EQ (para Fase 3)
            -- Por ahora es solo metadata
            bands = {
                {freq = 32, gain = 6},    -- Sub-bass
                {freq = 64, gain = 6},    -- Bass
                {freq = 125, gain = 4},   -- Bass
                {freq = 250, gain = 2},   -- Low-mid
                {freq = 500, gain = 1},   -- Mid
                {freq = 1000, gain = 0},  -- Mid
                {freq = 2000, gain = 0},  -- High-mid
                {freq = 4000, gain = 0},  -- Presence
                {freq = 8000, gain = 0},  -- Brilliance
                {freq = 16000, gain = 0}  -- Air
            }
        }
    }
}

-- Estado actual
tuneup.currentProfile = nil

-- Archivo de configuración
tuneup.settingsFile = os.getenv("HOME") .. "/Library/Preferences/com.tuneup.settings.json"

-- Función para leer configuración guardada
function tuneup.loadSettings()
    local file = io.open(tuneup.settingsFile, "r")
    if file then
        local content = file:read("*all")
        file:close()

        local success, settings = pcall(hs.json.decode, content)
        if success and settings and settings.currentProfile then
            return settings.currentProfile
        end
    end

    -- Default: Normal profile
    return "normal"
end

-- Función para guardar configuración
function tuneup.saveSettings()
    local settings = {
        currentProfile = tuneup.currentProfile,
        lastUpdated = os.time()
    }

    local success, jsonString = pcall(hs.json.encode, settings)
    if success then
        local file = io.open(tuneup.settingsFile, "w")
        if file then
            file:write(jsonString)
            file:close()
            return true
        end
    end

    return false
end

-- Función para aplicar perfil de audio
function tuneup.applyProfile(profileKey)
    local profile = tuneup.profiles[profileKey]

    if not profile then
        hs.alert.show("❌ Perfil desconocido: " .. tostring(profileKey))
        return false
    end

    -- FASE 1: Solo logging y notificación
    -- FASE 3: Aquí irá la implementación real de AVAudioEngine

    tuneup.currentProfile = profileKey
    tuneup.saveSettings()

    -- Notificación visual
    local message = string.format("%s %s", profile.icon, profile.name)
    hs.alert.show(message, 1.5)

    -- Log
    hs.printf("TuneUp: Switched to profile '%s'", profile.name)

    -- Trigger para SketchyBar (Fase 2)
    os.execute(string.format(
        "sketchybar --trigger tuneup_profile_change PROFILE='%s' ICON='%s' 2>/dev/null &",
        profile.name,
        profile.icon
    ))

    return true
end

-- Toggle entre perfiles
function tuneup.toggleProfile()
    if tuneup.currentProfile == "normal" then
        tuneup.applyProfile("bass_boosted")
    else
        tuneup.applyProfile("normal")
    end
end

-- Obtener perfil actual
function tuneup.getCurrentProfile()
    return tuneup.profiles[tuneup.currentProfile]
end

-- Listar todos los perfiles
function tuneup.listProfiles()
    local profileList = {}
    for key, profile in pairs(tuneup.profiles) do
        table.insert(profileList, {
            key = key,
            name = profile.name,
            icon = profile.icon,
            description = profile.description,
            active = (key == tuneup.currentProfile)
        })
    end
    return profileList
end

-- Menu bar (opcional, para Fase 4)
function tuneup.createMenuBar()
    if tuneup.menuBar then
        tuneup.menuBar:delete()
    end

    local currentProfile = tuneup.getCurrentProfile()

    tuneup.menuBar = hs.menubar.new()
    tuneup.menuBar:setTitle(currentProfile.icon)
    tuneup.menuBar:setTooltip("TuneUp: " .. currentProfile.name)

    tuneup.menuBar:setMenu(function()
        local menu = {}

        for key, profile in pairs(tuneup.profiles) do
            local isActive = (key == tuneup.currentProfile)
            table.insert(menu, {
                title = string.format("%s %s%s",
                    profile.icon,
                    profile.name,
                    isActive and " ✓" or ""
                ),
                fn = function() tuneup.applyProfile(key) end,
                checked = isActive
            })
        end

        table.insert(menu, {title = "-"})
        table.insert(menu, {
            title = "Reload TuneUp",
            fn = function()
                hs.reload()
                hs.alert.show("TuneUp reloaded")
            end
        })

        return menu
    end)
end

-- Inicialización
function tuneup.init()
    hs.printf("TuneUp: Initializing...")

    -- Cargar configuración guardada
    local savedProfile = tuneup.loadSettings()
    tuneup.currentProfile = savedProfile

    -- Aplicar perfil guardado
    tuneup.applyProfile(tuneup.currentProfile)

    -- Hotkey: Cmd+Alt+E para toggle
    hs.hotkey.bind({"cmd", "alt"}, "E", function()
        tuneup.toggleProfile()
    end)

    hs.printf("TuneUp: Initialized with profile '%s'", tuneup.getCurrentProfile().name)
    hs.printf("TuneUp: Use Cmd+Alt+E to toggle profiles")

    -- Crear menu bar (opcional, comentado por defecto)
    -- tuneup.createMenuBar()

    return tuneup
end

-- Auto-inicializar si se carga como módulo
return tuneup.init()
