import SwiftUI

extension EnvironmentValues {
    /// Le compte connecté a accès aux surfaces admin (bandeau, ligne des
    /// Réglages, écran Admin). Posé à la racine (`AuthRoot`) depuis la requête
    /// `me` du lancement ; false partout ailleurs, donc les surfaces sont
    /// simplement absentes pour tout le monde.
    @Entry var isAdmin: Bool = false
}
