import Testing
@testable import wakuwaku_typing

struct KanaKeyboardModelTests {
    @Test func gridShape() {
        #expect(KanaKeyboardModel.rows.count == 4)
        for row in KanaKeyboardModel.rows {
            #expect(row.count == 3)
        }
    }

    @Test func aRowMatchesPrototype() {
        // Row 1: あ key — center=あ, left=い, up=う, right=え, down=お
        guard case .kana(let aKey) = KanaKeyboardModel.rows[0][0] else {
            Issue.record("expected kana key")
            return
        }
        #expect(aKey.center == "あ")
        #expect(aKey.left == "い")
        #expect(aKey.up == "う")
        #expect(aKey.right == "え")
        #expect(aKey.down == "お")
    }

    @Test func waRowMatchesPrototype() {
        // Row 4: わ key — center=わ, left=を, up=ん, right=ー, down=〜
        guard case .kana(let waKey) = KanaKeyboardModel.rows[3][1] else {
            Issue.record("expected kana key")
            return
        }
        #expect(waKey.center == "わ")
        #expect(waKey.left == "を")
        #expect(waKey.up == "ん")
        #expect(waKey.right == "ー")
        #expect(waKey.down == "〜")
    }

    @Test func yaKeyOnlyHasYaYuYo() {
        // Row 3: や key — only や/ゆ/よ are valid (left/right are ( ) in prototype, omitted here)
        guard case .kana(let yaKey) = KanaKeyboardModel.rows[2][1] else {
            Issue.record("expected kana key")
            return
        }
        #expect(yaKey.center == "や")
        #expect(yaKey.up == "ゆ")
        #expect(yaKey.down == "よ")
        #expect(yaKey.left == nil)
        #expect(yaKey.right == nil)
    }

    @Test func cornerKeysAreSpecial() {
        if case .special(let s) = KanaKeyboardModel.rows[3][0] {
            #expect(s == .modifier)
        } else {
            Issue.record("expected modifier key at row 4 col 1")
        }
        if case .special(let s) = KanaKeyboardModel.rows[3][2] {
            #expect(s == .punctuation)
        } else {
            Issue.record("expected punctuation key at row 4 col 3")
        }
    }

    @Test func keyForKana() {
        let kForKi = KanaKeyboardModel.key(producing: "き")
        #expect(kForKi?.key.center == "か")
        #expect(kForKi?.direction == .left)

        let kForN = KanaKeyboardModel.key(producing: "ん")
        #expect(kForN?.key.center == "わ")
        #expect(kForN?.direction == .up)

        let kForKo = KanaKeyboardModel.key(producing: "こ")
        #expect(kForKo?.key.center == "か")
        #expect(kForKo?.direction == .down)
    }
}
