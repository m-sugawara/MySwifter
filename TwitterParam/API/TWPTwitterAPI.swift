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
import ReactiveCocoa

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
                let user = TWPUserHelper.currentUser()
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
    
    // MARK: - Wrapper Method(Login)
    func tryToLogin() -> RACSignal? {
        // try to Login
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAuthorizeWithAccount().subscribeError({ (error) -> Void in
                
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
    
    // MARK: - Wrapper Method(User)
    func getMyUser() -> RACSignal? {
        return self.getUsersShowWithUserID(TWPUserHelper.currentUserID()!)
    }
    
    func getUsersShowWithUserID(userID: String, includeEntities: Bool? = nil) -> RACSignal? {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.getUsersShowWithUserID(userID,
                includeEntities: includeEntities,
                success: { (user: Dictionary<String, JSONValue>?) -> Void in
                    println("TwitterAPI's user\(user)")
                    
                    // create TWPUser Instance
                    var userInfo = TWPUser(dictionary: user!)
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
    // MARK: - Wrapper Method(Follow)
    func getFriendListWithID(id: String, cursor: Int? = nil, count: Int? = nil, skipStatus: Bool? = nil, includeUserEntities: Bool? = nil) -> RACSignal? {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.getFriendsListWithID(id,
                cursor: cursor,
                count: count,
                skipStatus: skipStatus,
                includeUserEntities: includeUserEntities,
                success: { (users, previousCursor, nextCursor) -> Void in
                    println("\(users)")
                    var resultUsers:Array<TWPUser> = []
                    for user:JSONValue in users! {
                        println("what is user? : \(user)")
                        var resultUser = TWPUser(dictionary: user.object!)
                        resultUsers.append(resultUser)
                    }
                    subscriber.sendNext(resultUsers)
                    subscriber.sendCompleted()
                    
            }, failure: { (error) -> Void in
                subscriber.sendError(error)
            })
            
            return RACDisposable()
        })
    }
    // MARK: - Wrapper Method(Followers)
    func getFollowersListWithID(id: String, cursor: Int? = nil, count: Int? = nil, skipStatus: Bool? = nil, includeUserEntities: Bool? = nil) -> RACSignal? {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.getFollowersListWithID(id,
                cursor: cursor,
                count: count,
                skipStatus: skipStatus,
                includeUserEntities: includeUserEntities,
                success: { (users, previousCursor, nextCursor) -> Void in
                    println("\(users)")
            }, failure: { (error) -> Void in
                subscriber.sendError(error)
            })
            
            return RACDisposable()
        })
    }
    
    // MARK: - Wrapper Method(Timeline)
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
    
    // MARK: - Wrapper Method(Tweet)
    func postStatusUpdate(status: String, inReplyToStatusID: String? = nil, lat: Double? = nil, long: Double? = nil, placeID: Double? = nil, displayCoordinates: Bool? = nil, trimUser: Bool? = nil) -> RACSignal? {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.postStatusUpdate(status,
                inReplyToStatusID: inReplyToStatusID,
                lat: lat,
                long: long,
                placeID: placeID,
                displayCoordinates: displayCoordinates,
                trimUser: trimUser,
                success: { (status) -> Void in
                    println(status)
                    
                    subscriber.sendCompleted()
            }, failure: { (error) -> Void in
                subscriber.sendError(error)
            })
            
            return RACDisposable()
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
    
    // MARK: - Wrapper Method(Retweet)
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
    
    // MARK: - Wrapper Methods(favorite)
    func getFavoritesListWithUserID(userID: String, count: Int? = nil, sinceID: String? = nil, maxID: String? = nil) -> RACSignal? {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.getFavoritesListWithUserID(userID,
                count: count,
                sinceID: sinceID,
                maxID: maxID,
                success: { (statuses) -> Void in
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
            }, failure: { (error) -> Void in
                subscriber.sendError(error)
            })
            
            return RACDisposable()
        })
    }
    
    func postCreateFavoriteWithID(id: String, includeEntities: Bool? = nil) -> RACSignal? {
    
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.postCreateFavoriteWithID(id,
                includeEntities: includeEntities,
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
    
    func postDestroyFavoriteWithID(id: String, includeEntities: Bool? = nil) -> RACSignal? {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.postDestroyFavoriteWithID(id,
                includeEntities: includeEntities,
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
    
    // MARK: - Wrapper Methods(follow)
    func postCreateFriendshipWithID(id: String, follow: Bool? = nil) -> RACSignal? {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.postCreateFriendshipWithID(id,
                follow: follow,
                success: { (user) -> Void in
                    println("post create friend ship success:\(user)")
                    TWPUserList.sharedInstance.findUserByUserID(id)?.following = true
                    
                    subscriber.sendNext(nil)
                    subscriber.sendCompleted()
                }) { (error) -> Void in
                    subscriber.sendError(error)
            }

            return RACDisposable()
        })
    }
    
    func postDestroyFriendshipWithID(id: String) -> RACSignal? {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.swifter.postDestroyFriendshipWithID(id,
                success: { (user) -> Void in
                    println("post destroy friend ship success:\(user)")
                    TWPUserList.sharedInstance.findUserByUserID(id)?.following = false
                    
                    subscriber.sendNext(nil)
                    subscriber.sendCompleted()
            }, failure: { (error) -> Void in
                subscriber.sendError(error)
            })
            return RACDisposable()
        })
    }
    
}

