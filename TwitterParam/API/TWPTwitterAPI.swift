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
                            
                            // Save User's AccessToken
                            TWPUserHelper.saveUserAccount(twitterAccount)
                            
                            subscriber.sendCompleted()
                        }
                    }
                    else {
                        println("There are no Twitter accounts configured.")
                        
                        let error = self.errorWithCode(kTWPErrorCodeNoTwitterAccount, message: "There are no Twitter accounts configured")
                        subscriber.sendError(error)
                    }
                }
                else {
                    println("ACAccount access failed.")
                    
                    let error = self.errorWithCode(kTWPErrorCodeNotGrantedACAccount, message: "ACAccount access failed")
                    subscriber.sendError(error)
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
                
                subscriber.sendCompleted()
            }
            else {
                // Nothing AccessToken
                self.swifter.authorizeWithCallbackURL(NSURL(string: "tekitou://success")!,
                    success: { (accessToken, response) -> Void in
                        println("Successfully authorized")
                        var accessToken = self.swifter.client.credential?.accessToken
                        TWPUserHelper.saveUserToken(accessToken!)
                        
                        subscriber.sendCompleted()
                    },
                    failure: { (error) -> Void in
                        subscriber.sendError(error)
                })
            }
            
            
            return RACDisposable(block: { () -> Void in
                
            })
        })

    }
    
    // MARK: - Logout
    func tryToLogout() -> RACSignal {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            TWPUserHelper.removeUserToken()
            subscriber.sendCompleted()
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
    
    // MARK: - Wrapper Method
    func tryToLogin() -> RACSignal? {
        // try to Login
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAuthorizeWithOAuth().subscribeError({ (error) -> Void in
                
                if (error.code == kTWPErrorCodeNoTwitterAccount || error.code == kTWPErrorCodeNotGrantedACAccount) {
                    // if try to login for using ACAccount failed, try to login with OAuth.
                    self.twitterAuthorizeWithOAuth().subscribeError( { (error) -> Void in
                        subscriber.sendError(error)
                    }, completed: { () -> Void in
                        // OAuth access success!
                        subscriber.sendCompleted()
                    })
                }
                else {
                    subscriber.sendError(error)
                }
                
            }, completed: { () -> Void in
                // ACAccount access success!
                subscriber.sendCompleted()
            })
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
    
    func getMyUser() -> RACSignal? {
        // get my userID
        let user = TWPUserHelper.fetchUserQData()
        let userID = user!["userID"] as? String
        
        return self.getUsersShowWithUserID(userID!)
    }
    
    func getUsersShowWithUserID(userID: String, includeEntities: Bool? = nil) -> RACSignal? {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.getUsersShowWithUserID(userID,
                includeEntities: includeEntities,
                success: { (user: Dictionary<String, JSONValue>?) -> Void in
                    println("TwitterAPI's user\(user)")
                    
                    // create TWPUser Instance
                    var userInfo = TWPUser(userID: userID, name: user!["name"]!.string, screenName: user!["screen_name"]!.string, profileImageUrl: user!["profile_image_url"]!.string)
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
                        var userDictionary:Dictionary<String, JSONValue> = statuses![i]["user"].object as Dictionary<String, JSONValue>!
                        
                        // create user
                        var user:TWPUser = TWPUser(dictionary: userDictionary)
                        // create tweet
                        var status:JSONValue = statuses![i]
                        status["id_str"].string
                        var tweet:TWPTweet? = TWPTweet(status: statuses![i], user: user)
                        
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
                        var userDictionary:Dictionary<String, JSONValue> = statuses![i]["user"].object as Dictionary<String, JSONValue>!
                        
                        // create user
                        var user:TWPUser = TWPUser(dictionary: userDictionary)
                        
                        // create tweet
                        var tweet:TWPTweet? = TWPTweet(status: statuses![i], user: user)
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
    
    func getCurrentUserRetweetIDWithID(id: String) -> RACSignal? {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.getStatusesShowWithID(id,
                includeMyRetweet: true,
                success: { (status) -> Void in
                    println(status)
                    var currentUserRetweet: Dictionary<String, JSONValue> = status!["current_user_retweet"]!.object as Dictionary<String, JSONValue>!
                    
                    var currentUserRetweetID: String! = currentUserRetweet["id_str"]?.string!
                    
                    subscriber.sendNext(currentUserRetweetID)
                    subscriber.sendCompleted()
            }, failure: { (error) -> Void in
                subscriber.sendError(error)
            })
            
            return RACDisposable(block: { () -> Void in
                
            })
        })
    }
    
    func getStatuesShowWithID(id: String, count: Int? = nil, trimUser: Bool? = nil, includeMyRetweet: Bool? = nil, includeEntities: Bool? = nil) -> RACSignal? {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.getStatusesShowWithID(id,
                count: count,
                trimUser: trimUser,
                includeMyRetweet: includeMyRetweet,
                includeEntities: includeEntities,
                success: { (status: Dictionary<String, JSONValue>?) -> Void in
                    println(status);
                    var userDictionary:Dictionary<String, JSONValue> = status!["user"]!.object as Dictionary<String, JSONValue>!
                    
                    // create user
                    var user:TWPUser = TWPUser(dictionary: userDictionary)
                    
                    // create tweet
                    var tweet:TWPTweet? = TWPTweet(dictionary: status!, user: user)
//                    var tweet:TWPTweet = TWPTweet(text: status!["text"]!.string, profileImageUrl:status!["user"]["profile_image_url"]!.string)
                    
                    subscriber.sendNext(tweet)
                    subscriber.sendCompleted()
                    
            }, failure: { (error) -> Void in
                subscriber.sendError(error)
            })
            
            return RACDisposable(block: { () -> Void in
                
            })
        })
        
    }
    
    func postStatusRetweetWithID(id: String, trimUser: Bool? = nil) -> RACSignal? {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.postStatusRetweetWithID(id,
                trimUser: trimUser,
                success: { (status) -> Void in
                    subscriber.sendNext(nil)
                    subscriber.sendCompleted()
            }, failure: { (error) -> Void in
                subscriber.sendError(error)
            })
            
            return RACDisposable(block: { () -> Void in
                
            })
        })
    }
    
    func postStatusesDestroyWithID(id: String, trimUser: Bool? = nil) -> RACSignal? {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.postStatusesDestroyWithID(id,
                trimUser: trimUser,
                success: { (status) -> Void in
                    subscriber.sendNext(nil)
                    subscriber.sendCompleted()
            }, failure: { (error) -> Void in
                subscriber.sendError(error)
            })
            
            return RACDisposable(block: { () -> Void in
                
            })
        })
    }

    
    // MARK: - Wrapper Methods(Not Use RACSignal)
    func postStatusRetweetWithID(id: String, trimUser: Bool? = nil, success: ((status: Dictionary<String, JSONValue>?) -> Void)? = nil, failure: FailureHandler? = nil) {
        self.swifter.postStatusRetweetWithID(id, trimUser: trimUser, success: success, failure: failure)
    }
    
    func postStatusesDestroyWithID(id: String, trimUser: Bool? = nil, success: ((status: Dictionary<String, JSONValue>?) -> Void)? = nil, failure: FailureHandler? = nil) {
        self.swifter.postStatusesDestroyWithID(id, trimUser: trimUser, success: success, failure: failure)
    }
}

