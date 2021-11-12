//
//  UserUseCase.swift
//  StudyRecordApp
//
//  Created by 大西玲音 on 2021/08/28.
//

import UIKit
import RxSwift
import RxRelay

final class UserUseCase {
    
    private var repository: UserRepositoryProtocol
    private let loginTrigger = PublishRelay<(String, String)>()
    private let loginSuccessfulRelay = PublishRelay<Void>()
    private let loginErrorRelay = PublishRelay<Error>()
    private let disposeBag = DisposeBag()
    
    init(repository: UserRepositoryProtocol) {
        self.repository = repository
        setupBindings()
    }
    
    var loginSuccessful: Observable<Void> {
        loginSuccessfulRelay.asObservable()
    }
    
    var loginError: Observable<Error> {
        loginErrorRelay.asObservable()
    }
    
    private func setupBindings() {
        loginTrigger
            .subscribe(onNext: { emailText, passwordText in
                self.repository.login(email: emailText, password: passwordText)
                    .subscribe(
                        onCompleted: {
                            self.loginSuccessfulRelay.accept(())
                        },
                        onError: { error in
                            self.loginErrorRelay.accept(error)
                        }
                    )
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
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
    
    func registerUser(email: String,
                      password: String,
                      completion: @escaping ResultHandler<User>) {
        repository.registerUser(email: email,
                                password: password,
                                completion: completion)
    }
    
    func createUser(userId: String,
                    email: String,
                    completion: @escaping ResultHandler<Any?>) {
        repository.createUser(userId: userId,
                              email: email,
                              completion: completion)
    }
    
    func login(email: String, password: String) {
        loginTrigger.accept((email, password))
    }
    
    func logout(completion: @escaping ResultHandler<Any?>) {
        repository.logout(completion: completion)
    }
    
    func sendPasswordResetMail(email: String,
                               completion: @escaping ResultHandler<Any?>) {
        repository.sendPasswordResetMail(email: email,
                                         completion: completion)
    }
    
    func signInAnonymously(completion: @escaping ResultHandler<Any?>) {
        repository.signInAnonymously(completion: completion)
    }
    
}
