# TuneUp - Roadmap de Desarrollo

Plan de desarrollo por fases para TuneUp, un gestor de perfiles de ecualización para macOS.

---

## 📊 Estado Actual

**Fase Completada:** ✅ Fase 1 - MVP Básico
**Próxima Fase:** 🔄 Fase 2 - Integración Visual
**Fecha de Inicio:** 22 Octubre 2024

---

## ✅ Fase 1: MVP Básico (COMPLETADO)

**Duración:** ~2 horas
**Estado:** 100% ✅

### Entregables
- [x] Estructura de proyecto organizada
- [x] Módulo HammerSpoon (`tuneup.lua`)
- [x] Perfiles: Normal y Bass Boosted
- [x] Sistema de persistencia (JSON)
- [x] Hotkey global: `Cmd+Alt+E`
- [x] Notificaciones visuales (hs.alert)
- [x] Script de instalación automática
- [x] Documentación completa

### Características Técnicas
```lua
-- Gestión de perfiles
tuneup.profiles = {
    normal = {...},
    bass_boosted = {...}
}

-- Persistencia
~/Library/Preferences/com.tuneup.settings.json

-- API
tuneup.applyProfile(profileKey)
tuneup.toggleProfile()
tuneup.getCurrentProfile()
tuneup.listProfiles()
```

### Limitaciones
- ⚠️ EQ no se aplica realmente (solo metadata)
- ⚠️ Solo 2 perfiles hardcoded
- ⚠️ Sin UI visual permanente

---

## 🔄 Fase 2: Integración Visual

**Duración Estimada:** 1-2 días
**Estado:** En Preparación (archivos base creados)
**Prioridad:** Alta

### Objetivos
1. Widget visible en SketchyBar
2. Indicador del perfil activo
3. Interacción con click
4. Integración con tema Tokyo Night

### Tareas Pendientes
- [ ] Integrar `tuneup.sh` en sketchybarrc
- [ ] Configurar colores del tema
- [ ] Añadir tooltip con descripción del perfil
- [ ] Test de click handler
- [ ] Documentar posicionamiento en barra

### Diseño del Widget
```
┌────────────────────┐
│ 🔊 Bass Boosted    │  ← Widget en SketchyBar
└────────────────────┘
     ↑
     └─ Click para toggle
```

### Archivos Involucrados
- `sketchybar/tuneup.sh` ✅ (creado)
- `sketchybar/tuneup_item.sh` ✅ (creado)
- `~/.config/sketchybar/sketchybarrc` (manual)

---

## 🎚️ Fase 3: Audio Engine Real

**Duración Estimada:** 1-2 semanas
**Estado:** Planeado
**Prioridad:** Media-Alta

### Objetivos
1. Implementar AVAudioEngine en Swift
2. EQ de 10 bandas funcional
3. Procesamiento de audio en tiempo real
4. 5+ perfiles de EQ

### Stack Técnico
```swift
import AVFoundation
import AudioToolbox

// Core components
AVAudioEngine        // Engine principal
AVAudioUnitEQ        // Ecualizador de 10 bandas
AVAudioInputNode     // Captura de audio
AVAudioOutputNode    // Salida procesada
```

### Arquitectura Propuesta
```
┌─────────────────────────────────────────┐
│  macOS Audio Input (System Device)      │
└─────────────┬───────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────┐
│  AVAudioEngine                          │
│  ┌────────────────────────────────────┐ │
│  │ Input Node                         │ │
│  │         ↓                          │ │
│  │ AVAudioUnitEQ (10 bands)          │ │
│  │         ↓                          │ │
│  │ Output Node                        │ │
│  └────────────────────────────────────┘ │
└─────────────┬───────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────┐
│  macOS Audio Output (Current Device)    │
└─────────────────────────────────────────┘
```

### Nuevos Perfiles
- [ ] Vocal Enhance (podcasts)
- [ ] Treble Boost (claridad)
- [ ] V-Shape (rock/metal)
- [ ] Flat Reference (producción)
- [ ] Late Night (bajo volumen)

### Tareas
- [ ] Crear proyecto Swift (TuneUpEngine)
- [ ] Implementar AVAudioEngine wrapper
- [ ] CLI tool para HammerSpoon integration
- [ ] Device change watcher
- [ ] Latency optimization (<10ms)
- [ ] Error handling robusto
- [ ] Test con diferentes dispositivos

### Desafíos Anticipados
1. **Permisos de macOS:** Audio Input access
2. **Latencia:** Minimizar delay del procesamiento
3. **Bluetooth:** Conflictos con EQ interno de dispositivos
4. **Estabilidad:** Manejar cambios de dispositivo sin crashes

---

## 🎨 Fase 4: UI Avanzada

**Duración Estimada:** 2-3 semanas
**Estado:** Planeado
**Prioridad:** Media

### Objetivos
1. SwiftUI app standalone
2. Editor visual de perfiles
3. Auto-switch por dispositivo
4. Import/Export perfiles

