import UIKit
import BNImagePageView

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        var topController = window?.rootViewController
        var allControllers: [UIViewController] = []
        while let presented = topController?.presentedViewController {
            allControllers.append(presented)
            topController = presented
        }
        let isBNPresent = allControllers.contains {
            $0 is BNImagePageGridView || $0 is BNImagePageGridHideShareView || $0 is BNImagePageViewController
        }
        if isBNPresent { return .all }
        let isBNDismissing = allControllers.contains { $0.isBeingDismissed &&
            ($0 is BNImagePageGridView || $0 is BNImagePageGridHideShareView || $0 is BNImagePageViewController)
        }
        if isBNDismissing { return .all }
        return .portrait
    }
}

