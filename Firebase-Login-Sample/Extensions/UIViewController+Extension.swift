//
//  UIViewController+Extension.swift
//  Firebase-Login-Sample
//
//  Created by 大西玲音 on 2021/11/09.
//

import UIKit

extension UIViewController {
    
    func showErrorAlert(title: String,
                        message: String? = nil,
                        handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "閉じる", style: .default, handler: handler))
        present(alert, animated: true)
    }
    
}
