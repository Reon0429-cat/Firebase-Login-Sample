//
//  SignUpViewController.swift
//  StudyRecordApp
//
//  Created by 大西玲音 on 2021/08/26.
//

import UIKit

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
    private var isPasswordHidden = true
    private var isPasswordConfirmationHidden = true
    private var isKeyboardHidden = true
    private let userUseCase = UserUseCase(
        repository: UserRepository()
    )
    private let indicator = Indicator(kinds: PKHUDIndicator())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        setupKeyboardObserver()
        self.view.backgroundColor = .dynamicColor(light: .white,
                                                  dark: .secondarySystemBackground)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

// MARK: - IBAction func
private extension SignUpViewController {
    
    @IBAction func passwordSecureButtonDidTapped(_ sender: Any) {
        changePasswordSecureButtonImage(isSlash: isPasswordHidden)
        passwordTextField.isSecureTextEntry.toggle()
        isPasswordHidden.toggle()
    }
    
    @IBAction func passwordConfirmationSecureButtonDidTapped(_ sender: Any) {
        changePasswordConfirmationSecureButtonImage(isSlash: isPasswordConfirmationHidden)
        passwordConfirmationTextField.isSecureTextEntry.toggle()
        isPasswordConfirmationHidden.toggle()
    }
    
    @IBAction func signUpButtonDidTapped(_ sender: Any) {
        guard let email = mailAddressTextField.text,
              let password = passwordTextField.text,
              let passwordConfirmation = passwordConfirmationTextField.text else { return }
        if CommunicationStatus().unstable() {
            showErrorAlert(title: "通信環境が良くありません")
            return
        }
        if password != passwordConfirmation {
            showErrorAlert(title: "パスワードが一致しません")
            return
        }
        indicator.show(.progress)
        registerUser(email: email, password: password)
    }
    
    @IBAction func guestUserButtonDidTapped(_ sender: Any) {
        if CommunicationStatus().unstable() {
            showErrorAlert(title: "通信環境が良くありません")
            return
        }
        indicator.show(.progress)
        userUseCase.signInAnonymously { [weak self] result in
            guard let self = self else { return }
            switch result {
                case .failure(let error):
                    self.indicator.flash(.error) {
                        self.showErrorAlert(title: error.toAuthErrorMessage)
                    }
                case .success:
                    self.indicator.flash(.success) {
                        self.dismiss(animated: true)
                    }
            }
        }
    }
    
}

// MARK: - func
private extension SignUpViewController {
    
    func registerUser(email: String, password: String) {
        userUseCase.registerUser(email: email,
                                 password: password) { [weak self] result in
            guard let self = self else { return }
            switch result {
                case .failure(let error):
                    self.indicator.flash(.error) {
                        self.showErrorAlert(title: error.toAuthErrorMessage)
                    }
                case .success(let user):
                    self.createUser(userId: user.id, mailAddressText: email)
            }
        }
    }
    
    func createUser(userId: String, mailAddressText: String) {
        userUseCase.createUser(userId: userId,
                               email: mailAddressText) { [weak self] result in
            guard let self = self else { return }
            switch result {
                case .failure(let error):
                    self.indicator.flash(.error) {
                        self.showErrorAlert(title: error.toAuthErrorMessage)
                    }
                case .success:
                    self.indicator.flash(.success) {
                        self.dismiss(animated: true)
                    }
            }
        }
    }
    
    func changePasswordSecureButtonImage(isSlash: Bool) {
        let eyeFillImage = UIImage(systemName: .eyeFill)
        let eyeSlashFillImage = UIImage(systemName: .eyeSlashFill)
        let image = isSlash ? eyeSlashFillImage : eyeFillImage
        passwordSecureButton.setImage(image, for: .normal)
    }
    
    func changePasswordConfirmationSecureButtonImage(isSlash: Bool) {
        let eyeFillImage = UIImage(systemName: .eyeFill)
        let eyeSlashFillImage = UIImage(systemName: .eyeSlashFill)
        let image = isSlash ? eyeSlashFillImage : eyeFillImage
        passwordConfirmationSecureButton.setImage(image, for: .normal)
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
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .newPassword
    }
    
    func setupPasswordConfirmationTextField() {
        passwordConfirmationTextField.delegate = self
        passwordConfirmationTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .newPassword
    }
    
    func setupPasswordSecureButton() {
        changePasswordSecureButtonImage(isSlash: false)
        passwordSecureButton.tintColor = .dynamicColor(light: .black, dark: .white)
    }
    
    func setupPasswordConfirmationSecureButton() {
        changePasswordConfirmationSecureButtonImage(isSlash: false)
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
        if isKeyboardHidden {
            UIView.animate(deadlineFromNow: 0, duration: 0.5) {
                if self.view.frame.height < 600 {
                    self.stackView.spacing -= 25
                    self.signUpButtonTopConstraint.constant -= 40
                } else {
                    self.stackView.spacing -= 15
                    self.signUpButtonTopConstraint.constant -= 20
                }
                self.view.layoutIfNeeded()
            }
        }
        isKeyboardHidden = false
    }
    
    @objc
    func keyboardWillHide() {
        if !isKeyboardHidden {
            UIView.animate(deadlineFromNow: 0, duration: 0.5) {
                if self.view.frame.height < 600 {
                    self.stackView.spacing += 25
                    self.signUpButtonTopConstraint.constant += 40
                } else {
                    self.stackView.spacing += 15
                    self.signUpButtonTopConstraint.constant += 20
                }
                self.view.layoutIfNeeded()
            }
        }
        isKeyboardHidden = true
    }
    
}
