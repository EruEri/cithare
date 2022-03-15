import Foundation
import ArgumentParser

let APPDIR : String = ".pswm"
let PASSFILE : String = ".pswmfile"
var appFileFullPath : String {
    let fileManager = FileManager.default
    var home : URL
    if #available(macOS 10.12, *) {
        home = fileManager.homeDirectoryForCurrentUser
    } else {
        home = URL(fileURLWithPath: NSHomeDirectory())
    }
    home.appendPathComponent(APPDIR)
    home.appendPathComponent(PASSFILE)
    return home.path
}

struct Pswn : ParsableCommand {
    static var configuration = CommandConfiguration( subcommands: [Pswn.AddPwd.self, Pswn.Init.self] )
    
}


extension Pswn {
    struct AddPwd : ParsableCommand {
        enum PwdError : Error, CustomStringConvertible {
            var description: String {
                switch self {
                case .nullPasswordPointer:
                    return "Error while entering the password"
                case .unmatchPassword:
                    return "Passwords don't match"
                case .wrongMasterPassword:
                    return "Wrong master password"
                }
            }
            
            case nullPasswordPointer
            case unmatchPassword
            case wrongMasterPassword
        }
        @Option(name: .long)
        var webSite : String
        
        @Option(name : .shortAndLong)
        var username : String?
        
        @Option(name: .shortAndLong)
        var mail : String?
        
        func run() throws {
            switch(self.username, self.mail){
            case (.none, .none):
                print("at least --username or --mail should be provided")
                return
//            case (.some(let uName), .none):
//                break
//            case (.none, .some(let uMail)):
//                break
//            case (.some(let uName), .some(let uMail)):
//                break
            default:
                let pass_opt  = getpass("Enter a password : ")
                guard let pass1 = pass_opt else { throw Self.PwdError.nullPasswordPointer }
                let pass_opt2 = getpass("Confirm password :  ")
                guard let pass2 = pass_opt2 else { throw Self.PwdError.nullPasswordPointer }
                let p1 = String.init(cString: pass1)
                let p2 = String(cString: pass2)
                if (p1 != p2) { throw Self.PwdError.unmatchPassword }
                let masterKeywordOpt = getpass("Enter the master password : ")
                guard let masterKey = masterKeywordOpt else { throw Self.PwdError.nullPasswordPointer }
                
            }
        }
    }
    
    struct Init : ParsableCommand {
        enum InitError : Error, CustomStringConvertible {
            var description: String {
                switch self {
                case .unableToCreateDirectory:
                    return "Unable to create the app dir at path :"
                case .unableToCreateFile:
                    return "Unable to create app file"
                }
            }
            case unableToCreateDirectory
            case unableToCreateFile
        }
        
        func run() throws {
            let fileManager = FileManager.default
            var home : URL
            if #available(macOS 10.12, *) {
                home = fileManager.homeDirectoryForCurrentUser
            } else {
                home = URL(fileURLWithPath: NSHomeDirectory())
            }
            home.appendPathComponent(APPDIR)
            if !fileManager.fileExists(atPath: home.path, isDirectory: nil ) {
                do {
                    try fileManager.createDirectory(at: home, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    //print("Unable to create the app dir at path : \(home.absoluteString)")
                    throw Self.InitError.unableToCreateDirectory
                }
            }
            home.appendPathComponent(PASSFILE)
            let isCreated = fileManager.createFile(atPath: home.path, contents: nil, attributes: nil)
            if (!isCreated) {
                throw Self.InitError.unableToCreateFile
            }else {
                print("Pswm initialized")
                return
            }
        }
    }

}


//Pswn.main()

if #available(macOS 12.0, *) {
    let masterKey = "MasterPass"
    func addPassword(){
        let passWord : Password = .init(website: "Nautiljon.fr", username: "Hello", mail: "you@me.mail", password: "Trymefirst123")
        let pm = PasswordManager()
        pm.addPassword(password: passWord)
        let pse = PasswordManagerEncryption.init()
        print(pse.encrypt(passwordManager: pm, masterKey: masterKey, atPath: appFileFullPath))
    }
    
    func decrypt(){
        let pse = PasswordManagerEncryption.init()
        switch pse.decrypt(masterKey: masterKey, atPath: appFileFullPath) {
        case .failure(let error):
            print("\(error)")
        case .success(let passwordManager):
            print("\(passwordManager)")

        }
    }
    
    decrypt()

}
