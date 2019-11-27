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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "fromLoginToMain" {
            let mainViewController = segue.destination as! TWPMainViewController
            mainViewController.logoutButtonAction = Action<Void, Void, Error> {
                return SignalProducer<Void, Error> { [weak mainViewController] observer, lifetime in
                    guard let mainViewController = mainViewController, !lifetime.hasEnded else {
                        observer.sendInterrupted()
                        return
                    }

                    let cancelAction = { () -> Void in
                        observer.sendCompleted()
                    }
                    let yesAction: (UIAlertAction?) -> Void = { [weak mainViewController] action in
                        // if selected YES, try to logout and dismissViewController
                        TWPTwitterAPI.shared.logout()
                        observer.sendCompleted()
                        mainViewController?.dismiss(animated: true, completion: nil)
                    }
                    mainViewController.showAlert(
                        with: "ALERT",
                        message: "LOGOUT?",
                        cancelButtonTitle: "NO",
                        cancelTappedAction: cancelAction,
                        otherButtonTitles: ["YES"],
                        otherButtonTappedActions: yesAction)
                }
            }
        }
    }

    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
