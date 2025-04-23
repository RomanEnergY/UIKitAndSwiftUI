//
//  File.swift
//  UIKitAndSwiftUI
//
//  Created by ZverikRS on 25.04.2025.
//

extension Array {
    subscript(safe index: Index?) -> Element? {
        guard let index else { return nil }
        
        guard index >= startIndex,
              index < endIndex
        else {
            return nil
        }
        
        return self[index]
    }
}
