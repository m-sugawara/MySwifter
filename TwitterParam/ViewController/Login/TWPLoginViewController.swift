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

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var loginButon: UIButton!
    
    // MARK: - Deinit
    deinit {
        print("deinit login ViewController")
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Set background color
        let backgroundColor = UIColor(patternImage: UIImage(named: "Background_Pattern")!)
        self.contentView.backgroundColor = backgroundColor
        
        self.bindSignals()
    }

    // MARK: - Binding
    func bindSignals() {
        
        self.loginButon.reactive.pressed = CocoaAction(self.model.loginButtonAction)

        // Handling Value
        self.model.loginButtonAction.events.observeValues { [weak self] event in
            switch event {
            case .value:
                fallthrough
            case .completed:
                self?.showAlert(with: "SUCCESS", message: "LOGIN SUCCESS", cancelButtonTitle: "OK", cancelTappedAction: { [weak self] () -> Void in
                    self?.performSegue(withIdentifier: "fromLoginToMain", sender: nil)
                })
            case .failed(let error):
                self?.showAlert(with: "ERROR!", message: "\(error.localizedDescription)")
            case .interrupted:
                break
            }
        }
    }

}
