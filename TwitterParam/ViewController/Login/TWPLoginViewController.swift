//
//  TWPLoginViewController.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/21.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

class TWPLoginViewController: UIViewController {
    let model = TWPLoginViewModel()

    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var loginButon: UIButton!
    
    // MARK: - Deinit
    deinit {
        println("deinit login ViewController")
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if segue.identifier == "fromLoginToMain" {
            let mainViewController: TWPMainViewController = segue.destinationViewController as! TWPMainViewController
            mainViewController.logoutButtonCommand = RACCommand(signalBlock: { (input) -> RACSignal! in
                return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                    // show alert
                    println("self:\(NSStringFromClass(self.dynamicType))")
                    mainViewController.showAlertWithTitle("ALERT", message: "LOGOUT?",
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
                        subscriber.sendCompleted()
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                    
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
        
        self.loginButon.rac_command = self.model.loginButtonCommand
        
        // Completed Signals
        self.loginButon.rac_command.executionSignals.flatten().subscribeNext { (next) -> Void in
            // Login success
            self.showAlertWithTitle("SUCCESS", message: "LOGIN SUCCESS", cancelButtonTitle: "OK", cancelTappedAction: { () -> Void in
                // OK button tapped, segue Main page
                self.performSegueWithIdentifier("fromLoginToMain", sender: nil)
            })
        }
        
        // Error Signals
        self.loginButon.rac_command.errors.subscribeNext { (error) -> Void in
            if error != nil {
                self.showAlertWithTitle("ERROR!", message: error.localizedDescription)
            }
        }
    }

}
