import Foundation
import ArgumentParser

#if canImport(APPKit)
import AppKit
#endif

let APPDIR : String = ".cithare"
let PASSFILE : String = ".citharecf"
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
struct Cithare : ParsableCommand {
    static var configuration = CommandConfiguration( subcommands: [
        Cithare.Init.self,
        Cithare.Add.self,
        Cithare.Show.self,
        Cithare.GeneratePassword.self
    ])
    
    @Flag()
    var changeMasterPassword = false
    
    func run() throws {
        
        if !changeMasterPassword {
            return
        }
        
        let pass_opt = getpass("Enter the master password : ")
        guard let pass1 = pass_opt else { throw (Cithare.Add.AddError.nullPasswordPointer) }
        let passWord = String(cString: pass1)
        let result = confirmPassword("Enter the new master password : ", "Confirm the new master password : ")
        switch result {
        case .failure(let error):
            throw error
        default:
            break
        }
        
        let new_pass = try! result.get()
        let passEncryp = PasswordManagerEncryption.init()
        switch passEncryp.decrypt(masterKey: passWord, atPath: appFileFullPath) {
        case .failure(let error):
            throw error
        case .success(let password):
            switch passEncryp.encrypt(passwordManager: password, masterKey: new_pass, atPath: appFileFullPath) {
            case .failure(let error):
                throw error
            case .success(_):
                print("Master password sucessfully changed")
            }
        }
    }
    
}


@available(macOS 10.15, *)
extension Cithare {
    
    struct Add : ParsableCommand {
        
        static var configuration: CommandConfiguration = CommandConfiguration(abstract: "Add a new password into the password Manager")
        enum AddError : Error, CustomStringConvertible {
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
        
        @Flag(name: .shortAndLong, help: "Use in order to replace a password")
        var replace = false
        
        @Option(name: .shortAndLong)
        var webSite : String
        
        @Option(name: .shortAndLong)
        var username : String?
        
        @Option(name: .shortAndLong)
        var mail : String?
        
        @Option(name: .long, help: "Generate an automatic password with a given lenght")
        var autoGen: UInt8?
        
        func validate() throws {
            if self.username == nil && self.mail == nil && !self.replace {
                throw ValidationError("at least --username or --mail should be provided to add")
            }
            if !FileManager.default.fileExists(atPath: appFileFullPath) {
                throw ValidationError("app file not found.\nYou should run 'init' command")
            }
            if let lenght = autoGen, lenght < 8 {
                throw ValidationError("Password lenght is too short\n Need at least 8 charaters")
            }
        }
        
        func getPass() -> Result<String, Cithare.Add.AddError> {
            if let autoGen = autoGen {
                if let pass = isPasswordsatisfying(UInt(autoGen), true, true) {
                    return .success(pass)
                } else {
                    return .failure(.passwordNotSatisfying)
                }
            } else {
                return confirmPassword("Enter a password : ", "Confirm password :  ")
            }
        }
        
