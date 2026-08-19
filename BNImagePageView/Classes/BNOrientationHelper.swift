import UIKit

public enum BNOrientationHelper {
    public static func unlock() {
        if #available(iOS 16.0, *) {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first else { return }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
            UIViewController.attemptRotationToDeviceOrientation()
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.unknown.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }

    public static func lockPortrait() {
        if #available(iOS 16.0, *) {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first else { return }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}
