import Foundation

struct MIDIParser {
    private var runningStatus: UInt8?
    private var message: [UInt8] = []
    private var expectedDataBytes = 0
    private var inSysEx = false

    mutating func feed(_ byte: UInt8) -> [[UInt8]] {
        // System real-time bytes may occur anywhere and do not disturb state.
        if byte >= 0xF8 { return [[byte]] }

        if inSysEx {
            message.append(byte)
            if byte == 0xF7 {
                inSysEx = false
                let complete = message
                message.removeAll(keepingCapacity: true)
                return [complete]
            }
            return []
        }

        if byte >= 0x80 {
            if byte == 0xF0 {
                runningStatus = nil
                inSysEx = true
                message = [byte]
                return []
            }

            runningStatus = byte < 0xF0 ? byte : nil
            message = [byte]
            expectedDataBytes = Self.dataLength(for: byte)
            if expectedDataBytes == 0 {
                let complete = message
                message.removeAll(keepingCapacity: true)
                return [complete]
            }
            return []
        }

        if message.isEmpty {
            guard let status = runningStatus else { return [] }
            message = [status]
            expectedDataBytes = Self.dataLength(for: status)
        }

        message.append(byte)
        if message.count == expectedDataBytes + 1 {
            let complete = message
            message.removeAll(keepingCapacity: true)
            return [complete]
        }
        return []
    }

    private static func dataLength(for status: UInt8) -> Int {
        switch status {
        case 0x80...0xBF, 0xE0...0xEF: return 2
        case 0xC0...0xDF: return 1
        case 0xF1, 0xF3: return 1
        case 0xF2: return 2
        default: return 0
        }
    }
}
