//
//  UserRepository.swift
//  StudyRecordApp
//
//  Created by 大西玲音 on 2021/08/29.
//

import Foundation
import RxSwift
import FirebaseAuth

final class UserRepository: UserRepositoryProtocol {
    
    private var dataStore = FirebaseUserDataStore()
    
    var currentUser: User? {
        if let user = dataStore.currentUser {
            return User(user: user)
        }
        return nil
    }
    
    func registerUser(email: String, password: String) -> Single<User> {
        Single<User>.create { observer in
            self.dataStore.registerUser(email: email, password: password) { result in
                switch result {
                    case .failure(let error):
                        observer(.failure(error))
                    case .success(let user):
                        observer(.success(User(user: user)))
                }
            }
            return Disposables.create()
        }
    }
    
    func createUser(userId: String, email: String) -> Completable {
        Completable.create { observer in
            self.dataStore.createUser(userId: userId, email: email) { result in
                switch result {
                    case .failure(let error):
                        observer(.error(error))
                    case .success:
                        observer(.completed)
                }
            }
            return Disposables.create()
        }
    }
    
    func signInAnonymously() -> Completable {
        Completable.create { observer in
            self.dataStore.signInAnonymously { result in
                switch result {
                    case .failure(let error):
                        observer(.error(error))
                    case .success:
                        observer(.completed)
                }
            }
            return Disposables.create()
        }
    }
    
    func login(email: String, password: String) -> Completable {
        Completable.create { observer in
            self.dataStore.login(email: email,
                                 password: password) { result in
                switch result {
                    case .failure(let error):
                        observer(.error(error))
                    case .success:
                        observer(.completed)
                }
            }
            return Disposables.create()
        }
    }
    
    func logout(completion: @escaping ResultHandler<Any?>) {
        dataStore.logout(completion: completion)
    }
    
    func sendPasswordResetMail(email: String) -> Completable {
        Completable.create { observer in
            self.dataStore.sendPasswordResetMail(email: email) { result in
                switch result {
                    case .failure(let error):
                        observer(.error(error))
                    case .success:
                        observer(.completed)
                }
            }
            return Disposables.create()
        }
    }
    
}

private extension User {
    
    init(user: FirebaseAuth.User) {
        self.id = user.uid
        self.isAnonymous = user.isAnonymous
    }
    
}
