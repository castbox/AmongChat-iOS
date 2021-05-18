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
            ["name": "Marvel Strike force", "bundleId": "com.foxnextgames.m3", "scheme": "fb126932034661742", "installed": false],
            ["name": "Township", "bundleId": "com.playrix.township-ios", "scheme": "fb226681500790782", "installed": false],
            ["name": "FIFA Soccer", "bundleId": "com.ea.ios.fifamobile", "scheme": "fb1662455200680363", "installed": false],
            ["name": "Fire Emblem Heroes", "bundleId": "com.nintendo.zaba", "scheme": "npf6557cf629b753d86", "installed": false],
            ["name": "Modern Combat Versus", "bundleId": "com.gameloft.mcvs", "scheme": "fb132426687177126", "installed": false],
            ["name": "shadowgun legends", "bundleId": "com.madfingergames.legends", "scheme": "fb1789655757943334", "installed": false],
            ["name": "Vainglory", "bundleId": "com.superevilmegacorp.kindred", "scheme": "vainglory", "installed": false],
            ["name": "World of Tanks Blitz", "bundleId": "net.wargaming.wotblitz", "scheme": "fb573320556091057", "installed": false],
            ["name": "World of Warships Blitz", "bundleId": "net.wargaming.wowsblitz", "scheme": "fb1598320380208251wowsb", "installed": false],
            ["name": "Gear.Club - True Racing", "bundleId": "com.edengames.GTSpirit", "scheme": "fb1067191693314092", "installed": false],
            ["name": "Heartstone ", "bundleId": "com.blizzard.wtcg.hearthstone", "scheme": "hearthstone", "installed": false],
            ["name": "Modern Combat 5", "bundleId": "com.gameloft.ModernCombat5", "scheme": "fb523631134360162", "installed": false],
            ["name": "Gods of Boom", "bundleId": "com.gameinsight.gobios", "scheme": "fb1628087097518022", "installed": false],
            ["name": "Mini Militia - Doodle Army 2", "bundleId": "com.chadtowns.da2", "scheme": "doodlearmy2", "installed": false],
            ["name": "Call of Duty: Black Ops Zombies", "bundleId": "com.activision.calloty.blackopszombies", "scheme": "fb209252576430910", "installed": false],
            ["name": "Arena of Valor ", "bundleId": "com.ngame.allstar.eu", "scheme": "fb528157434056869", "installed": false],
            ["name": "Star Wars™: Galaxy of Heroes", "bundleId": "com.ea.starwarscapital.bv", "scheme": "fb337540763102929", "installed": false],
            ["name": "Ludo King ", "bundleId": "com.gametion.ludo", "scheme": "fb321549981551150", "installed": false],
            ["name": "Bowling King", "bundleId": "com.pnixgames.bowlingking", "scheme": "fb571236316289363", "installed": false],
            ["name": "Battle Racing Stars", "bundleId": "com.halfbrick.boosterraiders", "scheme": "fb125434931488903", "installed": false],
            ["name": "Tanks A lot ", "bundleId": "com.boombitgames.TanksALot", "scheme": "fb216001735624718", "installed": false],
            ["name": "Sonic Forces", "bundleId": "com.sega.sonic2017ios", "scheme": "fb116129639069273", "installed": false],
            ["name": "Tennis Clash ", "bundleId": "com.fungames.tennisclash", "scheme": "fb272124996722604", "installed": false],
            ["name": "N.O.V.A. Legacy", "bundleId": "com.gameloft.novalegacy", "scheme": "fb988201081231135", "installed": false],
            ["name": "Drive Ahead ", "bundleId": "com.dodreams.crashonwheels", "scheme": "dodreams", "installed": false],
            ["name": "Hay Day", "bundleId": "com.supercell.soil", "scheme": "fb333917559972367", "installed": false],
            ["name": "Words With Friends 2", "bundleId": "com.zynga.WordsWithFriends3", "scheme": "fb168378113211268wordswithfriends3", "installed": false],
            ["name": "Sky Children of the Light ", "bundleId": "com.tgc.sky.ios", "scheme": "fb293746044767069", "installed": false],
            ["name": "Super Stickman Golf 2", "bundleId": "com.noodlecake.ssgpuzzle", "scheme": "ssg3", "installed": false],
            ["name": "Dots and Boxes", "bundleId": "com.outofthebit.dots", "scheme": "ootbdotsandboxes", "installed": false],
            ["name": "Black Desert Mobile", "bundleId": "com.pearlabyss.blackdesertm.gl", "scheme": "fb408324359791912", "installed": false],
            ["name": "War Machines", "bundleId": "com.fungames.battletanksbeta", "scheme": "fb481621545372239", "installed": false]
        ]
    }
}
