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
    
    typealias FailureHandler = (error: NSError) -> Void
    private var swifter:Swifter = Swifter(consumerKey: "5UwojnG3QBtSA3StY4JOvjVAK", consumerSecret: "XAKBmM3I4Mgt1lQtICLLKkuCWZzN0nXGe4sJ5qwDhqKK4PtCYd")
    
    // MARK: - Initializer
    override init() {
        super.init()
    }

    // MARK: - ACAccount
    func twitterAuthorizeWithAccount() -> RACSignal {
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
                granted, error in
                
                if granted {
                    let twitterAccounts = accountStore.accountsWithAccountType(accountType)
                    
                    if (twitterAccounts != nil) {
                        if twitterAccounts.count == 0 {
                            println("There are no Twitter accounts configured.")
                            subscriber.sendError(nil)
                        }
                        else {
                            let twitterAccount = twitterAccounts[0] as! ACAccount
                            
                            self.swifter = Swifter(account: twitterAccount)
                            
                            // when authorize successed, get Timeline
                            self.getStatusesHomeTimelineWithCount(20)?.subscribeError({ (error) -> Void in
                                subscriber.sendError(error)
                                },
                                completed: { () -> Void in
                                    subscriber.sendCompleted()
                            })
                        }
                    }
                    else {
                        println("There are no Twitter accounts configured.")
                        subscriber.sendError(nil)
                    }
                }
                else {
                    subscriber.sendError(nil)
                }
            }
            
            return RACDisposable(block: { () -> Void in
                
            })

        })
    }
    
    // MARK: - OAuth
    func twitterAuthorizeWithOAuth() -> RACSignal! {

        swifter = Swifter(consumerKey: "5UwojnG3QBtSA3StY4JOvjVAK", consumerSecret: "XAKBmM3I4Mgt1lQtICLLKkuCWZzN0nXGe4sJ5qwDhqKK4PtCYd")
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            
            if TWPUserHelper.fetchUserToken() != nil {
                // Having AccessToken
                self.swifter.client.credential = TWPUserHelper.fetchUserToken()
                let user = TWPUserHelper.fetchUserQData()
                println("user\(user)")
            }
            else {
                // Nothing AccessToken
                self.swifter.authorizeWithCallbackURL(NSURL(string: "tekitou://success")!,
                    success: { (accessToken, response) -> Void in
                        println("Successfully authorized")
                        var accessToken = self.swifter.client.credential?.accessToken
                        TWPUserHelper.saveUserToken(accessToken!)
                        
                        // when authorize successed, get Timeline
                        self.getStatusesHomeTimelineWithCount(20)?.subscribeError({ (error) -> Void in
                                subscriber.sendError(error)
                        },
                            completed: { () -> Void in
                                subscriber.sendCompleted()
                        })
                    },
                    failure: { (error) -> Void in
                        subscriber.sendError(error)
                })
            }
            
            
            return RACDisposable(block: { () -> Void in
                
            })
        })

    }
    
    // MARK: - Wrapper Method
    func getStatusesHomeTimelineWithCount(_ count: Int? = nil, sinceID: String? = nil, maxID: String? = nil, trimUser: Bool? = nil, contributorDetails: Bool? = nil, includeEntities: Bool? = nil) -> RACSignal? {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            
            self.swifter.getStatusesHomeTimelineWithCount(count,
                sinceID: sinceID,
                maxID: maxID,
                trimUser: trimUser,
                contributorDetails: contributorDetails,
                includeEntities: includeEntities,
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
            
            return RACDisposable(block: { () -> Void in
                
            })
        })
    }
}

