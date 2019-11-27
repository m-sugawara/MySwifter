//
//  TWPLoginViewModel.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/21.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveSwift

class TWPLoginViewModel: NSObject {
    
    // MARK: - Deinit
    deinit {
        print("LoginViewModel deinit")
    }
    
    // MARK: - RACCommands
    var loginButtonAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> { _ in
            return TWPTwitterAPI.shared.tryToLogin()
        }
    }
}
