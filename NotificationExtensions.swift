import Foundation

// Уведомления об обновлении пароля
extension Notification.Name {
    static let passwordUpdatedFromAPI = Notification.Name("passwordUpdatedFromAPI")
    static let resetEmergencyIndication = Notification.Name("resetEmergencyIndication")
    static let ghostEffectChanged = Notification.Name("ghostEffectChanged")
} 