### Features Principales

#### 1. Profile Editor
```
┌────────────────────────────────────────┐
│  TuneUp - Profile Editor              │
├────────────────────────────────────────┤
│                                        │
│  Profile: Bass Boosted 🔊              │
│                                        │
│  32 Hz    [━━━━━━━━━━] +6 dB          │
│  64 Hz    [━━━━━━━━━━] +6 dB          │
│  125 Hz   [━━━━━━━━━━] +4 dB          │
│  250 Hz   [━━━━━━━━━━] +2 dB          │
│  ...                                   │
│                                        │
│  [Save] [Export] [Reset]               │
└────────────────────────────────────────┘
```

#### 2. Device Rules
```json
{
  "deviceRules": {
    "WH-1000XM4": "bass_boosted",
    "Philips TAT1215": "normal",
    "fifine": "vocal_enhance",
    "MacBook Pro Speakers": "bass_boosted"
  }
}
```

#### 3. Real-time Spectrum Analyzer
- Visualización de frecuencias pre/post EQ
- Espectrograma en tiempo real
- Métricas de audio (peak, RMS, etc.)

### Tareas
- [ ] Crear proyecto SwiftUI
- [ ] Diseñar UI/UX mockups
- [ ] Implementar 10-band slider interface
- [ ] Profile import/export (JSON)
- [ ] Device auto-detection
- [ ] Spectrum analyzer visualization
- [ ] Settings panel
- [ ] Menú bar app integration

---

## 🚀 Fase 5: Distribución (Opcional)

**Duración Estimada:** 1 semana
**Estado:** Futuro
**Prioridad:** Baja

### Objetivos
1. Distribución pública
2. Auto-updater
3. Telemetría básica (opt-in)

### Tareas
- [ ] Code signing
- [ ] Notarización de macOS
- [ ] Crear installer DMG
- [ ] Website/landing page
- [ ] Documentación pública
- [ ] GitHub releases automation
- [ ] Sparkle framework para updates

---

## 📅 Timeline Estimado

```
Fase 1: MVP Básico
  [████████████████████] 100% ✅
  22 Oct 2024

Fase 2: Integración Visual
  [████░░░░░░░░░░░░░░░░]  20%
  ETA: 24 Oct 2024

Fase 3: Audio Engine Real
  [░░░░░░░░░░░░░░░░░░░░]   0%
  ETA: Noviembre 2024

Fase 4: UI Avanzada
  [░░░░░░░░░░░░░░░░░░░░]   0%
  ETA: Diciembre 2024

Fase 5: Distribución
  [░░░░░░░░░░░░░░░░░░░░]   0%
  ETA: 2025
```

---

## 🎯 Hitos Clave

| Hito | Fecha Target | Estado |
|------|--------------|--------|
| MVP funcional | 22 Oct 2024 | ✅ Completado |
| SketchyBar widget | 24 Oct 2024 | 🔄 En progreso |
| EQ real aplicándose | 15 Nov 2024 | 📋 Planeado |
| 5+ perfiles disponibles | 30 Nov 2024 | 📋 Planeado |
| SwiftUI app alpha | 15 Dic 2024 | 📋 Planeado |
| Beta pública | Q1 2025 | 💭 Considerando |

---

## 🔀 Decisiones Pendientes

### Arquitectura de Fase 3
- ¿Audio Unit Extension o AVAudioEngine directo?
- ¿Dispositivo de audio virtual o tap directo?
- ¿Limitador/compresor automático?

### UI de Fase 4
- ¿App standalone o solo MenuBar app?
- ¿Preset marketplace/sharing?
- ¿Integración con Apple Music API?

### Distribución
- ¿Open source o cerrado?
- ¿Freemium con pro features?
- ¿Mac App Store o distribución directa?

---

## 🤝 Contribuciones

Aunque es un proyecto personal, ideas y feedback son bienvenidos:

**Perfiles útiles:**
- ¿Qué género musical escuchas?
- ¿Qué dispositivos usas?
- ¿Perfiles específicos que te gustaría tener?

**Testing:**
- Hardware diferente (audífonos, DACs, etc.)
- Casos de uso específicos
- Bugs y edge cases

---

## 📚 Referencias y Aprendizaje

### Audio Engineering
- [Sound on Sound - EQ Tutorials](https://www.soundonsound.com)
- [AutoEQ - Headphone EQ Database](https://github.com/jaakkopasanen/AutoEq)
- [r/oratory1990 - EQ Settings](https://www.reddit.com/r/oratory1990/)

### macOS Development
- [AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Core Audio Programming Guide](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/CoreAudioOverview/)
- [eqMac - Open Source Reference](https://github.com/bitgapp/eqMac)

### Diseño
- [Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

---

**Última actualización:** 22 Octubre 2024
**Versión:** 0.1.0-alpha (Fase 1)
