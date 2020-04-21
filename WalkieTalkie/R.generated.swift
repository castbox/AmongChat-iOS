//
// This is a generated file, do not edit!
// Generated by R.swift, see https://github.com/mac-cain13/R.swift
//

import Foundation
import Rswift
import UIKit

/// This `R` struct is generated and contains references to static resources.
struct R: Rswift.Validatable {
  fileprivate static let applicationLocale = hostingBundle.preferredLocalizations.first.flatMap(Locale.init) ?? Locale.current
  fileprivate static let hostingBundle = Bundle(for: R.Class.self)
  
  static func validate() throws {
    try font.validate()
    try intern.validate()
  }
  
  /// This `R.file` struct is generated, and contains static references to 4 files.
  struct file {
    /// Resource file `GoogleService-Info.plist`.
    static let googleServiceInfoPlist = Rswift.FileResource(bundle: R.hostingBundle, name: "GoogleService-Info", pathExtension: "plist")
    /// Resource file `call.m4a`.
    static let callM4a = Rswift.FileResource(bundle: R.hostingBundle, name: "call", pathExtension: "m4a")
    /// Resource file `cbegin.mp3`.
    static let cbeginMp3 = Rswift.FileResource(bundle: R.hostingBundle, name: "cbegin", pathExtension: "mp3")
    /// Resource file `end.mp3`.
    static let endMp3 = Rswift.FileResource(bundle: R.hostingBundle, name: "end", pathExtension: "mp3")
    
    /// `bundle.url(forResource: "GoogleService-Info", withExtension: "plist")`
    static func googleServiceInfoPlist(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.googleServiceInfoPlist
      return fileResource.bundle.url(forResource: fileResource)
    }
    
    /// `bundle.url(forResource: "call", withExtension: "m4a")`
    static func callM4a(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.callM4a
      return fileResource.bundle.url(forResource: fileResource)
    }
    
    /// `bundle.url(forResource: "cbegin", withExtension: "mp3")`
    static func cbeginMp3(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.cbeginMp3
      return fileResource.bundle.url(forResource: fileResource)
    }
    
    /// `bundle.url(forResource: "end", withExtension: "mp3")`
    static func endMp3(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.endMp3
      return fileResource.bundle.url(forResource: fileResource)
    }
    
    fileprivate init() {}
  }
  
  /// This `R.font` struct is generated, and contains static references to 2 fonts.
  struct font: Rswift.Validatable {
    /// Font `BlackOpsOne-Regular`.
    static let blackOpsOneRegular = Rswift.FontResource(fontName: "BlackOpsOne-Regular")
    /// Font `ElectronicHighwaySign`.
    static let electronicHighwaySign = Rswift.FontResource(fontName: "ElectronicHighwaySign")
    
    /// `UIFont(name: "BlackOpsOne-Regular", size: ...)`
    static func blackOpsOneRegular(size: CGFloat) -> UIKit.UIFont? {
      return UIKit.UIFont(resource: blackOpsOneRegular, size: size)
    }
    
    /// `UIFont(name: "ElectronicHighwaySign", size: ...)`
    static func electronicHighwaySign(size: CGFloat) -> UIKit.UIFont? {
      return UIKit.UIFont(resource: electronicHighwaySign, size: size)
    }
    
    static func validate() throws {
      if R.font.blackOpsOneRegular(size: 42) == nil { throw Rswift.ValidationError(description:"[R.swift] Font 'BlackOpsOne-Regular' could not be loaded, is 'BlackOpsOne-Regular.ttf' added to the UIAppFonts array in this targets Info.plist?") }
      if R.font.electronicHighwaySign(size: 42) == nil { throw Rswift.ValidationError(description:"[R.swift] Font 'ElectronicHighwaySign' could not be loaded, is 'EHSMB.TTF' added to the UIAppFonts array in this targets Info.plist?") }
    }
    
    fileprivate init() {}
  }
  
