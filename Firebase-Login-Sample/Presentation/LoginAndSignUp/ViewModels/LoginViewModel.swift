//
//  LoginViewModel.swift
//  Firebase-Login-Sample
//
//  Created by 大西玲音 on 2021/11/12.
//

import Foundation
import RxSwift
import RxCocoa

protocol LoginViewModelInput {
    func viewDidLoad()
    func passwordSecureButtonDidTapped(shouldPasswordTextFieldSecure: Bool)
    func loginButtonDidTapped(email: String?, password: String?)
    func passwordForgotButtonDidTapped()
    func keyboardWillShow()
    func keyboardWillHide()
}

protocol LoginViewModelOutput: AnyObject {
    var passwordSecureButtonImage: Driver<UIImage> { get }
    var shouldPasswordTextFieldSecure: Driver<Bool> { get }
    var stackViewTopConstant: Driver<CGFloat> { get }
    var event: Driver<LoginViewModel.Event> { get }
}

protocol LoginViewModelType {
    var inputs: LoginViewModelInput { get }
    var outputs: LoginViewModelOutput { get }
}

final class LoginViewModel {
    
    private var isPasswordHidden = true
    private var isKeyboardHidden = true
    private let indicator = Indicator(kinds: PKHUDIndicator())
    private let userUseCase = UserUseCase(
        repository: UserRepository(
            dataStore: FirebaseUserDataStore()
        )
    )
    private let passwordSecureButtonImageNameRelay = PublishRelay<UIImage>()
    private let passwordForgotButtonRelay = PublishRelay<Void>()
    private let shouldPasswordTextFieldSecureRelay = BehaviorRelay<Bool>(value: true)
    private let stackViewTopConstantRelay = PublishRelay<CGFloat>()
    private let eventRelay = PublishRelay<Event>()
    
    enum Event {
        case dismiss
        case presentResetingPassword
        case showErrorAlert(title: String)
    }
    
    private func changePasswordSecureButtonImage(isSlash: Bool) {
        let eyeFillImage = UIImage(systemName: .eyeFill)
        let eyeSlashFillImage = UIImage(systemName: .eyeSlashFill)
        let image = isSlash ? eyeSlashFillImage : eyeFillImage
        passwordSecureButtonImageNameRelay.accept(image)
    }
    
}

// MARK: - Input
extension LoginViewModel: LoginViewModelInput {
    
    func viewDidLoad() {
        changePasswordSecureButtonImage(isSlash: false)
        shouldPasswordTextFieldSecureRelay.accept(true)
    }
    
    func passwordSecureButtonDidTapped(shouldPasswordTextFieldSecure: Bool) {
        changePasswordSecureButtonImage(isSlash: isPasswordHidden)
        shouldPasswordTextFieldSecureRelay.accept(!shouldPasswordTextFieldSecure)
        isPasswordHidden.toggle()
    }
    
    func loginButtonDidTapped(email: String?, password: String?) {
        guard let email = email,
              let password = password else { return }
        if CommunicationStatus().unstable() {
            eventRelay.accept(.showErrorAlert(title: "通信環境が良くありません"))
            return
        }
        indicator.show(.progress)
        userUseCase.login(email: email,
                          password: password) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
                case .failure(let title):
                    strongSelf.indicator.flash(.error) {
                        strongSelf.eventRelay.accept(.showErrorAlert(title: title))
                    }
                case .success:
                    strongSelf.indicator.flash(.success) {
                        strongSelf.eventRelay.accept(.dismiss)
                    }
            }
        }
    }
    
    func passwordForgotButtonDidTapped() {
        eventRelay.accept(.presentResetingPassword)
    }
    
    func keyboardWillShow() {
        if isKeyboardHidden {
            stackViewTopConstantRelay.accept(-100)
        }
        isKeyboardHidden = false
    }
    
    func keyboardWillHide() {
        if !isKeyboardHidden {
            stackViewTopConstantRelay.accept(100)
        }
        isKeyboardHidden = true
    }
    
}

// MARK: - Output
extension LoginViewModel: LoginViewModelOutput {
    
    var passwordSecureButtonImage: Driver<UIImage> {
        passwordSecureButtonImageNameRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var shouldPasswordTextFieldSecure: Driver<Bool> {
        shouldPasswordTextFieldSecureRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var stackViewTopConstant: Driver<CGFloat> {
        stackViewTopConstantRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var event: Driver<Event> {
        eventRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}

extension LoginViewModel: LoginViewModelType {
    
    var inputs: LoginViewModelInput {
        return self
    }
    
    var outputs: LoginViewModelOutput {
        return self
    }
    
}
