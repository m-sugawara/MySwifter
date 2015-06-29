//
//  TWPLoginViewModel.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/21.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa

class TWPLoginViewModel: NSObject {
    let twitterAPI = TWPTwitterAPI.sharedInstance
    
    // MARK: - Deinit
    deinit {
        println("LoginViewModel deinit")
    }
    
    // MARK: - RACCommands
    var loginButtonCommand: RACCommand {
        return RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return self!.loginButtonSignal
        })
    }
    
    var loginButtonSignal: RACSignal {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            
            self.twitterAPI.tryToLogin()?.subscribeError({ (error) -> Void in
                subscriber.sendError(error)
                }, completed: { () -> Void in
                    subscriber.sendNext(nil)
                    subscriber.sendCompleted()
            })
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
}
