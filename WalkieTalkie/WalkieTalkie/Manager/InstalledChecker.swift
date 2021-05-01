//
//  GameInstalledChecker.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 29/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import CastboxDebuger
import RxSwift
import RxCocoa
import SwiftyUserDefaults

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[InstalledChecker]-\(message)")
}

class InstalledChecker {
    
    static let `default` = InstalledChecker()
    
    struct App: Codable {
        let name: String
        let bundleId: String
        let scheme: String?
        var installed: Bool
        var topicId: String?
        
        var topicType: AmongChat.Topic? {
            guard let topicId = topicId else {
                return nil
            }
            return AmongChat.Topic(rawValue: topicId)
        }
        
        var schemeValue: String {
            scheme ?? bundleId
        }
    }
    
    private var apps: [App] = [] {
        didSet {
            let installedApp = apps.filter { $0.installed }
            installedAppReplay.accept(installedApp)
        }
    }
    
    let installedAppReplay = BehaviorRelay<[App]>(value: [])
    
    init() {
        //start
        decoderCatcher {
            apps = try JSONDecoder().decodeAnyData([App].self, from: InstalledChecker.appList())
        }
    }
    
    func update() {
        cdPrint("start update app count: \(apps.count)")
        
        //update
        let time = Date().string(withFormat: "dd/MM/yyyy")
        guard Defaults[\.updateInstalledAppTime] != time else {
            return
        }
        Defaults[\.updateInstalledAppTime] = time
        apps = apps.map { item -> App in
            guard let url = URL(string: item.schemeValue+"://") else {
                return item
            }
            var app = item
            app.installed = UIApplication.shared.canOpenURL(url)
            return app
        }
        cdPrint("end update, installed app count: \(installedAppReplay.value.count)")
    }
    
}

private extension InstalledChecker {
    static func appList() -> [[String: Any]] {
        return [
            ["name": "Among us","bundleId": "com.innersloth.amongus", "scheme": "amongus", "installed": false, "topicId": "amongus"],
            ["name": "Roblox","bundleId": "com.roblox.robloxmobile", "scheme": "roblox", "installed": false, "topicId": "roblox"],
            ["name": "Minecraft","bundleId": "com.mojang.minecraftpe", "scheme": "minecraft", "installed": false, "topicId": "minecraft"],
            ["name": "Brawl stars","bundleId": "com.supercell.laser", "scheme": "brawlstars", "installed": false, "topicId": "brawlstars"],
            ["name": "PUBG","bundleId": "com.tencent.ig", "scheme": "fb1036341366506456", "installed": false, "topicId": "pubgmobile"],
            ["name": "Animal crossing: Pocket Camp","bundleId": "com.nintendo.zaca", "scheme": "npfde157939dc7df45a", "installed": false, "topicId": "animalcrossing"],
            ["name": "League of Legends: Wild rift","bundleId": "com.riotgames.league.wildrift", "scheme": "fb308784200478744", "installed": false, "topicId": ""],
            ["name": "Garena Free Fire- World Series","bundleId": "com.dts.freefireth", "scheme": "freefire", "installed": false, "topicId": "freefire"],
            ["name": "Mobile Legends : Bang Bang","bundleId": "com.mobile.legends", "scheme": "mobilelegends", "installed": false, "topicId": "mobilelegends"],
            ["name": "Call of duty : Mobile","bundleId": "com.activision.callofduty.shooter", "scheme": "cod", "installed": false, "topicId": "callofduty"],
            ["name": "Clash of Clans", "bundleId": "com.supercell.magic", "scheme": "", "installed": false],
            ["name": "rules of survival", "bundleId": "com.netease.chiji", "scheme": "", "installed": false],
            ["name": "Monster Legends", "bundleId": "es.socialpoint.MonsterCity", "scheme": "", "installed": false],
            ["name": "Dragon City", "bundleId": "es.socialpoint.dragoncity", "scheme": "", "installed": false],
            ["name": "Clash Royale", "bundleId": "com.supercell.scroll", "scheme": "", "installed": false],
            ["name": "State of survival", "bundleId": "com.kingsgroup.ss", "scheme": "", "installed": false],
            ["name": "Mafia City", "bundleId": "com.yottagames.mafiawar", "scheme": "", "installed": false],
            ["name": "Cooking Madness", "bundleId": "net.ajoy.kf", "scheme": "", "installed": false],
            ["name": "Subway Surfers", "bundleId": "com.kiloo.subwaysurfers", "scheme": "", "installed": false],
            ["name": "Mario Kart Tour", "bundleId": "com.nintendo.zaka", "scheme": "", "installed": false],
            ["name": "Bowmasters", "bundleId": "com.playgendary.bowmasters", "scheme": "", "installed": false],
            ["name": "Sniper 3D", "bundleId": "com.fungames.sniper3d", "scheme": "", "installed": false],
            ["name": "Pixel Gun 3D", "bundleId": "zombiegun3d", "scheme": "", "installed": false],
            ["name": "Zooba", "bundleId": "com.fungames.battleroyale", "scheme": "", "installed": false],
            ["name": "creative destruction", "bundleId": "com.titan.cd.gb", "scheme": "", "installed": false],
            ["name": "Bloons TD Battles", "bundleId": "com.ninjakiwi.bloonstdbattles", "scheme": "", "installed": false],
            ["name": "Marvel Contest of Champions", "bundleId": "com.kabam.marvelbattle", "scheme": "", "installed": false],
            ["name": "8 ball pool", "bundleId": "com.miniclip.8ballpoolmult", "scheme": "", "installed": false],
            ["name": "CSR 2", "bundleId": "com.naturalmotion.customstreetracer2", "scheme": "", "installed": false],
            ["name": "Golf Battle", "bundleId": "games.onebutton.golfbattle", "scheme": "", "installed": false],
        ]
    }
}


