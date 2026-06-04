import Foundation

struct SaveKeys {
    static let highScoreTime    = "highScoreTime"
    static let highScoreCoins   = "highScoreCoins"
    static let totalKills       = "totalKills"
    static let totalGamesPlayed = "totalGamesPlayed"
    static let totalCoinsEarned = "totalCoinsEarned"
    static let isMuted          = "isMuted"
    static let isAdFree         = "isAdFree"
    static let bgmVolume        = "bgmVolume"
    static let sfxVolume        = "sfxVolume"
    static let hasSeenTutorial  = "hasSeenTutorial"
}

final class SaveManager {
    static let shared = SaveManager()
    private let ud = UserDefaults.standard

    private init() {}

    func saveGameSession(_ session: GameSession) {
        if session.survivalTime > ud.double(forKey: SaveKeys.highScoreTime) {
            ud.set(session.survivalTime, forKey: SaveKeys.highScoreTime)
        }
        if session.totalCoins > ud.integer(forKey: SaveKeys.highScoreCoins) {
            ud.set(session.totalCoins, forKey: SaveKeys.highScoreCoins)
        }
        let kills = ud.integer(forKey: SaveKeys.totalKills)
        ud.set(kills + session.totalKills, forKey: SaveKeys.totalKills)

        let coins = ud.integer(forKey: SaveKeys.totalCoinsEarned)
        ud.set(coins + session.totalCoins, forKey: SaveKeys.totalCoinsEarned)

        let games = ud.integer(forKey: SaveKeys.totalGamesPlayed)
        ud.set(games + 1, forKey: SaveKeys.totalGamesPlayed)
    }

    var highScoreTime:  TimeInterval { ud.double(forKey: SaveKeys.highScoreTime) }
    var highScoreCoins: Int          { ud.integer(forKey: SaveKeys.highScoreCoins) }
    var totalKills:     Int          { ud.integer(forKey: SaveKeys.totalKills) }
    var totalGamesPlayed: Int        { ud.integer(forKey: SaveKeys.totalGamesPlayed) }
    var isMuted:        Bool         { ud.bool(forKey: SaveKeys.isMuted) }
    var isAdFree:       Bool         { ud.bool(forKey: SaveKeys.isAdFree) }
    var bgmVolume:      Float        { ud.float(forKey: SaveKeys.bgmVolume) == 0 ? 0.5 : ud.float(forKey: SaveKeys.bgmVolume) }
    var sfxVolume:      Float        { ud.float(forKey: SaveKeys.sfxVolume) == 0 ? 0.8 : ud.float(forKey: SaveKeys.sfxVolume) }
    var hasSeenTutorial: Bool        { ud.bool(forKey: SaveKeys.hasSeenTutorial) }

    func setMuted(_ v: Bool)          { ud.set(v, forKey: SaveKeys.isMuted) }
    func setAdFree(_ v: Bool)         { ud.set(v, forKey: SaveKeys.isAdFree) }
    func setTutorialSeen()            { ud.set(true, forKey: SaveKeys.hasSeenTutorial) }
}
