//
//  LoginViewModel.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/21.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import ReactiveSwift

enum LoginStatus {
    case ready
    case logined
    case failed(errorMessage: String)
}

protocol LoginViewModelProtocol {
    var statusSignal: Signal<LoginStatus, Never> { get }
    var loginAction: Action<Void, Void, Error> { get }
    func setTwitterAPI(_ twitterAPI: TwitterAPI)
}

class LoginViewModel: LoginViewModelProtocol {

    private var twitterAPI: TwitterAPI!

    private let (_statusSignal, statusObserver) = Signal<LoginStatus, Never>.pipe()
    var statusSignal: Signal<LoginStatus, Never> {
        return _statusSignal
    }

    // MARK: - Deinit

    deinit {
        print("LoginViewModel deinit")
    }

    func setTwitterAPI(_ twitterAPI: TwitterAPI) {
        self.twitterAPI = twitterAPI
    }

    // MARK: - Action

    var loginAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error>(execute: tryToLogin)
    }

    private var tryToLogin: () -> SignalProducer<Void, Error> {
        return {
            return SignalProducer { observer, _ in
                self.twitterAPI.tryToLogin().startWithResult { [weak self] result in
                    switch result {
                    case .success:
                        self?.statusObserver.send(value: .logined)

                    case .failure(let error):
                        self?.statusObserver.send(value: .failed(errorMessage: error.localizedDescription))
                    }
                    observer.sendCompleted()
                }
            }
        }
    }
}

#if DEBUG
class DummyLoginViewModel: LoginViewModelProtocol {
    func setTwitterAPI(_ twitterAPI: TwitterAPI) {}

    private let (_statusSignal, statusObserver) = Signal<LoginStatus, Never>.pipe()
    var statusSignal: Signal<LoginStatus, Never> {
        return _statusSignal
    }

    var loginAction: Action<Void, Void, Error> {
        return Action<Void, Void, Error> {
            return SignalProducer { observer, _ in
                self.statusObserver.send(value: .logined)
                observer.sendCompleted()
            }
        }
    }

}
#endif
