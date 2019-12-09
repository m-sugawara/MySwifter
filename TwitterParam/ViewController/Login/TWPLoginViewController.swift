//
//  TWPLoginViewController.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/21.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import ReactiveCocoa

class TWPLoginViewController: UIViewController {

    private lazy var model = TWPLoginViewModel(viewController: self)

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

    func showAlert() {
        showAlert(
            with: "SUCCESS",
            message: "LOGIN SUCCESS",
            cancelButtonTitle: "OK",
            cancelTappedAction: { [weak self] _ in
                self?.performSegue(withIdentifier: "fromLoginToMain", sender: nil)
            }
        )
    }

    func showAlert(withError error: NSError) {
        showAlert(
            with: "ERROR!",
            message: "\(error.localizedDescription)"
        )
    }

    // MARK: - Binding
    private func bindSignals() {
        loginButon.reactive.pressed = CocoaAction(model.loginAction)
    }

}
