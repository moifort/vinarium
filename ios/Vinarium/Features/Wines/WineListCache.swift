import Foundation

/// The list's opening page, kept on disk so a relaunch opens on the wines seen last
/// time instead of on a loader. A cellar changes slowly: the page written last time is
/// almost always the page the server is about to send, and a row one session old is
/// worth far more than an empty screen. The cached page draws first, the server's
/// answer replaces it a moment later.
///
/// It lives in the caches directory, which the system may reclaim at will — that is
/// what a cache is for, and losing it costs one loader. Only the page the list *opens*
/// on is written: a sorted, filtered or other-view list is a question the user asked,
/// not what to draw on the next launch.
struct WineListCache: Sendable {
    /// Bump whenever `Wine` changes shape. An older file is then ignored instead of
    /// decoded into something that no longer means the same thing.
    private static let version = 1

    private static var file: URL {
        URL.cachesDirectory.appending(path: "wine-list.json")
    }

    /// The wines of the last visit, or `nil` when there is no usable file: a first
    /// launch, a cache the system reclaimed, or a file written by an older shape. An
    /// empty file reads as nothing too — an empty cellar must show its empty state, not
    /// a list that is briefly empty for a different reason.
    func read() -> [Wine]? {
        guard let data = try? Data(contentsOf: Self.file),
              let stored = try? JSONDecoder().decode(Stored.self, from: data),
              stored.version == Self.version,
              !stored.items.isEmpty
        else { return nil }
        return stored.items
    }

    /// Overwrite the file with what is on screen. A failure is swallowed on purpose: a
    /// cache that cannot be written costs a loader on the next launch, nothing more.
    func write(_ items: [Wine]) {
        guard let data = try? JSONEncoder().encode(Stored(version: Self.version, items: items))
        else { return }
        try? data.write(to: Self.file, options: .atomic)
    }

    /// Forget the list. Called when the session ends: whoever opens the app next must
    /// not read the previous account's cellar before the server has said a word.
    static func clear() {
        try? FileManager.default.removeItem(at: file)
    }

    private struct Stored: Codable {
        let version: Int
        let items: [Wine]
    }
}
