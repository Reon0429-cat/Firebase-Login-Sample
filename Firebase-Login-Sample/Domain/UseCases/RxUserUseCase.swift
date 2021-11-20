//
//  UserUseCase.swift
//  StudyRecordApp
//
//  Created by 大西玲音 on 2021/08/28.
//

import UIKit
import RxSwift
import RxRelay

final class RxUserUseCase {
    
    private var repository: UserRepositoryProtocol
    
    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }
    
    var isLoggedIn: Bool {
        repository.currentUser != nil
    }
    
    var isLoggedInAsAnonymously: Bool {
        if let user = repository.currentUser {
            return user.isAnonymous
        }
        return false
    }
    
    func registerUser(email: String, password: String) -> Single<User> {
        repository.registerUser(email: email, password: password)
    }
    
    func createUser(userId: String, email: String) -> Completable {
        repository.createUser(userId: userId, email: email)
    }
    
    func login(email: String, password: String) -> Completable {
        repository.login(email: email, password: password)
    }
    
    func logout(completion: @escaping ResultHandler<Any?>) {
        repository.logout(completion: completion)
    }
    
    func sendPasswordResetMail(email: String) -> Completable {
        repository.sendPasswordResetMail(email: email)
    }
    
    func signInAnonymously() -> Completable {
        repository.signInAnonymously()
    }
    
}
