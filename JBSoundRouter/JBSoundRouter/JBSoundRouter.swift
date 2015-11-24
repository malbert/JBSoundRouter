//
//  JBSoundRouter.swift
//
//  Created by Josip Bernat on 1/26/15.
//  Copyright (c) 2015 Josip-Bernat. All rights reserved.
//

import Foundation
import AVFoundation

enum JBSoundRoute: Int {

    case NotDefined = 0
    case Speaker
    case Receiver
}

@objc class JBSoundRouter: NSObject {

    let JBSoundRouterDidChangeRouteNotification = "JBSoundRouterDidChangeRouteNotification"
    
    class func routeSound(route: JBSoundRoute) {
    
        let instance: JBSoundRouter = self.sharedInstance
        instance.currentRoute = route
    }
    
    class func currentSoundRoute() -> JBSoundRoute {
        
        let instance: JBSoundRouter = self.sharedInstance
        return instance.currentRoute
    }
    
    class func isHeadsetPluggedIn() -> Bool {
        
        let route: AVAudioSessionRouteDescription = AVAudioSession.sharedInstance().currentRoute
        for port in route.outputs {
            
            let portDescription: AVAudioSessionPortDescription = port as AVAudioSessionPortDescription
            if portDescription.portType == AVAudioSessionPortHeadphones || portDescription.portType == AVAudioSessionPortHeadsetMic {
                return true
            }
        }
        return false
    }
    
    //MARK: Shared Instance
    //MARK:
    
    private class var sharedInstance : JBSoundRouter {
        
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance : JBSoundRouter? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = JBSoundRouter()
        }
        return Static.instance!
    }
    
    //MARK: Initialization
    //MARK:
    
    override init() {
        
        super.init();
        
        NSNotificationCenter.defaultCenter().addObserverForName(
            AVAudioSessionRouteChangeNotification, object: nil,
            queue: NSOperationQueue.mainQueue()) { (note) -> Void in
                
                let notification: NSNotification = note as NSNotification
                let dict: Dictionary = notification.userInfo as Dictionary!
                self.JBLog(String(format: "AVAudioSessionRouteChangeNotification received. UserInfo: %@", dict))
                
                self.__handleSessionRouteChangeNotification(note)
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(
            AVAudioSessionInterruptionNotification, object: nil,
            queue: NSOperationQueue.mainQueue()) { (note) -> Void in
                
                let notification: NSNotification = note as NSNotification
                let dict: Dictionary = notification.userInfo as Dictionary!
                self.JBLog(String(format: "AVAudioSessionInterruptionNotification received. UserInfo: %@", dict))
        }
    }
    
    private func __handleSessionRouteChangeNotification(notification: NSNotification) {
        
        // Because userInfo is an optional we need to check it first.
        if let info = notification.userInfo {
            
            let numberReason: NSNumber = info[AVAudioSessionRouteChangeReasonKey] as! NSNumber
            if let reason = AVAudioSessionRouteChangeReason(rawValue: UInt(numberReason.integerValue)) {
                
                switch (reason) {
                    
                case .Unknown:
                    JBLog("AVAudioSessionRouteChangeReason.Unknown!")
                    
                case .CategoryChange:
                    // We don't want infinite loop here
                    break
                    
                case .NewDeviceAvailable:
                    __updateSoundRoute(reason)
                    JBLog("AVAudioSessionRouteChangeReason.NewDeviceAvailable")
                    
                case .OldDeviceUnavailable:
                    __updateSoundRoute(reason)
                    JBLog("AVAudioSessionRouteChangeReason.OldDeviceUnavailable")
                    
                case .Override:
                    __updateSoundRoute(reason)
                    JBLog("AVAudioSessionRouteChangeReason.Override")
                    
                case .RouteConfigurationChange:
                    __updateSoundRoute(reason)
                    JBLog("AVAudioSessionRouteChangeReason.RouteConfigurationChange")
                    
                case .WakeFromSleep:
                    JBLog("AVAudioSessionRouteChangeReason.WakeFromSleep")
                    
                default:
                    break
                }
            }
        }
    }

    //MARK: Setters
    //MARK:
    
    private var currentRoute: JBSoundRoute = JBSoundRoute.Speaker {
    
        didSet {
            
            self.__updateSoundRoute(AVAudioSessionRouteChangeReason.Unknown)
            NSNotificationCenter.defaultCenter().postNotificationName(JBSoundRouterDidChangeRouteNotification, object: nil)
        }
    }
    
    //MARK: Routing
    //MARK:
    
    private func __updateSoundRoute(reason: AVAudioSessionRouteChangeReason) {
        
        if reason == AVAudioSessionRouteChangeReason.NewDeviceAvailable {
            
            if JBSoundRouter.isHeadsetPluggedIn() == true {
                self.currentRoute = JBSoundRoute.Receiver
                return
            }
        }
        else if reason == AVAudioSessionRouteChangeReason.OldDeviceUnavailable {
            
            if JBSoundRouter.isHeadsetPluggedIn() == false {
                self.currentRoute = JBSoundRoute.Speaker
                return
            }
        }
        
        let session: AVAudioSession = AVAudioSession.sharedInstance()
        
        if let route: AVAudioSessionRouteDescription = session.currentRoute {
            let outputs = route.outputs
            if  outputs.count > 0 {
                
                for port in route.outputs {
                    
                    let portDescription: AVAudioSessionPortDescription = port as AVAudioSessionPortDescription
                    JBLog(portDescription.portType)
                    
                    if (self.currentRoute == JBSoundRoute.Receiver && portDescription.portType != AVAudioSessionPortBuiltInReceiver) {
                        
                        // Switch to Receiver
                        do {
                            try session.overrideOutputAudioPort(AVAudioSessionPortOverride.None)
                        } catch let error as NSError {
                            print(error.description)
                        }
                    }
                    else if (self.currentRoute == JBSoundRoute.Speaker && portDescription.portType != AVAudioSessionPortBuiltInSpeaker) {
                        
                        // Switch to Speaker
                        do {
                            try session.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker)
                        } catch let error as NSError {
                            print(error.description)
                        }
                    }
                }
            }
        }
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }
        
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print(error.description)
        }
    }
    
    //MARK: Logging
    //MARK:
    
    func JBLog(message: String, function: String = __FUNCTION__) {
        #if DEBUG
            println("\(function): \(message)")
        #endif
    }
}
