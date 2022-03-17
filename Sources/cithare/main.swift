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

@available(macOS 10.15, *)
struct Pswn : ParsableCommand {
    static var configuration = CommandConfiguration( subcommands: [Pswn.AddPwd.self, Pswn.Init.self] )
    
}


@available(macOS 10.15, *)
extension Pswn {
    
    struct AddPwd : ParsableCommand {
        
        static var configuration: CommandConfiguration = CommandConfiguration(abstract: "Add a new password into the password Manager")
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
        
        func validate() throws {
            if self.username == nil && self.mail == nil {
                throw ValidationError("at least --username or --mail should be provided")
            }
            if !FileManager.default.fileExists(atPath: appFileFullPath) {
                throw ValidationError("app file not found.\nYou should run 'init' command")
            }
        }
        
        func run() throws {
            
            let result = confirmPassword("Enter a password : ", "Confirm password :  ")
            switch result {
            case .failure(let error):
                throw error
            default:
                break
            }
            let p1 = try! result.get()
            let masterKeywordOpt = getpass("Enter the master password : ")
            guard let masterKey = masterKeywordOpt else { throw Self.PwdError.nullPasswordPointer }
            let passwordEncrypter = PasswordManagerEncryption.init()
            let sMasterkey = String(cString: masterKey)
            switch passwordEncrypter.decrypt(masterKey: sMasterkey, atPath: appFileFullPath) {
            case .failure(let error):
                print("\(error)")
                return
            case .success(let passwordManager):
                let password = Password.init(website: self.webSite, username: self.username, mail: self.mail, password: p1)
                passwordManager.addPassword(password: password)
                switch passwordEncrypter.encrypt(passwordManager: passwordManager, masterKey: sMasterkey, atPath: appFileFullPath) {
                case .failure(let error):
                    print("\(error)")
                    return
                case .success(_):
                    print("Password saved")
                    return
                }
            }

        }
    }
    
    struct Init : ParsableCommand {
        
        static var configuration: CommandConfiguration = CommandConfiguration.init(abstract: "Initialize the password Manager")
        enum InitError : Error, CustomStringConvertible {
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
        
        @Flag(name: .shortAndLong, help : "Force the initialization")
        var force = false
        
        func run() throws {
            let fileManager = FileManager.default
            var home : URL = fileManager.homeDirectoryForCurrentUser
//            if #available(macOS 10.12, *) {
//                home = fileManager.homeDirectoryForCurrentUser
//            } else {
//                home = URL(fileURLWithPath: NSHomeDirectory())
//            }
            home.appendPathComponent(APPDIR)
            if !fileManager.fileExists(atPath: home.path, isDirectory: nil ) {
                do {
                    try fileManager.createDirectory(at: home, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    throw Self.InitError.unableToCreateDirectory
                }
            }
            home.appendPathComponent(PASSFILE)
            if (!self.force){
                if fileManager.fileExists(atPath: home.path) {
                    throw Self.InitError.alreadyInitialized
                }
            }
            let isCreated = fileManager.createFile(atPath: home.path, contents: nil, attributes: nil)
            if (!isCreated) {
                throw Self.InitError.unableToCreateFile
            }else {
                let confirmPass = confirmPassword("Choose the master password : ", "Confirm the master password : ")
                switch confirmPass {
                case .failure(let error):
                    throw error
                default:
                    break
                }
                let master = try! confirmPass.get()
                let passwordManager = PasswordManager.init()
                let passwordManagerEncryption =  PasswordManagerEncryption.init()
                switch passwordManagerEncryption.encrypt(passwordManager: passwordManager, masterKey: master, atPath: home.path){
                case .failure(let error):
                    throw error
                case .success(_):
                    print("Cithare Initiliazed\n")
                    return
                }
                
            }
        }
    }

}


if #available(macOS 10.15, *) {
    Pswn.main()
} else {
    print("Need macOS min version 10.15")
}

//if #available(macOS 12.0, *) {
//    let masterKey = "MasterPass"
//    func addPassword(){
//        let passWord : Password = .init(website: "Nautiljon.fr", username: "Hello", mail: "you@me.mail", password: "Trymefirst123")
//        let pm = PasswordManager()
//        pm.addPassword(password: passWord)
//        let pse = PasswordManagerEncryption.init()
//        print(pse.encrypt(passwordManager: pm, masterKey: masterKey, atPath: appFileFullPath))
//    }
//
//    func decrypt(){
//        let pse = PasswordManagerEncryption.init()
//        switch pse.decrypt(masterKey: masterKey, atPath: appFileFullPath) {
//        case .failure(let error):
//            print("\(error)")
//        case .success(let passwordManager):
//            print("\(passwordManager)")
//        }
//    }
//
//    addPassword()
//    decrypt()
//}
