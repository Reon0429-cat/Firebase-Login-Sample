//
//  ResetingPasswordViewModel.swift
//  Firebase-Login-Sample
//
//  Created by 大西玲音 on 2021/11/17.
//

import Foundation
import RxSwift
import RxCocoa

final class ResetingPasswordViewModel {
    
    private let disposeBag = DisposeBag()
    private var isKeyboardHidden = true
    private let indicator = Indicator(kinds: PKHUDIndicator())
    private let eventRelay = PublishRelay<Event>()
    private let isEnabledSendButtonRelay = BehaviorRelay<Bool>(value: false)
    private let stackViewTopConstantRelay = PublishRelay<CGFloat>()
    
    enum Event {
        case dismiss
        case presentErrorAlert(title: String)
    }
    
    init(userUseCase: UserUseCase,
         sendButton: Signal<Void>,
         mailText: Driver<String>) {
        
        // Input
        sendButton.asObservable()
            .withLatestFrom(mailText.asObservable())
            .subscribe(onNext: { [weak self] mailText in
                guard let self = self else { return }
                self.indicator.show(.progress)
                userUseCase.sendPasswordResetMail(email: mailText)
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
                                self.eventRelay.accept(.presentErrorAlert(title: error.toAuthErrorMessage))
                            }
                        }
                    )
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
        
        mailText
            .drive(onNext: { [weak self] mailText in
                guard let self = self else { return }
                self.isEnabledSendButtonRelay.accept(!mailText.isEmpty)
            })
            .disposed(by: disposeBag)
        
    }
    
    // Input
    func willShowedKeyboard() {
        if isKeyboardHidden {
            stackViewTopConstantRelay.accept(-30)
        }
        isKeyboardHidden = false
    }
    
    func willHiddenKeyboard() {
        if !isKeyboardHidden {
            stackViewTopConstantRelay.accept(30)
        }
        isKeyboardHidden = true
    }
    
    // Output
    var event: Driver<Event> {
        eventRelay.asDriver(onErrorDriveWith: .empty())
    }
    
    var isEnabledSendButton: Driver<Bool> {
        isEnabledSendButtonRelay.asDriver()
    }
    
    var stackViewTopConstant: Driver<CGFloat> {
        stackViewTopConstantRelay.asDriver(onErrorDriveWith: .empty())
    }
    
}
