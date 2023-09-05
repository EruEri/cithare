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


enum CithareConfig {
    static let CITHARE_NAME = "cithare"
    static let VERSION = "0.8.0"
    static let PASSWORD_FILE = ".citharecf"
    static let CITHARE_ENV_SAVE_STATE = "CITHARE_SAVE_STATE"
    static let CITHARE_DIRS = Xdg(appName: CITHARE_NAME)
    
    static func isPasswordFileExist() -> Result<Bool, XdgError> {
        let dataDirectory : XdgDirectory = .xdgDataDirectory
        return Self.CITHARE_DIRS
            .getDirectory(dataDirectory)
            .map { url in
                let url2 = url.appendingPathComponent(Self.PASSWORD_FILE)
                let exist = FileManager.default.fileExists(atPath: url2.path)
                return exist
            }
    }
    
    static func shouldSaveState() -> Bool {
        ProcessInfo.processInfo
            .environment[Self.CITHARE_ENV_SAVE_STATE]
            .fold(none: true) { env in
                let value = env.lowercased()
                return !(value == "no" || value == "0" || value == "false")
            }
    }
}