  /// This `R.image` struct is generated, and contains static references to 29 images.
  struct image {
    /// Image `backNor`.
    static let backNor = Rswift.ImageResource(bundle: R.hostingBundle, name: "backNor")
    /// Image `btn_call_off`.
    static let btn_call_off = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_call_off")
    /// Image `btn_call_on`.
    static let btn_call_on = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_call_on")
    /// Image `btn_down`.
    static let btn_down = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_down")
    /// Image `btn_power_on`.
    static let btn_power_on = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_power_on")
    /// Image `btn_power`.
    static let btn_power = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_power")
    /// Image `btn_private_icon`.
    static let btn_private_icon = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_private_icon")
    /// Image `btn_private_small`.
    static let btn_private_small = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_private_small")
    /// Image `btn_private`.
    static let btn_private = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_private")
    /// Image `btn_share`.
    static let btn_share = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_share")
    /// Image `btn_up`.
    static let btn_up = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_up")
    /// Image `home_btn_bg_b`.
    static let home_btn_bg_b = Rswift.ImageResource(bundle: R.hostingBundle, name: "home_btn_bg_b")
    /// Image `home_btn_bg`.
    static let home_btn_bg = Rswift.ImageResource(bundle: R.hostingBundle, name: "home_btn_bg")
    /// Image `icon_close`.
    static let icon_close = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_close")
    /// Image `icon_pri_ad`.
    static let icon_pri_ad = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_pri_ad")
    /// Image `icon_pri_join`.
    static let icon_pri_join = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_pri_join")
    /// Image `icon_pro_bg`.
    static let icon_pro_bg = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_pro_bg")
    /// Image `icon_pro_persons`.
    static let icon_pro_persons = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_pro_persons")
    /// Image `icon_pro_select`.
    static let icon_pro_select = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_pro_select")
    /// Image `icon_pro`.
    static let icon_pro = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_pro")
    /// Image `icon_room_lock`.
    static let icon_room_lock = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_room_lock")
    /// Image `icon_setting_diamonds_u`.
    static let icon_setting_diamonds_u = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_setting_diamonds_u")
    /// Image `icon_setting_diamonds`.
    static let icon_setting_diamonds = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_setting_diamonds")
    /// Image `icon_setting_star`.
    static let icon_setting_star = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_setting_star")
    /// Image `icon_setting`.
    static let icon_setting = Rswift.ImageResource(bundle: R.hostingBundle, name: "icon_setting")
    /// Image `launch_name`.
    static let launch_name = Rswift.ImageResource(bundle: R.hostingBundle, name: "launch_name")
    /// Image `share_logo`.
    static let share_logo = Rswift.ImageResource(bundle: R.hostingBundle, name: "share_logo")
    /// Image `speak_button_nor`.
    static let speak_button_nor = Rswift.ImageResource(bundle: R.hostingBundle, name: "speak_button_nor")
    /// Image `speak_button_pre`.
    static let speak_button_pre = Rswift.ImageResource(bundle: R.hostingBundle, name: "speak_button_pre")
    
