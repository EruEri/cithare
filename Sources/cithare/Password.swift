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

#if os(macOS)
import CryptoKit
#else
import Crypto
#endif


let upperLetterAsciiRange: ClosedRange<UInt8> = 65...90
let lowerLetterAsciiRange: ClosedRange<UInt8> = 97...122

var lettersAscii: [UInt8] {
    var array = [UInt8]()
    array.append(contentsOf: upperLetterAsciiRange)
    array.append(contentsOf: lowerLetterAsciiRange)
    return array
}

var specialCharAsciiCode: [UInt8] {
    let firstRange: ClosedRange<UInt8> = (33...47)
    let secondeRange: ClosedRange<UInt8> = (58...64)
    let thirdRange: ClosedRange<UInt8> = (91...96)
    let fourthRange: ClosedRange<UInt8> = 123...126
    var array: [UInt8] = []
    array.append(contentsOf: firstRange)
    array.append(contentsOf: secondeRange)
    array.append(contentsOf: thirdRange)
    array.append(contentsOf: fourthRange)
    return array
}

enum CharType: CaseIterable {
    case number
    case letter
    case specialChar
    
    func pickRandomChar() -> Character {
        switch self {
        case .number:
            return (0...9).randomElement().map { Character.init("\($0)") }.unsafelyUnwrapped
        case .letter:
            return lettersAscii.randomElement().map { Character.init(.init($0)) }!
        case .specialChar:
            return specialCharAsciiCode.randomElement().map { Character.init(.init($0)) }!
        }
    }
}

func readValidatedInput(_ defaultMessage: String, _ errorMessage: String, _ emptyLineError: String) -> Bool {
    print(defaultMessage)
    let input = readLine()
    guard let read = input else {
        print(emptyLineError)
        return readValidatedInput(defaultMessage, errorMessage, emptyLineError)
    }
    if read.count != 1 {
        print(errorMessage)
        return readValidatedInput(defaultMessage, errorMessage, emptyLineError)
    } else {
        switch read.first! {
        case "y", "Y":
            return true
        case "n", "N":
            return false
        default:
            print("Error ?")
            print(errorMessage)
            return readValidatedInput(defaultMessage, errorMessage, emptyLineError)
        }
    }
}

func generateRandomPassword(_ length: UInt, _ useNumber: Bool, _ useSpecialChar: Bool) -> String {
    var cases: [CharType] = [.letter]
    if useNumber { cases.append(.number) }
    if useSpecialChar { cases.append(.specialChar) }
    
    var choosen = cases
    var string = ""
    for _ in 0..<length {
        choosen.shuffle()
        let type = choosen.removeFirst()
        if choosen.isEmpty { choosen = cases }
        string.append(type.pickRandomChar())
    }
    
    return string
}

func isPasswordsatisfying(_ length: UInt, _ useNumber: Bool, _ useSpecialChar: Bool) -> Optional<String> {

    let pass = generateRandomPassword(length, useNumber, useSpecialChar)
    print("Generated Password\n***  \(pass) ***")
    let response = readValidatedInput("Is password satisfying ? [y/n]",
                                      "Wrong Input!\nSelect between [y/n]",
                                      "No Input!\nPlease select a reponse")
    if response {
        return pass
    } else {
        let shouldKeepTrying = readValidatedInput("Do you want to try again? [y/n]",
                                                  "Wrong Input!\nSelect between [y/n]",
                                                  "No Input!\nPlease select a reponse")
        if shouldKeepTrying {
            return isPasswordsatisfying(length, useNumber, useSpecialChar)
        } else {
            return .none
        }
    }
    
}

func addSpace(_ n : Int) -> String {
    (0..<abs(n)).map({ _ in " "}).joined()
}




@available(macOS 10.15, *)
func confirmPassword(_ firstMessage : String, _ confirmMessage : String) -> Result<String, Cithare.Add.AddError> {
    let pass_opt  = getpass(firstMessage)
    guard let pass1 = pass_opt else { return .failure(Cithare.Add.AddError.nullPasswordPointer) }
    let p1 = String(cString: pass1)
    let pass_opt2 = getpass(confirmMessage)
    guard let pass2 = pass_opt2 else { return .failure(Cithare.Add.AddError.nullPasswordPointer) }
    let p2 = String(cString: pass2)
    if p1 != p2 { return .failure(Cithare.Add.AddError.unmatchPassword) }
    return .success(p1)
}

class Password : Codable {
    var website : String
    var username : String?
    var mail : String?
    var password : String
    
