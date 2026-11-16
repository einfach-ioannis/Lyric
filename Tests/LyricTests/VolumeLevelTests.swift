import Testing
@testable import Lyric

struct VolumeLevelTests {
    @Test func clampsToRange() {
        #expect(VolumeLevel.clamped(-10) == 0)
        #expect(VolumeLevel.clamped(55.5) == 55.5)
        #expect(VolumeLevel.clamped(250) == 100)
        #expect(VolumeLevel.clamped(.nan) == 0)
        #expect(VolumeLevel.clamped(.infinity) == 0)
    }

    @Test func stepsRoundToIntegers() {
        #expect(VolumeLevel.step(41.4) == 41)
        #expect(VolumeLevel.step(41.6) == 42)
        #expect(VolumeLevel.step(120) == 100)
    }

    @Test func sendsOnlyWhenTheStepChanges() {
        #expect(VolumeLevel.needsSend(from: nil, to: 30))
        #expect(!VolumeLevel.needsSend(from: 30.1, to: 30.4))
        #expect(VolumeLevel.needsSend(from: 30.4, to: 30.6))
        #expect(!VolumeLevel.needsSend(from: 100, to: 130))
    }
}
