//
//  ViewController.swift
//  Oled
//
//  Created by Flavian Mary on 17/04/2018.
//  Copyright © 2018 Flavian Mary. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var lastPoint = CGPoint.zero
    var swiped = false

    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var tempImageView: UIImageView!
    
    var listPoint: [CGPoint] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clearAction(_ sender: Any) {
        mainImageView.image = nil
        listPoint = []
    }
    
    @IBAction func sendAction(_ sender: Any) {
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        let listPoint = self.listPoint
        
        
        
        
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
}

