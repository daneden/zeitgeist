//
//  Session.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation
import SwiftUI
import Combine

enum SessionError: Error {
  case notAuthenticated
}

typealias AccountIDs = [VercelAccount.ID]

extension AccountIDs: RawRepresentable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(AccountIDs.self, from: data)
    else {
      return nil
    }
    self = result
  }

  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

extension SessionError: CustomStringConvertible {
  var description: String {
    switch self {
    case .notAuthenticated:
      return "The chosen account has not been authenticated on this device"
    }
  }
}

class VercelSession: ObservableObject {
  @Published var accountId: VercelAccount.ID = .NullValue {
    didSet { Task { account = await loadAccount() } }
  }
  
  @Published var account: VercelAccount?
  
  var authenticationToken: String? {
    guard accountId != .NullValue else {
      return nil
    }

    return KeychainItem(account: accountId).wrappedValue
  }
  
  var isAuthenticated: Bool {
    accountId != .NullValue && authenticationToken != nil
  }
  
  @MainActor
  func loadAccount() async -> VercelAccount? {
    do {
      guard accountId != .NullValue, authenticationToken != nil else {
        return nil
      }

      var request = try VercelAPI.request(for: .account(id: accountId), with: accountId)
      try! signRequest(&request)
      
      let (data, _) = try await URLSession.shared.data(for: request)

      return try JSONDecoder().decode(VercelAccount.self, from: data)
    } catch {
      print(error)
      return nil
    }
  }
  
  static func addAccount(id: String, token: String) {
    KeychainItem(account: id).wrappedValue = token
    
    DispatchQueue.main.async {
      Preferences.authenticatedAccountIds.append(id)
      Preferences.authenticatedAccountIds = Preferences.authenticatedAccountIds.removingDuplicates()
    }
  }
  
  static func deleteAccount(id: String) {
    let keychain = KeychainItem(account: id)
    keychain.wrappedValue = nil
    
    Preferences.authenticatedAccountIds.removeAll { id == $0 }
  }
  
  func signRequest(_ request: inout URLRequest) throws {
    guard let authenticationToken = authenticationToken else {
      throw SessionError.notAuthenticated
    }

    request.addValue("Bearer \(authenticationToken)", forHTTPHeaderField: "Authorization")
  }
}
