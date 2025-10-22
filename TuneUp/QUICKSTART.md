# TuneUp - Quick Start Guide

## 🚀 Instalación en 3 Pasos

### 1. Ejecutar Instalador
```bash
cd ~/dotfiles/TuneUp
./install.sh
```

### 2. Configurar SketchyBar (Opcional)
Si elegiste instalar la integración, agrega esto a `~/.config/sketchybar/sketchybarrc`:

```bash
# TuneUp - Audio Profile Widget
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

sketchybar --add event tuneup_profile_change \
           --add item tuneup right \
           --set tuneup \
                 icon=🎵 \
                 icon.font="Hack Nerd Font:Bold:16.0" \
                 icon.padding_left=8 \
                 icon.padding_right=4 \
                 label="Normal" \
                 label.font="SF Pro:Semibold:12.0" \
                 label.padding_right=8 \
                 background.color=0xff1a1b26 \
                 background.corner_radius=6 \
                 background.height=24 \
                 background.padding_left=4 \
                 background.padding_right=4 \
                 script="$PLUGIN_DIR/tuneup.sh" \
                 click_script="hs -c 'tuneup.toggleProfile()'" \
           --subscribe tuneup tuneup_profile_change
```

Luego recarga SketchyBar:
```bash
sketchybar --reload
```

### 3. ¡Listo!
Presiona `Cmd+Alt+E` para cambiar entre perfiles.

---

## ⌨️ Uso Diario

### Cambiar Perfil
- **Hotkey:** `Cmd+Alt+E` (toggle Normal ↔ Bass Boosted)
- **SketchyBar:** Click en el widget
- **HammerSpoon Console:**
  ```lua
  tuneup.applyProfile("bass_boosted")
  tuneup.applyProfile("normal")
  ```

### Ver Perfil Actual
```bash
hs -c "print(tuneup.getCurrentProfile().name)"
```

### Listar Todos los Perfiles
```bash
hs -c "hs.inspect(tuneup.listProfiles())"
```

---

## 🎵 Perfiles Disponibles

| Perfil | Icono | Descripción | Uso |
|--------|-------|-------------|-----|
| **Normal** | 🎵 | Audio sin modificaciones | Default, contenido masterizado |
| **Bass Boosted** | 🔊 | +6dB en bajos | Electrónica, hip-hop, EDM |

---

## 🛠️ Comandos Útiles

### Debug
```bash
# Ver logs de HammerSpoon
hs -c "hs.console.show()"

# Ver configuración guardada
cat ~/Library/Preferences/com.tuneup.settings.json | jq

# Recargar HammerSpoon
hs -c "hs.reload()"
```

### Test SketchyBar
```bash
# Trigger manual
sketchybar --trigger tuneup_profile_change PROFILE='Bass Boosted' ICON='🔊'

# Ver eventos
sketchybar --query tuneup
```

### Toggle Programático
```bash
# Desde terminal
hs -c "tuneup.toggleProfile()"

# Desde otro script
osascript -e 'tell application "Hammerspoon" to execute lua code "tuneup.toggleProfile()"'
```

---

## 📁 Estructura de Archivos

```
TuneUp/
├── README.md                    # Documentación principal
├── QUICKSTART.md               # Esta guía
├── install.sh                  # Instalador automático
├── hammerspoon/
│   └── tuneup.lua              # Módulo HammerSpoon (CORE)
├── sketchybar/
│   ├── tuneup.sh               # Plugin SketchyBar
│   └── tuneup_item.sh          # Configuración del widget
└── docs/
    ├── architecture.md         # Arquitectura técnica
    └── profiles.md             # Guía de perfiles de EQ
```

---

## 🎓 Próximos Pasos

### Fase 2: Integración Visual
- Widget funcional en SketchyBar
- Click para toggle
- Hover para descripción

### Fase 3: Audio Real
- Implementación de AVAudioEngine
- EQ de 10 bandas aplicándose de verdad
- Más perfiles (Vocal Enhance, Treble Boost, etc.)

### Fase 4: UI Avanzada
- SwiftUI app standalone
- Editor de perfiles con sliders
- Auto-switch por dispositivo

---

## 🐛 Troubleshooting

### El hotkey no funciona
1. Verificar que HammerSpoon tenga permisos de Accessibility
2. Recargar HammerSpoon: `hs -c "hs.reload()"`
3. Ver logs: `hs -c "hs.console.show()"`

### No veo el widget en SketchyBar
1. Verificar que agregaste la config a `sketchybarrc`
2. Recargar SketchyBar: `sketchybar --reload`
3. Ver si el plugin existe: `ls -la ~/.config/sketchybar/plugins/tuneup.sh`

### El perfil no persiste entre reinicios
1. Verificar permisos: `ls -la ~/Library/Preferences/com.tuneup.settings.json`
2. Aplicar perfil manualmente: `hs -c "tuneup.applyProfile('bass_boosted')"`
3. Ver contenido del archivo: `cat ~/Library/Preferences/com.tuneup.settings.json`

---

## 📚 Más Información

- **README.md**: Visión general y roadmap
- **docs/architecture.md**: Detalles técnicos de implementación
- **docs/profiles.md**: Guía completa de perfiles de EQ

---

## 💡 Tips

1. **Usar Normal para trabajo**: Menos fatiga auditiva
2. **Bass Boosted para ejercicio**: Más energía y motivación
3. **Auto-reload**: HammerSpoon se recarga automáticamente al editar `tuneup.lua`
4. **Backup settings**: El archivo JSON es portable, puedes copiarlo entre Macs

---

## 🙌 Feedback

Si encuentras bugs o tienes ideas para nuevos perfiles, documéntalos en el repo.

**¡Disfruta tu audio mejorado!** 🎧
