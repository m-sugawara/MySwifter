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

final class TWPTwitterAPI: NSObject {
    
    typealias FailureHandler = (error: NSError) -> Void
    private var swifter:Swifter = Swifter(consumerKey: "5UwojnG3QBtSA3StY4JOvjVAK", consumerSecret: "XAKBmM3I4Mgt1lQtICLLKkuCWZzN0nXGe4sJ5qwDhqKK4PtCYd")
    
    // MARK: - Singleton
    static let sharedInstance = TWPTwitterAPI()
    
    // MARK: - Initializer
    private override init() {
        super.init()
    }
    
    // MARK: - ErrorHelper
    func errorWithCode(code :Int, message: String) -> NSError {
        return NSError(domain: NSURLErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
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
                            let error = self.errorWithCode(kTWPErrorCodeNoTwitterAccount, message: "There are no Twitter accounts configured")
                            subscriber.sendError(error)
                        }
                        else {
                            let twitterAccount = twitterAccounts[0] as! ACAccount
                            
                            self.swifter = Swifter(account: twitterAccount)
                            
                            // when authorize successed, get Timeline
                            self.getStatusesHomeTimelineWithCount(20)?.subscribeNext({ (next) -> Void in
                                subscriber.sendNext(next)
                                }, error: { (error) -> Void in
                                    subscriber.sendError(error)
                                }, completed: { () -> Void in
                                    subscriber.sendCompleted()
                            })
                        }
                    }
                    else {
                        println("There are no Twitter accounts configured.")
                        
                        let error = self.errorWithCode(kTWPErrorCodeNoTwitterAccount, message: "There are no Twitter accounts configured")
                        subscriber.sendError(error)
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
                
                // when authorize successed, get Timeline
                self.getStatusesHomeTimelineWithCount(20)?.subscribeNext({ (next) -> Void in
                    subscriber.sendNext(next)
                    }, error: { (error) -> Void in
                        subscriber.sendError(error)
                    }, completed: { () -> Void in
                        subscriber.sendCompleted()
                })
            }
            else {
                // Nothing AccessToken
                self.swifter.authorizeWithCallbackURL(NSURL(string: "tekitou://success")!,
                    success: { (accessToken, response) -> Void in
                        println("Successfully authorized")
                        var accessToken = self.swifter.client.credential?.accessToken
                        TWPUserHelper.saveUserToken(accessToken!)
                        
                        // when authorize successed, get Timeline
                        self.getStatusesHomeTimelineWithCount(20)?.subscribeNext({ (next) -> Void in
                            subscriber.sendNext(next)
                        }, error: { (error) -> Void in
                            subscriber.sendError(error)
                        }, completed: { () -> Void in
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
    func getMyUser() -> RACSignal? {
        let user = TWPUserHelper.fetchUserQData()
        let userID = user["userID"] as? String
        
        return self.getUsersShowWithUserID(userID!)
    }
    
    func getUsersShowWithUserID(userID: String, includeEntities: Bool? = nil) -> RACSignal? {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.getUsersShowWithUserID(userID,
                includeEntities: includeEntities,
                success: { (user: Dictionary<String, JSONValue>?) -> Void in
                    println("TwitterAPI's user\(user)")
                    
                    // create TWPUser Instance
                    var userInfo = TWPUser(userID: userID, name: user!["name"]!.string, screen_name: user!["screen_name"]!.string, profileImageUrl: user!["profile_image_url"]!.string)
                    // store shared instance
                    TWPUserList.sharedInstance.appendUser(userInfo)
                    
                    subscriber.sendCompleted()
                }, failure: { (error) -> Void in
                    println("error:\(error)")
                    subscriber.sendError(error)
            })
            
            return RACDisposable(block: { () -> Void in
            })
            
        })
    }
    
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
    
    func getStatusesUserTimelineWithUserID(userID: String, count: Int? = nil, sinceID: String? = nil, maxID: String? = nil, trimUser: Bool? = nil, contributorDetails: Bool? = nil, includeEntities: Bool? = nil) -> RACSignal? {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.getStatusesUserTimelineWithUserID(userID,
                count: count,
                sinceID: sinceID,
                maxID: maxID,
                trimUser: trimUser,
                contributorDetails: contributorDetails,
                includeEntities: includeEntities,
                success: { (statuses: [JSONValue]?) -> Void in
                    println(statuses);
                    
                    var tweets: NSMutableArray! = []
                    for i in 0..<statuses!.count {
                        var tweet:TWPTweet? = TWPTweet(text: statuses![i]["text"].string, profileImageUrl: statuses![i]["user"]["profile_image_url"].string)
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

