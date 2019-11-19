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
    let model = TWPLoginViewModel()

    
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
        
        self.bindCommands()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "fromLoginToMain" {
            let mainViewController: TWPMainViewController = segue.destination as! TWPMainViewController
            mainViewController.logoutButtonCommand = RACCommand(signalBlock: { [weak mainViewController] (input) -> RACSignal! in
                return RACSignal.createSignal({ [weak mainViewController] (subscriber) -> RACDisposable! in
                    // show alert
                    if let strongMainViewController = mainViewController {
                        mainViewController!.showAlertWithTitle("ALERT", message: "LOGOUT?",
                            cancelButtonTitle: "NO",
                            cancelTappedAction: { () -> Void in
                                subscriber.sendCompleted()
                            },
                            otherButtonTitles: ["YES"],
                            otherButtonTappedActions: { (UIAlertAction) -> Void in
                                // if selected YES, try to logout and dismissViewController
                                // TODO: Fuckin'solution, should find out more better solution!
                                TWPTwitterAPI.sharedInstance.tryToLogout().subscribeCompleted({ () -> Void in
                                    subscriber.sendNext(nil)
                                    subscriber.sendCompleted()
                                })
                                if let strongMainViewController = mainViewController {
                                    strongMainViewController.dismissViewControllerAnimated(true, completion: nil)
                                }
                                subscriber.sendCompleted()
                        })
                        
                    }
                    
                    return RACDisposable(block: { () -> Void in
                    })

                })
            })
        }
        
    }

    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Binding
    func bindCommands() {
        
        self.loginButon.reactive.pressed = CocoaAction(self.model.loginButtonAction)

        self.model.loginButtonAction.events.observeCompleted {
            // Login success
            self.showAlert(with: "SUCCESS", message: "LOGIN SUCCESS", cancelButtonTitle: "OK", cancelTappedAction: { () -> Void in
                // OK button tapped, segue Main page
                self.performSegue(withIdentifier: "fromLoginToMain", sender: nil)
            })
        }
        
        // Error Signals
        self.model.loginButtonAction.events.observeFailed { [weak self] _ in
            self?.showAlert(with: "ERROR!", message: "error.localizedDescription")
        }
    }

}