    /// `UIImage(named: "backNor", bundle: ..., traitCollection: ...)`
    static func backNor(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.backNor, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_call_off", bundle: ..., traitCollection: ...)`
    static func btn_call_off(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_call_off, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_call_on", bundle: ..., traitCollection: ...)`
    static func btn_call_on(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_call_on, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_down", bundle: ..., traitCollection: ...)`
    static func btn_down(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_down, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_power", bundle: ..., traitCollection: ...)`
    static func btn_power(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_power, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_power_on", bundle: ..., traitCollection: ...)`
    static func btn_power_on(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_power_on, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_private", bundle: ..., traitCollection: ...)`
    static func btn_private(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_private, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_private_icon", bundle: ..., traitCollection: ...)`
    static func btn_private_icon(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_private_icon, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_private_small", bundle: ..., traitCollection: ...)`
    static func btn_private_small(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_private_small, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_share", bundle: ..., traitCollection: ...)`
    static func btn_share(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_share, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_up", bundle: ..., traitCollection: ...)`
    static func btn_up(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_up, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "home_btn_bg", bundle: ..., traitCollection: ...)`
    static func home_btn_bg(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.home_btn_bg, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "home_btn_bg_b", bundle: ..., traitCollection: ...)`
    static func home_btn_bg_b(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.home_btn_bg_b, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_close", bundle: ..., traitCollection: ...)`
    static func icon_close(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_close, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_pri_ad", bundle: ..., traitCollection: ...)`
    static func icon_pri_ad(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_pri_ad, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_pri_join", bundle: ..., traitCollection: ...)`
    static func icon_pri_join(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_pri_join, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_pro", bundle: ..., traitCollection: ...)`
    static func icon_pro(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_pro, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_pro_bg", bundle: ..., traitCollection: ...)`
    static func icon_pro_bg(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_pro_bg, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_pro_persons", bundle: ..., traitCollection: ...)`
    static func icon_pro_persons(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_pro_persons, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_pro_select", bundle: ..., traitCollection: ...)`
    static func icon_pro_select(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_pro_select, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_room_lock", bundle: ..., traitCollection: ...)`
    static func icon_room_lock(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_room_lock, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_setting", bundle: ..., traitCollection: ...)`
    static func icon_setting(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_setting, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_setting_diamonds", bundle: ..., traitCollection: ...)`
    static func icon_setting_diamonds(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_setting_diamonds, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_setting_diamonds_u", bundle: ..., traitCollection: ...)`
    static func icon_setting_diamonds_u(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_setting_diamonds_u, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "icon_setting_star", bundle: ..., traitCollection: ...)`
    static func icon_setting_star(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.icon_setting_star, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "launch_name", bundle: ..., traitCollection: ...)`
    static func launch_name(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.launch_name, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "share_logo", bundle: ..., traitCollection: ...)`
    static func share_logo(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.share_logo, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "speak_button_nor", bundle: ..., traitCollection: ...)`
    static func speak_button_nor(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.speak_button_nor, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "speak_button_pre", bundle: ..., traitCollection: ...)`
    static func speak_button_pre(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.speak_button_pre, compatibleWith: traitCollection)
    }
    
    fileprivate init() {}
  }
  
  /// This `R.reuseIdentifier` struct is generated, and contains static references to 1 reuse identifiers.
  struct reuseIdentifier {
    /// Reuse identifier `SearchCell`.
    static let searchCell: Rswift.ReuseIdentifier<SearchCell> = Rswift.ReuseIdentifier(identifier: "SearchCell")
    
    fileprivate init() {}
  }
  
  /// This `R.storyboard` struct is generated, and contains static references to 2 storyboards.
  struct storyboard {
    /// Storyboard `LaunchScreen`.
    static let launchScreen = _R.storyboard.launchScreen()
    /// Storyboard `Main`.
    static let main = _R.storyboard.main()
    
    /// `UIStoryboard(name: "LaunchScreen", bundle: ...)`
    static func launchScreen(_: Void = ()) -> UIKit.UIStoryboard {
      return UIKit.UIStoryboard(resource: R.storyboard.launchScreen)
    }
    
    /// `UIStoryboard(name: "Main", bundle: ...)`
    static func main(_: Void = ()) -> UIKit.UIStoryboard {
      return UIKit.UIStoryboard(resource: R.storyboard.main)
    }
    
    fileprivate init() {}
  }
  
  /// This `R.string` struct is generated, and contains static references to 1 localization tables.
  struct string {
    /// This `R.string.localizable` struct is generated, and contains static references to 21 localization keys.
    struct localizable {
      /// en translation: %@ subscription is %@, it automatically renews unless turned off in Accounting Settings at least 24h before current period ends. Payment is charged to your iTunes Account, cancel any time.
      /// 
      /// Locales: en
      static let premiumSubscriptionDetailNormal = Rswift.StringResource(key: "premium.subscription.detail.normal", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: After the free trial, %@ subscription is %@, it automatically renews unless turned off in Accounting Settings at least 24h before current period ends. Payment is charged to your iTunes Account, cancel any time.
      /// 
      /// Locales: en
      static let premiumSubscriptionDetailFree = Rswift.StringResource(key: "premium.subscription.detail.free", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Cancel
      /// 
      /// Locales: en
      static let toastCancel = Rswift.StringResource(key: "toast.cancel", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Change theme automatically
      /// 
      /// Locales: en
      static let premiumPrivAutomatically = Rswift.StringResource(key: "premium.priv.automatically", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: No ad available, please try again later. 
      /// 
      /// Locales: en
      static let noAdAlert = Rswift.StringResource(key: "no.ad.alert", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: No purchases were found on your account
      /// 
      /// Locales: en
      static let settingsRestoreFailBody = Rswift.StringResource(key: "settings.restore.fail.body", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: OK
      /// 
      /// Locales: en
      static let toastConfirm = Rswift.StringResource(key: "toast.confirm", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Ok
      /// 
      /// Locales: en
      static let alertOk = Rswift.StringResource(key: "alert.ok", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Passcode does not exist
      /// 
      /// Locales: en
      static let privateErrorCode = Rswift.StringResource(key: "private.error.code", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Purchase not found
      /// 
      /// Locales: en
      static let settingsRestoreFailTitle = Rswift.StringResource(key: "settings.restore.fail.title", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Remove ads
      /// 
      /// Locales: en
      static let premiumPrivAds = Rswift.StringResource(key: "premium.priv.ads", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Restore Purchase
      /// 
      /// Locales: en
      static let settingsRestoreTitle = Rswift.StringResource(key: "settings.restore.title", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: SKIP TRIAL
      /// 
      /// Locales: en
      static let premiumSkipTrial = Rswift.StringResource(key: "premium.skip.trial", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Settings
      /// 
      /// Locales: en
      static let settingsTitle = Rswift.StringResource(key: "settings.title", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Subscription Terms:
      /// 
      /// Locales: en
      static let premiumSubscriptionTerms = Rswift.StringResource(key: "premium.subscription.terms", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: TRY IT FREE
      /// 
      /// Locales: en
      static let premiumFreeTrial = Rswift.StringResource(key: "premium.free.trial", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Unlock all categories
      /// 
      /// Locales: en
      static let premiumPrivCategories = Rswift.StringResource(key: "premium.priv.categories", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Unlock all themes
      /// 
      /// Locales: en
      static let premiumPrivThemes = Rswift.StringResource(key: "premium.priv.themes", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: Unreachable networking!
      /// 
      /// Locales: en
      static let networkNotReachable = Rswift.StringResource(key: "network.not.reachable", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: You’re all set
      /// 
      /// Locales: en
      static let settingsRestoreSuccessTitle = Rswift.StringResource(key: "settings.restore.success.title", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      /// en translation: your purchase was successful
      /// 
      /// Locales: en
      static let settingsRestoreSuccessBody = Rswift.StringResource(key: "settings.restore.success.body", tableName: "Localizable", bundle: R.hostingBundle, locales: ["en"], comment: nil)
      
      /// en translation: %@ subscription is %@, it automatically renews unless turned off in Accounting Settings at least 24h before current period ends. Payment is charged to your iTunes Account, cancel any time.
      /// 
      /// Locales: en
      static func premiumSubscriptionDetailNormal(_ value1: String, _ value2: String) -> String {
        return String(format: NSLocalizedString("premium.subscription.detail.normal", bundle: R.hostingBundle, comment: ""), locale: R.applicationLocale, value1, value2)
      }
      
      /// en translation: After the free trial, %@ subscription is %@, it automatically renews unless turned off in Accounting Settings at least 24h before current period ends. Payment is charged to your iTunes Account, cancel any time.
      /// 
      /// Locales: en
      static func premiumSubscriptionDetailFree(_ value1: String, _ value2: String) -> String {
        return String(format: NSLocalizedString("premium.subscription.detail.free", bundle: R.hostingBundle, comment: ""), locale: R.applicationLocale, value1, value2)
      }
      
      /// en translation: Cancel
      /// 
      /// Locales: en
      static func toastCancel(_: Void = ()) -> String {
        return NSLocalizedString("toast.cancel", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Change theme automatically
      /// 
      /// Locales: en
      static func premiumPrivAutomatically(_: Void = ()) -> String {
        return NSLocalizedString("premium.priv.automatically", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: No ad available, please try again later. 
      /// 
      /// Locales: en
      static func noAdAlert(_: Void = ()) -> String {
        return NSLocalizedString("no.ad.alert", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: No purchases were found on your account
      /// 
      /// Locales: en
      static func settingsRestoreFailBody(_: Void = ()) -> String {
        return NSLocalizedString("settings.restore.fail.body", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: OK
      /// 
      /// Locales: en
      static func toastConfirm(_: Void = ()) -> String {
        return NSLocalizedString("toast.confirm", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Ok
      /// 
      /// Locales: en
      static func alertOk(_: Void = ()) -> String {
        return NSLocalizedString("alert.ok", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Passcode does not exist
      /// 
      /// Locales: en
      static func privateErrorCode(_: Void = ()) -> String {
        return NSLocalizedString("private.error.code", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Purchase not found
      /// 
      /// Locales: en
      static func settingsRestoreFailTitle(_: Void = ()) -> String {
        return NSLocalizedString("settings.restore.fail.title", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Remove ads
      /// 
      /// Locales: en
      static func premiumPrivAds(_: Void = ()) -> String {
        return NSLocalizedString("premium.priv.ads", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Restore Purchase
      /// 
      /// Locales: en
      static func settingsRestoreTitle(_: Void = ()) -> String {
        return NSLocalizedString("settings.restore.title", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: SKIP TRIAL
      /// 
      /// Locales: en
      static func premiumSkipTrial(_: Void = ()) -> String {
        return NSLocalizedString("premium.skip.trial", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Settings
      /// 
      /// Locales: en
      static func settingsTitle(_: Void = ()) -> String {
        return NSLocalizedString("settings.title", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Subscription Terms:
      /// 
      /// Locales: en
      static func premiumSubscriptionTerms(_: Void = ()) -> String {
        return NSLocalizedString("premium.subscription.terms", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: TRY IT FREE
      /// 
      /// Locales: en
      static func premiumFreeTrial(_: Void = ()) -> String {
        return NSLocalizedString("premium.free.trial", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Unlock all categories
      /// 
      /// Locales: en
      static func premiumPrivCategories(_: Void = ()) -> String {
        return NSLocalizedString("premium.priv.categories", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Unlock all themes
      /// 
      /// Locales: en
      static func premiumPrivThemes(_: Void = ()) -> String {
        return NSLocalizedString("premium.priv.themes", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: Unreachable networking!
      /// 
      /// Locales: en
      static func networkNotReachable(_: Void = ()) -> String {
        return NSLocalizedString("network.not.reachable", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: You’re all set
      /// 
      /// Locales: en
      static func settingsRestoreSuccessTitle(_: Void = ()) -> String {
        return NSLocalizedString("settings.restore.success.title", bundle: R.hostingBundle, comment: "")
      }
      
      /// en translation: your purchase was successful
      /// 
      /// Locales: en
      static func settingsRestoreSuccessBody(_: Void = ()) -> String {
        return NSLocalizedString("settings.restore.success.body", bundle: R.hostingBundle, comment: "")
      }
      
      fileprivate init() {}
    }
    
    fileprivate init() {}
  }
  
  fileprivate struct intern: Rswift.Validatable {
    fileprivate static func validate() throws {
      try _R.validate()
    }
    
    fileprivate init() {}
  }
  
  fileprivate class Class {}
  
  fileprivate init() {}
}

struct _R: Rswift.Validatable {
  static func validate() throws {
    try storyboard.validate()
  }
  
  struct storyboard: Rswift.Validatable {
    static func validate() throws {
      try launchScreen.validate()
      try main.validate()
    }
    
    struct launchScreen: Rswift.StoryboardResourceWithInitialControllerType, Rswift.Validatable {
      typealias InitialController = UIKit.UIViewController
      
      let bundle = R.hostingBundle
      let name = "LaunchScreen"
      
      static func validate() throws {
        if UIKit.UIImage(named: "launch_name", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'launch_name' is used in storyboard 'LaunchScreen', but couldn't be loaded.") }
        if UIKit.UIImage(named: "share_logo", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'share_logo' is used in storyboard 'LaunchScreen', but couldn't be loaded.") }
        if #available(iOS 11.0, *) {
        }
      }
      
      fileprivate init() {}
    }
    
    struct main: Rswift.StoryboardResourceWithInitialControllerType, Rswift.Validatable {
      typealias InitialController = NavigationViewController
      
      let bundle = R.hostingBundle
      let name = "Main"
      let premiumViewController = StoryboardViewControllerResource<PremiumViewController>(identifier: "PremiumViewController")
      let privateChannelController = StoryboardViewControllerResource<PrivateChannelController>(identifier: "PrivateChannelController")
      let privateShareController = StoryboardViewControllerResource<PrivateShareController>(identifier: "PrivateShareController")
      let searchViewController = StoryboardViewControllerResource<SearchViewController>(identifier: "SearchViewController")
      let settingViewController = StoryboardViewControllerResource<SettingViewController>(identifier: "SettingViewController")
      
      func premiumViewController(_: Void = ()) -> PremiumViewController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: premiumViewController)
      }
      
      func privateChannelController(_: Void = ()) -> PrivateChannelController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: privateChannelController)
      }
      
      func privateShareController(_: Void = ()) -> PrivateShareController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: privateShareController)
      }
      
      func searchViewController(_: Void = ()) -> SearchViewController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: searchViewController)
      }
      
      func settingViewController(_: Void = ()) -> SettingViewController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: settingViewController)
      }
      
      static func validate() throws {
        if UIKit.UIImage(named: "btn_call_on", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_call_on' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_down", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_down' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_power", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_power' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_private", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_private' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_private_icon", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_private_icon' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_share", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_share' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_up", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_up' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "button_press", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'button_press' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "home_btn_bg_b", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'home_btn_bg_b' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_close", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_close' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_pri_ad", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_pri_ad' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_pri_join", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_pri_join' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_pro", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_pro' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_pro_persons", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_pro_persons' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_pro_select", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_pro_select' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_room_lock", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_room_lock' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_setting", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_setting' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_setting_diamonds_u", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_setting_diamonds_u' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "icon_setting_star", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'icon_setting_star' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "speak_button_nor", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'speak_button_nor' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "speak_button_pre", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'speak_button_pre' is used in storyboard 'Main', but couldn't be loaded.") }
        if #available(iOS 11.0, *) {
          if UIKit.UIColor(named: "textColor", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Color named 'textColor' is used in storyboard 'Main', but couldn't be loaded.") }
        }
        if _R.storyboard.main().premiumViewController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'premiumViewController' could not be loaded from storyboard 'Main' as 'PremiumViewController'.") }
        if _R.storyboard.main().privateChannelController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'privateChannelController' could not be loaded from storyboard 'Main' as 'PrivateChannelController'.") }
        if _R.storyboard.main().privateShareController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'privateShareController' could not be loaded from storyboard 'Main' as 'PrivateShareController'.") }
        if _R.storyboard.main().searchViewController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'searchViewController' could not be loaded from storyboard 'Main' as 'SearchViewController'.") }
        if _R.storyboard.main().settingViewController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'settingViewController' could not be loaded from storyboard 'Main' as 'SettingViewController'.") }
      }
      
      fileprivate init() {}
    }
    
    fileprivate init() {}
  }
  
  fileprivate init() {}
}
