//
//  AppLaunchViewController.swift
//  LucentExample
//
//  Created by Steven Grosmark on 4/15/26.
//

import UIKit
import Lucent


class AppLaunchViewController: UIViewController {

    private var viewModel: ViewModel<AppLaunchScreen>

    private var launchScreenView: UIView?
    private lazy var indicator = UIActivityIndicatorView(style: .large)
    private lazy var statusText = UILabel()

    init(viewModel: ViewModel<AppLaunchScreen>) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadLaunchScreen()

        guard let launchScreenView, let imageView = launchScreenView.viewWithTag(1) else {
            return
        }

        launchScreenView.addSubview(indicator)
        launchScreenView.addSubview(statusText)

        indicator.translatesAutoresizingMaskIntoConstraints = false
        statusText.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            indicator.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),

            statusText.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            statusText.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 12)
        ])

        indicator.startAnimating()
        statusText.text = viewModel.status

        viewModel.send(action: .viewDidLoad)
    }

    private func loadLaunchScreen() {
        let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        let launchController = storyboard.instantiateViewController(withIdentifier: "LaunchScreen")

        addChild(launchController)
        view.addSubview(launchController.view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: launchController.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: launchController.view.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: launchController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: launchController.view.trailingAnchor),
        ])
        launchController.didMove(toParent: self)

        launchScreenView = launchController.view
    }
}
