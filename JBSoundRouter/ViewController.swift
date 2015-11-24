//
//  ViewController.swift
//  JBSoundRouter
//
//  Created by Josip Bernat on 1/26/15.
//  Copyright (c) 2015 Josip Bernat. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    private var audioPlayer: AVAudioPlayer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let delayTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
            
            let path: String = NSBundle.mainBundle().pathForResource("ringing_voice", ofType: "mp3")!
            let data: NSData = NSData(contentsOfFile: path)!
            
            var player: AVAudioPlayer
            do {
                player = try AVAudioPlayer(data: data)
                player.prepareToPlay()
                player.play()
                
                self.audioPlayer = player
                
                self.onRouteToSpeaker(self)
            } catch let error as NSError {
                print(error.description)
            } catch {
                fatalError()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onRouteToSpeaker(sender: AnyObject) {
    
        JBSoundRouter.routeSound(JBSoundRoute.Speaker)
    }

    @IBAction func onRouteToReceiver(sender: AnyObject) {
    
        JBSoundRouter.routeSound(JBSoundRoute.Receiver)
    }
}

