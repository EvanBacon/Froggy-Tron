//
//  GameScene.swift
//  Crossy Road
//
//  Created by Evan Bacon on 02/20/15.
//  Copyright (c) 2015 brix. All rights reserved.
//

import SceneKit
import SpriteKit


class GameScene : SCNScene, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, GameLevelSpawnDelegate {
    
    // MARK: Properties
    var sceneView: SCNView!
    var gameState = GameState.waitingForFirstTap
    
    var camera: SCNNode!
    var cameraOrthographicScale = 1.0
    
    //  var cameraOrthographicScale = 0.5
    //  var cameraOffsetFromPlayer = SCNVector3(x: 0.25, y: 1.25, z: 0.55)
    var cameraOffsetFromPlayer = SCNVector3(x: 0.25, y: 5.0, z: 2.0)
    
    var cameraRoomBuffer = CGFloat()
    
    var cameraRatio = CGFloat()
    var minDist = CGPoint()
    var maxDist = CGPoint()
    var levelData: GameLevel!
    //  var levelWidth: Int = 19
    //  var levelHeight: Int = 50
    var levelWidth: Int = 30
    var levelHeight: Int = 25
    
    var won: Bool!
    var player: SCNNode!
    let playerScene = SCNScene(named: "assets.scnassets/Models/frog.dae")
    var playerGridCol = 7 + 15
    var playerGridRow = 6 + 13
    var playerChildNode: SCNNode!
    
    let carScene = SCNScene(named: "assets.scnassets/Models/car.dae")
    
    var counterLabel: CounterNode!
    
    var curDirection: MoveDirection!
    var lastTile = CGPoint()
    var enemy = SCNNode()
    
    
    
    //  var enemyAi: Enemy!
    
    var enemyArray = NSMutableArray()
    // MARK: Init
    init(view: SCNView) {
        
        
        sceneView = view
        super.init()
        initializeLevel()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func initializeLevel() {
        
        if UserDefaults.standard.integer(forKey: "level") < 1 {
            UserDefaults.standard.set(2, forKey: "level")
            UserDefaults.standard.synchronize()
        }
        self.sceneView.backgroundColor = UIColor.gray
        cameraRatio = CGFloat(UIScreen.main.bounds.size.height / UIScreen.main.bounds.size.width)
        cameraRoomBuffer = 3.0
        enemyArray = NSMutableArray()
        setupGestureRecognizersForView(sceneView)
        setupLevel()
        setupPlayer()
        setupEnemy()
        
        setupCamera()
        setupLights()

        switchToWaitingForFirstTap()
    }
    
    
    
    func setupPlayer() {
        curDirection = .forward
        player = SCNNode()
        player.name = "Player"
        player.position = levelData.frogCoordinatesForGridPosition(column: playerGridCol, row: playerGridRow)
        player.position.y = 0.0
        
        player.castsShadow = true
        let playerMaterial = SCNMaterial()
        playerMaterial.diffuse.contents = UIImage(named: "assets.scnassets/Textures/model_texture.tga")
        playerMaterial.locksAmbientWithDiffuse = false
        
        playerChildNode = playerScene!.rootNode.childNode(withName: "Frog", recursively: false)!
        playerChildNode.geometry!.firstMaterial = playerMaterial
        playerChildNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.075)

        playerChildNode.castsShadow = true
        player.addChildNode(playerChildNode)
        
        // Create a physicsbody for collision detection
        let playerPhysicsBodyShape = SCNPhysicsShape(geometry: SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0.0), options: nil)
        
        playerChildNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: playerPhysicsBodyShape)
        playerChildNode.physicsBody!.categoryBitMask = PhysicsCategory.Player
        playerChildNode.physicsBody!.collisionBitMask = PhysicsCategory.Car
        
        rootNode.addChildNode(player)
    }
    
    func setupEnemy() {
        let random = Int(arc4random_uniform(UInt32(5))) + 1
        //        var random = 5
        
        //        var random = 1
        
        //        var random = NSUserDefaults.standardUserDefaults().integerForKey("level")
        for i in 0 ..< random {
            let enemyAi = Enemy(level: levelData)
            
            let randPoint = CGPoint(x: CGFloat(Int(arc4random_uniform(UInt32(levelWidth - 4)) + 2)) + CGFloat(levelWidth/2),y: CGFloat(Int(arc4random_uniform(UInt32(levelHeight - 4)) + 2))  + CGFloat(levelHeight/2) )
            var r = Int(levelData.data.rowCount() / random)
            //            var q = round(Float((i + 1) * 2))
            //            var randPoint = CGPointMake(CGFloat(Int(arc4random_uniform(2) + 1) * i),CGFloat(Int(arc4random_uniform(10) + 10)))
            rootNode.addChildNode(enemyAi.makeNode(randPoint))
            enemyArray.add(enemyAi)
        }
        setupCounter()
    }
    
    func setupCamera() {
        camera = SCNNode()
        camera.name = "Camera"
        camera.position = cameraOffsetFromPlayer
        camera.camera = SCNCamera()
        camera.camera!.usesOrthographicProjection = true
        camera.camera!.orthographicScale = cameraOrthographicScale
//        camera.camera!.zNear = 0.05
//        camera.camera!.zFar = 150.0
        
        camera.camera?.automaticallyAdjustsZRange = true
        player.addChildNode(camera)
        
        //    var node = rootNode.childNodeWithName("level", recursively: false)
        ////    camera.position = SCNVector3Make(player.presentationNode().position.x + cameraOffsetFromPlayer.x, player.presentationNode().position.y + cameraOffsetFromPlayer.y, player.presentationNode().position.z + cameraOffsetFromPlayer.z)
        //    player.addChildNode(camera)
        
        //    let allCharacters = NSMutableArray()
        //    allCharacters.addObject(SCNLookAtConstraint(target: player))
        //    for object in enemyArray {
        //        if let enemy = object as? Enemy {
        //            if (enemy.dead == false){
        //                allCharacters.addObject(SCNLookAtConstraint(target: enemy.enemy))
        //            }
        //        }
        //    }
        
        
        //    camera.constraints = NSArray(array: allCharacters) as? [SCNConstraint]
        
        

//        sceneView.allowsCameraControl = true
        camera.constraints = [SCNLookAtConstraint(target: player)]
    }
    
    
    func setupLevel() {
        maxDist = CGPoint(x: -1, y: -1)
        minDist = CGPoint(x: CGFloat(levelWidth + 1), y: CGFloat(levelHeight + 1))
        
        won = false
        levelData = GameLevel(width: levelWidth, height: levelHeight)
        levelData.setupLevelAtPosition(SCNVector3Zero, parentNode: rootNode)
        levelData.spawnDelegate = self
    }
    
    
    func setupGestureRecognizersForView(_ view: SCNView) {
        // Create tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GameScene.handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        
        // Create swipe gesture recognizers
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.handleSwipe(_:)))
        swipeUpGesture.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(swipeUpGesture)
        
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.handleSwipe(_:)))
        swipeDownGesture.direction = UISwipeGestureRecognizerDirection.down
        view.addGestureRecognizer(swipeDownGesture)
        
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.handleSwipe(_:)))
        swipeLeftGesture.direction = UISwipeGestureRecognizerDirection.left
        view.addGestureRecognizer(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.handleSwipe(_:)))
        swipeRightGesture.direction = UISwipeGestureRecognizerDirection.right
        view.addGestureRecognizer(swipeRightGesture)
    }
    
    
    func centerNodeOnPosition(_ node: SCNNode) -> SCNVector3 {
        
        var minVec = SCNVector3Zero
        var maxVec = SCNVector3Zero
        if node.__getBoundingBoxMin(&minVec, max: &maxVec) {
            let bound = SCNVector3(
                
                x: maxVec.x - minVec.x,
                y: maxVec.y - minVec.y,
                z: maxVec.z - minVec.z)
            
            
            let center = SCNVector3(
                x: minVec.x + (bound.x/2),
                y: minVec.y + (bound.y/2),
                z: minVec.z + (bound.z/2))
            
            return center

        }

        return SCNVector3Zero
    }
    
    func leftPositonOfNode(_ node: SCNNode) -> SCNVector3 {
        
        var minVec = SCNVector3Zero
        var maxVec = SCNVector3Zero
        if node.__getBoundingBoxMin(&minVec, max: &maxVec) {
            let bound = SCNVector3(
                
                x: maxVec.x - minVec.x,
                y: maxVec.y - minVec.y,
                z: maxVec.z - minVec.z)
            
            
            let center = SCNVector3(
                x: minVec.x,
                y: minVec.y + (bound.y/2),
                z: minVec.z + (bound.z/2))
            
            print("found ", center)
            
            return center
            //            node.pivot = SCNMatrix4MakeTranslation(bound.x / 2, bound.y / 2, bound.z / 2)
        }
        print("didnt")
        
        return SCNVector3Zero
    }

    
    func getMap() -> SCNNode {
        return rootNode.childNode(withName: "level", recursively: false)!
    }
    
    var spotLightNode:SCNNode!
    func setupLights() {

        
        // Create ambient light
        let spotLight = SCNLight()
        spotLight.type = SCNLight.LightType.spot
        spotLight.color = UIColor.white

        spotLight.castsShadow = true
//        spotLight.shadowMode = SCNShadowMode.Deferred
//        spotLight.shadowRadius = 1.0
         spotLightNode = SCNNode()
        spotLightNode.name = "SpotLight"
        spotLightNode.light = spotLight
        spotLightNode.castsShadow = true

        spotLight.spotInnerAngle = 180
                spotLight.spotOuterAngle = 180
        spotLight.shadowRadius = 0
        spotLightNode.constraints = [SCNLookAtConstraint(target: player)]
        rootNode.addChildNode(spotLightNode)
        
        
        let map = getMap()

//        let map = levelData.mapNode.presentationNode
        
        var pos = leftPositonOfNode(map)
        pos.x -= 1
        pos.y += 2

        spotLightNode.position = pos

        
//        let box = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
//        
//        box.position = pos
//        rootNode.addChildNode(box)
        
        
//        // Create an omni-directional light
        let omniLight = SCNLight()
        omniLight.type = SCNLight.LightType.omni
        omniLight.color = UIColor.white.withAlphaComponent(0.5)
        let omniLightNode = SCNNode()
        omniLightNode.name = "OmniLight"
        omniLightNode.light = omniLight
        //        omniLightNode.light?.castsShadow = true
        
        var center =  centerNodeOnPosition(map)
        center.y += 1
        
        
        omniLightNode.position = center
        rootNode.addChildNode(omniLightNode)

        
//        // Create ambient light
        let ambientLight = SCNLight()
        ambientLight.type = SCNLight.LightType.ambient
        ambientLight.color = UIColor.white
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "AmbientLight"
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)
//
//        // Create an omni-directional light
//        let omniLight = SCNLight()
//        omniLight.type = SCNLightTypeOmni
//        omniLight.color = UIColor.whiteColor()
//        let omniLightNode = SCNNode()
//        omniLightNode.name = "OmniLight"
//        omniLightNode.light = omniLight
////        omniLightNode.light?.castsShadow = true
//        omniLightNode.position = SCNVector3(x: -10.0, y: 20, z: 10.0)
//        rootNode.addChildNode(omniLightNode)
        
    }
    
    
    // MARK: Game State
    func switchToWaitingForFirstTap() {
        
        gameState = GameState.waitingForFirstTap
        
        // Fade in
        if let overlay = sceneView.overlaySKScene {
            overlay.enumerateChildNodes(withName: "RestartLevel", using: { node, stop in
                node.run(SKAction.sequence(
                    [SKAction.fadeOut(withDuration: 0.5),
                        SKAction.removeFromParent()]))
            })
            
            
            // Tap to play animation icon
            let handNode = HandNode()
            handNode.position = CGPoint(x: sceneView.bounds.size.width * 0.5, y: sceneView.bounds.size.height * 0.2)
            overlay.addChild(handNode)
        }
    }
    
    func setupCounter() {
        if let overlay = sceneView.overlaySKScene {
            overlay.enumerateChildNodes(withName: "counter", using: { node, stop in
                node.run(SKAction.sequence(
                    [SKAction.fadeOut(withDuration: 0.5),
                        SKAction.removeFromParent()]))
            })
            counterLabel = CounterNode(
                position: CGPoint(x: overlay.size.width/8.0, y: overlay.size.height/8.0),
                size: 24, color: .blue,
                text: "x\(enemyArray.count)",
                name: "counter")
            overlay.addChild(counterLabel)
        }
        
    }
    
    
    func switchToPlaying() {
        
        gameState = GameState.playing
        
        if let overlay = sceneView.overlaySKScene {
            // Remove tutorial
            overlay.enumerateChildNodes(withName: "Tutorial", using: { node, stop in
                node.run(SKAction.sequence(
                    [SKAction.fadeOut(withDuration: 0.25),
                        SKAction.removeFromParent()]))
            })
            
            
        }
        var timer = Timer.scheduledTimer(timeInterval: 0.6, target: self, selector: #selector(GameScene.update), userInfo: nil, repeats: true)
    }
    
    func update() {
        movePlayerInDirection(curDirection)
    }
    
    func switchToGameOver() {
        
        gameState = GameState.gameOver
        
        if let overlay = sceneView.overlaySKScene {
            var gameOverLabel: LabelNode!
            if won == true {
                //            if score > NSUserDefaults.standardUserDefaults().integerForKey("level") {
                UserDefaults.standard.set(Int(UserDefaults.standard.integer(forKey: "level")) + 1, forKey: "level")
                UserDefaults.standard.synchronize()
                //            }
                
                gameOverLabel = LabelNode(
                    position: CGPoint(x: overlay.size.width/2.0, y: overlay.size.height/2.0),
                    size: 24, color: .green,
                    text: "You Won!",
                    name: "GameOver")
            }
            else{
                if Int(UserDefaults.standard.integer(forKey: "level")) > 1 {
                    UserDefaults.standard.set(Int(UserDefaults.standard.integer(forKey: "level")) - 1, forKey: "level")
                    UserDefaults.standard.synchronize()
                    
                }
                gameOverLabel = LabelNode(
                    position: CGPoint(x: overlay.size.width/2.0, y: overlay.size.height/2.0),
                    size: 24, color: .red,
                    text: "Game Over",
                    name: "GameOver")
                
            }
            overlay.addChild(gameOverLabel)
            
            let clickToRestartLabel = LabelNode(
                position: CGPoint(x: gameOverLabel.position.x, y: gameOverLabel.position.y - 24.0),
                size: 14,
                color: .white,
                text: "Tap to restart",
                name: "GameOver")
            
            overlay.addChild(clickToRestartLabel)
        }
        physicsWorld.contactDelegate = nil
    }
    
    
    func switchToRestartLevel() {
        
        gameState = GameState.restartLevel
        if let overlay = sceneView.overlaySKScene {
            
            // Fade out game over screen
            overlay.enumerateChildNodes(withName: "GameOver", using: { node, stop in
                node.run(SKAction.sequence(
                    [SKAction.fadeOut(withDuration: 0.25),
                        SKAction.removeFromParent()]))
            })
            
            // Fade to black - and create a new level to play
            let blackNode = SKSpriteNode(color: UIColor.black, size: overlay.frame.size)
            blackNode.name = "RestartLevel"
            blackNode.alpha = 0.0
            blackNode.position = CGPoint(x: sceneView.bounds.size.width/2.0, y: sceneView.bounds.size.height/2.0)
            overlay.addChild(blackNode)
            blackNode.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.5), SKAction.run({
                let newScene = GameScene(view: self.sceneView)
                newScene.physicsWorld.contactDelegate = newScene
                self.sceneView.scene = newScene
                self.sceneView.delegate = newScene
            })]))
        }
    }
    
    
    // MARK: Delegates
    func renderer(_ aRenderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        //    if gameState == GameState.Playing && (playerGridRow == levelData.data.rowCount() - 6 || enemyArray.count == 0) {
        // player completed the level
        if gameState == GameState.playing && (enemyArray.count == 0) {
            won = true
            
            switchToGameOver()
        }
    }
    
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if gameState == GameState.playing {
            switchToGameOver()
        }
    }
    
    
    func spawnCarAtPosition(_ position: SCNVector3) {
        
        // Create a material using the model_texture.tga image
        let carMaterial = SCNMaterial()
        carMaterial.diffuse.contents = UIImage(named: "assets.scnassets/Textures/model_texture.tga")
        carMaterial.locksAmbientWithDiffuse = false
        
        // Create a clone of the Car node of the carScene - you need a clone because you need to add many cars
        let carNode = carScene!.rootNode.childNode(withName: "Car", recursively: false)!.clone() as SCNNode
        
        carNode.name = "Car"
        
        carNode.position = position
        
        // Set the material
        carNode.geometry!.firstMaterial = carMaterial
        
        // Create a physicsbody for collision detection
        let carPhysicsBodyShape = SCNPhysicsShape(geometry: SCNBox(width: 0.30, height: 0.20, length: 0.16, chamferRadius: 0.0), options: nil)
        
        carNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: carPhysicsBodyShape)
        carNode.physicsBody!.categoryBitMask = PhysicsCategory.Car
        carNode.physicsBody!.collisionBitMask = PhysicsCategory.Player
        
        rootNode.addChildNode(carNode)
        
        
        
        // Move the car
        let moveDirection: Float = position.x > 0.0 ? -1.0 : 1.0
        let moveDistance = levelData.gameLevelWidth()
        let moveAction = SCNAction.move(by: SCNVector3(x: moveDistance * moveDirection, y: 0.0, z: 0.0), duration: 10.0)
        let removeAction = SCNAction.run { node -> Void in
            node.removeFromParentNode()
        }
        carNode.runAction(SCNAction.sequence([moveAction, removeAction]))
        
        // Rotate the car to move it in the right direction
        if moveDirection > 0.0 {
            carNode.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: 3.1415)
        }
    }
    
    
    // MARK: Touch Handling
    func handleTap(_ gesture: UIGestureRecognizer) {
        if let tapGesture = gesture as? UITapGestureRecognizer {
            //      movePlayerInDirection(.Forward)
            movePlayerInDirection(curDirection)
        }
    }
    
    
    func handleSwipe(_ gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.up:
                curDirection = .forward
                
                
                //        let dest = CGFloat(0)
                //        if (player.eulerAngles.y != Float(dest)) {
                //            player.runAction(SCNAction.rotateByX(0, y: dest, z: 0, duration: 1))
                //        }
                
                //        movePlayerInDirection(.Forward)
                break
                
            case UISwipeGestureRecognizerDirection.down:
                curDirection = .backward
                
                
                //        if (player.eulerAngles.y != Float(M_PI)) {
                //            player.runAction(SCNAction.rotateByX(0, y: CGFloat(M_PI), z: 0, duration: 1))
                //        }
                //        player.eulerAngles.y = Float(M_PI)
                //        movePlayerInDirection(.Backward)
                break
                
            case UISwipeGestureRecognizerDirection.left:
                curDirection = .left
                
                //        movePlayerInDirection(.Left)
                break
                
            case UISwipeGestureRecognizerDirection.right:
                curDirection = .right
                
                //        movePlayerInDirection(.Right)
                break
                
            default:
                break
            }
            movePlayerInDirection(curDirection)
        }
    }
    
    
    // MARK: Player movement
    func movePlayerInDirection(_ direction: MoveDirection) {
        
        switch gameState {
        case .waitingForFirstTap:
            
            // Start playing
            switchToPlaying()
            movePlayerInDirection(direction)
            
            break
            
        case .playing:
            // 1 - Check for player movement
            
            let gridColumnAndRowAfterMove = levelData.gridColumnAndRowAfterMoveInDirection(direction, currentGridColumn: playerGridCol, currentGridRow: playerGridRow)
            
            if gridColumnAndRowAfterMove.didMove == false {
                //        maxDist = CGPointMake(-1, -1)
                //        minDist = CGPointMake(CGFloat(levelWidth + 1), CGFloat(levelHeight + 1))
                
                return
            }
            maxDist = CGPoint(x: -1, y: -1)
            minDist = CGPoint(x: CGFloat(levelWidth + 1), y: CGFloat(levelHeight + 1))
            
            
            //Sink Tiles
            sinkTile(CGPoint(x: CGFloat(playerGridCol), y: CGFloat(playerGridRow)), color: UIColor.cyan)
            
            
            
            
            //Update Positions
            playerGridCol = gridColumnAndRowAfterMove.newGridColumn
            playerGridRow = gridColumnAndRowAfterMove.newGridRow
            
            changeTileAvalibility(CGPoint(x: CGFloat(playerGridCol), y: CGFloat(playerGridRow)))
            
            //Calculate the coordinates for the player after the move
            let jumpUpAction = SCNAction.move(by: SCNVector3(x: 0.0, y: 0.2, z: 0.0), duration: 0.1)
            jumpUpAction.timingMode = SCNActionTimingMode.easeOut
            let jumpDownAction = SCNAction.move(by: SCNVector3(x: 0.0, y: -0.2, z: 0.0), duration: 0.1)
            jumpDownAction.timingMode = SCNActionTimingMode.easeIn
            let jumpAction = SCNAction.sequence([jumpUpAction, jumpDownAction])
            
            //Move Enemies
            
            for object in enemyArray {
                if let enemy = object as? Enemy {
                    if (enemy.dead == false){
                        sinkTile(enemy.computerHeadPositon, color: enemy.trailColor)
                        enemy.move()
                        
                        enemy.enemy.runAction(makeMoveAction(Int(enemy.computerHeadPositon.x), row: Int(enemy.computerHeadPositon.y)))
                        enemy.enemy.runAction(jumpAction, completionHandler: {(Bool)  in
                            if  (enemy.checkIfBoxedIn(Int(enemy.computerHeadPositon.x), posY: Int(enemy.computerHeadPositon.y))){
                                enemy.explode()
                                self.enemyArray.remove(object)
                                self.counterLabel.text = "x\(self.enemyArray.count)"
                            }
                        })
                        
                        testForBounds(CGPoint(x: CGFloat(enemy.computerHeadPositon.x), y: CGFloat(enemy.computerHeadPositon.y)))
                    }
                }
            }
            
            
            //Run Actions
            player.runAction(makeMoveAction(playerGridCol, row: playerGridRow))
            playerChildNode.runAction(jumpAction, completionHandler: {(Bool)  in
                if  (self.checkIfBoxedIn(self.playerGridCol, posY: self.playerGridRow)){
                    self.switchToGameOver()
                }
            })
            testForBounds(CGPoint(x: CGFloat(playerGridCol), y: CGFloat(playerGridRow)))
            
            
     
            var node = rootNode.childNode(withName: "level", recursively: false)
            
            
            //      var middle = CGPointMake(round(((maxDist.x - minDist.x)/2 ) + CGFloat(playerGridCol)) , round(((maxDist.y - minDist.y)/2 ) + CGFloat(playerGridCol)))
            
            let middle = CGPoint(x: round(maxDist.x - minDist.x) + cameraRoomBuffer, y: round(maxDist.y - minDist.y))
            
            
            //      var middle = CGPointMake(round(((maxDist.x - minDist.x)/2 ) + minDist.x) , round(((maxDist.y - minDist.y)/2 ) + minDist.y ))
            //      var tile = node?.childNodeWithName("\(Int(middle.x)) \(Int(middle.y))", recursively: false)
            
            //      println("\(minDist) \(maxDist) \(middle)")
            
            
            let cameraMinimumScale = CGFloat(7)
            
            var newScale = CGFloat()
            if middle.x > middle.y {
                newScale = middle.x
                if newScale < cameraMinimumScale {
                    newScale = cameraMinimumScale
                }
                newScale *= 2
                
            }
            else {
                newScale = middle.y
                
                if newScale < cameraMinimumScale {
                    newScale = cameraMinimumScale
                }
                newScale *= cameraRatio
                
                //Fix
                
                //            if (CGFloat(playerGridRow) - (newScale / 2)) < 0 {
                //                var tile = node?.childNodeWithName("\(Int(middle.x)) \( Int(round((newScale/2) + CGFloat(playerGridRow))))", recursively: false)
                //                camera.constraints = [SCNLookAtConstraint(target: tile!)]
                //                println("HERE")
                //            }
                //        else if (CGFloat(playerGridRow) + (newScale / 2)) > CGFloat(levelHeight) {
                //            var tile = node?.childNodeWithName("\(Int(middle.x)) \( Int(CGFloat(playerGridRow) - round(newScale/2)))", recursively: false)
                //            camera.constraints = [SCNLookAtConstraint(target: tile!)]
                //            println("HERE")
                //        }
                //            else {
                //                camera.constraints = [SCNLookAtConstraint(target: player)]
                //
                //        }
                
            }
            

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
//            camera.camera!.orthographicScale = Double(newScale / 10)
            

            

            spotLightNode.position.z = player.position.z
            spotLightNode.position.x = player.position.x - 1
            spotLightNode.position.y = player.position.y + 1

            
            SCNTransaction.commit()
            
            break
            
        case .gameOver:
            // Switch to tutorial
            switchToRestartLevel()
            break
            
        case .restartLevel:
            // Switch to new level
            switchToWaitingForFirstTap()
            break
        }
    }
    
    func testForBounds(_ position: CGPoint) {
        if position.y <= minDist.y {
            minDist.y = position.y
        }
        if position.x <= minDist.x {
            minDist.x = position.x
        }
        if position.y >= maxDist.y {
            maxDist.y = position.y
        }
        if position.x >= maxDist.x {
            maxDist.x = position.x
        }
    }
    
    func makeMoveAction(_ column: Int, row: Int) -> SCNAction {
        let pos = levelData.frogCoordinatesForGridPosition(column: Int(column), row: Int(row))
        changeTileAvalibility(CGPoint(x: CGFloat(column), y: CGFloat(row)))
        
        return SCNAction.move(to: pos, duration: 0.2)
    }
    
    func changeTileAvalibility(_ tile: CGPoint){
        levelData.data[Int(tile.x),Int(tile.y)] = GameLevel.GameLevelDataType.obstacle.rawValue
    }
    
    func checkIfBoxedIn(_ posX: Int,posY: Int) -> Bool {
        return (checkCollsion(posX + 1, posY: posY) && checkCollsion(posX - 1, posY: posY) && checkCollsion(posX, posY: posY + 1) && checkCollsion(posX, posY: posY - 1));
    }
    
    func checkCollsion(_ posX: Int,posY: Int ) -> Bool {
        let num = grid.gameLevelDataTypeForGridPosition(column: posX, row: posY)
        return (num == GameLevel.GameLevelDataType.obstacle || (num == GameLevel.GameLevelDataType.invalid))
    }
    
    func sinkTile(_ position: CGPoint, color: UIColor){
        changeTileAvalibility(position)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.locksAmbientWithDiffuse = false
        
        let node = rootNode.childNode(withName: "level", recursively: false)
        
        let tile = node?.childNode(withName: "\(Int(position.x)) \(Int(position.y))", recursively: false)
        tile?.geometry?.firstMaterial = mat
        
        let jumpUpAction = SCNAction.move(by: SCNVector3(x: 0.0, y: 0.1, z: 0.0), duration: 0.1)
        jumpUpAction.timingMode = SCNActionTimingMode.easeOut
        let jumpDownAction = SCNAction.move(by: SCNVector3(x: 0.0, y: -0.3, z: 0.0), duration: 0.2)
        jumpDownAction.timingMode = SCNActionTimingMode.easeIn
        let jumpAction = SCNAction.sequence([jumpUpAction, jumpDownAction])
        
        tile?.runAction(jumpAction, completionHandler: {(Bool)  in
            self.boilAction(tile!)
        })
    }
    
    func boilAction(_ tile: SCNNode) {
        let random = Float(drand48().truncatingRemainder(dividingBy: 0.05))
        let jumpUpAction = SCNAction.move(by: SCNVector3(x: 0.0, y: random, z: 0.0), duration: 0.5)
        jumpUpAction.timingMode = SCNActionTimingMode.easeOut
        let jumpDownAction = SCNAction.move(by: SCNVector3(x: 0.0, y: -random, z: 0.0), duration: 0.5)
        jumpDownAction.timingMode = SCNActionTimingMode.easeIn
        tile.runAction(SCNAction.repeatForever(SCNAction.sequence([jumpUpAction, jumpDownAction])))
        
        let material = tile.geometry!.firstMaterial!
        
        
        let spotColor = CAKeyframeAnimation(keyPath: "color")
        
        let colors = NSMutableArray()
        colors.add(lighterColorForColor(material.diffuse.contents as! UIColor))
        colors.add(material.diffuse.contents as! UIColor)
        colors.add(darkerColorForColor(material.diffuse.contents as! UIColor))
        
        
        //        colors.addObject(UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        //        colors.addObject(UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0))
        //
        //        colors.addObject(UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        
        
        //        for (var i = 0; i < 3; i++){
        //            colors.addObject(varyColor(material.diffuse.contents as UIColor, distance: 0.3))
        //        }
        colors.add(colors.firstObject!)
        
        spotColor.values = colors as [AnyObject]
        spotColor.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        spotColor.repeatCount = Float(INT32_MAX)
        spotColor.duration = 5.0
        
        material.addAnimation(spotColor, forKey: "ChangeTheColorOfTheSpot")
    }
    
    
    func lighterColorForColor(_ c: UIColor) -> UIColor {
        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        
        if c.getHue(&r, saturation: &g, brightness: &b, alpha: &a){
            return UIColor(hue: r, saturation: g, brightness: min(b * 1.3, 1.0), alpha: a)
        }
        return c;
    }
    
    func darkerColorForColor(_ c: UIColor) -> UIColor {
        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        
        if c.getHue(&r, saturation: &g, brightness: &b, alpha: &a){
            return UIColor(hue: r, saturation: g, brightness: b * 0.75, alpha: a)
        }
        return c;
    }
    
    
    
    
    func varyColor( _ baseColor:UIColor, distance:CGFloat ) -> UIColor {
        
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        
        //        baseColor.getRed( &red, green: &green, blue: &blue, alpha: nil )
        baseColor.getHue(&red, saturation: &green, brightness: &blue, alpha: nil)
        
        let randomRed: CGFloat = CGFloat( drand48() ).truncatingRemainder(dividingBy: distance)
        let randomGreen: CGFloat = CGFloat( drand48() ).truncatingRemainder(dividingBy: distance)
        let randomBlue: CGFloat = CGFloat( drand48() ).truncatingRemainder(dividingBy: distance)
        
        red += ( red + randomRed > 1.0 ) ? randomRed * -1.0 : randomRed
        green += ( red + randomGreen > 1.0 ) ? randomGreen * -1.0 : randomGreen
        blue += ( red + randomBlue > 1.0 ) ? randomBlue * -1.0 : randomBlue
        
        return UIColor(hue: red, saturation: green, brightness: blue, alpha: 1.0)
        
        //        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    
    func sizeOfBoundingBoxFromNode(_ node: SCNNode) -> (width: Float, height: Float, depth: Float) {
        var boundingBoxMin = SCNVector3Zero
        var boundingBoxMax = SCNVector3Zero
        let boundingBox = node.__getBoundingBoxMin(&boundingBoxMin, max: &boundingBoxMax)
        
        let width = boundingBoxMax.x - boundingBoxMin.x
        let height = boundingBoxMax.y - boundingBoxMin.y
        let depth = boundingBoxMax.z - boundingBoxMin.z
        
        return (width, height, depth)
    }
    
}