        func run() throws {
            
            switch getPass() {
            case .failure(let error):
                throw error
            case .success(let p1):
                let masterKeywordOpt = getpass("Enter the master password : ")
                guard let masterKey = masterKeywordOpt else { throw Self.AddError.nullPasswordPointer }
                let passwordEncrypter = PasswordManagerEncryption.init()
                let sMasterkey = String(cString: masterKey)
                switch passwordEncrypter.decrypt(masterKey: sMasterkey, atPath: appFileFullPath) {
                case .failure(let error):
                    throw error
                case .success(let passwordManager):
                    
                    if self.replace {
                        switch passwordManager.replaceOrAdd(website: self.webSite, password: p1, username: self.username, mail: self.mail){
                        case .replaced:
                            print("Password replaced")
                        case .added:
                            print("Password added")
                        }
                    } else {
                        let password = Password.init(website: self.webSite, username: self.username, mail: self.mail, password: p1)
                        passwordManager.addPassword(password: password)
                    }
                    
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
            if !self.force {
                if fileManager.fileExists(atPath: home.path) {
                    throw Self.InitError.alreadyInitialized
                }
            }
            let isCreated = fileManager.createFile(atPath: home.path, contents: nil, attributes: nil)
            if !isCreated {
                throw Self.InitError.unableToCreateFile
            } else {
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
    
    struct Show : ParsableCommand {
        
        static var configuration: CommandConfiguration = CommandConfiguration.init(abstract: "Show password")
        
        
        @Option(name: [.short, .long, .customLong("dt")], help : "Display duration in seconds" )
        var displayTime: UInt = 5
        
        @Option(name: .shortAndLong, help : "Specify the site")
        var website: String?
        
        
        @Flag(name: [.short, .long], help: "Find the website by matching its name")
        var regex = false
        

        @Option(name: [.short, .long], help: "Output file")
        var output: String?

        #if os(macOS)
        @Flag(name: [.short, .long], help: "Write the password into the pasteboard")
        var paste = false
        #endif

        func validate() throws {
            #if os(macOS)
            if paste && website == nil {
                throw ValidationError(" --website must be provided if --paste is present")
            }
            #endif
        }
        
        func run() throws {
            let masterKeywordOpt = getpass("Enter the master password : ")
            guard let masterKey = masterKeywordOpt else { throw Cithare.Add.AddError.nullPasswordPointer }
            let passwordEncrypter = PasswordManagerEncryption.init()
            let sMasterkey = String(cString: masterKey)
            switch passwordEncrypter.decrypt(masterKey: sMasterkey, atPath: appFileFullPath) {
            case .failure(let error):
                print("\(error)")
                return
            case .success(let passwordManager):
                if let website = self.website {
                    if regex {
                        let regexR = try NSRegularExpression(pattern: website, options: .caseInsensitive)
                        passwordManager.filter { password in
                            let matches = regexR.matches(in: password.website, range: .init(location: 0, length: password.website.count))
                            return !matches.isEmpty
                        }
                        
                        if passwordManager.count == 0 {
                            print("No websites matched")
                            throw ExitCode.init(1)
                        } else if passwordManager.count >= 2  {
                            print("To much websites matched\nConflict between:\n  \(passwordManager.passwords.map({ $0.website }).joined(separator: "\n  "))")
                            throw ExitCode.init(1)
                        }
                    } else {
                        passwordManager.filter { pw in pw.website == website }
                    }
                }
                #if os(macOS)
                if paste {
                   
                    if let password = passwordManager.passwords.first {
                        NSPasteboard.general.clearContents()
                        if NSPasteboard.general.setString(password.password, forType: .string) {
                            if regex {
                                print("For : \(password.website)")
                            }
                            print("Password successfully written in pasteboard")
                            return
                        } else {
                            print("Unable to write into the pasteboard")
                            throw ExitCode.init(1)
                        }
                    } else {
                        print("Cannot find a password for the given website")
                        throw ExitCode.init(1)
                    }
                    return
                } #endif 
                if let output = output {
                    let fileManager = FileManager.default
                    if fileManager.createFile(atPath: output, contents: passwordManager.description.data(using: .utf8)) {
                        print("Successfully written at \(output)")
                        return
                    } else {
                        print("Unable to create the output file")
                        throw ExitCode.init(1)
                    }
                } else {
                    print(passwordManager.description)
                    sleep(UInt32(self.displayTime))
                    print("\u{001B}[2J")
                }
                return
            }
        }
    }
    
    struct GeneratePassword: ParsableCommand {
        static var configuration: CommandConfiguration = CommandConfiguration.init(abstract: "Generate a random password")
        
        @Option(name: .shortAndLong, help: "Password length")
        var length : UInt = 16
        
        @Flag(name: [.customShort("n"), .long], help: "Use numbers in password creation")
        var useNumber: Bool = false
        
        @Flag(name: [.customLong("sp"), .long], help: "Use special ascii character in password creation")
        var useSpecialChar: Bool = false
        
        func run() throws {
            print("Generating .....")
            print(generateRandomPassword(self.length, self.useNumber, self.useSpecialChar))
        }
    }

}


if #available(macOS 10.15, *) {
    Cithare.main()
} else {
    print("Need macOS min version 10.15")
}