    init(website : String, username : String?, mail : String?, password : String) {
        self.website = website
        self.username = username
        self.mail = mail
        self.password = password
    }
    
    fileprivate func lineDescription(_ webLineLen : Int, _ userLineLen : Int,
                                     _ mailLineLen : Int, _ passLineLen : Int) -> String {
        
        var content = ""
        content.append(Terminal.VERTICAL_LINE)
        content.append(self.website)
        content.append(addSpace(webLineLen - self.website.count))
        content.append(Terminal.VERTICAL_LINE)
        
        content.append(self.username ?? "")
        content.append(addSpace(userLineLen - (self.username?.count ?? 0) ))
        content.append(Terminal.VERTICAL_LINE)
        
        content.append(self.mail ?? "")
        content.append(addSpace(mailLineLen - (self.mail?.count ?? 0) ))
        content.append(Terminal.VERTICAL_LINE)
        
        content.append(self.password)
        content.append(addSpace(passLineLen - self.password.count))
        content.append(Terminal.VERTICAL_LINE)
        return content
    }
}

enum EncryptionError : Error {
    case unableToEncrypt
    case unableToCombine
    case unableToWrite
}

enum DecryptionError : Error {
    case unableToRead
    case unableToSealBox
    case unableToDecryptFile
    case unableToDecryptPasswordManager
}

enum ChangeStatus {
    case added
    case replaced
}



class PasswordManager : Codable, CustomStringConvertible {
    
    private static let VERTICAL_LINE = "│"
    
    private var websiteSquareLength: Int {
        let website = "website"
        return passwords.reduce(0, { result, pass in
            max(result, pass.website.count)
        }).max(y: website.count)
    }
    
    private var usernameSquareLength: Int {
        let username = "username"
        return self.passwords.reduce(0, { result, pass in
            max(result, pass.username?.count ?? -1)
        }).max(y: username.count)
    }
    private var mailSquareLength: Int {
        let mail = "mail"
        return self.passwords.reduce(0, { result, pass in
            result >= pass.mail?.count ?? 0 ? result : pass.mail!.count
        }).max(y: mail.count)
    }
    
    private var passwordSquareLength: Int {
        let password = "password"
        return self.passwords.reduce(0, { result, pass in
             result > pass.password.count ? result : pass.password.count
        }).max(y: password.count)
    }
    
    private var lineWidth: Int {
        websiteSquareLength + mailSquareLength + usernameSquareLength + passwordSquareLength + 4
    }

    
    init(formFormated formated: String) {
        self.passwords = formated
            .split(separator: "\n")
            .enumerated()
            .compactMap ({ (index, line) in index != 0 && index.isMultiple(of: 2) ? String(line) : nil  })
            .compactMap { line -> Password? in
                let passwordComponents = line.split(separator: "|")
                guard passwordComponents.count == 4 else { return nil }
                let website = passwordComponents[0]
                let username = (passwordComponents[1].contains { !$0.isWhitespace } ? passwordComponents[1] : nil).map(String.init)
                let mail = (passwordComponents[2].contains { !$0.isWhitespace } ? passwordComponents[2] : nil).map(String.init)
                let password = passwordComponents[3]
                return .init(website: String(website), username: username, mail: mail, password: String(password))
            }
    }
    
    public func display(displayTime: UInt?) {
        var terminal = Terminal(width: lineWidth)
        let thread = Thread(block: {
            self.draw(terminal: &terminal, killThread: true)
        })
        
        switch displayTime {
        case .none:
            self.draw(terminal: &terminal, killThread: false)
        case .some(let dt):
            thread.start()
            sleep( UInt32(dt) )
            thread.cancel()
            terminal.endWindow()
            
        }
    }
    
