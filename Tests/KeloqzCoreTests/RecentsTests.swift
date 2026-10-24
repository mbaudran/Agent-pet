import Foundation
import Testing
@testable import KeloqzCore

@Test func newestFirstDistinct() {
    #expect(mergeRecent(["/a", "/b"], adding: ["/b", "/c"]) == ["/b", "/c", "/a"])
}

@Test func capsAtLimit() {
    #expect(mergeRecent(["/1", "/2", "/3", "/4", "/5"], adding: ["/6"]) == ["/6", "/1", "/2", "/3", "/4"])
}

@Test func ignoresEmptyFolders() {
    #expect(mergeRecent(["/a"], adding: ["", "/b"]) == ["/b", "/a"])
}

@Test func shellQuoteWrapsAndEscapesSingleQuotes() {
    #expect(shellQuote("/work/my app") == "'/work/my app'")
    #expect(shellQuote("/work/it's") == #"'/work/it'\''s'"#)
}

@Test func newSessionScriptEscapesForAppleScript() {
    #expect(newSessionScript(in: #"/w/say "hi"\x"#) ==
        #"tell application "Terminal" to do script "cd '/w/say \"hi\"\\x' && claude""#)
}
