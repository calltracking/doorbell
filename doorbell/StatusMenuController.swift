//
//  StatusMenuController.swift
//  doorbell
//
//  Created by Jeremy Curcio on 3/23/18.
//  Copyright © 2018 Jeremy Curcio. All rights reserved.
//

import Cocoa
import SwiftWebSocket
import AVFoundation

class StatusMenuController: NSObject, NSUserNotificationCenterDelegate {
  @IBOutlet weak var statusMenu: NSMenu!
  @IBOutlet weak var gotItButton: NSMenuItem!
  @IBOutlet weak var connectDisconnectButton: NSMenuItem!
  
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  let ws = WebSocket("ws://192.168.7.49:3030")
  var player: AVAudioPlayer?
  var dingDong = false
  var connectionOpen = false
  
  func playSound() -> Void {
    guard let url = Bundle.main.url(forResource: "doorbell", withExtension: "mp3") else { return }
    do {
      player = try AVAudioPlayer(contentsOf: url)
      guard let player = player else { return }
      
      player.prepareToPlay()
      player.play()
      print("Play sound")
    } catch let error {
      print(error.localizedDescription)
    }
  }
  
  @objc func clearMenuItem() {
    statusItem.title = "Doorbell"
    gotItButton.isHidden = true
    self.dingDong = false
    NSUserNotificationCenter.default.removeAllDeliveredNotifications()
  }
  
  @IBAction func connectDisconnect(_ sender: Any) {
    if connectionOpen {
      ws.close()
      connectDisconnectButton.title = "Connect"
      connectionOpen = false;
    }
    else {
      ws.open()
      connectDisconnectButton.title = "Disconnect"
      connectionOpen = true;
    }
  }
  
  func doorbellRang(location: String) {
    self.statusItem.title = "DING DONG!"
    self.gotItButton.isHidden = false
    self.dingDong = true;
    self.playSound()
    NSUserNotificationCenter.default.removeAllDeliveredNotifications()
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = formatter.string(from: Date())
    
    var loc = location.replacingOccurrences(of: "-", with: " ")
    loc = loc.capitalized
    
    let notification = NSUserNotification()
    notification.identifier = dateString
    notification.title = "Doorbell Rang"
    notification.informativeText = "Location: \(loc)"
    notification.hasActionButton = true
    notification.actionButtonTitle = "I got it!"
    NSUserNotificationCenter.default.deliver(notification)
  }
  
  func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
    self.ws.send("GOT IT")
    clearMenuItem()
  }

  func reconnect() {
    ws.open()
  }
  
  override func awakeFromNib() {
    NSUserNotificationCenter.default.delegate = self
    
    statusItem.title = "Doorbell"
    statusItem.menu = statusMenu
    // Insert code here to initialize your application
    print("Load")
    
    ws.event.open = {
      print("opened")
      self.connectionOpen = true;
    }
    ws.event.close = { code, reason, clean in
      print(reason)
      self.connectionOpen = false;
      print("close")
      if reason != "Normal Closure" {
        self.reconnect()
      }
    }
    ws.event.error = { error in
      print("error \(error)")
    }
    ws.event.message = { message in
      print(message)
      
      var msg = [String : AnyObject]()
      msg = self.convertStringToDictionary(text: message as! String)!
      let type = msg["type"]!

      print(type)
      
      if (type as! String == "button pressed") {
        if (!self.dingDong) {
          self.doorbellRang(location: msg["location"] as! String)
        }
      }
      else if (type as! String == "got it") {
        self.clearMenuItem()
      }
    }
  }
  
  func convertStringToDictionary(text: String) -> [String:AnyObject]? {
    if let data = text.data(using: String.Encoding.utf8) {
      do {
        return try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
      } catch let error as NSError {
        print(error)
      }
    }
    return nil
  }
  
  @IBAction func quitClicked(_ sender: NSMenuItem) {
    NSApplication.shared.terminate(self)
  }
  
  @IBAction func iGotItClicked(_ sender: NSMenuItem) {
    self.ws.send("GOT IT")
    clearMenuItem()
  }
}
