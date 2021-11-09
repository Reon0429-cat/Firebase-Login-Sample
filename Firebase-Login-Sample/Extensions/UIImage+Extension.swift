//
//  UIImage+Extension.swift
//  Firebase-Login-Sample
//
//  Created by 大西玲音 on 2021/11/09.
//

import UIKit

enum SystemName: String {
    case eyedropper
    case eyeFill = "eye.fill"
    case eyeSlashFill = "eye.slash.fill"
    case envelope
    case lock
}

extension UIImage {
    
    func setColor(_ color: UIColor) -> UIImage {
        let image = self.withTintColor(color,
                                       renderingMode: .alwaysOriginal)
        return image
    }
    
}

extension UIImage {
    
    convenience init(systemName: SystemName) {
        self.init(systemName: systemName.rawValue)!
    }
    
}
