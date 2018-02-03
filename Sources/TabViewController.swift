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

    /// The current tab shown in the tab view controller's content view
    public var visibleViewController: UIViewController? {
        return model.visibleViewController
    }
    /// All of the tabs, in order.
    public var viewControllers: [UIViewController] {
        get { return model.viewControllers }
        set { model.setTabs(newValue) }
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

    /// Model storing state of the tabs
    private let model: TabViewControllerModel

    private var navigationItemObserver: NavigationItemObserver?

    /// Create a new tab view controller, with a theme.
    public init(theme: TabViewTheme) {
        self.theme = theme
        self.tabViewBar = TabViewBar(theme: theme)
        self.contentView = UIView()
        self.model = TabViewControllerModel()

        super.init(nibName: nil, bundle: nil)

        model.delegate = self

        tabViewBar.barDataSource = model
        tabViewBar.barDelegate = model

        self.navigationItemObserver = NavigationItemObserver.init(navigationItem: self.navigationItem, self.refreshTabBar)
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
        model.activateTab(tab)
    }

    /// Closes the provided tab and selects another tab to be active.
    ///
    /// - Parameter tab: the tab to close
    open func closeTab(_ tab: UIViewController) {
        model.closeTab(tab)
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
                contentView.addSubview(contentViewController.view)
                contentViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                contentViewController.didMove(toParentViewController: self)
            }
        }
    }

    private func refreshTabBar() {
        tabViewBar.refresh()
        tabViewBar.setLeadingBarButtonItems((navigationItem.leftBarButtonItems ?? []) + (model.visibleViewController?.navigationItem.leftBarButtonItems ?? []))
        tabViewBar.setTrailingBarButtonItems(((navigationItem.rightBarButtonItems ?? []) + (model.visibleViewController?.navigationItem.rightBarButtonItems ?? [])).reversed())
    }
    private func refreshEmptyView() {
        if let emptyView = self.emptyView {
            if model.viewControllers.isEmpty {
                emptyView.frame = contentView.bounds
                contentView.addSubview(emptyView)
                emptyView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            } else {
                emptyView.removeFromSuperview()
            }
        }
    }
}

extension TabViewController: TabViewModelDelegate {
    func modelVisibleViewControllerDidChange(to viewController: UIViewController?) {
        self.currentContentViewController = viewController
    }
    func modelVisibleNavigationItemDidChange() {
        refreshTabBar()
    }
    func modelViewControllersDidChange() {
        refreshTabBar()
        refreshEmptyView()
    }
}
