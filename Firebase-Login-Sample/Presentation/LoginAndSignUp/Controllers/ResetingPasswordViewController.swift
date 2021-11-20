//
//  ResetingPasswordViewController.swift
//  StudyRecordApp
//
//  Created by 大西玲音 on 2021/08/29.
//

import UIKit
import RxSwift
import RxCocoa

final class ResetingPasswordViewController: UIViewController {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var mailAddressImage: UIImageView!
    @IBOutlet private weak var mailAddressLabel: UILabel!
    @IBOutlet private weak var mailAddressTextField: CustomTextField!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var stackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var sendButton: CustomButton!
    
    private lazy var viewModel = ResetingPasswordViewModel(
        userUseCase: RxUserUseCase(repository: RxUserRepository()),
        sendButton: sendButton.rx.tap.asSignal(),
        mailText: mailAddressTextField.rx.text.orEmpty.asDriver()
    )
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func setupBindings() {
        // Input
        if self.view.frame.height < 800 {
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.viewModel.willShowedKeyboard()
                })
                .disposed(by: disposeBag)
            
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.viewModel.willHiddenKeyboard()
                })
                .disposed(by: disposeBag)
        }
        
        // Output
        viewModel.event
            .drive(onNext: { [weak self] event in
                guard let self = self else { return }
                switch event {
                    case .dismiss:
                        self.dismiss(animated: true)
                    case .presentErrorAlert(let title):
                        self.showErrorAlert(title: title)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.isEnabledSendButton
            .drive(onNext: { [weak self] isEnabled in
                guard let self = self else { return }
                self.sendButton.changeState(isEnabled: isEnabled)
            })
            .disposed(by: disposeBag)
        
        viewModel.stackViewTopConstant
            .drive(onNext: { [weak self] constant in
                guard let self = self else { return }
                UIView.animate(deadlineFromNow: 0, duration: 0.5) {
                    self.stackViewTopConstraint.constant += constant
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }
    
}

// MARK: - UITextFieldDelegate
extension ResetingPasswordViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

// MARK: - setup
private extension ResetingPasswordViewController {
    
    func setupUI() {
        setupTitleLabel()
        setupMailAddressLabel()
        setupMailAddressImage()
        setupDetailLabel()
        setupMailAddressTextField()
        setupSendButton()
    }
    
    func setupSendButton() {
        sendButton.setTitle("送信", for: .normal)
    }
    
    func setupMailAddressTextField() {
        mailAddressTextField.delegate = self
        mailAddressTextField.keyboardType = .emailAddress
    }
    
    func setupTitleLabel() {
        titleLabel.text = "パスワードをお忘れの場合"
    }
    
    func setupMailAddressLabel() {
        mailAddressLabel.text = "メールアドレス"
    }
    
    func setupMailAddressImage() {
        let envelopImage = UIImage(systemName: .envelope)
        mailAddressImage.image = envelopImage.setColor(.dynamicColor(light: .black, dark: .white))
    }
    
    func setupDetailLabel() {
        detailLabel.text = "上記のメールアドレスにパスワード\n再設定用のURLを送信します。"
    }
    
}
