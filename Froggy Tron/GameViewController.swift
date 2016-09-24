//
//  ViewController.swift
//  Froggy Tron
//
//  Created by Evan Bacon on 9/23/16.
//  Copyright © 2016 Brix. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit

class GameViewController: UIViewController {
    
    var scnView: SCNView {
        get {
            return self.view as! SCNView
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        // Set up the SCNView
        scnView.backgroundColor = UIColor(red: 100.0/255.0, green: 149.0/255.0, blue: 237.0/255.0, alpha: 1.0)
        //    scnView.showsStatistics = true
        scnView.antialiasingMode = SCNAntialiasingMode.multisampling2X
        scnView.overlaySKScene = SKScene(size: view.bounds.size)
        scnView.isPlaying = true
        
        // Set up the scene
        let scene = GameScene(view: scnView)
        scene.rootNode.isHidden = true
        scene.physicsWorld.contactDelegate = scene
        
        // Start playing the scene
        scnView.scene = scene
        scnView.delegate = scene
        scnView.scene!.rootNode.isHidden = false
        scnView.play(self)
    }
    
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
