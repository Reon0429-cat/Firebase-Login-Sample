//
//  FirebaseUserDataStore.swift
//  StudyRecordApp
//
//  Created by 大西玲音 on 2021/08/29.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Firebase

typealias ResultHandler<T> = (Result<T, Error>) -> Void

final class FirebaseUserDataStore {
    
    var currentUser: FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    func registerUser(email: String,
                      password: String,
                      completion: @escaping ResultHandler<FirebaseAuth.User>) {
        Auth.auth().createUser(withEmail: email,
                               password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                completion(.success(user))
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
    
    func createUser(userId: String,
                    email: String,
                    completion: @escaping ResultHandler<Any?>) {
        let userRef = Firestore.firestore().collection("users")
        let data = [String: Any]()
        userRef.document(userId).setData(data) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(nil))
        }
    }
    
    func login(email: String,
               password: String,
               completion: @escaping ResultHandler<Any?>) {
        Auth.auth().signIn(withEmail: email,
                           password: password) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(nil))
        }
    }
    
    func logout(completion: @escaping ResultHandler<Any?>) {
        do {
            try Auth.auth().signOut()
            completion(.success(nil))
        } catch {
            completion(.failure(error))
        }
    }
    
    func sendPasswordResetMail(email: String,
                               completion: @escaping ResultHandler<Any?>) {
        Auth.auth().languageCode = "ja_JP"
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(nil))
        }
    }
    
    func signInAnonymously(completion: @escaping ResultHandler<Any?>) {
        Auth.auth().signInAnonymously { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(nil))
        }
    }
    
}

extension Error {
    
    var toAuthErrorMessage: String {
        if let errorCode = AuthErrorCode(rawValue: self._code) {
            switch errorCode {
                case .invalidEmail:
                    return "メールアドレスの形式に誤りが含まれます。"
                case .weakPassword:
                    return "パスワードは６文字以上で入力してください。"
                case .wrongPassword:
                    return "パスワードに誤りがあります。"
                case .userNotFound:
                    return "こちらのメールアドレスは登録されていません。"
                case .emailAlreadyInUse:
                    return "こちらのメールアドレスは既に登録されています。"
                case .adminRestrictedOperation:
                    return "匿名ログインに失敗しました。"
                default:
                    break
            }
        }
        return "不明なエラーが発生しました。"
    }
    
}

