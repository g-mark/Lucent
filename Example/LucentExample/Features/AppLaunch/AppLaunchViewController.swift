//
//  AppLaunchViewController.swift
//  LucentExample
//
//  Created by Steven Grosmark on 4/15/26.
//

import UIKit
import SwiftUI
import Lucent
import WWLayout

class AppLaunchViewController: UIViewController, LucentScreen {

    @Bindable
    var viewModel: ViewModel<AppLaunchScreen>

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

        indicator.layout
            .centerX(to: imageView)
            .below(imageView, offset: 12)

        statusText.layout
            .centerX(to: imageView)
            .below(indicator, offset: 12)

        indicator.startAnimating()

        observe(\.status) { [weak statusText] status in
            statusText?.text = status
        }

        viewModel.send(action: .viewDidLoad)
    }

    private func loadLaunchScreen() {
        let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        let launchController = storyboard.instantiateViewController(withIdentifier: "LaunchScreen")

        addChild(launchController)
        view.addSubview(launchController.view)
        launchController.view.layout.fill(view)
        launchController.didMove(toParent: self)
        launchScreenView = launchController.view
    }
}
