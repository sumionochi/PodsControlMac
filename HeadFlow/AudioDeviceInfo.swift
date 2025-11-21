// AudioDeviceInfo.swift
import Foundation
import CoreAudio

/// Small helper around Core Audio to fetch the current default output device name.
enum AudioDeviceInfo {

    /// Returns the name of the system's default output device, e.g. "Mito’s AirPods Pro"
    static func defaultOutputDeviceName() -> String? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)

        // Get default output device ID
        var status = AudioObjectGetPropertyData(
            systemObjectID,
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        if status != noErr || deviceID == 0 {
            print("AudioDeviceInfo: failed to get default output device id, status = \(status)")
            return nil
        }

        // Get device name (CFString)
        var name: CFString = "" as CFString
        size = UInt32(MemoryLayout<CFString>.size)

        address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        status = withUnsafeMutablePointer(to: &name) { namePtr in
            AudioObjectGetPropertyData(
                deviceID,
                &address,
                0,
                nil,
                &size,
                namePtr
            )
        }

        if status != noErr {
            print("AudioDeviceInfo: failed to get device name, status = \(status)")
            return nil
        }

        return name as String
    }
}
