import Testing
@testable import PreludeBridge

@Test func channelMessagesAndRunningStatus() {
    var parser = MIDIParser()
    let bytes: [UInt8] = [0x99, 38, 100, 40, 80, 0x89, 38, 0]
    let messages = bytes.flatMap { parser.feed($0) }
    #expect(messages == [[0x99, 38, 100], [0x99, 40, 80], [0x89, 38, 0]])
}

@Test func realtimeDoesNotBreakMessage() {
    var parser = MIDIParser()
    let messages = [UInt8(0x90), 60, 0xF8, 127].flatMap { parser.feed($0) }
    #expect(messages == [[0xF8], [0x90, 60, 127]])
}

@Test func systemExclusive() {
    var parser = MIDIParser()
    let messages = [UInt8(0xF0), 1, 2, 0xF7].flatMap { parser.feed($0) }
    #expect(messages == [[0xF0, 1, 2, 0xF7]])
}

@Test func programChangeAndSystemCommon() {
    var parser = MIDIParser()
    let messages = [UInt8(0xC9), 12, 13, 0xF2, 1, 2].flatMap { parser.feed($0) }
    #expect(messages == [[0xC9, 12], [0xC9, 13], [0xF2, 1, 2]])
}

@Test func serialCandidateDiscovery() {
    let names = ["tty.usbserial-B", "cu.Bluetooth-Incoming-Port", "cu.usbserial-B", "cu.usbserial-A"]
    #expect(SerialDiscovery.candidates(from: names) == ["/dev/cu.usbserial-A", "/dev/cu.usbserial-B"])
}
