# Audio Assets for Local Languages

This folder contains pre-recorded audio files for local Ivorian languages
that are not supported by standard TTS engines.

## Structure

```
audio/
├── bci/           # Baoulé
│   ├── greetings/
│   ├── alerts/
│   ├── weather/
│   └── common/
├── dyu/           # Dioula/Malinké
│   ├── greetings/
│   ├── alerts/
│   ├── weather/
│   └── common/
└── sef/           # Sénoufo
    ├── greetings/
    ├── alerts/
    ├── weather/
    └── common/
```

## File Naming Convention

Files should be named using the translation key:
- `good_morning.mp3`
- `alert_critical.mp3`
- `weather_rainy.mp3`

## Recording Guidelines

1. Use clear, native speakers
2. Record at 44.1kHz, 16-bit
3. Export as MP3 at 128kbps
4. Keep files under 500KB for mobile optimization
