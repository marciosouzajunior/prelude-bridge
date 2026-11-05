import CoreMIDI
import Darwin
import Foundation

struct Options {
    var serial: String?
    var baud = 31_250
    var monitor = false
    var noMIDI = false

    static func parse() throws -> Options {
        var result = Options()
        var args = Array(CommandLine.arguments.dropFirst())
        while !args.isEmpty {
            let arg = args.removeFirst()
            switch arg {
            case "--serial": guard !args.isEmpty else { throw UsageError() }; result.serial = args.removeFirst()
            case "--baud": guard let value = args.first.flatMap(Int.init) else { throw UsageError() }; args.removeFirst(); result.baud = value
            case "--monitor": result.monitor = true
            case "--no-midi": result.noMIDI = true
            case "--version": print("prelude-bridge 0.1.0"); exit(0)
            case "--help", "-h": printUsage(); exit(0)
            default: throw UsageError()
            }
        }
        return result
    }
}

struct UsageError: Error {}
func printUsage() {
    print("""
    Uso: prelude-bridge [opções]

      --serial CAMINHO  Porta serial; descoberta automaticamente se houver apenas uma
      --baud VALOR      Velocidade serial (padrão: 31250)
      --monitor         Mostra os bytes recebidos em hexadecimal
      --no-midi         Não cria a fonte virtual CoreMIDI
      --version         Mostra a versão
      -h, --help        Mostra esta ajuda
    """)
}

final class VirtualMIDISource {
    private var client = MIDIClientRef()
    private var source = MIDIEndpointRef()

    init(name: String) throws {
        var status = MIDIClientCreateWithBlock("Prelude Bridge" as CFString, &client) { _ in }
        guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        status = MIDISourceCreate(client, name as CFString, &source)
        guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    deinit { MIDIEndpointDispose(source); MIDIClientDispose(client) }

    func send(_ bytes: [UInt8]) {
        var packetList = MIDIPacketList()
        let packet = MIDIPacketListInit(&packetList)
        bytes.withUnsafeBufferPointer { data in
            _ = MIDIPacketListAdd(&packetList, MemoryLayout<MIDIPacketList>.size, packet, 0, data.count, data.baseAddress!)
        }
        MIDIReceived(source, &packetList)
    }
}

do {
    let options = try Options.parse()
    let serialPath = try SerialDiscovery.resolve(explicitPath: options.serial)
    let port = try SerialPort(path: serialPath, baud: options.baud)
    let midi = options.noMIDI ? nil : try VirtualMIDISource(name: "Prelude MIDI Bridge")
    print("Prelude aberta em \(serialPath), \(options.baud) baud.")
    if midi != nil { print("Fonte CoreMIDI virtual: Prelude MIDI Bridge") }
    print("Aguardando MIDI; pressione Ctrl-C para encerrar.")

    var parser = MIDIParser()
    var buffer = [UInt8](repeating: 0, count: 256)
    while true {
        let count = buffer.withUnsafeMutableBufferPointer { port.read(into: $0.baseAddress!, count: $0.count) }
        if count > 0 {
            for byte in buffer.prefix(count) {
                if options.monitor { print(String(format: "%02X", byte), terminator: " "); fflush(stdout) }
                for message in parser.feed(byte) { midi?.send(message) }
            }
        } else if count < 0 && errno != EINTR && errno != EAGAIN {
            throw SerialError.posix("leitura serial", errno)
        }
    }
} catch is UsageError {
    printUsage(); exit(64)
} catch {
    fputs("Erro: \(error)\n", stderr); exit(1)
}
