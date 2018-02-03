//
//  TabViewBar.swift
//  TabView
//
//  Created by Ian McDowell on 2/2/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import UIKit

private let barHeight: CGFloat = 44
private let tabHeight: CGFloat = 32

protocol TabViewBarDataSource: class {
    var title: String? { get }
    var viewControllers: [UIViewController] { get }
    var visibleViewController: UIViewController? { get }
}

protocol TabViewBarDelegate: class {
    func activateTab(_ tab: UIViewController)
    func closeTab(_ tab: UIViewController)
    func swapTab(atIndex index: Int, withTabAtIndex atIndex: Int)
}

class TabViewBar: UIView {

    weak var barDataSource: TabViewBarDataSource? {
        didSet {
            tabCollectionView.barDataSource = barDataSource
        }
    }
    weak var barDelegate: TabViewBarDelegate? {
        didSet {
            tabCollectionView.barDelegate = barDelegate
        }
    }

    var theme: TabViewTheme {
        didSet { self.applyTheme(theme) }
    }

    private let visualEffectView: UIVisualEffectView

    private let titleLabel: UILabel
    private let leadingBarButtonStackView: UIStackView
    private let trailingBarButtonStackView: UIStackView

    private let tabCollectionView: TabViewTabCollectionView
    private let separator: UIView

    init(theme: TabViewTheme) {
        self.theme = theme

        self.visualEffectView = UIVisualEffectView(effect: nil)
        
        self.titleLabel = UILabel()
        self.leadingBarButtonStackView = UIStackView()
        self.trailingBarButtonStackView = UIStackView()

        self.tabCollectionView = TabViewTabCollectionView(theme: theme)
        self.separator = UIView()

        super.init(frame: .zero)

        addSubview(visualEffectView)
        visualEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.setContentCompressionResistancePriority(.init(500), for: .horizontal)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        for stackView in [leadingBarButtonStackView, trailingBarButtonStackView] {
            stackView.alignment = .fill
            stackView.axis = .horizontal
            stackView.distribution = .fill
            stackView.spacing = 15
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            stackView.setContentHuggingPriority(.required, for: .horizontal)
            addSubview(stackView)
        }
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).withPriority(.defaultLow),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingBarButtonStackView.trailingAnchor, constant: 5),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingBarButtonStackView.leadingAnchor, constant: -5),
            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: barHeight).withPriority(.defaultHigh)
        ])

        NSLayoutConstraint.activate([
            leadingBarButtonStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
            leadingBarButtonStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            leadingBarButtonStackView.heightAnchor.constraint(equalToConstant: barHeight).withPriority(.defaultHigh),
            trailingBarButtonStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15),
            trailingBarButtonStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            trailingBarButtonStackView.heightAnchor.constraint(equalToConstant: barHeight).withPriority(.defaultHigh)
        ])

        tabCollectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabCollectionView)
        NSLayoutConstraint.activate([
            tabCollectionView.heightAnchor.constraint(equalToConstant: tabHeight),
            tabCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            tabCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 0.5).withPriority(.defaultHigh),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyTheme(theme)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyTheme(_ theme: TabViewTheme) {
        self.backgroundColor = theme.barTintColor.withAlphaComponent(0.7)
        self.visualEffectView.effect = UIBlurEffect.init(style: theme.barBlurStyle)
        self.titleLabel.textColor = theme.barTitleColor
        self.separator.backgroundColor = theme.separatorColor
        self.tabCollectionView.theme = theme
    }

    func setLeadingBarButtonItems(_ barButtonItems: [UIBarButtonItem]) {
        let views = barButtonItems.map { $0.toView() }

        for view in leadingBarButtonStackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        for view in views {
            leadingBarButtonStackView.addArrangedSubview(view)
        }
    }

    func setTrailingBarButtonItems(_ barButtonItems: [UIBarButtonItem]) {
        let views = barButtonItems.map { $0.toView() }

        for view in trailingBarButtonStackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        for view in views {
            trailingBarButtonStackView.addArrangedSubview(view)
        }
    }

    func addTab(atIndex index: Int) {
        tabCollectionView.performBatchUpdates({
            tabCollectionView.insertItems(at: [IndexPath.init(item: index, section: 0)])
        }, completion: nil)
    }

    func removeTab(atIndex index: Int) {
        tabCollectionView.performBatchUpdates({
            tabCollectionView.deleteItems(at: [IndexPath.init(item: index, section: 0)])
        }, completion: nil)
    }

    func selectTab(atIndex index: Int) {
        if let indexPaths = tabCollectionView.indexPathsForSelectedItems {
            for indexPath in indexPaths where indexPath.item != index {
                tabCollectionView.deselectItem(at: indexPath, animated: true)
            }
        }
        tabCollectionView.selectItem(at: IndexPath.init(item: index, section: 0), animated: true, scrollPosition: .centeredHorizontally)
    }

    func updateTitle() {
        self.titleLabel.text = barDataSource?.title
    }

    func refresh() {
        updateTitle()
        tabCollectionView.reloadData()

        if let visibleVC = barDataSource?.visibleViewController, let index = barDataSource?.viewControllers.index(of: visibleVC) {
            self.selectTab(atIndex: index)
        }
    }
}
