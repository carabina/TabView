//
//  TabViewModel.swift
//  TabView
//
//  Created by Ian McDowell on 2/2/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import UIKit

/// Delegate to receive change notifications about the model's contents
protocol TabViewModelDelegate: class {
    /// The visible view controller did change
    func modelVisibleViewControllerDidChange(to viewController: UIViewController?)

    /// The title or bar button items did change in the visible view controller
    func modelVisibleNavigationItemDidChange()

    /// There were changes to the array of view controllers
    func modelViewControllersDidChange()
}

/// This model sits between the TabViewController and the TabViewBar.
/// The TabViewController reads these values and presents them to the consumer,
/// and the tab view bar will be reloaded with this data if the TabViewController deems it necessary.
class TabViewControllerModel: TabViewBarDataSource, TabViewBarDelegate {
    weak var delegate: TabViewModelDelegate?
    var navigationItemObserver: NavigationItemObserver?

    private(set) var visibleViewController: UIViewController? {
        didSet {
            if let visibleViewController = visibleViewController {
                navigationItemObserver = NavigationItemObserver.init(navigationItem: visibleViewController.navigationItem, { [weak self] in self?.delegate?.modelVisibleNavigationItemDidChange()
                })
            } else {
                navigationItemObserver = nil
            }
            delegate?.modelVisibleViewControllerDidChange(to: visibleViewController)
        }
    }
    private(set) var viewControllers: [UIViewController] = []

    func activateTab(_ tab: UIViewController) {
        if !viewControllers.contains(tab) {
            viewControllers.append(tab)
        }
        visibleViewController = tab

        delegate?.modelViewControllersDidChange()
    }

    func closeTab(_ tab: UIViewController) {
        if let index = viewControllers.index(of: tab) {
            viewControllers.remove(at: index)
        }

        // TODO: Pick next vc or some better logic
        visibleViewController = viewControllers.last

        delegate?.modelViewControllersDidChange()
    }

    func swapTab(atIndex index: Int, withTabAtIndex atIndex: Int) {
        viewControllers.swapAt(index, atIndex)

        delegate?.modelViewControllersDidChange()
    }

    func setTabs(_ tabs: [UIViewController]) {
        viewControllers = tabs
        if visibleViewController == nil || !tabs.contains(visibleViewController!) {
            visibleViewController = viewControllers.first
        }

        delegate?.modelViewControllersDidChange()
    }
}
