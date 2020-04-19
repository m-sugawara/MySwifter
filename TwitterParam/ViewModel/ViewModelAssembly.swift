//
//  ViewModelAssembly.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2020/04/05.
//  Copyright © 2020 sugawar. All rights reserved.
//

import Swinject

class ViewModelAssembly: Assembly {
    func assemble(container: Container) {
        container.register(LoginViewModelProtocol.self) { resolver in
            let model = LoginViewModel()
            model.setTwitterAPI(resolver.resolve(TwitterAPI.self)!)
            return model
        }
        container.register(MainViewModel.self) { resolver in
            let model = MainViewModel()
            model.userHelper = resolver.resolve(UserHelper.self)!
            model.twitterAPI = resolver.resolve(TwitterAPI.self)!
            return model
        }
        container.register(TweetDetailViewModel.self) { resolver in
            let model = TweetDetailViewModel()
            model.twitterAPI = resolver.resolve(TwitterAPI.self)!
            return model
        }
        container.register(UserListViewModel.self) { resolver in
            let model = UserListViewModel()
            model.twitterAPI = resolver.resolve(TwitterAPI.self)!
            return model
        }
        container.register(UserInfoViewModel.self) { resolver in
            let model = UserInfoViewModel()
            model.twitterAPI = resolver.resolve(TwitterAPI.self)!
            model.userHelper = resolver.resolve(UserHelper.self)!
            return model
        }
    }
}
