//
//  File.swift
//  
//
//  Created by Yves Ndiaye on 14/03/2022.
//

import Foundation
import CryptoKit


func readAllFile(atPath : String) -> [UInt8]? {
    guard let file = fopen(atPath, "r") else { return nil }
    
    fseek(file, 0, SEEK_END)
    let size = ftell(file)
    fseek(file, 0, SEEK_SET)
    var buffer = [UInt8].init(repeating: 0, count: size)
    fread(&buffer, 1, size, file)
    return buffer
}

func copyString(_ ptr : UnsafeMutablePointer<CChar>) -> String {
    var s = ""
    var offset = 0
    var offsetChar = ptr.advanced(by: offset).pointee;
    let nullTerminate : Character = "\0"
    while offset != (nullTerminate.asciiValue!) {
        s.append(String.init(format: "%c", offsetChar))
        offset += 1
        offsetChar = ptr.advanced(by: offset).pointee
    }
    return s
}


@available(macOS 10.15, *)
func confirmPassword(_ firstMessage : String, _ confirmMessage : String) -> Result<String, Pswn.Add.AddError> {
    let pass_opt  = getpass(firstMessage)
    guard let pass1 = pass_opt else { return .failure(Pswn.Add.AddError.nullPasswordPointer) }
    let p1 = String.init(cString: pass1)
    let pass_opt2 = getpass(confirmMessage)
    guard let pass2 = pass_opt2 else { return .failure(Pswn.Add.AddError.nullPasswordPointer) }
    let p2 = String(cString: pass2)
    if (p1 != p2) { return  .failure(Pswn.Add.AddError.unmatchPassword) }
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



class PasswordManager : Codable {
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
    
    ///
    ///
    /// - Returns : If the password is replace
    func replaceOrAdd(website : String, password : String, username : String? = nil, mail : String? = nil) -> ChangeStatus {
        if let pass = (self.passwords.first { pwd in pwd.website == website }) {
            pass.password = password
            pass.username = username ?? pass.username
            pass.mail = mail ?? pass.mail
            return .replaced
        }else {
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
        let asciiCharRange = (33...126)
        let key = SymmetricKey.init(data: SHA256.hash(data: masterKey.data(using: .utf8)!))
//        print(key.withUnsafeBytes { $0.map { $0 } }  )
        let nonce = AES.GCM.Nonce.init()
        let tagStr = String.init( (0..<16).map { _ in
            Character.init(Unicode.Scalar.init(asciiCharRange.randomElement()!)!)
        } )
        let tag = tagStr.data(using: .ascii)!
        let data = passwordManager.toData()
        guard let sealedBox = try? AES.GCM.seal(data, using: key, nonce: nonce, authenticating: tag) else { return .failure(.unableToEncrypt) }
        guard var encryptedContent = sealedBox.combined else { return .failure(.unableToCombine) }
        encryptedContent.append(contentsOf: tag)
        guard let _ = try? encryptedContent.write(to: URL.init(fileURLWithPath: file), options: [.atomic]) else {  return .failure(.unableToWrite) }
        return .success(())
    }
    
    public func decrypt(masterKey: String, atPath file : String) -> Result<PasswordManager, DecryptionError> {
        guard var dataByte = FileManager.default.contents(atPath: file) else { return .failure(.unableToRead) }
        let tagStr = String.init(data: dataByte[(dataByte.count - 16)...], encoding: .ascii)!
        let tag = tagStr.data(using: .ascii)!
        dataByte = dataByte.dropLast(16)
        let key = SymmetricKey.init(data: SHA256.hash(data: masterKey.data(using: .utf8)!))
        guard let sealedBox = try? AES.GCM.SealedBox.init(combined: dataByte) else { return .failure(.unableToSealBox) }
        guard let decryptedData = try? AES.GCM.open(sealedBox, using: key, authenticating: tag) else { return .failure(.unableToDecryptFile)}
        let decoder = JSONDecoder()
        guard let passwordManager = try? decoder.decode(PasswordManager.self, from: decryptedData) else { return .failure(.unableToDecryptPasswordManager) }
        return .success(passwordManager)
    }
    
    
}
