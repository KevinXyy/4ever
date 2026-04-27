import CryptoKit
import Flutter
import Foundation
import Security

final class CryptoHostApiAdapter: NSObject {
  private let keyId = "database-key"
  private let keychainService = "com.gemmalocal.keys"

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.gemmalocal.native/crypto",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "getOrCreateDatabaseKeyId":
        _ = try getOrCreateKey()
        result(keyId)
      case "encrypt":
        guard let payload = call.arguments as? [String: Any],
              let plaintext = payload["plaintext"] as? FlutterStandardTypedData else {
          result(nativeFlutterError(.unknown, message: "Invalid encrypt request."))
          return
        }
        let sealedBox = try AES.GCM.seal(plaintext.data, using: getOrCreateKey())
        result(FlutterStandardTypedData(bytes: sealedBox.combined ?? Data()))
      case "decrypt":
        guard let payload = call.arguments as? [String: Any],
              let ciphertext = payload["ciphertext"] as? FlutterStandardTypedData else {
          result(nativeFlutterError(.unknown, message: "Invalid decrypt request."))
          return
        }
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext.data)
        let plaintext = try AES.GCM.open(sealedBox, using: getOrCreateKey())
        result(FlutterStandardTypedData(bytes: plaintext))
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(nativeFlutterError(.unknown, message: error.localizedDescription))
    }
  }

  private func getOrCreateKey() throws -> SymmetricKey {
    if let data = readKeychainData() {
      return SymmetricKey(data: data)
    }

    let data = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    try writeKeychainData(data)
    return SymmetricKey(data: data)
  }

  private func readKeychainData() -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keyId,
      kSecReturnData as String: true
    ]

    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else {
      return nil
    }

    return item as? Data
  }

  private func writeKeychainData(_ data: Data) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keyId,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      kSecValueData as String: data
    ]

    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
  }
}
