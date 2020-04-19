//
//  LoginViewController.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/21.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class LoginViewController: UIViewController {

    var model: LoginViewModelProtocol!

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var loginButon: UIButton!

    // MARK: - Deinit
    deinit {
        print("deinit login ViewController")
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        initializeUI()
        bindSignals()
    }

    private func initializeUI() {
        contentView.backgroundColor = UIColor(patternImage: UIImage(named: "Background_Pattern")!)
    }

    // MARK: - Binding
    private func bindSignals() {
        model.statusSignal.observe(on: UIScheduler()).observeValues { [weak self] status in
            switch status {
            case .logined:
                self?.showAlert(with: "Success",
                                message: "Login Success",
                                cancelButtonTitle: "OK",
                    cancelTappedAction: { [weak self] _ in
                        self?.dismiss(animated: true, completion: nil)
                })
            case .failed(let errorMessage):
                self?.showAlert(
                    with: "ERROR!",
                    message: errorMessage
                )
            case .ready:
                break
            }
        }

        loginButon.reactive.pressed = CocoaAction(model.loginAction)
    }

}
