//
//  File.swift
//  
//
//  Created by EruEri on 21/03/2022.
//

import Foundation

extension Int {
    public func max(y: Self) -> Self {
        return Swift.max(self, y)
    }
}

extension UnsafeMutablePointer where Pointee == CChar {
    func resetMemory(with value: CChar = 0) {
        let stringLen = strlen(self)
        self.assign(repeating: value, count: stringLen)
    }
}
