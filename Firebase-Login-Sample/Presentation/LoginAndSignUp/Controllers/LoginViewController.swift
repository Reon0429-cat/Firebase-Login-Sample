//
//  LoginViewController.swift
//  StudyRecordApp
//
//  Created by 大西玲音 on 2021/08/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol LoginVCDelegate: AnyObject {
    func leftSwipeDid()
}

final class LoginViewController: UIViewController {
    
    @IBOutlet private weak var stackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mailAddressImage: UIImageView!
    @IBOutlet private weak var mailAddressLabel: UILabel!
    @IBOutlet private weak var mailAddressTextField: CustomTextField!
    @IBOutlet private weak var passwordImage: UIImageView!
    @IBOutlet private weak var passwordLabel: UILabel!
    @IBOutlet private weak var passwordTextField: CustomTextField!
    @IBOutlet private weak var passwordSecureButton: UIButton!
    @IBOutlet private weak var loginButton: CustomButton!
    @IBOutlet private weak var passwordForgotButton: CustomButton!
    @IBOutlet private weak var passwordForgotLabel: UILabel!
    
    weak var delegate: LoginVCDelegate?
    private let viewModel: LoginViewModelType = LoginViewModel()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGR()
        setupMailAddressTextField()
        setupPasswordTextField()
        setupLoginButton()
        setupPasswordSecureButton()
        setupMailAddressImage()
        setupPasswordImage()
        setupPasswordLabel()
        setupMailAddressLabel()
        setupPasswordForgotLabel()
        setupPasswordForgotButton()
        setupKeyboardObserver()
        self.view.backgroundColor = .dynamicColor(light: .white,
                                                  dark: .secondarySystemBackground)
        setupBindings()
        viewModel.inputs.viewDidLoad()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func setupBindings() {
        // MARK: - Input
        passwordSecureButton.rx.tap
            .subscribe(onNext: {
                self.viewModel.inputs.passwordSecureButtonDidTapped(
                    shouldPasswordTextFieldSecure: self.passwordTextField.isSecureTextEntry
                )
            })
            .disposed(by: disposeBag)
        
        loginButton.rx.tap
            .subscribe(onNext: {
                self.viewModel.inputs.loginButtonDidTapped(
                    email: self.mailAddressTextField.text,
                    password: self.passwordTextField.text
                )
            })
            .disposed(by: disposeBag)
        
        passwordForgotButton.rx.tap
            .subscribe(onNext: viewModel.inputs.passwordForgotButtonDidTapped)
            .disposed(by: disposeBag)
        
        // MARK: - Output
        viewModel.outputs.passwordSecureButtonImage
            .drive(onNext: { self.passwordSecureButton.setImage($0, for: .normal) })
            .disposed(by: disposeBag)
        
        viewModel.outputs.event
            .drive(onNext: { event in
                switch event {
                    case .dismiss:
                        self.dismiss(animated: true)
                    case .showErrorAlert(let title):
                        self.showErrorAlert(title: title)
                    case .presentResetingPassword:
                        guard let resetingPasswordVC = UIStoryboard(name: "ResetingPassword", bundle: nil)
                                .instantiateInitialViewController() else { return }
                        self.present(resetingPasswordVC, animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.shouldPasswordTextFieldSecure
            .drive(passwordTextField.rx.isSecureTextEntry)
            .disposed(by: disposeBag)
        
        viewModel.outputs.stackViewTopConstant
            .drive(onNext: { constant in
                UIView.animate(deadlineFromNow: 0, duration: 0.5) {
                    self.stackViewTopConstraint.constant += constant
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }
    
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let mailAddressText = mailAddressTextField.text,
              let passwordText = passwordTextField.text else { return }
        let isEnabled = !mailAddressText.isEmpty && !passwordText.isEmpty
        loginButton.changeState(isEnabled: isEnabled)
    }
    
}

// MARK: - setup
private extension LoginViewController {
    
    func setupGR() {
        let leftSwipeGR = UISwipeGestureRecognizer(target: self,
                                                   action: #selector(leftSwipeDid))
        leftSwipeGR.direction = .left
        self.view.addGestureRecognizer(leftSwipeGR)
    }
    
    @objc
    func leftSwipeDid() {
        delegate?.leftSwipeDid()
    }
    
    func setupMailAddressLabel() {
        mailAddressLabel.text = "メールアドレス"
        mailAddressLabel.textColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupMailAddressTextField() {
        mailAddressTextField.delegate = self
        mailAddressTextField.keyboardType = .URL
    }
    
    func setupPasswordLabel() {
        passwordLabel.text = "パスワード"
        passwordLabel.textColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupPasswordTextField() {
        passwordTextField.delegate = self
        passwordTextField.textContentType = .newPassword
    }
    
    func setupMailAddressImage() {
        let envelopImage = UIImage(systemName: .envelope)
        mailAddressImage.image = envelopImage.setColor(.dynamicColor(light: .black, dark: .white))
    }
    
    func setupLoginButton() {
        loginButton.setTitle("ログイン", for: .normal)
        loginButton.changeState(isEnabled: false)
    }
    
    func setupPasswordSecureButton() {
        passwordSecureButton.tintColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupPasswordForgotLabel() {
        passwordForgotLabel.text = "パスワードをお忘れの方は"
        passwordForgotLabel.textColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupPasswordForgotButton() {
        passwordForgotButton.setTitle("こちら", for: .normal)
    }
    
    func setupPasswordImage() {
        let lockImage = UIImage(systemName: .lock)
        passwordImage.image = lockImage.setColor(.dynamicColor(light: .black, dark: .white))
    }
    
    func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc
    func keyboardWillShow() {
        viewModel.inputs.keyboardWillShow()
    }
    
    @objc
    func keyboardWillHide() {
        viewModel.inputs.keyboardWillHide()
    }
    
}
