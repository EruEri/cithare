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

enum XdgDirectory {
    case xdgCacheDirectory
    case xdgDataDirectory
    case xdgConfigDirectory
    case xdgStateDirectory
}

enum XdgError : Error {
    case xdgInvalidUrl(XdgDirectory)
    case xdgUnableToCreateDir(XdgDirectory)
}

struct Xdg {
    public let appName : String
    
    private let XDG_ENV_DATA_HOME = "XDG_DATA_HOME"
    private let XDG_ENV_CONFIG_HOME = "XDG_CONFIG_HOME"
    private let XDG_ENV_CACHE_HOME = "XDG_CACHE_HOME"
    private let XDG_ENV_STATE_HOME = "XDG_STATE_HOME"
    
    public var xdgDataDirectory : String? {
        let defaultPath =
            FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local")
            .appendingPathComponent("share")
            .absoluteString

        let path = ProcessInfo.processInfo.environment[XDG_ENV_DATA_HOME] ?? defaultPath
        
        var url = URL(string: path)
        url = url?.appendingPathComponent(appName)
        return url?.absoluteString
    }
    
    public var xdgCacheDirectory : String? {
        let defaultPath =
            FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache")
            .absoluteString

        let path = ProcessInfo.processInfo.environment[XDG_ENV_CACHE_HOME] ?? defaultPath
        
        var url = URL(string: path)
        url = url?.appendingPathComponent(appName)
        return url?.absoluteString
    }
    
    public var xdgConfigDirectory : String? {
        let defaultPath =
            FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .absoluteString

        let path = ProcessInfo.processInfo.environment[XDG_ENV_CONFIG_HOME] ?? defaultPath
        
        var url = URL(string: path)
        url = url?.appendingPathComponent(appName)
        return url?.absoluteString
    }
    
    public var xdgStateDirectory : String? {
        let defaultPath =
            FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local")
            .appendingPathComponent("state")
            .absoluteString

        let path = ProcessInfo.processInfo.environment[XDG_ENV_CACHE_HOME] ?? defaultPath
        
        var url = URL(string: path)
        url = url?.appendingPathComponent(appName)
        return url?.absoluteString
    }
    
    func getDirectory(_ kind : XdgDirectory) -> Result<String, XdgError> {
        var path : String?
        switch kind {
        case .xdgCacheDirectory:
            path = self.xdgCacheDirectory
        case .xdgDataDirectory:
            path = self.xdgDataDirectory
        case .xdgConfigDirectory:
            path = self.xdgConfigDirectory
        case .xdgStateDirectory:
            path = self.xdgStateDirectory
        }
        
        guard let path = path else {
            return .failure(.xdgInvalidUrl(kind))
        }
        
        if FileManager.default.fileExists(atPath: path) {
            return .success(path)
        }
        
        let success: ()? = try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        
        guard let _ = success else {
            return .failure(.xdgUnableToCreateDir(kind))
        }
        
        return .success(path)
    }
}
