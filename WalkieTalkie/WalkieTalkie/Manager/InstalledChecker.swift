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
    //        ["name": "Clash of Clans","bundleId": "com.supercell.magic", "scheme": ""],
    //        ["name": "rules of survival","bundleId": "com.netease.chiji", "scheme": ""],
    //        ["name": "Monster Legends","bundleId": "es.socialpoint.MonsterCity", "scheme": ""],
    //        ["name": "Dragon City","bundleId": "es.socialpoint.dragoncity", "scheme": ""],
    //        ["name": "Clash Royale","bundleId": "com.supercell.scroll", "scheme": ""],
    //        ["name": "State of survival","bundleId": "com.kingsgroup.ss", "scheme": ""],
    //        ["name": "Mafia City","bundleId": "com.yottagames.mafiawar", "scheme": ""],
    //        ["name": "Cooking Madness","bundleId": "net.ajoy.kf", "scheme": ""],
    //        ["name": "Subway Surfers","bundleId": "com.kiloo.subwaysurfers", "scheme": ""],
    //        ["name": "Mario Kart Tour","bundleId": "com.nintendo.zaka", "scheme": ""],
    //        ["name": "Bowmasters","bundleId": "com.playgendary.bowmasters", "scheme": ""],
    //        ["name": "Sniper 3D","bundleId": "com.fungames.sniper3d", "scheme": ""],
    //        ["name": "Pixel Gun 3D","bundleId": "zombiegun3d", "scheme": ""],
    //        ["name": "Zooba","bundleId": "com.fungames.battleroyale", "scheme": ""],
    //        ["name": "creative destruction","bundleId": "com.titan.cd.gb", "scheme": ""],
    //        ["name": "Bloons TD Battles","bundleId": "com.ninjakiwi.bloonstdbattles", "scheme": ""],
    //        ["name": "Crazy Kick","bundleId": "com.orbitalknight.ridiculousfreekick", "scheme": ""],
    //        ["name": "Marvel Contest of Champions","bundleId": "com.kabam.marvelbattle", "scheme": ""],
    //        ["name": "Marvel Strike force","bundleId": "com.foxnextgames.m3", "scheme": ""],
    //        ["name": "Township","bundleId": "com.playrix.township-ios", "scheme": ""],
    //        ["name": "8 ball pool","bundleId": "com.miniclip.8ballpoolmult", "scheme": ""],
    //        ["name": "CSR 2","bundleId": "com.naturalmotion.customstreetracer2", "scheme": ""],
    //        ["name": "Bloons TD 6","bundleId": "com.ninjakiwi.bloonstd6", "scheme": ""],
    //        ["name": "Dota underlords","bundleId": "com.valvesoftware.underlords", "scheme": ""],
    //        ["name": "FIFA Soccer","bundleId": "com.ea.ios.fifamobile", "scheme": ""],
    //        ["name": "Fire Emblem Heroes","bundleId": "com.nintendo.zaba", "scheme": ""],
    //        ["name": "Modern Combat Versus","bundleId": "com.gameloft.mcvs", "scheme": ""],
    //        ["name": "shadowgun legends","bundleId": "com.madfingergames.legends", "scheme": ""],
    //        ["name": "Terraria","bundleId": "com.505games.terraria", "scheme": ""],
    //        ["name": "Vainglory","bundleId": "com.superevilmegacorp.kindred", "scheme": ""],
    //        ["name": "World of Tanks Blitz","bundleId": "net.wargaming.wotblitz", "scheme": ""],
    //        ["name": "World of Warships Blitz","bundleId": "net.wargaming.wowsblitz", "scheme": ""],
    //        ["name": "Gear.Club - True Racing","bundleId": "com.edengames.GTSpirit", "scheme": ""],
    //        ["name": "Heartstone","bundleId": "com.blizzard.wtcg.hearthstone", "scheme": ""],
    //        ["name": "Alto's Adventure","bundleId": "com.snowman.alto", "scheme": ""],
    //        ["name": "Modern Combat 5","bundleId": "com.gameloft.ModernCombat5", "scheme": ""],
    //        ["name": "Gods of Boom","bundleId": "com.gameinsight.gobios", "scheme": ""],
    //        ["name": "Mini Militia - Doodle Army 2","bundleId": "com.chadtowns.da2", "scheme": ""],
    //        ["name": "Call of Duty: Black Ops Zombies","bundleId": "com.activision.callofduty.blackopszombies", "scheme": ""],
    //        ["name": "Arena of Valor","bundleId": "com.ngame.allstar.eu", "scheme": ""],
    //        ["name": "Star Wars™: Galaxy of Heroes","bundleId": "com.ea.starwarscapital.bv", "scheme": ""],
    //        ["name": "Ludo King","bundleId": "com.gametion.ludo", "scheme": ""],
    //        ["name": "Bowling King","bundleId": "com.pnixgames.bowlingking", "scheme": ""],
    //        ["name": "Battle Racing Stars","bundleId": "com.halfbrick.boosterraiders", "scheme": ""],
    //        ["name": "Tanks A lot","bundleId": "com.boombitgames.TanksALot", "scheme": ""],
    //        ["name": "Sonic Forces","bundleId": "com.sega.sonic2017ios", "scheme": ""],
    //        ["name": "Tennis Clash","bundleId": "com.fungames.tennisclash", "scheme": ""],
    //        ["name": "Golf Battle","bundleId": "games.onebutton.golfbattle", "scheme": ""],
    //        ["name": "Monopoly","bundleId": "com.marmalade.monopoly", "scheme": ""],
    //        ["name": "N.O.V.A. Legacy","bundleId": "com.gameloft.novalegacy", "scheme": ""],
    //        ["name": "Drive Ahead","bundleId": "com.dodreams.crashonwheels", "scheme": ""],
    //        ["name": "Hay Day","bundleId": "com.supercell.soil", "scheme": ""],
    //        ["name": "Words With Friends 2","bundleId": "com.zynga.WordsWithFriends3", "scheme": ""],
    //        ["name": "Sky Children of the Light","bundleId": "com.tgc.sky.ios", "scheme": ""],
    //        ["name": "Battle of Polytopia","bundleId": "com.felixrum.supertribes", "scheme": ""],
    //        ["name": "Super Stickman Golf 2","bundleId": "com.noodlecake.ssgpuzzle", "scheme": ""],
    //        ["name": "Dots and Boxes","bundleId": "com.outofthebit.dots", "scheme": ""],
    //        ["name": "Among us","bundleId": "com.innersloth.amongus", "scheme": ""],
    //        ["name": "Black Desert Mobile","bundleId": "com.pearlabyss.blackdesertm.gl", "scheme": ""],
    //        ["name": "War Machines","bundleId": "com.fungames.battletanksbeta", "scheme": ""]
        ]
    }
}
