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

    struct LoginError: Error {
        var message: String {
            return "Failed to login"
        }
    }

    enum LoginStatus {
        case ready
        case logined
        case failed(error: LoginError)
    }

    private let (_statusSignal, statusObserver) = Signal<LoginStatus, Never>.pipe()
    var statusSignal: Signal<LoginStatus, Never> {
        return _statusSignal
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

    private var tryToLogin: () -> SignalProducer<Void, Error> {
        return {
            return SignalProducer { observer, _ in
                TWPTwitterAPI.shared.tryToLogin().startWithResult { [weak self] result in
                    switch result {
                    case .success:
                        self?.statusObserver.send(value: .logined)

                    case .failure:
                        let error = LoginError()
                        self?.statusObserver.send(value: .failed(error: error))
                    }
                    observer.sendCompleted()
                }
            }
        }
    }

}
