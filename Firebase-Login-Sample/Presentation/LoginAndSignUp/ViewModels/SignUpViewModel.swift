//
//  SignUpViewModel.swift
//  Firebase-Login-Sample
//
//  Created by 大西玲音 on 2021/11/16.
//

import Foundation
import RxSwift
import RxCocoa

protocol SignUpViewModelInput {
    func keyboardWillShow(viewHeight: CGFloat)
    func keyboardWillHide(viewHeight: CGFloat)
}

protocol SignUpViewModelOutput: AnyObject {
    var event: Driver<SignUpViewModel.Event> { get }
    var shouldPasswordTextSecured: Driver<SignUpViewModel.PasswordElement> { get }
    var shouldPasswordConfirmationTextSecured: Driver<SignUpViewModel.PasswordElement> { get }
    var animateOfStackView: Driver<(spacing: CGFloat, constant: CGFloat)> { get }
}

protocol SignUpViewModelType {
    var inputs: SignUpViewModelInput { get }
    var outputs: SignUpViewModelOutput { get }
}

final class SignUpViewModel {
    
    private var isPasswordHidden = true
    private var isPasswordConfirmationHidden = true
    private var isKeyboardHidden = true
    private let disposeBag = DisposeBag()
    private let indicator = Indicator(kinds: PKHUDIndicator())
    private let eventRelay = PublishRelay<Event>()
    private lazy var shouldPasswordTextSecuredRelay = BehaviorRelay<PasswordElement>(
        value: PasswordElement(
            isSecured: true,
            image: getPasswordSecureButtonImage(isSlash: false)
        )
    )
    private lazy var shouldPasswordConfirmationTextSecuredRelay = BehaviorRelay<PasswordElement>(
        value: PasswordElement(
            isSecured: true,
            image: getPasswordSecureButtonImage(isSlash: false)
        )
    )
    private let animateOfStackViewRelay = PublishRelay<(spacing: CGFloat, constant: CGFloat)>()
    
    enum Event {
        case showErrorAlert(title: String)
        case dismiss
    }
    
    struct PasswordElement {
        let isSecured: Bool
        let image: UIImage
    }
    
