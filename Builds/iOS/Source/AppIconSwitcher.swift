import UIKit

@objc class AppIconSwitcher: NSObject {
    @objc static func setAppIcon(_ iconName: NSString?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Este dispositivo no soporta íconos alternativos.")
            return
        }

        UIApplication.shared.setAlternateIconName(iconName as String?) { error in
            if let error = error {
                print("Error al cambiar el ícono: \(error.localizedDescription)")
            } else {
                print("Ícono cambiado a: \(iconName ?? "AppIcon")")
            }
        }
    }
}