//
//  SignUpViewController.swift
//  StudyRecordApp
//
//  Created by 大西玲音 on 2021/08/26.
//

import UIKit
import RxSwift
import RxCocoa

protocol SignUpVCDelegate: AnyObject {
    func rightSwipeDid()
}

final class SignUpViewController: UIViewController {
    
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var mailAddressImage: UIImageView!
    @IBOutlet private weak var mailAddressLabel: UILabel!
    @IBOutlet private weak var mailAddressTextField: CustomTextField!
    @IBOutlet private weak var passwordTextField: CustomTextField!
    @IBOutlet private weak var passwordImage: UIImageView!
    @IBOutlet private weak var passwordLabel: UILabel!
    @IBOutlet private weak var passwordSecureButton: UIButton!
    @IBOutlet private weak var passwordConfirmationImage: UIImageView!
    @IBOutlet private weak var passwordConfirmationLabel: UILabel!
    @IBOutlet private weak var passwordConfirmationTextField: CustomTextField!
    @IBOutlet private weak var passwordConfirmationSecureButton: UIButton!
    @IBOutlet private weak var signUpButton: CustomButton!
    @IBOutlet private weak var signUpButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var guestUserButton: CustomButton!
    
    weak var delegate: SignUpVCDelegate?
    private lazy var viewModel: SignUpViewModelType = SignUpViewModel(
        userUseCase: RxUserUseCase(repository: UserRepository()),
        signUpButton: signUpButton.rx.tap.asSignal(),
        guestUserButton: guestUserButton.rx.tap.asSignal(),
        passwordSecureButton: passwordSecureButton.rx.tap.asSignal(),
        passwordConfirmationSecureButton: passwordConfirmationSecureButton.rx.tap.asSignal(),
        mailAddressText: mailAddressTextField.rx.text.orEmpty.asDriver(),
        passwordText: passwordTextField.rx.text.orEmpty.asDriver(),
        passwordConfirmation: passwordConfirmationTextField.rx.text.orEmpty.asDriver()
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
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.inputs.keyboardWillShow(viewHeight: self.view.frame.height)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.inputs.keyboardWillHide(viewHeight: self.view.frame.height)
            })
            .disposed(by: disposeBag)
        
        // Output
        viewModel.outputs.event
            .drive(onNext: { [weak self] event in
                guard let self = self else { return }
                switch event {
                    case .showErrorAlert(let title):
                        self.showErrorAlert(title: title)
                    case .dismiss:
                        self.dismiss(animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.shouldPasswordTextSecured
            .drive(onNext: { [weak self] element in
                guard let self = self else { return }
                self.passwordTextField.isSecureTextEntry = element.isSecured
                self.passwordSecureButton.setImage(element.image, for: .normal)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.shouldPasswordConfirmationTextSecured
            .drive(onNext: { [weak self] element in
                guard let self = self else { return }
                self.passwordConfirmationTextField.isSecureTextEntry = element.isSecured
                self.passwordConfirmationSecureButton.setImage(element.image, for: .normal)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.animateOfStackView
            .drive(onNext: { [weak self] (spacing, constant) in
                guard let self = self else { return }
                UIView.animate(deadlineFromNow: 0, duration: 0.5) {
                    self.stackView.spacing += spacing
                    self.signUpButtonTopConstraint.constant += constant
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
    }
    
}

// MARK: - UITextFieldDelegate
extension SignUpViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let mailAddressText = mailAddressTextField.text,
              let passwordText = passwordTextField.text,
              let passwordConfirmationText = passwordConfirmationTextField.text else { return }
        let isEnabled = !mailAddressText.isEmpty && !passwordText.isEmpty && !passwordConfirmationText.isEmpty
        signUpButton.changeState(isEnabled: isEnabled)
    }
    
}

// MARK: - setup
private extension SignUpViewController {
    
    func setupUI() {
        setupGR()
        setupMailAddressTextField()
        setupPasswordTextField()
        setupPasswordConfirmationTextField()
        setupPasswordSecureButton()
        setupPasswordConfirmationSecureButton()
        setupSignUpButton()
        setupMailAddressLabel()
        setupMailAddressImage()
        setupPasswordLabel()
        setupPasswordImage()
        setupPasswordConfirmationLabel()
        setupPasswordConfirmationImage()
        setupGuestUserButton()
        self.view.backgroundColor = .dynamicColor(light: .white,
                                                  dark: .secondarySystemBackground)
    }
    
    func setupGR() {
        let rightSwipeGR = UISwipeGestureRecognizer(target: self,
                                                    action: #selector(rightSwipeDid))
        rightSwipeGR.direction = .right
        self.view.addGestureRecognizer(rightSwipeGR)
    }
    
    @objc
    func rightSwipeDid() {
        delegate?.rightSwipeDid()
    }
    
    func setupMailAddressTextField() {
        mailAddressTextField.delegate = self
        mailAddressTextField.keyboardType = .emailAddress
    }
    
    func setupPasswordTextField() {
        passwordTextField.delegate = self
        passwordTextField.textContentType = .newPassword
    }
    
    func setupPasswordConfirmationTextField() {
        passwordConfirmationTextField.delegate = self
        passwordTextField.textContentType = .newPassword
    }
    
    func setupPasswordSecureButton() {
        passwordSecureButton.tintColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupPasswordConfirmationSecureButton() {
        passwordConfirmationSecureButton.tintColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupSignUpButton() {
        signUpButton.layer.cornerRadius = 10
        signUpButton.setTitle("サインアップ", for: .normal)
        signUpButton.changeState(isEnabled: false)
    }
    
    func setupMailAddressLabel() {
        mailAddressLabel.text = "メールアドレス"
        mailAddressLabel.textColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupMailAddressImage() {
        let envelopImage = UIImage(systemName: .envelope)
        mailAddressImage.image = envelopImage.setColor(.dynamicColor(light: .black, dark: .white))
    }
    
    func setupPasswordLabel() {
        passwordLabel.text = "パスワード"
        passwordLabel.textColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupPasswordImage() {
        let lockImage = UIImage(systemName: .lock)
        passwordImage.image = lockImage.setColor(.dynamicColor(light: .black, dark: .white))
    }
    
    func setupPasswordConfirmationLabel() {
        passwordConfirmationLabel.text = "パスワード(確認用)"
        passwordConfirmationLabel.textColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupPasswordConfirmationImage() {
        let lockImage = UIImage(systemName: .lock)
        passwordConfirmationImage.image = lockImage.setColor(.dynamicColor(light: .black, dark: .white))
    }
    
    func setupGuestUserButton() {
        guestUserButton.setTitle("ゲストユーザーとして利用する", for: .normal)
        guestUserButton.titleLabel?.adjustsFontSizeToFitWidth = true
        guestUserButton.titleLabel?.minimumScaleFactor = 0.8
        guestUserButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    }
    
}
