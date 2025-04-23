//
//  MainViewController.swift
//  UIKitAndSwiftUI
//
//  Created by ZverikRS on 23.04.2025.
//

import UIKit
import SwiftUI

final class MainViewController: UIViewController {
    
    // MARK: - public properties
    var presenter: MainBusinessLogic?
    
    // MARK: - initializers
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
    }
}

// MARK: - MainViewController
private extension MainViewController {
    func config() {
        let mainView: MainView = .init(viewModel: .init())
        let hostingController: UIHostingController = .init(rootView: mainView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        presenter?.start(viewDisplay: mainView)
    }
}
