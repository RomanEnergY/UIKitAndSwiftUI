//
//  MainView.swift
//  UIKitAndSwiftUI
//
//  Created by ZverikRS on 23.04.2025.
//

import SwiftUI

protocol MainViewDisplayLogic: Any {
    func showLoading()
    func hideLoading()
    func updateView(model: MainViewDisplayModel)
}

struct MainViewDisplayModel {
    let datas: [GSDThreadData]
    let onSirealQueuePressed: (() -> Void)?
    let onConcurrentQueuePressed: (() -> Void)?
}

struct MainView: View {
    
    // MARK: - private properties
    @ObservedObject private(set) var viewModel: MainViewModel
    
    // MARK: - initializers
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - life cycle
    var body: some View {
        ZStack {
            Color.accentColor
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColorRevert))
                    
                } else {
                    VStack(spacing: 10) {
                        if let data = viewModel.data {
                            HStack {
                                Spacer()
                                Text(verbatim: .init(format: "time: %.2f", data.finish - data.start))
                                    .font(.callout)
                                    .foregroundColor(.accentColorRevert)
                                Spacer()
                                Text("tasks: \(data.taskCount)")
                                    .font(.callout)
                                    .foregroundColor(.accentColorRevert)
                                Spacer()
                                Text("threads: \(Set(data.elements).count)")
                                    .font(.callout)
                                    .foregroundColor(.accentColorRevert)
                                Spacer()
                            }
                            
                            ScrollView(.vertical) {
                                let textWidth: CGFloat = {
                                    if let item = data.elements.sorted(by: { $0.number > $1.number }).first {
                                        let count = "\(item.number)".count
                                        return CGFloat(count * 12)
                                    } else {
                                        return 0
                                    }
                                }()
                                
                                LazyVStack {
                                    ForEach(data.elements, id: \.self) { element in
                                        ItemView(
                                            start: data.start,
                                            finish: data.finish,
                                            element: element,
                                            textWidth: textWidth)
                                        .padding(.horizontal, 10)
                                    }
                                }
                            }
                            .clipped()
                        }
                        
                        Spacer()
                        HStack {
                            Spacer()
                            CustomButton(
                                text: "sirealQueue",
                                disabled: viewModel.onSirealQueuePressed == nil,
                                action: {
                                    viewModel.onSirealQueuePressed?()
                                })
                            .frame(maxWidth: .infinity)
                            
                            CustomButton(
                                text: "concurrentQueue",
                                disabled: viewModel.onConcurrentQueuePressed == nil,
                                action: {
                                    viewModel.onConcurrentQueuePressed?()
                                })
                            .frame(maxWidth: .infinity)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - MainViewDisplayLogic
extension MainView: MainViewDisplayLogic {
    func showLoading() {
        Task { @MainActor in
            viewModel.isLoading = true
            viewModel.data = .init()
        }
    }
    
    func hideLoading() {
        Task { @MainActor in
            viewModel.isLoading = false
        }
    }
    
    func updateView(model: MainViewDisplayModel) {
        Task { @MainActor in
            viewModel.data = .convert(datas: model.datas)
            viewModel.onSirealQueuePressed = model.onSirealQueuePressed
            viewModel.onConcurrentQueuePressed = model.onConcurrentQueuePressed
        }
    }
}

// MARK: - ItemView
private extension MainView {
    struct ItemView: View {
        let start: TimeInterval
        let finish: TimeInterval
        let element: MainViewModel.Data.Element
        let textWidth: CGFloat
        
        // MARK: - private properties
        private let lineWidth: CGFloat = 10
        
        // MARK: - life cycle
        var body: some View {
            HStack {
                Text("\(element.number)")
                    .font(.callout)
                    .foregroundColor(.accentColorRevert)
                    .frame(width: textWidth, alignment: .trailing)
                
                GeometryReader { geometry in
                    let size: CGSize = geometry.size
                    let array = calculateDistance(width: size.width)
                    let paths = array.enumerated().map { (offset, element) in
                        ZStack {
                            let lastPath: (_ start: CGFloat, _ finish: CGFloat, _ color: Color) -> some View = { start, finish, color in
                                Path { path in
                                    path.move(to: CGPoint(x: start, y: size.height / 2))
                                    path.addLine(to: CGPoint(x: finish, y: size.height / 2))
                                }
                                .stroke(color, lineWidth: lineWidth / 2)
                            }
                            
                            if offset == 0 {
                                lastPath(0, element.start, .red)
                            }
                            
                            Path { path in
                                path.move(to: CGPoint(x: element.start - 2, y: size.height / 2))
                                path.addLine(to: CGPoint(x: element.start, y: size.height / 2))
                            }
                            .stroke(.gray, lineWidth: lineWidth * 1.5)
                            
                            Path { path in
                                path.move(to: CGPoint(x: element.start, y: size.height / 2))
                                path.addLine(to: CGPoint(x: element.finish, y: size.height / 2))
                            }
                            .stroke(.green, lineWidth: lineWidth)
                            
                            Path { path in
                                path.move(to: CGPoint(x: element.finish - 2, y: size.height / 2))
                                path.addLine(to: CGPoint(x: element.finish, y: size.height / 2))
                            }
                            .stroke(.gray, lineWidth: lineWidth * 1.5)
                            
                            if let elementNext = array[safe: offset + 1] {
                                lastPath(element.finish, elementNext.start, .yellow)
                            }
                            
                            if offset == array.count - 1 {
                                lastPath(element.finish, size.width, .yellow)
                            }
                        }
                    }
                    
                    ForEach(0 ..< paths.count, id: \.self) { index in
                        paths[index]
                    }
                }
            }
        }
    }
}

// MARK: - Distance
private extension MainView.ItemView {
    struct Distance {
        let start: CGFloat
        let finish: CGFloat
    }
    
    func calculateDistance(
        width: CGFloat
    ) -> [Distance] {
        let distance = finish - start
        var array: [Distance] = []
        var index: Int = 0
        while let item = calculateDistance(item: element.items[safe: index], distance: distance, width: width)  {
            array.append(item)
            index += 1
        }
        
        return array
    }
    
    func calculateDistance(
        item: MainViewModel.Data.Element.Item?,
        distance: TimeInterval,
        width: CGFloat
    ) -> Distance? {
        guard let item else { return nil }
        let start: CGFloat = {
            let firstDistance = item.start
            let distanceStart = distance - firstDistance
            return width * (1 - distanceStart / distance)
        }()
        
        let finish: CGFloat = {
            let lastDistance = item.distance
            return start + width * (lastDistance / distance)
        }()
        
        return .init(start: start, finish: finish)
    }
}

// MARK: - CustomButton
private extension MainView {
    struct CustomButton: View {
        let text: String
        let disabled: Bool
        let action: () -> Void
        
        var body: some View {
            let buttonColor: Color = disabled ? .gray : .accentColorRevert
            Button(action: action, label: {
                Text(text)
                    .font(.headline)
                    .foregroundColor(buttonColor)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(CustomButtonBackground(strokeColor: buttonColor))
            })
            .disabled(disabled)
        }
    }
}

// MARK: - ButtonBackground
private extension MainView.CustomButton {
    private struct CustomButtonBackground: View {
        let strokeColor: Color
        
        var body: some View {
            RoundedRectangle(cornerRadius: 15)
                .stroke(strokeColor, lineWidth: 2)
        }
    }
}

#Preview {
    MainView(viewModel: {
        var viewModel: MainViewModel = .init()
        viewModel.isLoading = false
        viewModel.data = .debugData()
        return viewModel
    }())
}

private extension MainViewModel.Data {
    static func debugData() -> Self {
        .init(
            start: 0,
            finish: 5,
            elements: [
                .init(number: 0, items: [
                    .init(start: 3, distance: 1),
                    .init(start: 1, distance: 1)
                ]),
                .init(number: 1, items: [
                ]),
                .init(number: 2, items: [
                    .init(start: 2, distance: 2),
                    .init(start: 0, distance: 1)
                ])
            ])
    }
}
