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
    /// Resource file `begin.mp3`.
    static let beginMp3 = Rswift.FileResource(bundle: R.hostingBundle, name: "begin", pathExtension: "mp3")
    /// Resource file `call.m4a`.
    static let callM4a = Rswift.FileResource(bundle: R.hostingBundle, name: "call", pathExtension: "m4a")
    /// Resource file `end.mp3`.
    static let endMp3 = Rswift.FileResource(bundle: R.hostingBundle, name: "end", pathExtension: "mp3")
    
    /// `bundle.url(forResource: "GoogleService-Info", withExtension: "plist")`
    static func googleServiceInfoPlist(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.googleServiceInfoPlist
      return fileResource.bundle.url(forResource: fileResource)
    }
    
    /// `bundle.url(forResource: "begin", withExtension: "mp3")`
    static func beginMp3(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.beginMp3
      return fileResource.bundle.url(forResource: fileResource)
    }
    
    /// `bundle.url(forResource: "call", withExtension: "m4a")`
    static func callM4a(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.callM4a
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
  
  /// This `R.image` struct is generated, and contains static references to 10 images.
  struct image {
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
    /// Image `btn_share`.
    static let btn_share = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_share")
    /// Image `btn_up`.
    static let btn_up = Rswift.ImageResource(bundle: R.hostingBundle, name: "btn_up")
    /// Image `share_logo`.
    static let share_logo = Rswift.ImageResource(bundle: R.hostingBundle, name: "share_logo")
    /// Image `speak_button_nor`.
    static let speak_button_nor = Rswift.ImageResource(bundle: R.hostingBundle, name: "speak_button_nor")
    /// Image `speak_button_pre`.
    static let speak_button_pre = Rswift.ImageResource(bundle: R.hostingBundle, name: "speak_button_pre")
    
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
    
    /// `UIImage(named: "btn_share", bundle: ..., traitCollection: ...)`
    static func btn_share(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_share, compatibleWith: traitCollection)
    }
    
    /// `UIImage(named: "btn_up", bundle: ..., traitCollection: ...)`
    static func btn_up(compatibleWith traitCollection: UIKit.UITraitCollection? = nil) -> UIKit.UIImage? {
      return UIKit.UIImage(resource: R.image.btn_up, compatibleWith: traitCollection)
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
        if UIKit.UIImage(named: "share_logo", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'share_logo' is used in storyboard 'LaunchScreen', but couldn't be loaded.") }
        if #available(iOS 11.0, *) {
        }
      }
      
      fileprivate init() {}
    }
    
    struct main: Rswift.StoryboardResourceWithInitialControllerType, Rswift.Validatable {
      typealias InitialController = ViewController
      
      let bundle = R.hostingBundle
      let name = "Main"
      let searchViewController = StoryboardViewControllerResource<SearchViewController>(identifier: "SearchViewController")
      
      func searchViewController(_: Void = ()) -> SearchViewController? {
        return UIKit.UIStoryboard(resource: self).instantiateViewController(withResource: searchViewController)
      }
      
      static func validate() throws {
        if UIKit.UIImage(named: "btn_call_on", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_call_on' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_down", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_down' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_power", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_power' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_share", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_share' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "btn_up", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'btn_up' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "button_press", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'button_press' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "speak_button_nor", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'speak_button_nor' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIKit.UIImage(named: "speak_button_pre", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: "[R.swift] Image named 'speak_button_pre' is used in storyboard 'Main', but couldn't be loaded.") }
        if #available(iOS 11.0, *) {
        }
        if _R.storyboard.main().searchViewController() == nil { throw Rswift.ValidationError(description:"[R.swift] ViewController with identifier 'searchViewController' could not be loaded from storyboard 'Main' as 'SearchViewController'.") }
      }
      
      fileprivate init() {}
    }
    
    fileprivate init() {}
  }
  
  fileprivate init() {}
}
