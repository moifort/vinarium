import Foundation

/// Les chiffres du mois que les surfaces admin affichent : coûts mesurés
/// (tokens Gemini, facture GCP), revenus App Store et comptes.
struct AdminMetrics {
    struct TokenUsage {
        let promptTokens: Int
        let outputTokens: Int
        let thinkingTokens: Int
    }

    let aiCostEur: Double
    /// Facture GCP mesurée du projet, nil tant que l'export de facturation n'est
    /// pas configuré ou n'a pas encore répondu. Aucune ligne fixe : l'abonnement
    /// Apple Developer, partagé entre plusieurs projets, en est volontairement exclu.
    let infraEur: Double?
    let totalCostEur: Double
    let totalUsers: Int
    let premiumTotal: Int
    let premiumMonthly: Int
    let premiumYearly: Int
    /// Net encaissé (ce qu'Apple reverse), nil tant que la clé App Store Connect n'a pas répondu.
    let revenueProceedsEur: Double?
    let revenueGrossEur: Double?
    let scans: Int
    let cacheHits: Int
    let vision: TokenUsage
    let enrichment: TokenUsage
    /// Dernier passage du rafraîchissement quotidien, nil avant sa première exécution.
    let refreshedAt: Date?
}
