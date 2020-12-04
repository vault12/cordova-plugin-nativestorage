import Foundation
import UIKit
import LocalAuthentication


@objc(CryptoUtils)
class CryptoUtils: NSObject {
    
    private static let keyAlias = "vault12.cryptonativestorage.keyalias"
    
    private static func makeAndStoreKey(name: String,
                                        requiresBiometry: Bool = false) throws -> SecKey {
        let flags: SecAccessControlCreateFlags
        if #available(iOS 11.3, *) {
            flags = requiresBiometry ?
                [.privateKeyUsage, .biometryCurrentSet] : .privateKeyUsage
        } else {
            flags = requiresBiometry ?
                [.privateKeyUsage, .touchIDCurrentSet] : .privateKeyUsage
        }
        let access =
            SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                            kSecAttrAccessibleAfterFirstUnlock,
                                            flags,
                                            nil)!
        let tag = name.data(using: .utf8)!
        var attributes: [String: Any] = [
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String     : 256,
            kSecPrivateKeyAttrs as String : [
                kSecAttrIsPermanent as String       : true,
                kSecAttrApplicationTag as String    : tag,
                kSecAttrAccessControl as String     : access
            ]
        ]
        if Device.hasSecureEnclave {
            attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        }
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            print ("Error creating key")
            throw error!.takeRetainedValue() as Error
        }
        
        return privateKey
    }
    
    private static func loadKey(name: String) -> SecKey? {
        let tag = name.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecReturnRef as String             : true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        return (item as! SecKey)
    }
    
    private static func getKey(name: String) -> SecKey? {
        if let key = loadKey(name: name) {
            return key
        } else {
            do {
                return try makeAndStoreKey(name: name, requiresBiometry: false)
            } catch {
                print("\(error.localizedDescription)")
                return nil
            }
        }
    }
        
    @objc
    static func encrypt(clearText: String) -> Data? {
        guard let keyItem = getKey(name: keyAlias) else {
            print("Can't get key item")
            return nil
        }
        guard let publicKey = SecKeyCopyPublicKey(keyItem) else {
            print("Can't get public key")
            return nil
        }
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            print("Algorithm not supported")
            return nil
        }
        var error: Unmanaged<CFError>?
        let clearTextData = clearText.data(using: .utf8)!
        let cipherTextData = SecKeyCreateEncryptedData(publicKey, algorithm,
                                                   clearTextData as CFData,
                                                   &error) as Data?
        guard cipherTextData != nil else {
            print("Can't encrypt: \((error!.takeRetainedValue() as Error).localizedDescription)")
            return nil
        }
        return cipherTextData
    }
    
    @objc
    static func decrypt(cipherTextData: Data, completion: @escaping (String?) -> Void) -> Void {
        
        guard let keyItem = getKey(name: keyAlias) else {
            print("Can't get key item")
            completion(nil)
            return
        }

        
        // cipherTextData is our encrypted data
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(keyItem, .decrypt, algorithm) else {
            print("Algorithm not supported")
            completion(nil)
            return
        }

        // SecKeyCreateDecryptedData call is blocking when the used key
        // is protected by biometry authentication. If that's not the case,
        // dispatching to a background thread isn't necessary.
        DispatchQueue.global().async {
            var error: Unmanaged<CFError>?
            let clearTextData = SecKeyCreateDecryptedData(keyItem,
                                                          algorithm,
                                                          cipherTextData as CFData,
                                                          &error) as Data?
            DispatchQueue.main.async {
                guard clearTextData != nil else {
                    print("Can't decrypt: \((error!.takeRetainedValue() as Error).localizedDescription)")
                    completion(nil)
                    return
                }
                let clearText = String(decoding: clearTextData!, as: UTF8.self)
                completion(clearText)
            }
        }
    }
    
    @objc
    static func test() {
        if let encrypted = encrypt(clearText: "Hello world") {
            print("encrypted OK")
            decrypt(cipherTextData: encrypted) { (decrypted) in
                print("decrypted: \(decrypted ?? "nil")")
            }
        } else {
            print("encryption failed")
        }
    }
    
}

public enum Device {
    
    public static var hasTouchID: Bool {
        if #available(OSX 10.12.2, *) {
            return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        } else {
            return false
        }
    }
    
    public static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
    public static var hasSecureEnclave: Bool {
        return hasTouchID && !isSimulator
    }
    
}

