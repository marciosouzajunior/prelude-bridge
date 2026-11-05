import Foundation

enum SerialDiscoveryError: Error, CustomStringConvertible {
    case noneFound
    case multipleFound([String])

    var description: String {
        switch self {
        case .noneFound:
            return "nenhuma porta /dev/cu.usbserial-* foi encontrada; conecte a Prelude ou use --serial CAMINHO"
        case let .multipleFound(paths):
            return "mais de uma porta serial FTDI foi encontrada; use --serial CAMINHO:\n  \(paths.joined(separator: "\n  "))"
        }
    }
}

enum SerialDiscovery {
    static func candidates(from deviceNames: [String]) -> [String] {
        deviceNames
            .filter { $0.hasPrefix("cu.usbserial-") }
            .map { "/dev/\($0)" }
            .sorted()
    }

    static func resolve(explicitPath: String?) throws -> String {
        if let explicitPath { return explicitPath }
        let names = try FileManager.default.contentsOfDirectory(atPath: "/dev")
        let paths = candidates(from: names)
        switch paths.count {
        case 1: return paths[0]
        case 0: throw SerialDiscoveryError.noneFound
        default: throw SerialDiscoveryError.multipleFound(paths)
        }
    }
}
