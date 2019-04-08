//
//  PhilipsHueViewController.swift
//  NExT
//
//  Created by Casten on 2019/4/5.
//  Copyright © 2019 Dinsafer. All rights reserved.
//

import UIKit

struct PHConstants {
    static let PHMaxHue = 65535
    static let PHMaxBri = 254
    static let PHMaxBri2 = 253
}

class PhilipsHueViewController: DSViewController {
    
    let bridgeDiscovery = PHSBridgeDiscovery()
    var bridge: PHSBridge?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let btn = UIButton(type: .system)
        btn.frame = CGRect(x: 0, y: 100, width: 100, height: 50)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.centerX = view.centerX
        btn.setTitle("Connect", for: .normal)
        btn.addTarget(self, action: #selector(connect), for: .touchUpInside)
        view.addSubview(btn)
        
        let btn1 = UIButton(type: .system)
        btn1.frame = CGRect(x: 0, y: 200, width: 100, height: 50)
        btn1.setTitleColor(UIColor.white, for: .normal)
        btn1.centerX = view.centerX
        btn1.setTitle("Random Color", for: .normal)
        btn1.addTarget(self, action: #selector(RandomColor), for: .touchUpInside)
        view.addSubview(btn1)
        
        // 搜索Hub
        let options = PHSBridgeDiscoveryOption.discoveryOptionUPNP;
        bridgeDiscovery.search(options) { [weak self ] (results, returnCode) in
            if results != nil && results!.count > 0 {
                dlog(results!)
                // 创建Bridge
                let foundBridges:[PHBridgeInfo] = results!.map({ (key, value) in PHBridgeInfo(withDiscoveryResult: value) })
                let info = foundBridges[0]
                self?.bridge = PHSBridge.init(block: { (builder) in
                    builder?.connectionTypes = .local
                    builder?.ipAddress = info.ipAddress
                    builder?.bridgeID  = info.uniqueId
                    builder?.bridgeConnectionObserver = self
                    builder?.add(self)
                }, withAppName: "test", withDeviceName: "test")
            }
            
        }
    }
    
    
    @objc private func connect() {
        bridge?.connect()
    }
    
    @objc private func RandomColor() {
        // 获取灯
        if let lights = bridge?.bridgeState.getDevicesOf(PHSDomainType.light) as? [PHSDevice] {
            dlog(lights)
            if lights.count > 0 {
                // 设置第一个灯的颜色
                if let lightPoint = lights[0] as? PHSLightPoint {
                    let lightState:PHSLightState = self.lightStateWithRandomColors()
                    lightPoint.update(lightState, allowedConnectionTypes: .local, completionHandler: { (responses, errors, returnCode) in
                        
                    })
                }
            }
        }
        
    }
    
    func lightStateWithRandomColors() -> PHSLightState {
        let lightState:PHSLightState = PHSLightState()
        
        lightState.on = true
        lightState.hue = Int(arc4random_uniform(UInt32(PHConstants.PHMaxHue))) as NSNumber
        lightState.brightness = Int(arc4random_uniform(UInt32(PHConstants.PHMaxBri))) as NSNumber
        
        return lightState
    }
}

extension PhilipsHueViewController: PHSBridgeStateUpdateObserver {
    func bridge(_ bridge: PHSBridge!, handle updateEvent: PHSBridgeStateUpdatedEvent) {
        if updateEvent == PHSBridgeStateUpdatedEvent.initialized {
            if let connection:PHSBridgeConnection = bridge.bridgeConnections().first {
                connection.heartbeatManager.startHeartbeat(with:.fullConfig, interval: 10)
            }
            dlog("PHSBridgeStateUpdatedEvent.initialized")
            // 真正成功，可以获取灯
        }
    }
}

extension PhilipsHueViewController: PHSBridgeConnectionObserver {
    func bridgeConnection(_ bridgeConnection: PHSBridgeConnection!, handle connectionEvent: PHSBridgeConnectionEvent) {
        
        switch connectionEvent {
        case .couldNotConnect:
            dlog("bridgeConnection : couldNotConnect")
            
        case .connected:
            dlog("bridgeConnection : connected")
            
        case .connectionLost:
            dlog("bridgeConnection : connectionLost")
            
        case .connectionRestored:
            dlog("bridgeConnection : connectionRestored")
            
        case .disconnected:
            dlog("bridgeConnection : disconnected")
            
        case .notAuthenticated:
            dlog("bridgeConnection : notAuthenticated")
            
        case .linkButtonNotPressed: // 第一次，提示用户按Hub上的按钮
            dlog("bridgeConnection : linkButtonNotPressed")
            
        case .authenticated:
            dlog("bridgeConnection : authenticated")
            
        default:
            dlog("bridgeConnection : unknow")
        }
    }
    
    func bridgeConnection(_ bridgeConnection: PHSBridgeConnection!, handleErrors connectionErrors: [PHSError]!) {
        
    }
    
    
}
