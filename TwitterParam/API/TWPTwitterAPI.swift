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
import ReactiveSwift

final class TWPTwitterAPI: NSObject {
    
    typealias FailureHandler = (_ error: Error) -> Void

    private var swifter: Swifter
    
    // MARK: - Singleton
    static let sharedInstance = TWPTwitterAPI()
    
    // MARK: - Initializer
    private override init() {
        super.init()
        self.swifter = Swifter(consumerKey: "5UwojnG3QBtSA3StY4JOvjVAK", consumerSecret: "XAKBmM3I4Mgt1lQtICLLKkuCWZzN0nXGe4sJ5qwDhqKK4PtCYd")
    }
    
    // MARK: - ErrorHelper
    func errorWithCode(code :Int, message: String) -> NSError {
        return NSError(domain: NSURLErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }

    // MARK: - ACAccount
    func twitterAuthorizeWithAccount() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }

            let accountStore = ACAccountStore()
            let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccounts(with: accountType, options: nil) { [weak self] granted, error in
                guard let self = self else {
                    observer.sendInterrupted()
                    return
                }
                guard granted else {
                    let error = self.errorWithCode(code: kTWPErrorCodeNotGrantedACAccount, message: "granted account not found")
                    observer.send(error: error)
                    return
                }
                guard let twitterAccount = accountStore.accounts(with: accountType)?.first as? ACAccount else {
                    let error = self.errorWithCode(code: kTWPErrorCodeNoTwitterAccount, message: "There is no configured Twitter account")
                    observer.send(error: error)
                    return
                }
                self.swifter = Swifter(account: twitterAccount)

                // Save User's AccessToken
                _ = TWPUserHelper.saveUserAccount(account: twitterAccount)

                observer.sendCompleted()
            }
        }
    }
    
    // MARK: - OAuth
    func twitterAuthorizeWithOAuth() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            guard let self = self else {
                observer.sendInterrupted()
                return
            }
            guard let userToken = TWPUserHelper.fetchUserToken() else {
                // Nothing AccessToken
                self.swifter.authorize(withCallback: URL(string: "tekitou://success")!, presentingFrom: nil,
                    success: { accessToken, response -> Void in
                        _ = TWPUserHelper.saveUserToken(data: accessToken!)
                        observer.sendCompleted()
                    },
                    failure: { (error) -> Void in
                        let error = self.errorWithCode(code: kTWPErrorCodeNoTwitterAccount, message: error.localizedDescription)
                        observer.send(error: error)
                })
                return
            }
            print("found valid user token")
            self.swifter.client.credential = userToken
            observer.sendCompleted()
        }
    }
    
    // MARK: - Logout
    func logout() {
        _ = TWPUserHelper.removeUserToken()
    }
    
    // MARK: - Wrapper Method(Login)
    func tryToLogin() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            self?.twitterAuthorizeWithAccount().start { event in
                switch event {
                case .failed(let error):
                    if (error as NSError).code == kTWPErrorCodeNoTwitterAccount,
                        (error as NSError).code == kTWPErrorCodeNotGrantedACAccount {
                        // if try to login for using ACAccount failed, try to login with OAuth.
                        self?.twitterAuthorizeWithOAuth().start { event in
                            switch event {
                            case .failed(let error):
                                observer.send(error: error)
                            case .completed:
                                observer.sendCompleted()
                            default:
                                break
                            }
                        }
                    } else {
                        observer.send(error: error)
                    }
                case .completed:
                    observer.sendCompleted()
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Wrapper Method(User)
    func getMyUser() -> SignalProducer<Void, Error> {
        return self.getUsersShow(with: .id(TWPUserHelper.currentUserID()!))
    }
    
    func getUsersShow(with userTag: UserTag, includeEntities: Bool? = nil) -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self?.swifter.showUser(userTag,
                includeEntities: includeEntities,
                success: { json in
                    let user = TWPUser(dictionary: json.object!)
                    TWPUserList.sharedInstance.appendUser(user)

                    observer.sendCompleted()
                }, failure: { (error) -> Void in
                    observer.send(error: error)
            })
        }
    }
    // MARK: - Wrapper Method(Follow)
    func getFriendList(with id: String, cursor: String? = nil, count: Int? = nil, skipStatus: Bool? = nil, includeUserEntities: Bool? = nil) -> SignalProducer<[TWPUser], Error> {
        return SignalProducer<[TWPUser], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getUserFollowingIDs(
                for: .id(id),
                cursor: cursor,
                count: count,
                success: { json, previousCursor, nextCursor in
                    var resultUsers: [TWPUser] = []
                    for userJSON in json.array! {
                        let resultUser = TWPUser(dictionary: userJSON.object!)
                        resultUsers.append(resultUser)
                    }
                    observer.send(value: resultUsers)
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }
    // MARK: - Wrapper Method(Followers)
    func getFollowersList(with id: String, cursor: String? = nil, count: Int? = nil, skipStatus: Bool? = nil, includeUserEntities: Bool? = nil) -> SignalProducer<[TWPUser], Error> {
        return SignalProducer<[TWPUser], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getUserFollowersIDs(
                for: .id(id),
                cursor: cursor,
                count: count,
                success: { json, previousCursor, nextCursor in
                    var resultUsers: [TWPUser] = []
                    for userJSON in json.array! {
                        let resultUser = TWPUser(dictionary: userJSON.object!)
                        resultUsers.append(resultUser)
                    }
                    observer.send(value: resultUsers)
                    observer.sendCompleted()
            }) { error in
                observer.send(error: error)
            }
        }
    }
    
    // MARK: - Wrapper Method(Timeline)
    func getStatusesHomeTimeline(with count: Int? = nil, sinceID: String? = nil, maxID: String? = nil, trimUser: Bool? = nil, contributorDetails: Bool? = nil, includeEntities: Bool? = nil, tweetMode: TweetMode = .default) -> SignalProducer<[TWPTweet], Error> {

        return SignalProducer<[TWPTweet], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getHomeTimeline(
                count: count,
                sinceID: sinceID,
                maxID: maxID,
                trimUser: trimUser,
                contributorDetails: contributorDetails,
                includeEntities: includeEntities,
                tweetMode: tweetMode,
                success: { json in
                    guard let tweets = self.parseTweets(from: json) else {
                        let error = self.errorWithCode(
                            code: kTWPErrorCodeFailedToParseJSON,
                            message: "failed to parse JSON Data")
                        observer.send(error: error)
                        return
                    }

                    observer.send(value: tweets)
                    observer.sendCompleted()
            }) { error in
                observer.send(error: error)
            }
        }
    }
    
    func getUserTimeline(with userId: String, customParam: [String: Any] = [:], count: Int? = nil, sinceID: String? = nil, maxID: String? = nil, trimUser: Bool? = nil, excludeReplies: Bool? = nil, includeRetweets: Bool? = nil, contributorDetails: Bool? = nil, includeEntities: Bool? = nil, tweetMode: TweetMode = .default) -> SignalProducer<[TWPTweet], Error> {

        return SignalProducer<[TWPTweet], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getTimeline(
                for: .id(userId),
                customParam: customParam,
                count: count,
                sinceID: sinceID,
                maxID: maxID,
                trimUser: trimUser,
                excludeReplies: excludeReplies,
                includeRetweets: includeRetweets,
                contributorDetails: contributorDetails,
                includeEntities: includeEntities,
                tweetMode: tweetMode,
                success: { json in
                    guard let tweets = self.parseTweets(from: json) else {
                        let error = self.errorWithCode(
                            code: kTWPErrorCodeFailedToParseJSON,
                            message: "failed to parse JSON Data")
                        observer.send(error: error)
                        return
                    }

                    observer.send(value: tweets)
                    observer.sendCompleted()
            }) { error in
                observer.send(error: error)
            }
        }
    }

    private func parseTweets(from json: JSON) -> [TWPTweet]? {
        guard let statuses = json.array else {
            return nil
        }
        var tweets = [TWPTweet]()
        statuses.forEach {
            guard let tweet = parseTweet(from: $0) else { return }
            tweets.append(tweet)
        }
        return tweets
    }

    private func parseTweet(from json: JSON) -> TWPTweet? {
        guard let userDictionary = json["user"].object else {
            return nil
        }
        let user = TWPUser(dictionary: userDictionary)
        return TWPTweet(status: json, user: user)
    }
    
    // MARK: - Wrapper Method(Tweet)
    func postStatusUpdate(status: String, inReplyToStatusID: String? = nil, coordinate: (lat: Double, long: Double)? = nil, autoPopulateReplyMetadata: Bool? = nil, excludeReplyUserIds: Bool? = nil, placeID: Double? = nil, displayCoordinates: Bool? = nil, trimUser: Bool? = nil, mediaIDs: [String] = [], attachmentURL: URL? = nil, tweetMode: TweetMode = .default) -> SignalProducer<Void, Error> {

        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.postTweet(
                status: status,
                inReplyToStatusID: inReplyToStatusID,
                coordinate: coordinate,
                autoPopulateReplyMetadata: autoPopulateReplyMetadata,
                excludeReplyUserIds: excludeReplyUserIds,
                placeID: placeID,
                displayCoordinates: displayCoordinates,
                trimUser: trimUser,
                mediaIDs: mediaIDs,
                attachmentURL: attachmentURL,
                tweetMode: tweetMode,
                success: { json in
                    observer.sendCompleted()
            }) { error in
                observer.send(error: error)
            }
        }
    }
    
    
    func getStatuesShow(with id: String, trimUser: Bool? = nil, includeMyRetweet: Bool? = nil, includeEntities: Bool? = nil, includeExtAltText: Bool? = nil, tweetMode: TweetMode = .default) -> SignalProducer<TWPTweet, Error> {

        return SignalProducer<TWPTweet, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getTweet(
                for: id,
                trimUser: trimUser,
                includeMyRetweet: includeMyRetweet,
                includeEntities: includeEntities,
                includeExtAltText: includeExtAltText,
                tweetMode: tweetMode,
                success: { json in
                    guard let tweet = self.parseTweet(from: json) else {
                        let error = self.errorWithCode(
                            code: kTWPErrorCodeFailedToParseJSON,
                            message: "failed to parse JSON Data")
                        observer.send(error: error)
                        return
                    }
                    observer.send(value: tweet)
            }) { error in
                observer.send(error: error)
            }
        }
    }
    
    // MARK: - Wrapper Method(Retweet)
    func getCurrentUserRetweetID(with id: String) -> SignalProducer<String, Error> {
        return SignalProducer<String, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getTweet(
                for: id,
                includeMyRetweet: true,
                tweetMode: .default,
                success: { json in
                    let currentUserRetweet = json["current_user_retweet"].object
                    guard let currentUserRetweetId = currentUserRetweet?["id_str"]?.string else {
                        let error = self.errorWithCode(
                            code: kTWPErrorCodeFailedToParseJSON,
                            message: "failed to get currentUserRetweetID")
                        observer.send(error: error)
                        return
                    }
                    observer.send(value: currentUserRetweetId)
                    observer.sendCompleted()
            }) { error in
                observer.send(error: error)
            }
        }
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
                    print(statuses);
                    
                    var tweets: NSMutableArray! = []
                    for i in 0..<statuses!.count {
                        var userDictionary:Dictionary<String, JSON> = statuses![i]["user"].object as Dictionary<String, JSON>!
                        
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
                    print("post create friend ship success:\(user)")
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
                    print("post destroy friend ship success:\(user)")
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

