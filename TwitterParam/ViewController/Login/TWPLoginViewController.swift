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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Set background color
        let backgroundColor = UIColor(patternImage: UIImage(named: "Background_Pattern")!)
        self.contentView.backgroundColor = backgroundColor
        
        self.bindCommands()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Binding
    func bindCommands() {
        
        self.loginButon.rac_command = RACCommand(signalBlock: { (input) -> RACSignal! in
            return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                subscriber.sendCompleted()
                
                return RACDisposable(block: { () -> Void in
                    self.performSegueWithIdentifier("fromLoginToMain", sender: nil)
                })
            })
        })
    }
    


}
