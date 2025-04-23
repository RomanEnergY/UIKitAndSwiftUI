//
//  MainViewModel.swift
//  UIKitAndSwiftUI
//
//  Created by ZverikRS on 23.04.2025.
//

import Foundation
import Combine

final class MainViewModel: ObservableObject {
    
    // MARK: - private properties
    @Published var isLoading: Bool = true
    @Published var data: Data?
    @Published var onSirealQueuePressed: (() -> Void)? = nil
    @Published var onConcurrentQueuePressed: (() -> Void)? = nil
}

extension MainViewModel {
    struct Data {
        let start: TimeInterval
        let finish: TimeInterval
        let elements: [Element]
        
        var taskCount: Int {
            var count: Int = 0
            elements.forEach { count += $0.items.count }
            return count
        }
        
        init() {
            start = 0
            finish = 0
            elements = []
        }
        
        init(
            start: TimeInterval,
            finish: TimeInterval,
            elements: Set<Element>
        ) {
            self.start = start
            self.finish = finish
            
            var _elements: Set<Element> = []
            elements.forEach { element in
                guard !element.items.isEmpty else { return }
                var items = element.items
                items.sort(by: { $0.start < $1.start })
                let _element: MainViewModel.Data.Element = .init(
                    number: element.number,
                    items: items)
                
                _elements.insert(_element)
            }
            
            self.elements = .init(_elements.sorted(by: { $0.number < $1.number }))
        }
    }
}

extension MainViewModel.Data {
    struct Element: Identifiable {
        let id: String
        let number: Int
        let items: [Item]
        
        init(
            id: String = UUID().uuidString,
            number: Int,
            items: [Item]
        ) {
            self.id = id
            self.number = number
            self.items = items
        }
    }
}

extension MainViewModel.Data.Element {
    struct Item {
        let start: TimeInterval
        let distance: TimeInterval
    }
}

// MARK: - Hashable
extension MainViewModel.Data.Element: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
}

// MARK: - Equatable
extension MainViewModel.Data.Element: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.number == rhs.number
    }
}

extension MainViewModel.Data {
    static func convert(datas: [GSDThreadData]) -> Self? {
        guard
            let initDate: Date = datas.sorted(by: { $0.initDate < $1.initDate }).first?.initDate,
            let finishDate: Date = datas.sorted(by: { $0.finishDate > $1.finishDate }).first?.finishDate
        else {
            return nil
        }
        
        return .init(
            start: 0,
            finish: finishDate.timeIntervalSince1970 - initDate.timeIntervalSince1970,
            elements: datas.convert(initDate: initDate))
    }
}

private extension Array where Element == GSDThreadData {
    func convert(initDate: Date) -> Set<MainViewModel.Data.Element> {
        var array: Set<MainViewModel.Data.Element> = []
        forEach { element in
            let _elementArray: MainViewModel.Data.Element
            if let elementArray = array.first(where: { $0.number == element.number }) {
                var items = elementArray.items
                items.append(.init(
                    start: element.startDate.timeIntervalSince1970 - initDate.timeIntervalSince1970,
                    distance: element.finishDate.timeIntervalSince1970 - element.startDate.timeIntervalSince1970))
                
                array.remove(.init(number: element.number, items: []))
                _elementArray = .init(
                    number: element.number,
                    items: items)
                
            } else {
                _elementArray = .init(
                    number: element.number,
                    items: [
                        .init(
                            start: element.startDate.timeIntervalSince1970 - initDate.timeIntervalSince1970,
                            distance: element.finishDate.timeIntervalSince1970 - element.startDate.timeIntervalSince1970)
                    ])
            }
            
            array.insert(_elementArray)
        }
        
        return array
    }
}
