//
// Copyright (c) 2025 Nightwind
//

import UIKit
import CydiaSubstrate

@objc private protocol WFMutableNetworkProfile {
	@objc var ssid: String { get set }
	@objc var password: String { get set }
}

@objc private protocol WFSettingsController {
	@objc var profile: WFMutableNetworkProfile? { get set }
}

@objc private protocol WFNetworkSettingsViewController {
	@objc var navigationItem: UINavigationItem { get }
	@objc var dataCoordinator: WFSettingsController { get set }

	@objc(presentViewController:animated:completion:)
	func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?)
}

private struct Hooks {
	private static let targetClass: AnyClass = objc_getClass("WFNetworkSettingsViewController") as! AnyClass

	fileprivate static func hook() {
		var origIMP: IMP?

		let hook: @convention(block) (WFNetworkSettingsViewController, Selector) -> Void = { target, selector in
			let orig = unsafeBitCast(origIMP, to: (@convention(c) (WFNetworkSettingsViewController, Selector) -> Void).self)
			orig(target, selector)

			guard target.dataCoordinator.profile != nil else { return }

			guard let keyImage = UIImage(systemName: "lock.open") else { return }
			let topMenuButton = UIBarButtonItem(image: keyImage, style: .plain, target: target, action: sel_getUid("_swfp_handleShowPasswordClick:"))
			target.navigationItem.rightBarButtonItem = topMenuButton
		}

		MSHookMessageEx(targetClass, sel_getUid("viewDidLoad"), imp_implementationWithBlock(hook), &origIMP);
	}

	fileprivate static func addHandler() {
		let implementation: @convention(block) (WFNetworkSettingsViewController, Selector, UIBarButtonItem) -> Void = { target, selector, sender in
			guard let profile = target.dataCoordinator.profile else { return }

			let alert = UIAlertController(title: profile.ssid, message: profile.password, preferredStyle: .alert)

			let dismissAction = UIAlertAction(title: "Dismiss", style: .default)
			let copyAction = UIAlertAction(title: "Copy", style: .default, handler: { action in
				UIPasteboard.general.string = profile.password
			})

			alert.addAction(dismissAction)
			alert.addAction(copyAction)

			alert.preferredAction = copyAction

			target.present(alert, animated: true, completion: nil)
		}

		class_addMethod(targetClass, sel_getUid("_swfp_handleShowPasswordClick:"), imp_implementationWithBlock(implementation), "v@:@")
	}
}

@_cdecl("swift_init")
func tweakInit() {
	guard let bundle = Bundle(path: "/System/Library/PrivateFrameworks/WiFiKitUI.framework") else { return }
	if bundle.load() {
		Hooks.hook()
		Hooks.addHandler()
	}
}