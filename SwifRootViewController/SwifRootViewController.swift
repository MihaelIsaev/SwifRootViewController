import UIKit

public protocol SwifRootViewControllerable {
    var splashScreen: UIViewController { get }
    var loginScreen: UIViewController { get }
    var logoutScreen: UIViewController { get }
    var mainScreen: UIViewController { get }
    var onboardingScreen: UIViewController? { get }

    func showLoginScreen()
    func showOnboardingScreen() -> Bool
    func switchToLogout()
    func switchToMainScreen()
}

typealias SwifRootViewControllerSimple = SwifRootViewController<Never>

open class SwifRootViewController<DeeplinkType>: UIViewController, SwifRootViewControllerable {
    
    public internal(set) var current: UIViewController = UIViewController()
    
    enum ScreenType {
        case splash, login, logout, main, onboarding, nothing
    }
    
    var currentType: ScreenType = .nothing
    
    public var deeplink: DeeplinkType? {
        didSet {
            if let deeplink = deeplink {
                handleDeepLink(type: deeplink)
            }
        }
    }
    
    open var splashScreen: UIViewController { print("a splashScreen"); return UIViewController() }
    open var loginScreen: UIViewController { print("a loginScreen"); return UIViewController() }
    open var logoutScreen: UIViewController { print("a logoutScreen"); return UIViewController() }
    open var mainScreen: UIViewController { print("a mainScreen"); return UIViewController() }
    open var onboardingScreen: UIViewController? { return nil }
    
    open var initialScreen: UIViewController { print("a initialScreen"); return splashScreen }
    
    open var shouldShowOnboardingBeforeMainScreen: Bool { return true }
    
    public init() {
        super.init(nibName:  nil, bundle: nil)
        current = initialScreen
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(current)
        current.view.frame = view.bounds
        view.addSubview(current.view)
        current.didMove(toParent: self)
    }
    
    open func showLoginScreen() {
        if currentType == .login {
            print("⚠️ Don't show login twice")
            return
        }
        currentType = .login
        replaceWithoutAnimation(loginScreen)
    }
    
    @discardableResult
    open func showOnboardingScreen() -> Bool {
        guard let new = onboardingScreen else { return false }
        if currentType == .onboarding {
            print("⚠️ Don't show onboarding twice")
            return false
        }
        currentType = .onboarding
        replaceWithoutAnimation(new)
        return true
    }
    
    open func switchToLogout() {
        if currentType == .logout {
            print("⚠️ Don't call switch to logout twice")
            return
        }
        currentType = .logout
        animateDismissTransition(to: logoutScreen)
    }
    
    open func switchToMainScreen() {
        if currentType == .main {
            print("⚠️ Don't call switch to main screen twice")
            return
        }
        currentType = .main
        if shouldShowOnboardingBeforeMainScreen, showOnboardingScreen() { return }
        animateFadeTransition(to: mainScreen) { [weak self] in
            if let deeplink = self?.deeplink {
                self?.handleDeepLink(type: deeplink)
            }
        }
    }
    
    private func replaceWithoutAnimation(_ new: UIViewController) {
        addChild(new)
        new.view.frame = view.bounds
        view.addSubview(new.view)
        new.didMove(toParent: self)
        
        current.willMove(toParent: nil)
        current.view.removeFromSuperview()
        current.removeFromParent()
        
        current = new
    }
    
    private func animateFadeTransition(to new: UIViewController, completion: (() -> Void)? = nil) {
        current.willMove(toParent: nil)
        addChild(new)
        new.willMove(toParent: self)
        transition(from: current, to: new, duration: 0.3, options: [.transitionCrossDissolve, .curveEaseOut], animations: {}) { completed in
            self.current.removeFromParent()
            new.didMove(toParent: self)
            self.current = new
            completion?()
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    private func animateDismissTransition(to new: UIViewController, completion: (() -> Void)? = nil) {
        let initialFrame = CGRect(x: -view.bounds.width, y: 0, width: view.bounds.width, height: view.bounds.height)
        current.willMove(toParent: nil)
        addChild(new)
        new.view.frame = initialFrame
        
        transition(from: current, to: new, duration: 0.3, options: [], animations: {
            new.view.frame = self.view.bounds
        }) { completed in
            self.current.removeFromParent()
            new.didMove(toParent: self)
            self.current = new
            completion?()
        }
    }
    
    open func handleDeepLink(type: DeeplinkType) {}
    
    public func attach(to window: inout UIWindow?) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = self
        window?.makeKeyAndVisible()
    }
}
