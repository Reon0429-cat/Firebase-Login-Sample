//
//  TopViewController.swift
//  Firebase-Login-Sample
//
//  Created by 大西玲音 on 2021/11/09.
//

import UIKit

final class TopViewController: UIViewController {
    
    private let userUseCase = UserUseCase(
        repository: UserRepository()
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction private func logoutButtonDidTapped(_ sender: Any) {
        userUseCase.logout { result in
            switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.showErrorAlert(title: error.toAuthErrorMessage)
                    }
                case .success:
                    DispatchQueue.main.async {
                        self.presentLoginAndSignUpVC()
                    }
            }
        }
    }
    
    private func presentLoginAndSignUpVC() {
        guard let loginAndSignUpVC = UIStoryboard(name: "LoginAndSignUp", bundle: nil)
                .instantiateInitialViewController() else { return }
        loginAndSignUpVC.modalPresentationStyle = .fullScreen
        present(loginAndSignUpVC, animated: true)
    }
    
}
