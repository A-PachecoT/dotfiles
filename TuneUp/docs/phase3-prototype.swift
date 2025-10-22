// TuneUp - Fase 3 Prototype
// Ejemplo de implementación de AVAudioEngine para EQ real
// Este código es solo un prototipo de referencia para la Fase 3

import AVFoundation
import Foundation

class TuneUpEngine {

    // MARK: - Properties

    private let audioEngine = AVAudioEngine()
    private let eq = AVAudioUnitEQ(numberOfBands: 10)
    private var isRunning = false

    // Frecuencias estándar de 10 bandas
    private let standardFrequencies: [Float] = [
        32,    // Sub-bass
        64,    // Bass
        125,   // Bass
        250,   // Low-mid
        500,   // Mid
        1000,  // Mid
        2000,  // High-mid
        4000,  // Presence
        8000,  // Brilliance
        16000  // Air
    ]

    // MARK: - Profiles

    struct EQProfile {
        let name: String
        let gains: [Float]  // Array de 10 ganancias en dB

        static let normal = EQProfile(
            name: "Normal",
            gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        )

        static let bassBoost = EQProfile(
            name: "Bass Boosted",
            gains: [6, 6, 4, 2, 1, 0, 0, 0, 0, 0]
        )

        static let vocalEnhance = EQProfile(
            name: "Vocal Enhance",
            gains: [0, -2, 0, 1, 3, 4, 2, 1, 0, 0]
        )

        static let trebleBoost = EQProfile(
            name: "Treble Boost",
            gains: [0, 0, 0, 0, 0, 1, 2, 3, 4, 3]
        )

        static let vShape = EQProfile(
            name: "V-Shape",
            gains: [5, 4, 2, -2, -3, -1, 2, 3, 5, 4]
        )
    }

    // MARK: - Initialization

    init() {
        setupAudioEngine()
    }

    deinit {
        stop()
    }

    // MARK: - Setup

    private func setupAudioEngine() {
        let inputNode = audioEngine.inputNode
        let outputNode = audioEngine.outputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Configurar EQ
        for (index, frequency) in standardFrequencies.enumerated() {
            let band = eq.bands[index]
            band.frequency = frequency
            band.gain = 0.0
            band.bypass = false
            band.filterType = .parametric

            // Q factor apropiado para cada rango
            if frequency < 100 {
                band.bandwidth = 0.5  // Más ancho para bajos
            } else if frequency > 8000 {
                band.bandwidth = 0.5  // Más ancho para altos
            } else {
                band.bandwidth = 0.7  // Default para medios
            }
        }

        // Conectar nodos: Input -> EQ -> Output
        audioEngine.attach(eq)
        audioEngine.connect(inputNode, to: eq, format: format)
        audioEngine.connect(eq, to: outputNode, format: format)

        print("TuneUpEngine: Audio engine configured")
    }

    // MARK: - Engine Control

    func start() throws {
        guard !isRunning else {
            print("TuneUpEngine: Already running")
            return
        }

        do {
            try audioEngine.start()
            isRunning = true
            print("TuneUpEngine: Started successfully")
        } catch {
            print("TuneUpEngine: Failed to start - \(error.localizedDescription)")
            throw error
        }
    }

    func stop() {
        guard isRunning else { return }

        audioEngine.stop()
        isRunning = false
        print("TuneUpEngine: Stopped")
    }

    // MARK: - Profile Application

    func applyProfile(_ profile: EQProfile) {
        print("TuneUpEngine: Applying profile '\(profile.name)'")

        guard profile.gains.count == standardFrequencies.count else {
            print("TuneUpEngine: Error - Invalid profile (wrong number of gains)")
            return
        }

        for (index, gain) in profile.gains.enumerated() {
            let band = eq.bands[index]
            band.gain = gain

            print("  Band \(index): \(standardFrequencies[index]) Hz = \(gain > 0 ? "+" : "")\(gain) dB")
        }

        print("TuneUpEngine: Profile applied")
    }

    // MARK: - Manual Band Control

    func setGain(forBand bandIndex: Int, gain: Float) {
        guard bandIndex >= 0 && bandIndex < eq.bands.count else {
            print("TuneUpEngine: Error - Invalid band index")
            return
        }

        eq.bands[bandIndex].gain = gain
        print("TuneUpEngine: Band \(bandIndex) (\(standardFrequencies[bandIndex]) Hz) set to \(gain) dB")
    }

    func setFrequency(forBand bandIndex: Int, frequency: Float) {
        guard bandIndex >= 0 && bandIndex < eq.bands.count else {
            print("TuneUpEngine: Error - Invalid band index")
            return
        }

        eq.bands[bandIndex].frequency = frequency
        print("TuneUpEngine: Band \(bandIndex) frequency set to \(frequency) Hz")
    }

    // MARK: - Getters

    func getCurrentGains() -> [Float] {
        return eq.bands.map { $0.gain }
    }

    func getBandInfo(index: Int) -> (frequency: Float, gain: Float, bandwidth: Float)? {
        guard index >= 0 && index < eq.bands.count else { return nil }

        let band = eq.bands[index]
        return (band.frequency, band.gain, band.bandwidth)
    }
}

// MARK: - CLI Tool

