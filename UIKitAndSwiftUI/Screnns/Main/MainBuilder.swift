//
//  MainBuilder.swift
//  UIKitAndSwiftUI
//
//  Created by ZverikRS on 23.04.2025.
//

import Foundation

struct MainBuilder {
}

extension MainBuilder: BaseBuilder {
    typealias T = MainViewController
    func build() -> MainViewController {
        let view: MainViewController = .init()
        let presenter: MainBusinessLogic = MainPresenter()
        
        view.presenter = presenter
        return view
    }
}
