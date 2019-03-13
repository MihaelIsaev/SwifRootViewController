# SwifRootViewController
🍀Useful root navigation view controller (by best practice)

## How to install

SwifRootViewController is available through [CocoaPods](https://cocoapods.org).

To install it, simply add the following line in your Podfile:
```ruby
pod 'SwifRootViewController', '~> 0.1.0'
```

## How to use

Create `RootViewController.swift` in your project and inherit it from `SwifRootViewCtonroller` like this

```swift
import UIKit
import SwifRootViewController

class RootViewController: SwifRootViewController<DeeplinkType> {
    override var splashScreen: UIViewController {
        return SplashViewController() // replace with yours
    }
    override var loginScreen: UIViewController {
        return LoginViewController() // replace with yours
    }
    // where user will be moved on `switchToLogout`
    override var logoutScreen: UIViewController {
        return LoginViewController() // replace with yours
    }
    // means your main view controller for authorized users
    override var mainScreen: UIViewController {
        return MainViewController() // replace with yours
    }
    // shows before main screen
    override var onboardingScreen: UIViewController? {
        // return something here to show it right after authorization
        return nil
    }
    // check authorization here and return proper screen
    override var initialScreen: UIViewController {
        return Session.shared.isAuthorized ? splashScreen : loginScreen
    }
    // handle deep links here
    override func handleDeepLink(type: DeeplinkType) {
        /// check you deep link in switch/case
        /// and go to the proper view controller
    }
}
```

If you don't want to use deep links for now you could use `SwifRootViewControllerSimple` instead of `SwifRootViewController<DeeplinkType>`

### Setting `RootViewController` as a window's `rootViewController`

```swift
@UIApplicationMain
class AppDelegateBase: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if super.application(application, didFinishLaunchingWithOptions: launchOptions) {
        // needed to set `RootViewController` aswindow's  `rootViewController`
        RootViewController().attach(to: &window)
        // needed for deep links registration
        // ShortcutParser.shared.registerShortcuts()
        return true
    }
    return false
  }
}
```

### Switching screens
First of all 
```swift

```

### Deep links

### Setting `RootViewController` as a window's `rootViewController`

ShortcutParser
```swift
import Foundation
import UIKit

enum ShortcutKey: String {
    case activity = "com.yourapp.activity"
    case messages = "com.yourapp.messages"
}

class ShortcutParser {
    static let shared = ShortcutParser()
    private init() { }
    
    func registerShortcuts() {
        let activityIcon = UIApplicationShortcutIcon(type: .invitation)
        let activityShortcutItem = UIApplicationShortcutItem(type: ShortcutKey.activity.rawValue, localizedTitle: "Recent Activity", localizedSubtitle: nil, icon: activityIcon, userInfo: nil)
        
        let messageIcon = UIApplicationShortcutIcon(type: .message)
        let messageShortcutItem = UIApplicationShortcutItem(type: ShortcutKey.messages.rawValue, localizedTitle: "Messages", localizedSubtitle: nil, icon: messageIcon, userInfo: nil)
        
        UIApplication.shared.shortcutItems = [activityShortcutItem, messageShortcutItem]
    }
    
    func handleShortcut(_ shortcut: UIApplicationShortcutItem) -> DeeplinkType? {
        switch shortcut.type {
        case ShortcutKey.activity.rawValue:
            return  .activity
        case ShortcutKey.messages.rawValue:
            return  .messages
        default:
            return nil
        }
    }
}
```

DeepLinkManager
```swift
import Foundation
import UIKit

// List your deeplinks in this enum
enum DeeplinkType {
    case messages
    case activity
}

let Deeplinker = DeepLinkManager()
class DeepLinkManager {
    fileprivate init() {}
    
    private var deeplinkType: DeeplinkType?
    
    @discardableResult
    func handleShortcut(item: UIApplicationShortcutItem) -> Bool {
        deeplinkType = ShortcutParser.shared.handleShortcut(item)
        return deeplinkType != nil
    }
    
    // check existing deepling and perform action
    func checkDeepLink() {
        if let rootViewController = AppDelegate.shared.rootViewController as? RootViewController {
            rootViewController.deeplink = deeplinkType
        }
        
        // reset deeplink after handling
        self.deeplinkType = nil
    }
}

```

Configure AppDelegate
```swift
@UIApplicationMain
class AppDelegateBase: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if super.application(application, didFinishLaunchingWithOptions: launchOptions) {
        // needed to set `RootViewController` aswindow's  `rootViewController`
        RootViewController().attach(to: &window)
        // needed for deep links registration
        ShortcutParser.shared.registerShortcuts()
        return true
    }
    return false
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    Deeplinker.checkDeepLink()
  }

  // MARK: Shortcuts

  func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    completionHandler(Deeplinker.handleShortcut(item: shortcutItem))
  }
}
``` 
