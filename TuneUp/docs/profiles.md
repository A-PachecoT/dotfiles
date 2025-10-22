# TuneUp - Perfiles de Audio

Documentación de perfiles de ecualización disponibles y cómo crear nuevos.

## Perfiles Incluidos

### 🎵 Normal (Default)
**Uso:** Audio sin modificaciones
**Descripción:** Passthrough puro, ideal para contenido ya masterizado correctamente
**EQ:** Todas las bandas en 0dB

---

### 🔊 Bass Boosted
**Uso:** Música electrónica, hip-hop, EDM
**Descripción:** Énfasis en frecuencias bajas para más punch y presencia de bajo

**EQ Settings:**
| Frecuencia | Ganancia | Descripción |
|------------|----------|-------------|
| 32 Hz      | +6 dB    | Sub-bass profundo |
| 64 Hz      | +6 dB    | Bass fundamental |
| 125 Hz     | +4 dB    | Bass punch |
| 250 Hz     | +2 dB    | Low-mid warmth |
| 500 Hz     | +1 dB    | Mid body |
| 1 kHz+     | 0 dB     | Sin cambios |

---

## Perfiles Futuros (Fase 3)

### 🎤 Vocal Enhance
**Uso:** Podcasts, audiolibros, llamadas
**EQ Settings:**
- 200 Hz: -2 dB (reducir boom de mic)
- 1 kHz: +3 dB (claridad vocal)
- 2.5 kHz: +4 dB (presencia)
- 8 kHz: +2 dB (brillantez)

---

### ✨ Treble Boost
**Uso:** Audífonos oscuros, música clásica
**EQ Settings:**
- 4 kHz: +3 dB (detalle)
- 8 kHz: +4 dB (brillantez)
- 16 kHz: +3 dB (air)

---

### 🎸 V-Shape (Smile Curve)
**Uso:** Rock, metal, música moderna
**EQ Settings:**
- 60 Hz: +5 dB (bass)
- 125 Hz: +4 dB (punch)
- 500 Hz: -2 dB (scoop mids)
- 1 kHz: -3 dB (clarity)
- 4 kHz: +3 dB (presence)
- 8 kHz: +5 dB (sparkle)
- 16 kHz: +4 dB (air)

---

### 🎹 Flat (Reference)
**Uso:** Producción musical, mezcla
**EQ Settings:**
- Todas las bandas en 0 dB (como Normal)
- Pero con análisis espectral activo

---

### 🌙 Late Night
**Uso:** Escuchar de noche sin molestar
**EQ Settings:**
- 32 Hz: -4 dB (reducir sub-bass)
- 64 Hz: -2 dB (control de graves)
- 1 kHz: +2 dB (mantener claridad)
- 2.5 kHz: +3 dB (detalle)

---

## Crear Perfiles Personalizados

### Fase 1-2 (Actual): Hardcoded en Lua

Editar `tuneup.lua` y añadir nuevo perfil:

```lua
tuneup.profiles.my_custom_profile = {
    name = "My Custom Profile",
    icon = "🎧",
    description = "Mi configuración personalizada",
    eq_settings = {
        bands = {
            {freq = 32, gain = 0},
            {freq = 64, gain = 2},
            {freq = 125, gain = 3},
            -- ... resto de bandas
        }
    }
}
```

### Fase 4 (Futuro): UI con Sliders

Usar la app de SwiftUI para:
1. Ajustar cada banda con sliders visuales
2. Previsualizar el espectro de frecuencias
3. Guardar como preset con nombre e icono custom
4. Exportar/importar perfiles como JSON

---

## Recomendaciones por Dispositivo

### WH-1000XM4 (Over-ear, bass-heavy)
- **Música:** Bass Boosted o V-Shape
- **Podcasts:** Vocal Enhance
- **Trabajo:** Normal o Flat

### Philips TAT1215 (In-ear, balanced)
- **Música:** V-Shape
- **Podcasts:** Vocal Enhance
- **Casual:** Normal

### fifine Microphone Output
- **Gaming:** Bass Boosted
- **Streaming:** Vocal Enhance

### MacBook Pro Speakers (Bright)
- **Multimedia:** Bass Boosted (compensa speakers pequeños)
- **Trabajo:** Normal

### Echo Dot (Smart speaker)
- **Siempre:** Normal (ya tiene su propio DSP)

---

## Ciencia del EQ

### Rangos de Frecuencia

| Rango        | Frecuencias | Características |
|--------------|-------------|-----------------|
| **Sub-bass** | 20-60 Hz    | Sensación física, rumble |
| **Bass**     | 60-250 Hz   | Fundamento, punch |
| **Low-mid**  | 250-500 Hz  | Calidez, cuerpo |
| **Mid**      | 500-2 kHz   | Presencia, fundamental |
| **High-mid** | 2-4 kHz     | Claridad, definición |
| **Presence** | 4-6 kHz     | Detalle, inteligibilidad |
| **Brillance**| 6-12 kHz    | Sparkle, sibilancia |
| **Air**      | 12-20 kHz   | Espacialidad, apertura |

### Reglas Generales

1. **Cortar es mejor que boostear**: -3 dB es más limpio que +3 dB
2. **Ajustes sutiles**: ±3 dB es suficiente en la mayoría de casos
3. **Q Factor**: 0.7 es un buen default (no muy estrecho, no muy ancho)
4. **Compensación de volumen**: Boostear EQ aumenta volumen general
5. **Fletcher-Munson**: A bajo volumen necesitas más bass y treble

### Q Factor (Bandwidth)

- **Q = 0.5**: Ancho, suave, musical
- **Q = 0.7**: Default, balanced
- **Q = 1.0**: Moderado, controlado
- **Q = 2.0+**: Estrecho, quirúrgico (para problemas específicos)

---

## Testing Tracks Recomendados

Para probar perfiles de EQ:

1. **Bass:** Daft Punk - "Contact" (sub-bass profundo)
2. **Vocal:** Norah Jones - "Don't Know Why" (voz clara)
3. **Full Range:** Pink Floyd - "Money" (todo el espectro)
4. **Detail:** Hotel California (Eagles) - Live (espacialidad)
5. **Modern:** Billie Eilish - "bad guy" (bass + highs extremos)

---

## Troubleshooting

### "El EQ no se aplica"
- **Fase 1-2**: Es normal, solo es metadata
- **Fase 3+**: Verificar que AVAudioEngine esté corriendo

### "Suena distorsionado"
- Reducir las ganancias (máximo ±6 dB)
- Activar limitador (Fase 3+)

### "No hay diferencia audible"
- Verificar que el perfil no sea "Normal"
- Algunos dispositivos tienen EQ interno que interfiere
- Probar con diferentes tracks

---

## Referencias

- [Sound on Sound - EQ Basics](https://www.soundonsound.com/techniques/series/sound-advice)
- [Headphone EQ Database](https://www.reddit.com/r/oratory1990/)
- [AutoEQ Project](https://github.com/jaakkopasanen/AutoEq)
