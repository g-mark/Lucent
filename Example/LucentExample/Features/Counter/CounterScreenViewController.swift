//
//  CounterScreenViewController.swift
//  LucentExample
//
//  Created by Steven Grosmark on 5/7/26.
//

import Lucent
import SwiftUI
import UIKit
import WWLayout


final class CounterScreenViewController: UIViewController, LucentScreen {

    @Bindable
    var viewModel: ViewModel<CounterScreen>

    private let countLabel = UILabel()
    private let decrementButton = UIButton(type: .system)
    private let incrementButton = UIButton(type: .system)
    private let factLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let factButton = UIButton(type: .system)

    init(viewModel: ViewModel<CounterScreen>) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureActions()
        configureObservation()
    }

    private func configureView() {
        title = "Counter"
        view.backgroundColor = .systemBackground
        view.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)

        countLabel.font = .preferredFont(forTextStyle: .largeTitle)
        countLabel.adjustsFontForContentSizeCategory = true
        countLabel.textAlignment = .center

        decrementButton.configuration = .borderedProminent()
        decrementButton.setTitle("Decrement", for: .normal)

        incrementButton.configuration = .borderedProminent()
        incrementButton.setTitle("Increment", for: .normal)

        let buttonStack = UIStackView(arrangedSubviews: [
            decrementButton,
            incrementButton
        ])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 12

        factLabel.font = .preferredFont(forTextStyle: .body)
        factLabel.adjustsFontForContentSizeCategory = true
        factLabel.numberOfLines = 0
        factLabel.textAlignment = .center

        activityIndicator.hidesWhenStopped = true

        factButton.configuration = .bordered()
        factButton.setTitle("Get fact", for: .normal)

        let allViews = [countLabel, buttonStack, factButton, activityIndicator, factLabel]
        view.addSubviews(allViews)

        buttonStack.layout.bottom(to: view, edge: .center)
        countLabel.layout.bottom(to: buttonStack, edge: .top, offset: -16)
        factButton.layout
            .below(buttonStack, offset: 16)
            .width(to: buttonStack.layout.width)
        factLabel.layout
            .below(factButton, offset: 16)
            .width(to: view.layout.width - 32)
        activityIndicator.layout.below(factButton, offset: 16)

        allViews.forEach {
            $0.layout.centerX(to: view)
        }
    }

    private func configureActions() {
        decrementButton.onTap(send: .decrementButtonTapped, to: viewModel)
        incrementButton.onTap(send: .incrementButtonTapped, to: viewModel)
        factButton.onTap(send: .factButtonTapped, to: viewModel)
    }

    private func configureObservation() {
        observe(\.count) { [weak countLabel] count in
            countLabel?.text = "\(count)"
        }

        observe(\.fact) { [weak factLabel] fact in
            factLabel?.text = fact
        }

        observe(\.fact.notEmptyOrNil) { [weak factLabel] hasFact in
            UIView.animate(withDuration: 0.3) {
                factLabel?.isHidden = !hasFact
                factLabel?.layer.opacity = hasFact ? 1.0 : 0.0
            }
        }

        observe(\.factIsLoading) { [weak self] factIsLoading in
            guard let self else { return }

            UIView.animate(withDuration: 0.3) {
                if factIsLoading {
                    self.activityIndicator.startAnimating()
                }
                else {
                    self.activityIndicator.stopAnimating()
                }
            }

            decrementButton.isEnabled = !factIsLoading
            incrementButton.isEnabled = !factIsLoading
            factButton.isEnabled = !factIsLoading
        }
    }
}

extension String? {

    fileprivate var notEmptyOrNil: Bool {
        if let self, !self.isEmpty {
            return true
        }
        return false
    }
}

extension UIView {

    fileprivate func addSubviews(_ views: UIView ...) {
        addSubviews(views)
    }

    fileprivate func addSubviews(_ views: [UIView]) {
        views.forEach(addSubview)
    }
}
