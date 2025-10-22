# TuneUp - Arquitectura Técnica

## Visión General

TuneUp es un sistema de gestión de perfiles de ecualización para macOS que se integra con HammerSpoon y SketchyBar para proporcionar una experiencia fluida de cambio entre configuraciones de audio.

## Arquitectura por Fases

### Fase 1: MVP Básico (ACTUAL) ✅

**Componentes:**
- `tuneup.lua`: Módulo de HammerSpoon con gestión de perfiles
- Persistencia: JSON en `~/Library/Preferences/`
- Hotkey: `Cmd+Alt+E`

**Flujo de Datos:**
```
User Input (Cmd+Alt+E)
    ↓
tuneup.toggleProfile()
    ↓
tuneup.applyProfile(profileKey)
    ↓
1. Update state (tuneup.currentProfile)
2. Save to JSON
3. Show hs.alert notification
4. Trigger SketchyBar update (if available)
```

**Limitaciones:**
- No hay EQ real aplicándose (solo metadata)
- Solo 2 perfiles hardcoded
- No hay UI visual avanzada

---

### Fase 2: Integración Visual

**Nuevos Componentes:**
- `sketchybar/tuneup.sh`: Plugin de SketchyBar
- `sketchybar/tuneup_item.sh`: Configuración del item

**Flujo de Datos:**
```
HammerSpoon (tuneup.applyProfile)
    ↓
sketchybar --trigger tuneup_profile_change
    ↓
tuneup.sh actualiza el item visual
    ↓
Usuario ve: 🎵 Normal  o  🔊 Bass Boosted
```

**Interacción:**
- Click en el item → toggle profile
- Hover → muestra descripción del perfil

---

### Fase 3: Audio Engine Real

**Nuevos Componentes:**
- `TuneUpEngine/`: Módulo Swift con AVAudioEngine
- `TuneUpCLI`: Binary CLI para aplicar EQ desde HammerSpoon

**Tecnología:**
- `AVFoundation` framework
- `AVAudioUnitEQ` con 10 bandas
- `AVAudioEngine` para procesamiento en tiempo real

**Flujo de Datos:**
```
tuneup.applyProfile(profileKey)
    ↓
Execute: tuneup-cli apply --profile bass_boosted
    ↓
Swift AVAudioEngine:
    1. Get current output device
    2. Create audio tap
    3. Insert AVAudioUnitEQ in chain
    4. Apply band gains from profile
    ↓
Audio procesado en tiempo real con EQ
```

**Desafíos Técnicos:**
1. **Latencia**: Audio tap añade ~5-10ms
2. **Permisos**: Requiere acceso a Audio Input/Output
3. **Dispositivos Bluetooth**: Algunos tienen EQ interno (conflicto posible)
4. **Estabilidad**: El engine debe sobrevivir cambios de dispositivo

**Solución Propuesta:**
- Usar `AVAudioEngine` con `installTap(onBus:)`
- Buffer size pequeño (512 frames) para baja latencia
- Watcher de cambios de dispositivo para reconectar engine

---

### Fase 4: UI Avanzada

**Nuevos Componentes:**
- `TuneUpApp/`: SwiftUI app standalone
- Custom profile editor con sliders
- Auto-switch rules por dispositivo

**Features:**
1. **Profile Editor:**
   - 10-band EQ con sliders visuales
   - Presets (Bass Boost, Treble Boost, Vocal Enhance, etc.)
   - Import/Export perfiles como JSON

2. **Device Rules:**
   ```json
   {
     "WH-1000XM4": "bass_boosted",
     "Philips TAT1215": "normal",
     "fifine": "vocal_enhance"
   }
   ```

3. **Visualización en Tiempo Real:**
   - Espectro de frecuencias
   - Antes/Después de EQ

---

## Estructura de Datos

### Profile Schema

```lua
{
    key = "bass_boosted",
    name = "Bass Boosted",
    icon = "🔊",
    description = "Énfasis en frecuencias bajas",
    eq_settings = {
        bands = {
            {freq = 32, gain = 6, q = 0.7},
            {freq = 64, gain = 6, q = 0.7},
            {freq = 125, gain = 4, q = 0.7},
            {freq = 250, gain = 2, q = 0.7},
            {freq = 500, gain = 1, q = 0.7},
            {freq = 1000, gain = 0, q = 0.7},
            {freq = 2000, gain = 0, q = 0.7},
            {freq = 4000, gain = 0, q = 0.7},
            {freq = 8000, gain = 0, q = 0.7},
            {freq = 16000, gain = 0, q = 0.7}
        }
    }
}
```

### Settings File

```json
{
    "currentProfile": "bass_boosted",
    "lastUpdated": 1729612800,
    "deviceRules": {
        "WH-1000XM4": "bass_boosted",
        "MacBook Pro Speakers": "normal"
    },
    "customProfiles": []
}
```

---

## Integración con Sistemas Existentes

### Audio Priority System

TuneUp se ejecuta **después** de audio-priority:

```
1. Device Connect Event
    ↓
2. audio-priority.lua selecciona dispositivo correcto
    ↓
3. TuneUp detecta cambio de dispositivo
    ↓
4. Aplica perfil correspondiente (si hay regla)
```

### SketchyBar

Nuevo item en la barra:

```
[... | 󰋋 WH-1000XM4 | 🔊 Bass | ...]
         ^audio         ^tuneup
```

---

## Comandos de Debug

```bash
# Ver configuración actual
cat ~/Library/Preferences/com.tuneup.settings.json | jq

# Logs de HammerSpoon
hs -c "hs.console.show()"

# Trigger manual de perfil
hs -c "tuneup.applyProfile('bass_boosted')"

# Listar perfiles disponibles
hs -c "hs.inspect(tuneup.listProfiles())"

# Test SketchyBar trigger
sketchybar --trigger tuneup_profile_change PROFILE='Bass Boosted' ICON='🔊'
```

---

## Roadmap Técnico

- [x] **Fase 1**: Estructura básica + persistencia
- [ ] **Fase 2**: SketchyBar integration
- [ ] **Fase 3**: AVAudioEngine + EQ real
- [ ] **Fase 4**: SwiftUI app + custom profiles

---

## Referencias

- [AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [AVAudioUnitEQ Documentation](https://developer.apple.com/documentation/avfaudio/avaudiouniteq)
- [eqMac Source Code](https://github.com/bitgapp/eqMac)
- [Core Audio Programming Guide](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/CoreAudioOverview/)
