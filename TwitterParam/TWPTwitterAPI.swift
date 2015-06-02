//
//  TwitterAPI.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

import Accounts
import SwifteriOS

class TWPTwitterAPI: NSObject {
    
    static let failureHandler: ((NSError) -> Void) = {
        error in
        
        println(error.localizedDescription)
    }

    class func twitterAuthorizeWithAccount() {
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
            granted, error in
            
            if granted {
                let twitterAccounts = accountStore.accountsWithAccountType(accountType)
                
                if (twitterAccounts != nil) {
                    if twitterAccounts.count == 0 {
                        println("There are no Twitter accounts configured.")
                    }
                    else {
                        let twitterAccount = twitterAccounts[0] as! ACAccount
                        
                        let swifter = Swifter(account: twitterAccount)
                        
                        swifter.getStatusesHomeTimelineWithCount(20, success: {
                            (statues: [JSONValue]?) in
                            
                            println(statues)
                            
                            },
                            failure: self.failureHandler)
                    }
                }
                else {
                    println("There are no Twitter accounts configured.")
                }
            }
            else {
                
            }
        }
    }
    
    class func twitterAuthorizeWithOAuth() -> RACSignal! {
        let swifter = Swifter(consumerKey: "5UwojnG3QBtSA3StY4JOvjVAK", consumerSecret: "XAKBmM3I4Mgt1lQtICLLKkuCWZzN0nXGe4sJ5qwDhqKK4PtCYd")
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            
            swifter.authorizeWithCallbackURL(NSURL(string: "tekitou://success")!,
                success: { (accessToken, response) -> Void in
                    println("Successfully authorized")
                    println(accessToken)
                    
                    
                    swifter.getStatusesHomeTimelineWithCount(20,
                        success: { (statuses: [JSONValue]?) -> Void in
                            println(statuses)
                            
                            var tweets: NSMutableArray! = []
                            for i in 0..<statuses!.count {
                                var tweet: TWPTweet? = TWPTweet(text: statuses![i]["text"].string, profileImageUrl: statuses![i]["user"]["profile_image_url"].string)
                                tweets.addObject(tweet!)
                            }
                            
                            subscriber.sendNext(tweets)
                            subscriber.sendCompleted()
                        },
                        failure: { (error) -> Void in
                            subscriber.sendError(error)
                    })
                },
                failure: { (error) -> Void in
                    subscriber.sendError(error)
            })
            
            
            return RACDisposable(block: { () -> Void in
                
            })
        })

    }
}