    init(userUseCase: UserUseCase,
         signUpButton: Signal<Void>,
         guestUserButton: Signal<Void>,
         passwordSecureButton: Signal<Void>,
         passwordConfirmationSecureButton: Signal<Void>,
         mailAddressText: Driver<String>,
         passwordText: Driver<String>,
         passwordConfirmation: Driver<String>) {
        
        signUpButton.asObservable()
            .withLatestFrom(
                Observable.combineLatest(
                    mailAddressText.asObservable(),
                    passwordText.asObservable(),
                    passwordConfirmation.asObservable()
                )
            )
            .subscribe(onNext: { [weak self] mailAddressText, passwordText, passwordConfirmationText in
                guard let self = self else { return }
                if CommunicationStatus().unstable() {
                    self.eventRelay.accept(.showErrorAlert(title: "通信環境が良くありません"))
                    return
                }
                if passwordText != passwordConfirmationText {
                    self.eventRelay.accept(.showErrorAlert(title: "パスワードが一致しません"))
                    return
                }
                self.indicator.show(.progress)
                self.registerUser(userUseCase: userUseCase,
                                  mailAddressText: mailAddressText,
                                  passwordText: passwordText)
            })
            .disposed(by: disposeBag)
        
        guestUserButton.asObservable()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                if CommunicationStatus().unstable() {
                    self.eventRelay.accept(.showErrorAlert(title: "通信環境が良くありません"))
                    return
                }
                self.indicator.show(.progress)
                self.signInAnonymously(userUseCase: userUseCase)
            })
            .disposed(by: disposeBag)
        
        passwordSecureButton.asObservable()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let image = self.getPasswordSecureButtonImage(isSlash: self.isPasswordHidden)
                self.shouldPasswordTextSecuredRelay.accept(
                    PasswordElement(
                        isSecured: !self.isPasswordHidden,
                        image: image
                    )
                )
                self.isPasswordHidden.toggle()
            })
            .disposed(by: disposeBag)
        
        passwordConfirmationSecureButton.asObservable()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let image = self.getPasswordSecureButtonImage(isSlash: self.isPasswordConfirmationHidden)
                self.shouldPasswordConfirmationTextSecuredRelay.accept(
                    PasswordElement(
                        isSecured: !self.isPasswordConfirmationHidden,
                        image: image
                    )
                )
                self.isPasswordConfirmationHidden.toggle()
            })
            .disposed(by: disposeBag)
        
    }
    
    private func registerUser(userUseCase: UserUseCase,
                              mailAddressText: String,
                              passwordText: String) {
        userUseCase.registerUser(email: mailAddressText, password: passwordText)
            .subscribe(
                onSuccess: { [weak self] user in
                    guard let self = self else { return }
                    self.createUser(userUseCase: userUseCase,
                                    user: user,
                                    mailAddressText: mailAddressText)
                },
                onFailure: { [weak self] error in
                    guard let self = self else { return }
                    self.indicator.flash(.error) {
                        self.eventRelay.accept(.showErrorAlert(title: error.toAuthErrorMessage))
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func createUser(userUseCase: UserUseCase,
                            user: User,
                            mailAddressText: String) {
        userUseCase.createUser(userId: user.id, email: mailAddressText)
            .subscribe(
                onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.indicator.flash(.success) {
                        self.eventRelay.accept(.dismiss)
                    }
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    self.indicator.flash(.error) {
                        self.eventRelay.accept(.showErrorAlert(title: error.toAuthErrorMessage))
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func signInAnonymously(userUseCase: UserUseCase) {
        userUseCase.signInAnonymously()
            .subscribe(
                onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.indicator.flash(.success) {
                        self.eventRelay.accept(.dismiss)
                    }
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    self.indicator.flash(.error) {
                        self.eventRelay.accept(.showErrorAlert(title: error.toAuthErrorMessage))
                    }
                })
            .disposed(by: disposeBag)
    }
    
    private func getPasswordSecureButtonImage(isSlash: Bool) -> UIImage {
        let eyeFillImage = UIImage(systemName: .eyeFill)
        let eyeSlashFillImage = UIImage(systemName: .eyeSlashFill)
        let image = isSlash ? eyeSlashFillImage : eyeFillImage
        return image
    }
    
}

// MARK: - Input
extension SignUpViewModel: SignUpViewModelInput {
    
    func keyboardWillShow(viewHeight: CGFloat) {
        if isKeyboardHidden {
            if viewHeight < 600 {
                self.animateOfStackViewRelay.accept((spacing: -25, constant: -40))
            } else {
                self.animateOfStackViewRelay.accept((spacing: -15, constant: -20))
            }
        }
        isKeyboardHidden = false
    }
    
    func keyboardWillHide(viewHeight: CGFloat) {
        if !isKeyboardHidden {
            if viewHeight < 600 {
                self.animateOfStackViewRelay.accept((spacing: 25, constant: 40))
            } else {
                self.animateOfStackViewRelay.accept((spacing: 15, constant: 20))
            }
        }
        isKeyboardHidden = true
    }
    
}

// MARK: - Output
extension SignUpViewModel: SignUpViewModelOutput {
    
    var event: Driver<Event> {
        eventRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var shouldPasswordTextSecured: Driver<PasswordElement> {
        shouldPasswordTextSecuredRelay.asDriver()
    }
    
    var shouldPasswordConfirmationTextSecured: Driver<PasswordElement> {
        shouldPasswordConfirmationTextSecuredRelay.asDriver()
    }
    
    var animateOfStackView: Driver<(spacing: CGFloat, constant: CGFloat)> {
        animateOfStackViewRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}

extension SignUpViewModel: SignUpViewModelType {
    
    var inputs: SignUpViewModelInput {
        return self
    }
    
    var outputs: SignUpViewModelOutput {
        return self
    }
    
}
