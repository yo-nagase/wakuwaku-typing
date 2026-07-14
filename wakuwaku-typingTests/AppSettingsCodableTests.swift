import Testing
import Foundation
@testable import wakuwaku_typing

struct AppSettingsCodableTests {
    /// inputMode 追加前（v1.x）の保存 JSON と同じキー構成
    private let legacySettingsJSON = """
    {"name":"ABC","onboarded":true,"theme":"neon","duration":30,"packID":"kotowaza","difficulty":"normal","soundOn":true,"hapticsOn":false}
    """

    @Test func legacyJSONWithoutInputModeDefaultsToFlick() throws {
        let s = try JSONDecoder().decode(AppSettings.self, from: Data(legacySettingsJSON.utf8))
        #expect(s.inputMode == .flick)
        #expect(s.name == "ABC")
        #expect(s.hapticsOn == false)
    }

    @Test func legacyStorageDecodesWithoutDataLoss() throws {
        let json = """
        {"settings":\(legacySettingsJSON),"history":[{"id":"00000000-0000-0000-0000-000000000000","date":700000000,"wpm":10,"acc":95,"combo":8,"words":5,"time":30,"course":"ことわざ / 30s","score":42}],"cumulativeScore":42,"totalGames":1}
        """
        let storage = try JSONDecoder().decode(Persistence.Storage.self, from: Data(json.utf8))
        #expect(storage.settings.inputMode == .flick)
        #expect(storage.history.count == 1)
        #expect(storage.cumulativeScore == 42)
    }

    @Test func roundTripsRomajiMode() throws {
        var s = AppSettings.default
        s.inputMode = .romaji
        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(s))
        #expect(decoded.inputMode == .romaji)
    }
}
