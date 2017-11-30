//
//  ViewController.swift
//  BLEPeripheralSample
//
//  Created by Hachibe on 2017/11/30.
//  Copyright © 2017年 Masanori. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var peripheralManager: CBPeripheralManager!
    let serviceUUID = CBUUID(string:"0000")
    var characteristic: CBMutableCharacteristic?
    let characteristicUUID = CBUUID(string: "0001")
    let responseData = "ResponseData".data(using: .utf8)!

    @IBOutlet weak var logTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    @IBAction func startAdvertisingButtonDidTouched() {
        let service = CBMutableService(type: serviceUUID, primary: true)
        characteristic = CBMutableCharacteristic(type: characteristicUUID,
                                                 properties: .read,
                                                 value: nil,
                                                 permissions: .readable)
        service.characteristics = [characteristic!]
        peripheralManager.add(service)
        
        let advertisementData: [String: Any] = [CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
                                                CBAdvertisementDataLocalNameKey: UIDevice.current.name]
        peripheralManager.startAdvertising(advertisementData)
    }
    
    @IBAction func stopAdvertisingButtonDidTouched() {
        peripheralManager.removeAllServices()
        peripheralManager.stopAdvertising()
    }
    
    @IBAction func deleteLogButtonTouched() {
        logTextView.text = ""
    }
}

// MARK: - Private Function
private extension ViewController {
    func appendLog(_ text: String) {
        print(text)
        logTextView.isScrollEnabled = false
        logTextView.text.append(text + "\n")
        scrollToButtom()
    }
    
    func appendSubLog(_ text: String) {
        appendLog("  " + text)
    }
    
    func scrollToButtom() {
        logTextView.selectedRange = NSRange(location: logTextView.text.count, length: 0)
        logTextView.isScrollEnabled = true
        
        let scrollY = logTextView.contentSize.height - logTextView.bounds.height
        let scrollPoint = CGPoint(x: 0, y: scrollY > 0 ? scrollY : 0)
        logTextView.setContentOffset(scrollPoint, animated: true)
    }
}

// MARK: - CBPeripheralManagerDelegate
extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        appendLog("Peripheral UpdateState: \(peripheral.state)\n")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        appendLog("Peripheral StartAdvertising")
        guard error == nil else {
            appendSubLog("error: \(String(describing: error))\n")
            return
        }
        appendSubLog("success!!\n")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        appendLog("Peripheral AddService")
        appendSubLog("service: \(service)")
        guard error == nil else {
            appendSubLog("error: \(String(describing: error))\n")
            return
        }
        guard let characteristics = service.characteristics else {
            appendSubLog("no characteristics\n")
            return
        }
        for characteristic in characteristics {
            appendSubLog("properties: \(characteristic.properties)\n")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        appendLog("Peripheral ReceiveRead")
        appendSubLog("request: \(request)\n")
        guard request.characteristic.uuid.isEqual(characteristic?.uuid) else {
            return
        }
        if request.offset > responseData.count {
            peripheralManager.respond(to: request, withResult: .invalidOffset)
            return;
        }
        // プロパティで保持しているキャラクタリスティックへのReadリクエストかどうかを判定
        // CBMutableCharacteristicのvalueをCBATTRequestのvalueにセット
        request.value = responseData.subdata(in: request.offset..<responseData.count)
        
        // リクエストに応答
        peripheralManager.respond(to: request, withResult: .success)
    }
}
