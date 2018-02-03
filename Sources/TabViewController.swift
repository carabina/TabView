//
//  TabViewController.swift
//  TabView
//
//  Created by Ian McDowell on 2/2/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import UIKit

open class TabViewController: UIViewController {

    /// Current theme
    public var theme: TabViewTheme {
        didSet { self.applyTheme(theme) }
    }

    open override var title: String? {
        get { return super.title ?? visibleViewController?.title }
        set { super.title = newValue }
    }

    /// The current tab shown in the tab view controller's content view
    public var visibleViewController: UIViewController? {
        didSet {
            currentContentViewController = visibleViewController
            
            if let visibleViewController = visibleViewController {
                visibleNavigationItemObserver = NavigationItemObserver.init(navigationItem: visibleViewController.navigationItem, { [weak self] in
                    self?.refreshTabBar()
                })
            } else {
                visibleNavigationItemObserver = nil
            }
            if let newValue = visibleViewController, let index = viewControllers.index(of: newValue) {
                tabViewBar.selectTab(atIndex: index)
            }
            refreshTabBar()
        }
    }
    private var _viewControllers: [UIViewController] = [] {
        didSet {
            if visibleViewController == nil || !viewControllers.contains(visibleViewController!) {
                visibleViewController = viewControllers.first
            }
            refreshEmptyView()
        }
    }
    /// All of the tabs, in order.
    public var viewControllers: [UIViewController] {
        get { return _viewControllers }
        set { _viewControllers = newValue; tabViewBar.refresh() }
    }

    /// If you want to display a view when there are no tabs, set this to some value
    public var emptyView: UIView? = nil {
        didSet {
            oldValue?.removeFromSuperview()
            refreshEmptyView()
        }
    }

    /// Tab bar shown above the content view
    private let tabViewBar: TabViewBar

    /// View containing the current tab's view
    private let contentView: UIView

    private var ownNavigationItemObserver: NavigationItemObserver?
    private var visibleNavigationItemObserver: NavigationItemObserver?

    /// Create a new tab view controller, with a theme.
    public init(theme: TabViewTheme) {
        self.theme = theme
        self.tabViewBar = TabViewBar(theme: theme)
        self.contentView = UIView()

        super.init(nibName: nil, bundle: nil)

        tabViewBar.barDataSource = self
        tabViewBar.barDelegate = self

        self.ownNavigationItemObserver = NavigationItemObserver.init(navigationItem: self.navigationItem, self.refreshTabBar)
    }

    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Content view fills frame
        contentView.frame = view.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(contentView)

        // Tab bar is on top of content view, with automatic height.
        tabViewBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabViewBar)
        NSLayoutConstraint.activate([
            tabViewBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabViewBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabViewBar.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        self.edgesForExtendedLayout = []

        applyTheme(theme)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let contentViewController = currentContentViewController {
            contentViewController.additionalSafeAreaInsets = UIEdgeInsets(top: tabViewBar.frame.size.height - contentView.safeAreaInsets.top, left: 0, bottom: 0, right: 0)
        }
    }

    /// Activates the given tab and saves the new state
    ///
    /// - Parameters:
    ///   - viewController: the tab to activate
    ///   - saveState: if the new state should be saved
    open func activateTab(_ tab: UIViewController) {
        if !_viewControllers.contains(tab) {
            _viewControllers.append(tab)
            tabViewBar.addTab(atIndex: _viewControllers.count - 1)
        }
        visibleViewController = tab
    }

    /// Closes the provided tab and selects another tab to be active.
    ///
    /// - Parameter tab: the tab to close
    open func closeTab(_ tab: UIViewController) {
        if let index = _viewControllers.index(of: tab) {
            _viewControllers.remove(at: index)
            tabViewBar.removeTab(atIndex: index)

            if index == 0 {
                visibleViewController = _viewControllers.first
            } else {
                visibleViewController = _viewControllers[index - 1]
            }
        }
    }

    func swapTab(atIndex index: Int, withTabAtIndex atIndex: Int) {
        _viewControllers.swapAt(index, atIndex)
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.statusBarStyle
    }

    /// Apply the current theme to the view controller and its views.
    private func applyTheme(_ theme: TabViewTheme) {
        self.view.backgroundColor = theme.backgroundColor
        self.setNeedsStatusBarAppearanceUpdate()
        tabViewBar.theme = theme
    }

    private var currentContentViewController: UIViewController? {
        didSet {
            oldValue?.removeFromParentViewController()
            oldValue?.view.removeFromSuperview()

            if let contentViewController = currentContentViewController {
                addChildViewController(contentViewController)
                contentViewController.view.frame = contentView.bounds
                contentViewController.additionalSafeAreaInsets = UIEdgeInsets(top: tabViewBar.frame.size.height - contentView.safeAreaInsets.top, left: 0, bottom: 0, right: 0)
                contentView.addSubview(contentViewController.view)
                contentViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                contentViewController.didMove(toParentViewController: self)
            }
        }
    }

    private func refreshTabBar() {
        tabViewBar.updateTitle()
        tabViewBar.setLeadingBarButtonItems((navigationItem.leftBarButtonItems ?? []) + (visibleViewController?.navigationItem.leftBarButtonItems ?? []))
        tabViewBar.setTrailingBarButtonItems((visibleViewController?.navigationItem.rightBarButtonItems ?? []) + (navigationItem.rightBarButtonItems ?? []))
    }
    private func refreshEmptyView() {
        if let emptyView = self.emptyView {
            if viewControllers.isEmpty {
                emptyView.frame = contentView.bounds
                contentView.addSubview(emptyView)
                emptyView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            } else {
                emptyView.removeFromSuperview()
            }
        }
    }
}

extension TabViewController: TabViewBarDataSource {

}

extension TabViewController: TabViewBarDelegate {

}
