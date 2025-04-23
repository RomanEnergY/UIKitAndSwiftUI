//
//  BaseBuilder.swift
//  UIKitAndSwiftUI
//
//  Created by ZverikRS on 23.04.2025.
//

import Foundation

protocol BaseBuilder {
    associatedtype T
    func build() -> T
}
