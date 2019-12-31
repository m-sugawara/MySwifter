//
//  TWPLoginViewModel.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/21.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import ReactiveSwift

class TWPLoginViewModel {

    enum LoginViewModelError: Error {
        case failedToLogin

        var message: String {
            switch self {
            case .failedToLogin:
                return "Failed to login"
            }
        }
    }

    private let (_loginSignal, loginObserver) = Signal<Bool, Never>.pipe()
    var loginSignal: Signal<Bool, Never> {
        return _loginSignal
    }

    // MARK: - Deinit

    deinit {
        print("LoginViewModel deinit")
    }

    // MARK: - Initializer

    init() {}

    // MARK: - Action

    var loginAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error>(execute: tryToLogin)
    }

    var tryToLogin: () -> SignalProducer<Void, Error> {
        return {
            return SignalProducer { observer, _ in
                TWPTwitterAPI.shared.tryToLogin().startWithResult { [weak self] result in
                    switch result {
                    case .success:
                        self?.loginObserver.send(value: true)

                    case .failure:
                        self?.loginObserver.send(value: false)
                    }
                    observer.sendCompleted()
                }
            }
        }
    }

}
