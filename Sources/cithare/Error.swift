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



enum CithareAddError : Error, CustomStringConvertible {
    var description: String {
        switch self {
        case .nullPasswordPointer:
            return "Error while entering the password"
        case .unmatchPassword:
            return "Passwords don't match"
        case .wrongMasterPassword:
            return "Wrong master password"
        case .alreadyPassforWebsite(let link):
            return "A password already exists for this site : \(link)"
        case .passwordNotSatisfying:
            return "Password Generation failed"
        }
    }
    
    case nullPasswordPointer
    case unmatchPassword
    case wrongMasterPassword
    case passwordNotSatisfying
    case alreadyPassforWebsite(String)
}

enum CithareInitError : Error, CustomStringConvertible {
    var description: String {
        switch self {
        case .unableToCreateDirectory:
            return "Unable to create the app dir at path :"
        case .unableToCreateFile:
            return "Unable to create app file"
        case .alreadyInitialized:
            return "Cithare is already initialized"
        }
    }
    case unableToCreateDirectory
    case unableToCreateFile
    case alreadyInitialized
}

enum CithareError : Error, CustomStringConvertible {
    case initError(CithareInitError)
    case addError(CithareAddError)
    
    
    var description: String {
        switch self {
        case .initError(let cithareInitError):
            return cithareInitError.description
        case .addError(let cithareAddError):
            return cithareAddError.description
        }
    }
}
