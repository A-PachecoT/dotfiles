# TuneUp - Audio Profile Manager for macOS

Gestión inteligente de perfiles de ecualización para tus audífonos, integrado con HammerSpoon y SketchyBar.

## 🎯 Características

- **Perfiles de Audio**: Normal (passthrough) y Bass Boosted
- **Toggle Rápido**: `Cmd+Alt+E` para cambiar entre perfiles
- **Persistencia**: El perfil activo se mantiene entre reinicios
- **Integración SketchyBar**: Muestra el perfil activo en la barra de estado
- **Auto-detection**: Funciona con tu sistema de audio priority existente

## 📋 Roadmap

### Fase 1: MVP Básico ✅ (ACTUAL)
- [x] Estructura de proyecto
- [x] Perfiles: Normal y Bass Boosted
- [x] HammerSpoon script para gestión
- [x] Toggle con hotkey
- [x] Persistencia de configuración

### Fase 2: Integración Visual
- [ ] SketchyBar widget mostrando perfil activo
- [ ] Click para toggle
- [ ] Iconos visuales

### Fase 3: Audio Engine Real
- [ ] AVAudioEngine implementation
- [ ] EQ de 10 bandas funcional
- [ ] Más perfiles (Treble Boost, Vocal Enhance, etc.)

### Fase 4: Polish
- [ ] SwiftUI app para gestión avanzada
- [ ] Custom profiles con sliders
- [ ] Auto-switch por dispositivo

## 🚀 Instalación

### 1. HammerSpoon Setup

```bash
# Copiar el módulo a HammerSpoon
cp TuneUp/hammerspoon/tuneup.lua ~/.hammerspoon/
```

### 2. Agregar a init.lua

```lua
-- En tu ~/.hammerspoon/init.lua
tuneup = require("tuneup")
```

### 3. Reload HammerSpoon

```bash
hs -c "hs.reload()"
```

## ⌨️ Hotkeys

- **`Cmd+Alt+E`**: Toggle entre perfiles (Normal ↔ Bass Boosted)

## 🎚️ Perfiles Disponibles

### Normal (Default)
Audio sin modificaciones, passthrough puro.

### Bass Boosted
Énfasis en frecuencias bajas (ideal para música electrónica, hip-hop):
- Sub-bass (20-60 Hz): +6dB
- Bass (60-250 Hz): +4dB
- Low-mid (250-500 Hz): +2dB

## 🔧 Configuración

Los ajustes se guardan automáticamente en:
```
~/Library/Preferences/com.tuneup.settings.json
```

## 🐛 Debug

Ver logs en HammerSpoon Console:
```bash
hs -c "hs.console.show()"
```

## 📦 Estructura del Proyecto

```
TuneUp/
├── hammerspoon/
│   └── tuneup.lua          # Módulo principal de HammerSpoon
├── sketchybar/
│   └── tuneup.sh           # Plugin de SketchyBar (Fase 2)
├── docs/
│   └── architecture.md     # Documentación técnica
└── README.md
```

## 🎵 Integración con Audio Priority

TuneUp funciona en conjunto con tu sistema de audio-priority existente:
- Audio Priority: Selecciona el dispositivo correcto
- TuneUp: Aplica el perfil de EQ al dispositivo seleccionado

## 🤝 Contribuir

Este es un proyecto personal pero abierto a mejoras. Si tienes ideas para nuevos perfiles o funcionalidades, ¡son bienvenidas!

## 📝 Licencia

MIT
