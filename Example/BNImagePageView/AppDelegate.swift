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
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        switch topController {
        case is BNImagePageGridView, is BNImagePageGridHideShareView, is BNImagePageViewController:
            print("[BNOrientation] \(type(of: topController!)) → .all")
            return .all
        default:
            print("[BNOrientation] \(type(of: topController as AnyObject)) → .portrait")
            return .portrait
        }
    }
}

