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

    private weak var viewController: TWPLoginViewController!

    // MARK: - Deinit

    deinit {
        print("LoginViewModel deinit")
    }

    // MARK: - Initializer

    init(viewController: TWPLoginViewController) {
        self.viewController = viewController
    }

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
                        DispatchQueue.main.async {
                            self?.viewController.showAlert()
                        }

                    case .failure(let error):
                        DispatchQueue.main.async {
                            self?.viewController.showAlert(withError: error as NSError)
                        }
                    }
                    observer.sendCompleted()
                }
            }
        }
    }

}
