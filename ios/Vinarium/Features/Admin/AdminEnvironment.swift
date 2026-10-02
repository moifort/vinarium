import SwiftUI

extension EnvironmentValues {
    /// The signed-in account has access to the admin surfaces (home toolbar button, settings row,
    /// Admin screen). Set at the root (`AuthRoot`) from the launch `me` query; false
    /// everywhere else, so those surfaces are simply absent for everyone else.
    @Entry var isAdmin: Bool = false
}
