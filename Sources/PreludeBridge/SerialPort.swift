import Darwin
import Foundation

enum SerialError: Error, CustomStringConvertible {
    case posix(String, Int32)
    case unsupportedSpeed(Int)

    var description: String {
        switch self {
        case let .posix(operation, code): return "\(operation): \(String(cString: strerror(code)))"
        case let .unsupportedSpeed(speed): return "não foi possível configurar a velocidade exata de \(speed) baud"
        }
    }
}

final class SerialPort {
    private(set) var fd: Int32 = -1

    init(path: String, baud: Int) throws {
        fd = open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)
        guard fd >= 0 else { throw SerialError.posix("abrir \(path)", errno) }
        do { try configure(baud: baud) } catch { close(fd); fd = -1; throw error }
    }

    deinit { if fd >= 0 { close(fd) } }

    func read(into buffer: UnsafeMutablePointer<UInt8>, count: Int) -> Int {
        Darwin.read(fd, buffer, count)
    }

    private func configure(baud: Int) throws {
        var options = termios()
        guard tcgetattr(fd, &options) == 0 else { throw SerialError.posix("tcgetattr", errno) }
        cfmakeraw(&options)
        options.c_cflag |= tcflag_t(CLOCAL | CREAD)
        options.c_cflag &= ~tcflag_t(CSTOPB | PARENB | CRTSCTS)
        options.c_cflag = (options.c_cflag & ~tcflag_t(CSIZE)) | tcflag_t(CS8)
        options.c_cc.16 = 1   // VMIN
        options.c_cc.17 = 1   // VTIME (0.1 s)
        guard tcsetattr(fd, TCSANOW, &options) == 0 else { throw SerialError.posix("tcsetattr", errno) }

        // IOSSIOSPEED asks the Apple FTDI driver for an arbitrary baud rate.
        // _IOW('T', 2, speed_t) on Darwin; spelling it locally avoids private headers.
        let request = UInt(0x8008_5402)
        var exactSpeed = UInt64(baud)
        guard ioctl(fd, request, &exactSpeed) == 0 else {
            throw SerialError.unsupportedSpeed(baud)
        }
        _ = fcntl(fd, F_SETFL, 0)
        tcflush(fd, TCIOFLUSH)
    }
}
