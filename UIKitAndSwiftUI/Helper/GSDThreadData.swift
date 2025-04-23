//
//  GSDThreadData.swift
//  UIKitAndSwiftUI
//
//  Created by ZverikRS on 24.04.2025.
//

import Foundation

struct GSDThreadData {
    
    // MARK: - public properties
    let number: Int
    let uid: String
    let initDate: Date
    let startDate: Date
    let finishDate: Date
    
    // MARK: - initializers
    init?(initDate: Date, thread: Thread) {
        guard let number = thread.number else { return nil }
        self.init(
            number: number,
            uid: thread.nSThreadUid,
            initDate: initDate,
            startDate: .init(),
            finishDate: .init())
    }
    
    // MARK: - public methods
    func updateFinishDate() -> Self {
        .init(
            number: number,
            uid: uid,
            initDate: initDate,
            startDate: startDate,
            finishDate: .init())
    }
}

private extension GSDThreadData {
    init(number: Int, uid: String, initDate: Date, startDate: Date, finishDate: Date) {
        self.number = number
        self.uid = uid
        self.initDate = initDate
        self.startDate = startDate
        self.finishDate = finishDate
    }
}

extension GSDThreadData: CustomStringConvertible {
    var description: String {
        let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "ss.SSS"
            return formatter
        }()
        
        let descriptions: [String] = [
            "numbers: \(number)",
            "uid: \(uid)",
            "start: \(formatter.string(from: startDate.addingTimeInterval(-initDate.timeIntervalSince1970)))",
            "finish: \(formatter.string(from: finishDate.addingTimeInterval(-initDate.timeIntervalSince1970))))"
        ]
        
        return descriptions.joined(separator: ", ")
    }
}

// MARK: - calculated properties
private extension Thread {
    var number: Int? {
        let threadCurrent = "\(self)"
        return threadCurrent.threadNumber
    }
    
    var nSThreadUid: String {
        "\(self)".nSThreadUid
    }
}

private extension String {
    var threadNumber: Int? {
        if let numberStr = find(pattern: "number = (?<number>\\d{1,}),", key: "number") {
            return Int(numberStr)
        } else {
            return nil
        }
    }
    
    var nSThreadUid: String {
        find(pattern: "<NSThread: (?<uid>\\S{1,})>", key: "uid") ?? "?"
    }
    
    func find(pattern: String, key: String) -> String? {
        let range = NSRange(startIndex ..< endIndex, in: self)
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: self, range: range),
           let key = match.getRange(key: key, in: self) {
            return key
        } else {
            return nil
        }
    }
}

private extension NSTextCheckingResult {
    func getRange(key: String, in text: String) -> String? {
        if let range = Range(range(withName: key), in: text) {
            return String(text[range])
        } else {
            return nil
        }
    }
}
