//
//  AppDelegate.swift
//  Menubar2FA
//
//  Created by Leander on 1/4/17.
//  Copyright © 2017 LL International. All rights reserved.
//

import Cocoa
import JavaScriptCore


class OTP {
    
    private var fn:JSValue?
    private var timer:Timer?
    var token:String
    var btn:NSStatusBarButton?
    var secret:String
    
    init () {
        fn = nil
        btn = nil
        timer = nil
        secret = ""
        token = ""
    }
    
    func start() {
        let bundle = Bundle.main
        let path = bundle.path(forResource:"totp", ofType: "js")!
        let jsSource = try? String.init(contentsOfFile: path)
        let context = JSContext()!
        context.evaluateScript(jsSource)
        fn = context.objectForKeyedSubscript("otp")
        timer = nil
        token = ""
        updateTimer()
        initTimer()
    }
    
    func updateTimer () {
        let result = self.fn!.call(withArguments: [self.secret])
        let token = result!.toString()!
        if self.token != token {
            self.token = token
            self.btn!.title = token
        }
    }
    
    func initTimer () {
        self.timer = Timer.new(every: 1.second) {
            self.updateTimer()
        }
        self.timer!.start()
    }
    
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let item = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let otp = OTP()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let btn = item.button!
        btn.target = self
        btn.action = #selector(self.clickedBtn(sender:))
        btn.sendAction(on: [.leftMouseUp, .rightMouseDown])
        otp.btn = btn
        
        let path = "\(NSHomeDirectory())/.menubar-2fa"
        guard let secret = try? String.init(contentsOfFile: path, encoding: String.Encoding.utf8) else {
            btn.title = "Missing file!"
            return
        }
        otp.secret = secret
        otp.start()
    }
    
    func clickedBtn (sender:NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if (event.type == .leftMouseUp) {
            NSPasteboard.general().clearContents();
            NSPasteboard.general().setString(otp.token, forType:NSPasteboardTypeString)
        } else {
            NSApplication.shared().terminate(self)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