// Este sería el ejecutable que HammerSpoon llamaría
// Compilado como: swiftc -o tuneup-cli phase3-prototype.swift

class TuneUpCLI {

    static func main() {
        let arguments = CommandLine.arguments

        guard arguments.count > 1 else {
            printUsage()
            exit(1)
        }

        let command = arguments[1]
        let engine = TuneUpEngine()

        switch command {
        case "start":
            do {
                try engine.start()
                print("Engine started. Press Ctrl+C to stop.")
                RunLoop.main.run()
            } catch {
                print("Failed to start: \(error)")
                exit(1)
            }

        case "apply":
            guard arguments.count > 2 else {
                print("Usage: tuneup-cli apply <profile>")
                exit(1)
            }

            let profileName = arguments[2]
            let profile: TuneUpEngine.EQProfile

            switch profileName {
            case "normal":
                profile = .normal
            case "bass_boosted":
                profile = .bassBoost
            case "vocal_enhance":
                profile = .vocalEnhance
            case "treble_boost":
                profile = .trebleBoost
            case "v_shape":
                profile = .vShape
            default:
                print("Unknown profile: \(profileName)")
                exit(1)
            }

            do {
                try engine.start()
                engine.applyProfile(profile)

                // Keep running
                print("Profile applied. Press Ctrl+C to stop.")
                RunLoop.main.run()
            } catch {
                print("Failed: \(error)")
                exit(1)
            }

        case "status":
            print("TuneUp Engine Status:")
            print("Current gains: \(engine.getCurrentGains())")

        default:
            print("Unknown command: \(command)")
            printUsage()
            exit(1)
        }
    }

    static func printUsage() {
        print("""
        TuneUp CLI - Audio EQ Engine

        Usage:
          tuneup-cli start
          tuneup-cli apply <profile>
          tuneup-cli status

        Profiles:
          normal, bass_boosted, vocal_enhance, treble_boost, v_shape

        Examples:
          tuneup-cli apply bass_boosted
          tuneup-cli start
        """)
    }
}

// MARK: - HammerSpoon Integration Example

/*
 En tuneup.lua (Fase 3), cambiarías applyProfile así:

 function tuneup.applyProfile(profileKey)
     local profile = tuneup.profiles[profileKey]
     if not profile then
         hs.alert.show("❌ Unknown profile")
         return false
     end

     -- Ejecutar el CLI tool
     local cmd = string.format(
         "/usr/local/bin/tuneup-cli apply %s &",
         profileKey
     )

     os.execute(cmd)

     -- Actualizar estado
     tuneup.currentProfile = profileKey
     tuneup.saveSettings()

     hs.alert.show(profile.icon .. " " .. profile.name)
     return true
 end
*/

// MARK: - Device Change Watcher (Bonus)

import CoreAudio

class AudioDeviceWatcher {

    private var propertyListenerBlock: AudioObjectPropertyListenerBlock?

    func startWatching(onChange: @escaping () -> Void) {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        propertyListenerBlock = { (inNumberAddresses, inAddresses) -> Void in
            print("Audio device changed!")
            onChange()
        }

        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.main,
            propertyListenerBlock!
        )

        if status != noErr {
            print("Failed to add device change listener: \(status)")
        } else {
            print("Watching for audio device changes...")
        }
    }

    func getCurrentOutputDevice() -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )

        guard status == noErr else {
            print("Failed to get device ID: \(status)")
            return nil
        }

        // Obtener nombre del dispositivo
        propertyAddress.mSelector = kAudioDevicePropertyDeviceNameCFString
        propertyAddress.mScope = kAudioObjectPropertyScopeGlobal

        var deviceName: CFString = "" as CFString
        propertySize = UInt32(MemoryLayout<CFString>.size)

        let nameStatus = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceName
        )

        guard nameStatus == noErr else {
            print("Failed to get device name: \(nameStatus)")
            return nil
        }

        return deviceName as String
    }
}

// MARK: - Usage Example

/*
 // Inicializar engine
 let engine = TuneUpEngine()

 // Iniciar
 try? engine.start()

 // Aplicar perfil
 engine.applyProfile(.bassBoost)

 // Watch device changes
 let watcher = AudioDeviceWatcher()
 watcher.startWatching {
     if let deviceName = watcher.getCurrentOutputDevice() {
         print("Switched to: \(deviceName)")
         // Aplicar perfil específico del dispositivo
     }
 }

 // Keep running
 RunLoop.main.run()
*/

// MARK: - Compilation Instructions

/*
 Para compilar este prototipo:

 1. Crear proyecto Swift:
    mkdir TuneUpEngine
    cd TuneUpEngine
    swift package init --type executable

 2. Editar Package.swift:
    // swift-tools-version:5.9
    import PackageDescription

    let package = Package(
        name: "TuneUpEngine",
        platforms: [
            .macOS(.v13)
        ],
        dependencies: [],
        targets: [
            .executableTarget(
                name: "tuneup-cli",
                dependencies: []
            )
        ]
    )

 3. Compilar:
    swift build -c release

 4. Instalar:
    cp .build/release/tuneup-cli /usr/local/bin/

 5. Usar desde HammerSpoon:
    os.execute("tuneup-cli apply bass_boosted &")
*/
