//
//  Enemy.swift
//  Tron
//
//  Created by Evan Bacon on 02/20/15.
//  Copyright (c) 2015 brix. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

var grid: GameLevel!
var flag = Bool()
var square = Int()
var openSpotBitMask = Int()

class Enemy {
    var trailColor = UIColor()

    var computerHeadPositon = CGPoint()
    var dead = Bool()
    var enemy = SCNNode()

    init(level:GameLevel) {
        grid = level
        flag = false
        dead = false
        openSpotBitMask = GameLevel.GameLevelDataType.road.rawValue
        
//        trailColor = varyColor(UIColor.redColor(), distance: 0.1)
        let v = arc4random_uniform(3)
        switch (v){
            case (0):
            trailColor = UIColor.red
            break
        case (1):
            trailColor = UIColor.orange
            break
        case (2):
            trailColor = UIColor.yellow
            break

        default:
            break
        }
    }
    
    func varyColor( _ baseColor:UIColor, distance:CGFloat ) -> UIColor {
        
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        
        baseColor.getRed( &red, green: &green, blue: &blue, alpha: nil )
        
        let randomRed: CGFloat = CGFloat( drand48() ).truncatingRemainder(dividingBy: distance)
        let randomGreen: CGFloat = CGFloat( drand48() ).truncatingRemainder(dividingBy: distance)
        let randomBlue: CGFloat = CGFloat( drand48() ).truncatingRemainder(dividingBy: distance)
        
        red += ( red + randomRed > 1.0 ) ? randomRed * -1.0 : randomRed
        green += ( red + randomGreen > 1.0 ) ? randomGreen * -1.0 : randomGreen
        blue += ( red + randomBlue > 1.0 ) ? randomBlue * -1.0 : randomBlue
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    
    func makeNode(_ position: CGPoint) -> SCNNode{
        
        enemy = SCNNode()
        enemy.name = "enemy"
        enemy.position = grid.frogCoordinatesForGridPosition(column: Int(position.x), row: Int(position.y))
        enemy.position.y = 0.0

        computerHeadPositon = position
        changeTileAvalibility(computerHeadPositon)

        // Create a physicsbody for collision detection
        let playerMaterial = SCNMaterial()
        playerMaterial.diffuse.contents = UIImage(named: "assets.scnassets/Textures/model_texture.tga")
        playerMaterial.locksAmbientWithDiffuse = false
        
        let playerScene = SCNScene(named: "assets.scnassets/Models/frog.dae")

        let ChildNode = playerScene!.rootNode.childNode(withName: "Frog", recursively: false)!

//        var ChildNode = SCNNode(geometry: SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0.001))
        ChildNode.geometry!.firstMaterial = playerMaterial
        ChildNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.075)
        
        ChildNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: SCNPhysicsShape(geometry: SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0.0), options: nil))
        ChildNode.physicsBody!.categoryBitMask = PhysicsCategory.Car
        ChildNode.physicsBody!.collisionBitMask = PhysicsCategory.Player
        
        enemy.addChildNode(ChildNode)

        return enemy
    }
    
    func explode() {
        let jumpUpAction = SCNAction.scale(by: 0.6, duration: 0.1)
        
        jumpUpAction.timingMode = SCNActionTimingMode.easeOut
        let jumpDownAction = SCNAction.scale(by: 2.0, duration: 0.1)
        jumpDownAction.timingMode = SCNActionTimingMode.easeIn
        let DownAction = SCNAction.fadeOpacity(to: 0.0, duration: 0.1)
        DownAction.timingMode = SCNActionTimingMode.linear
        
        let jumpAction = SCNAction.sequence([jumpUpAction, jumpDownAction, DownAction])
        
        enemy.runAction(jumpAction, completionHandler: {(Bool)  in
            self.raiseTile(CGPoint(x: CGFloat(self.computerHeadPositon.x), y: CGFloat(self.computerHeadPositon.y)))
            self.enemy.removeFromParentNode()
        })
    }
    
    func raiseTile(_ position: CGPoint){
        let node = grid.mapNode.childNode(withName: "level", recursively: false)!
        let tile = node.childNode(withName: "\(Int(position.x)) \(Int(position.y))", recursively: false)!
        
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.magenta
        mat.locksAmbientWithDiffuse = false
        tile.geometry?.firstMaterial = mat
        
        let jumpUpAction = SCNAction.move(by: SCNVector3(x: 0.0, y: -0.1, z: 0.0), duration: 0.1)
        jumpUpAction.timingMode = SCNActionTimingMode.easeOut
        let scaleAction = SCNAction.scale(by: 1.5, duration: 0.2)
        let jumpDownAction = SCNAction.move(by: SCNVector3(x: 0.0, y: 0.2, z: 0.0), duration: 0.2)
        jumpDownAction.timingMode = SCNActionTimingMode.easeIn
        let jumpAction = SCNAction.sequence([jumpUpAction,scaleAction ,jumpDownAction])
        
        tile.runAction(jumpAction, completionHandler: {(Bool)  in
        })
    }

    
    
    
    func move() {
    //flag is used to force computer initialy move towards player
        if (flag) {
            flag = false;
        }
        else if(checkIfBoxedIn(Int(computerHeadPositon.x), posY: Int(computerHeadPositon.y))){
            dead = true
        }
        else {
            switch (getEmptyCellsIndex(Int(computerHeadPositon.x), posY: Int(computerHeadPositon.y))) {
                case 0:
                    computerHeadPositon.y += CGFloat(1);
                    break;
                case 1:
                    computerHeadPositon.x += CGFloat(1);
                    break;
                case 2:
                    computerHeadPositon.y -= CGFloat(1);
                    break;
                case 3:
                    computerHeadPositon.x -= CGFloat(1);
                    break;
                default:
                    break;
            }
        }
    }
    
    func changeTileAvalibility(_ tile: CGPoint){
        grid.data[Int(tile.x),Int(tile.y)] = GameLevel.GameLevelDataType.obstacle.rawValue
    }
    
    func checkIfBoxedIn(_ posX: Int,posY: Int) -> Bool {
        return (checkCollsion(posX + 1, posY: posY) &&
                checkCollsion(posX - 1, posY: posY) &&
                checkCollsion(posX, posY: posY + 1) &&
                checkCollsion(posX, posY: posY - 1));
    }
    
    func checkCollsion(_ posX: Int,posY: Int ) -> Bool {
        let num = grid.gameLevelDataTypeForGridPosition(column: posX, row: posY)
        return (num == GameLevel.GameLevelDataType.obstacle) ||
               (num == GameLevel.GameLevelDataType.invalid) //FIX THIS
    }
    
    func spotIsOpen(_ spot: GameLevel.GameLevelDataType) -> Bool{
        if (spot == GameLevel.GameLevelDataType.obstacle || spot == GameLevel.GameLevelDataType.invalid) {
            return false
        } else {
            return true
        }
    }
    
    func getEmptyCellsIndex(_ posX: Int,posY: Int) -> Int {
        //up is the state of the top cell
        let up = grid.gameLevelDataTypeForGridPosition(column: posX, row: posY + 1)
        let right = grid.gameLevelDataTypeForGridPosition(column: posX + 1, row: posY)
        let bottom = grid.gameLevelDataTypeForGridPosition(column: posX, row: posY - 1)
        let left = grid.gameLevelDataTypeForGridPosition(column: posX - 1, row: posY)
//        println("Nid: \(up.rawValue)\(right.rawValue)\(bottom.rawValue)\(left.rawValue)")

        var upPPos = 0;
        var rightPPos = 0;
        var bottomPPos = 0;
        var leftPPos = 0;
    
        if(spotIsOpen(up)){
            upPPos = countBlueCells(posX, posY: posY + 1)}
        if( spotIsOpen(right)){
            rightPPos = countBlueCells(posX + 1, posY: posY)}
        if(spotIsOpen(bottom)){
            bottomPPos = countBlueCells(posX, posY: posY - 1)}
        if(spotIsOpen(left)){
            leftPPos = countBlueCells(posX - 1, posY: posY)}
        
        let temp = NSMutableArray()
        temp.add(NSNumber(value: up.rawValue as Int))
        temp.add(NSNumber(value: right.rawValue as Int))
        temp.add(NSNumber(value: bottom.rawValue as Int))
        temp.add(NSNumber(value: left.rawValue as Int))
//        println("Jid: \(temp)")

        //firstPriorityMovementArray holds directions which have 3 blue cells
        let firstPriorityMovmentArray  = NSMutableArray()
        let secondPiorityMovementArray = NSMutableArray()
        let lastPriorityMovementArray  = NSMutableArray()
    
        for i in 0 ..< 4 {
            let num: AnyObject = temp.object(at: i) as AnyObject
//            println("GJd: \(num.intValue)-\(num.integerValue)")

            if (i==0){
                //if top cell was blue and it had three blue cells
                if (num.intValue==openSpotBitMask && upPPos==3){
                    firstPriorityMovmentArray.add(NSNumber(value: i as Int))
                }
                else if (num.intValue == openSpotBitMask && upPPos == 2){
                    secondPiorityMovementArray.add(NSNumber(value: i as Int))
                }
                else if (num.intValue == openSpotBitMask && upPPos == 1){
                    lastPriorityMovementArray.add(NSNumber(value: i as Int))
                }
            }
            else if (i==1) {
                if (num.intValue == openSpotBitMask && (rightPPos==3)){
                    firstPriorityMovmentArray.add(NSNumber(value: i as Int))
                }
                else if (num.intValue == openSpotBitMask && rightPPos==2){
                    secondPiorityMovementArray.add(NSNumber(value: i as Int))
                }
                else if (num.intValue == openSpotBitMask && (rightPPos==1)){
                    lastPriorityMovementArray.add(NSNumber(value: i as Int))
                }
            }
            else if (i==2){
                if (num.intValue == openSpotBitMask && (bottomPPos==3)){
                    firstPriorityMovmentArray.add(NSNumber(value: i as Int))
                }
                else if (num.intValue == openSpotBitMask && bottomPPos==2){
                    secondPiorityMovementArray.add(NSNumber(value: i as Int))
                }
                else if (num.intValue == openSpotBitMask && (bottomPPos==1)){
                    lastPriorityMovementArray.add(NSNumber(value: i as Int))
                }
            }
            else if (i==3){
                if (num.intValue == openSpotBitMask && (leftPPos==3)){
                    firstPriorityMovmentArray.add(NSNumber(value: i as Int))
                }
                else if (num.intValue == openSpotBitMask && leftPPos==2){
                    secondPiorityMovementArray.add(NSNumber(value: i as Int))
                }
                else if (num.intValue == openSpotBitMask && (leftPPos==1)){
                    lastPriorityMovementArray.add(NSNumber(value: i as Int))
                }
            }
        }
        let numberOfPossibleMovement1 = firstPriorityMovmentArray.count;
        let numberOfPossibleMovement2 = secondPiorityMovementArray.count;
        let numberOfPossibleMovement3 = lastPriorityMovementArray.count;
    
        if ( numberOfPossibleMovement1 > 0){
            let number:Int = (Int(arc4random()) % Int(numberOfPossibleMovement1))
            return (firstPriorityMovmentArray.object(at: number) as AnyObject).intValue
        }
        else if ( numberOfPossibleMovement2 > 0){
            let number:Int = (Int(arc4random()) % Int(numberOfPossibleMovement2))
            return (secondPiorityMovementArray.object(at: number) as AnyObject).intValue
        }
        else if  ( numberOfPossibleMovement3 > 0){
            let number:Int = (Int(arc4random()) % Int(numberOfPossibleMovement3))
            return (lastPriorityMovementArray.object(at: number) as AnyObject).intValue
        }
        else {
            //this force computer to go to its last empty cell
            for i in 0..<4 {
                if ((temp.object(at: i) as AnyObject).intValue == openSpotBitMask){
                    return i
                }
            }
            return 1; //Returns Right
            }
        }
    
    func countBlueCells(_ posX: Int,posY: Int) -> Int {
        var count = 0;
        if (grid.gameLevelDataTypeForGridPosition(column: posX, row: posY + 1) != GameLevel.GameLevelDataType.obstacle){
            count+=1
        }
        if (grid.gameLevelDataTypeForGridPosition(column: posX + 1, row: posY) != GameLevel.GameLevelDataType.obstacle){
            count+=1
        }
        if (grid.gameLevelDataTypeForGridPosition(column: posX, row: posY - 1) != GameLevel.GameLevelDataType.obstacle){
            count+=1
        }
        if (grid.gameLevelDataTypeForGridPosition(column: posX - 1, row: posY) != GameLevel.GameLevelDataType.obstacle){
            count+=1
        }
        return count;
    }
}
