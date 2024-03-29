// /////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
// This file is part of cithare                                                               //
// Copyright (C) 2023 Yves Ndiaye                                                             //
//                                                                                            //
// cithare is free software: you can redistribute it and/or modify it under the terms         //
// of the GNU General Public License as published by the Free Software Foundation,            //
// either version 3 of the License, or (at your option) any later version.                    //
//                                                                                            //
// cithare is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;       //
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR           //
// PURPOSE.  See the GNU General Public License for more details.                             //
// You should have received a copy of the GNU General Public License along with ciathare.     //
// If not, see <http://www.gnu.org/licenses/>.                                                //
//                                                                                            //
// /////////////////////////////////////////////////////////////////////////////////////////////

import Foundation

extension Int {
    
    public var abs: Self {
        Swift.abs(self)
    }
    
    
    public func max(y: Self) -> Self {
        return Swift.max(self, y)
    }
}

extension Optional {
    
    func fold<U>(none: U, some: (Wrapped) -> U) -> U {
        switch self {
        case .none:
            return none
        case .some(let wrapped):
            return some(wrapped)
        }
    }
}

//extension UnsafeMutablePointer where Pointee == CChar {
//    func resetMemory(with value: CChar = 0) {
//        let stringLen = strlen(self)
//        self.assign(repeating: value, count: stringLen)
//    }
//}
