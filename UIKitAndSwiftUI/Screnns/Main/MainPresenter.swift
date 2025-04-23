//
//  MainPresenter.swift
//  UIKitAndSwiftUI
//
//  Created by ZverikRS on 23.04.2025.
//

import Foundation

// MARK: - BusinessLogic
protocol MainBusinessLogic {
    func start(viewDisplay: (any MainViewDisplayLogic)?)
}

final class MainPresenter {
    
    // MARK: - private Properties
    private var viewDisplay: (any MainViewDisplayLogic)?
    private var isCancelled: Bool = false
    private var datas: [GSDThreadData] = []
    private let countInteration: Int = 1_000
    private let sleep: TimeInterval = 0.01
    private let synchronizationQueue: DispatchQueue = .init(label: "synchronization")
    private let concurrentQueue: DispatchQueue = .init(label: "concurrent", attributes: .concurrent)
}

// MARK: - MainBusinessLogic
extension MainPresenter: MainBusinessLogic {
    func start(viewDisplay: (any MainViewDisplayLogic)?) {
        self.viewDisplay = viewDisplay
        calculateModel()
    }
}

private extension MainPresenter {
    func calculateModel() {
        let workItem: DispatchWorkItem = .init { [weak self] in
            self?.calculateModel()
        }
        
        viewDisplay?.hideLoading()
        viewDisplay?.updateView(model: .init(
            datas: datas.sort(),
            onSirealQueuePressed: { [weak self] in
                self?.viewDisplay?.showLoading()
                self?.sirealTestMethod(initDate: .init(), workItem: workItem)
            },
            onConcurrentQueuePressed: { [weak self] in
                self?.viewDisplay?.showLoading()
                self?.concurrentTestMethod(initDate: .init(), workItem: workItem)
            }))
        
        datas.removeAll()
    }
}

private extension MainPresenter {
    func sirealTestMethod(initDate: Date, workItem: DispatchWorkItem) {
        DispatchQueue.global().async { [weak self, countInteration] in
            let group: DispatchGroup = .init()
            for i in 0 ..< countInteration {
                group.enter()
                let aueue: DispatchQueue = .init(label: "sireal")
                aueue.async { [weak self] in
                    self?.testMethod(initDate: initDate, index: i)
                    group.leave()
                }
            }
            
            group.notify(
                queue: .global(),
                work: workItem)
        }
    }
}

private extension MainPresenter {
    func concurrentTestMethod(initDate: Date, workItem: DispatchWorkItem) {
        DispatchQueue.global().async { [weak self, countInteration] in
            let group: DispatchGroup = .init()
            for i in 0 ..< countInteration {
                group.enter()
                self?.concurrentQueue.async { [weak self] in
                    self?.testMethod(initDate: initDate, index: i)
                    group.leave()
                }
            }
            
            group.notify(
                queue: .global(),
                work: workItem)
        }
    }
}

private extension MainPresenter {
    func testMethod(initDate: Date, index: Int) {
        if !isCancelled {
            if let data = GSDThreadData(initDate: initDate, thread: Thread.current) {
                Thread.sleep(forTimeInterval: sleep)
                let _data = data.updateFinishDate()
                synchronize { [weak self] in
                    self?.datas.append(_data)
                }
                
                if !isCancelled {
                    print(_data)
                }
            }
        }
    }
    
    func synchronize(completion: @escaping () -> Void) {
        synchronizationQueue.sync {
            completion()
        }
    }
}

private extension Array where Element == GSDThreadData {
    func sort() -> Self {
        sorted(by: { lhs, rhs in
            guard lhs.number == rhs.number else {
                return lhs.number < rhs.number
            }
            return lhs.startDate < rhs.startDate
        })
    }
}
