//
//  TWPLoginViewController.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/21.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa
import ReactiveSwift

class TWPLoginViewController: UIViewController {
    private let model = TWPLoginViewModel()

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

    private func showAlertWithSuccess() {
        showAlert(
            with: "SUCCESS",
            message: "LOGIN SUCCESS",
            cancelButtonTitle: "OK",
            cancelTappedAction: { [weak self] _ in
                self?.performSegue(withIdentifier: "fromLoginToMain", sender: nil)
            }
        )
    }

    private func showAlertWithFailure(with error: NSError) {
        showAlert(
            with: "ERROR!",
            message: "\(error.localizedDescription)"
        )
    }

    // MARK: - Binding
    private func bindSignals() {
        loginButon.reactive.pressed = CocoaAction(Action<Void, Void, Error> { _ in
            return SignalProducer<Void, Error> { observer, _ in
                TWPTwitterAPI.shared.tryToLogin().startWithResult { [weak self] result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            self?.showAlertWithSuccess()
                        }

                    case .failure(let error):
                        DispatchQueue.main.async {
                            self?.showAlertWithFailure(with: error as NSError)
                        }
                    }
                    observer.sendCompleted()
                }
            }
        })
    }

}
