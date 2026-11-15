import Foundation

extension WineDetailView {
    /// The bottle's life, oldest first, from what is on record: how it came (given by
    /// someone, or bought, with its day and price), each move the cellar journal kept
    /// (a removal and a placement on the same day read as one move), then the present.
    /// A bottle still in the cellar ends on today and, ahead, the end of its drinking
    /// window; one that left ends on how it left: tasted, given, or taken out.
    /// Empty when nothing is known of it.
    static func timeline(_ detail: UserWineDetail, now: Date = .now) -> [WineTimeline.Step] {
        let calendar = Calendar.current
        let day: (Date) -> String = { $0.formatted(date: .abbreviated, time: .omitted) }
        let joined: ([String?]) -> String? = { parts in
            let kept = parts.compactMap { $0 }.filter { !$0.isEmpty }
            return kept.isEmpty ? nil : kept.joined(separator: " · ")
        }
        let inCellar = detail.cellar.map { $0.dateOut == nil } ?? false
        var steps: [WineTimeline.Step] = []

        // How it came.
        let bought = detail.purchaseDate.flatMap { purchaseDay($0) }
        let price = detail.purchasePrice.map { Money.formattedFromEur($0, fractionLength: 0) }
        if let giver = detail.giftedBy, !giver.isEmpty {
            steps.append(.init(
                id: "acquired",
                symbol: "gift",
                title: String(localized: "Offerte par \(giver)"),
                detail: joined([bought, price.map { String(localized: "Valeur \($0)") }])
            ))
        } else if bought != nil || price != nil {
            steps.append(.init(id: "acquired", symbol: "bag", title: String(localized: "Achetée"), detail: joined([bought, price])))
        }

        // The cellar journal; a wine placed before the journal existed still has its slot.
        // A move writes its removal and its placement at the same instant: the removal first.
        var moves = detail.moves.sorted {
            $0.date != $1.date ? $0.date < $1.date : ($0.kind == .removed && $1.kind == .placed)
        }
        if moves.isEmpty, let cellar = detail.cellar {
            moves = [CellarMove(kind: .placed, date: cellar.dateIn, position: "\(cellar.row)\(cellar.col)")]
        }
        // The last removal of a bottle that left is told by how it left, below.
        var exit: CellarMove?
        if !inCellar, let last = moves.last, last.kind == .removed {
            exit = moves.removeLast()
        }
        var index = 0
        while index < moves.count {
            let move = moves[index]
            let next = index + 1 < moves.count ? moves[index + 1] : nil
            if move.kind == .removed, let next, next.kind == .placed,
               calendar.isDate(move.date, inSameDayAs: next.date) {
                let by = next.byName ?? move.byName
                steps.append(.init(
                    id: "move-\(index)",
                    symbol: "arrow.left.arrow.right",
                    title: by.map { String(localized: "Déplacée par \($0)") } ?? String(localized: "Déplacée"),
                    detail: joined([day(next.date), String(localized: "De \(move.position) vers \(next.position)")])
                ))
                index += 2
                continue
            }
            if move.kind == .placed {
                steps.append(.init(
                    id: "in-\(index)",
                    symbol: "tray.and.arrow.down",
                    title: String(localized: "Entrée en cave"),
                    detail: joined([day(move.date), move.position, move.byName])
                ))
            } else {
                steps.append(.init(
                    id: "out-\(index)",
                    symbol: "tray.and.arrow.up",
                    title: String(localized: "Sortie de la cave"),
                    detail: joined([day(move.date), move.position, move.byName])
                ))
            }
            index += 1
        }

        // The present.
        if inCellar {
            let since = detail.cellar.map { timeInCellar(since: $0.dateIn, now: now) }
            steps.append(.init(
                id: "today",
                symbol: "clock",
                title: String(localized: "Aujourd’hui"),
                detail: joined([day(now), since]),
                state: .current
            ))
            if let until = detail.drinkUntil {
                let year = calendar.component(.year, from: now)
                let ready: String? = if let from = detail.drinkFrom, from > year {
                    String(localized: "À ouvrir à partir de \(String(from))")
                } else if until > year {
                    String(localized: "Prête à déguster, encore \(until - year) ans")
                } else {
                    String(localized: "Prête à déguster")
                }
                steps.append(.init(
                    id: "window",
                    symbol: "wineglass",
                    title: String(localized: "Fin de garde"),
                    detail: joined([String(until), ready]),
                    state: .future
                ))
            }
            return steps
        }

        let leftFrom = exit.map { String(localized: "Sortie de \($0.position)") }
        if let consumption = detail.consumption, let tasted = consumption.consumedDate {
            let company = consumption.contacts.flatMap { $0.isEmpty ? nil : $0.formatted(.list(type: .and)) }
            steps.append(.init(
                id: "end",
                symbol: "wineglass",
                title: company.map { String(localized: "Dégustée avec \($0)") } ?? String(localized: "Dégustée"),
                detail: joined([day(tasted), leftFrom]),
                state: .current
            ))
        } else if let gift = detail.gift {
            steps.append(.init(
                id: "end",
                symbol: "gift",
                title: gift.recipientName.map { String(localized: "Offerte à \($0)") } ?? String(localized: "Offerte"),
                detail: joined([day(gift.giftedDate), leftFrom]),
                state: .current
            ))
        } else if let exit {
            steps.append(.init(
                id: "end",
                symbol: "tray.and.arrow.up",
                title: String(localized: "Sortie de la cave"),
                detail: joined([day(exit.date), exit.position, exit.byName]),
                state: .current
            ))
        }
        return steps
    }
}
