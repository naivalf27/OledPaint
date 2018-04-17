//
//  ViewController.swift
//  Oled
//
//  Created by Flavian Mary on 17/04/2018.
//  Copyright © 2018 Flavian Mary. All rights reserved.
//

import UIKit
import SwiftSocket

class ViewController: UIViewController {
    
    var lastPoint = CGPoint.zero
    var swiped = false

    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var tempImageView: UIImageView!
    
    var listPoint: [CGPoint] = []
    var sentPoint: [CGPoint] = []
    
    let client = UDPClient(address: "127.0.0.1", port: 8888)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        client.send(data: prepareDataForSize(isWidth: true, value: Int(UIScreen.main.bounds.width)))
        client.send(data: prepareDataForSize(isWidth: false, value: Int(UIScreen.main.bounds.height)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clearAction(_ sender: Any) {
        mainImageView.image = nil
        listPoint = []
        sentPoint = []
        
        client.send(data: prepareDataForClearing())
    }
    
    @IBAction func sendAction(_ sender: Any) {
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        let listPoint = self.listPoint
        
        
        print(listPoint)
        
        print("send")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        guard let touch = touches.first else { return }
        lastPoint = touch.location(in: self.view)
        
        addPoint(lastPoint)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self.view)
        drawLine(from: lastPoint, to: currentPoint)
        addPoint(currentPoint)
        lastPoint = currentPoint
    }
    
    func addPoint(_ point: CGPoint) {
        if !listPoint.contains(point) {
            listPoint.append(point)
        }
        
        while listPoint.count - sentPoint.count > 40 {
            sendPoints( );
        }
    }
    
    func sendPoints( ) {
        var pointsToSendNow: [CGPoint] = []
        
        listPoint.forEach { (point) in
            if !sentPoint.contains(point) && pointsToSendNow.count < 50 {
                sentPoint.append(point)
                pointsToSendNow.append(point)
            }
        }
        
        if pointsToSendNow.count > 0 {
            print( "Sending \(pointsToSendNow.count) points" )
            client.send(data: prepareDataForPoints(points: pointsToSendNow))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            drawLine(from: lastPoint, to: lastPoint)
            addPoint(lastPoint)
        }
        
        UIGraphicsBeginImageContext(mainImageView.frame.size)
        mainImageView.image?.draw(
            in: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height),
            blendMode: .normal,
            alpha: 1.0)
        tempImageView.image?.draw(
            in: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height),
            blendMode: .normal,
            alpha: 1.0)
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        tempImageView.image = nil
        
        while listPoint.count - sentPoint.count > 0 {
            sendPoints( );
        }
    }
    
    func drawLine(from: CGPoint, to: CGPoint) {
        UIGraphicsBeginImageContext(view.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        
        context?.move(to: from)
        context?.addLine(to: to)
        
        context?.setLineCap(.round)
        context?.setLineWidth(10.0)
        context?.setStrokeColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context?.setBlendMode(.normal)
        
        context?.strokePath()
        
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func prepareDataForPoints( points: [CGPoint] ) -> Data {
        var data: Data = Data( )
        
        data.append(contentsOf: [0x03])
        data.append(contentsOf: splitToUint8(value: points.count))
        
        points.forEach { (point) in
            data.append(contentsOf: splitToUint8(value: Int(point.x)))
            data.append(contentsOf: splitToUint8(value: Int(point.y)))
        }
        
        return data;
    }
    
    func prepareDataForClearing( ) -> Data {
        var data: Data = Data( )
        data.append(contentsOf: [0x00])
        return data;
    }
    
    func prepareDataForSize( isWidth: Bool, value: Int ) -> Data {
        var data: Data = Data( )
        
        if isWidth == true {
            data.append(contentsOf: [0x01])
        } else {
            data.append(contentsOf: [0x02])
        }
        
        data.append(contentsOf: splitToUint8(value: value))
        
        return data;
    }
    
    func splitToUint8( value: Int ) -> [UInt8] {
        var final: [UInt8] = []
        final.append(UInt8((value&0xFF00)>>8))
        final.append(UInt8(value&0xFF))
        return final
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}