    private func draw(terminal: inout Terminal, killThread: Bool = false) {
        let passwordString = self.passwords.map { pass in
            pass.lineDescription(websiteSquareLength, usernameSquareLength, mailSquareLength, passwordSquareLength)
        }
        let count = passwordString.count
        
        var running = true
        
        var oldSize = terminal.size
        terminal.startWindow()
        var currentLine = 0
        var oldLine = ( (count - 1) % count ).abs

        while running {
            let newSize = terminal.size
            var input: UInt8 = 0
            if oldLine != currentLine {
                oldLine = currentLine
                terminal.drawItem(items: passwordString, startAt: currentLine, title: "cithare")
            } else if oldSize != newSize {
                oldSize = newSize
                terminal.width = min(lineWidth, newSize.column)
                terminal.drawItem(items: passwordString, startAt: currentLine, title: "cithare")
            }
            read(STDIN_FILENO, &input , 1)
            switch input {
            case Character("q").asciiValue!:
                running = false
            case  Character("i").asciiValue!:
                currentLine = (currentLine + 1) % count
            case Character("k").asciiValue!:
                currentLine = ((currentLine - 1) % count).abs
            default:
                break
            }
        }
        
        terminal.endWindow()
        
        if killThread {
            exit(0)
        }
        
    }
    
    
    var description: String {
        
        let website = "website"
        let username = "username"
        let mail = "mail"
        let password = "password"
        
        var content = ""
        
        content.append(website)
        content.append(addSpace(websiteSquareLength - website.count))
        content.append("|")
        
        content.append(username)
        content.append(addSpace(usernameSquareLength - (username.count) ))
        content.append("|")
        
        content.append(mail)
        content.append(addSpace(mailSquareLength - (mail.count) ))
        content.append("|")
        
        content.append(password)
        content.append(addSpace(passwordSquareLength - password.count))
        content.append("|\n")
        
        
        for _ in (0..<websiteSquareLength + mailSquareLength + usernameSquareLength + passwordSquareLength + 4) {
            content.append("-")
        }
        content.append("\n")
        
        self.passwords.forEach { pass in
            content.append(
                pass.lineDescription(websiteSquareLength, usernameSquareLength, mailSquareLength, passwordSquareLength)
            )
        }
        return content
    }
    
    var passwords : [Password]
    
    var count : Int {
        self.passwords.count
    }
    
    init(){
        self.passwords = .init()
    }
    
    
    func addPassword(password : Password) {
        self.passwords.append(password)
    }
    
    
    ///
    /// - Parameter website :website name
    /// - Returns : The number of deleted password
    func remove(website: String) -> Int {
        let count = self.count
        self.passwords.removeAll { $0.website == website }
        return count - self.count
    }
    
    func filter(where isIncluded: (Password) throws -> Bool) rethrows {
        self.passwords = try self.passwords.filter(isIncluded)
    }
    
    func findIndex(predicate: (Password) -> Bool) -> Int? {
        for (i, password) in passwords.enumerated() {
            if predicate(password) { return i }
        }
        return nil
    }
    
    ///
    ///
    /// - Returns : If the password is replace
    func replaceOrAdd(website : String, password : String, username : String? = nil, mail : String? = nil) -> ChangeStatus {
        if let pass = (self.passwords.first { pwd in pwd.website == website }) {
            pass.password = password
            pass.username = username ?? pass.username
            pass.mail = mail ?? pass.mail
            return .replaced
        } else {
            self.addPassword(password: Password.init(website: website, username: username, mail: mail, password: password))
            return .added
        }
    }
    
    fileprivate func toData() -> Data {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        return data!
    }
    
}



@available(macOS 10.15, *)
struct PasswordManagerEncryption {
    
    public func encrypt(passwordManager : PasswordManager, masterKey : String, atPath file : String) -> Result<(), EncryptionError> {
        let key = SymmetricKey.init(data: SHA256.hash(data: masterKey.data(using: .utf8)!))
        let derivedKey = HKDF<SHA256>.deriveKey(inputKeyMaterial: key, outputByteCount: 32)
        
        let nonce = AES.GCM.Nonce.init()
        let data = passwordManager.toData()
        guard let sealedBox = try? AES.GCM.seal(data, using: derivedKey, nonce: nonce) else { return .failure(.unableToEncrypt) }
        guard let encryptedContent = sealedBox.combined else { return .failure(.unableToCombine) }
        guard let _ = try? encryptedContent.write(to: URL.init(fileURLWithPath: file), options: [.atomic]) else {  return .failure(.unableToWrite) }
        return .success(())
    }
    
    public func decrypt(masterKey: String, atPath file : String) -> Result<PasswordManager, DecryptionError> {
        guard let dataByte = FileManager.default.contents(atPath: file) else { return .failure(.unableToRead) }
        let key = SymmetricKey.init(data: SHA256.hash(data: masterKey.data(using: .utf8)!))
        let derivedKey = HKDF<SHA256>.deriveKey(inputKeyMaterial: key, outputByteCount: 32)
        
        guard let sealedBox = try? AES.GCM.SealedBox.init(combined: dataByte) else { return .failure(.unableToSealBox) }
        guard let decryptedData = try? AES.GCM.open(sealedBox, using: derivedKey) else { return .failure(.unableToDecryptFile)}
        let decoder = JSONDecoder()
        guard let passwordManager = try? decoder.decode(PasswordManager.self, from: decryptedData) else { return .failure(.unableToDecryptPasswordManager) }
        return .success(passwordManager)
    }
    
}
