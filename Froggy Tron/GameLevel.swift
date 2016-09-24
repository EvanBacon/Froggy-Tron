//
//  GameLevelGenerator.swift
//  Crossy Road
//
//  Created by Evan Bacon on 02/20/15.
//  Copyright (c) 2015 brix. All rights reserved.
//

import SceneKit


protocol GameLevelSpawnDelegate : NSObjectProtocol {
    func spawnCarAtPosition(_ position: SCNVector3)
}

class GameLevel: CustomStringConvertible {
    
    enum GameLevelDataType: Int {
        case invalid = -1 // Invalid tile
        case grass = 0    // The player can move on these tiles
        case coin = 1
        case road = 2          // The player can move on these tiles but cars will be driving on this too .. watch out!
        case obstacle = 3     // The player cannot move through this tile
    }

    
    // A delegate that is called when a new car needs to be spawned on a road.
    var spawnDelegate: GameLevelSpawnDelegate?
    
    var data: Array2D
    let segmentSize: Float = 0.2
    var maxObstaclesPerRow: Int = 3
//    var maxObstaclesPerRow: Int = 0

    var mapNode = SCNNode()
    
    // Outputs the data structure to the console - great for debugging
    var description: String {
        var outputString: String = ""
        for row in 0..<data.rowCount() {
            outputString += "[\(row)]: "
            for col in 0..<data.columnCount() {
                outputString += String(data[col, row])
            }
            outputString += "\n"
        }
        return outputString
    }
    var generator = PerlinGenerator()

    
    let CHUNK_SIZE = 5
    func perlinForPosition(_ x: Float, y: Float) -> Float {
        
        var val = abs(generator.perlinNoise(x,
            y: Float(y),
            z: 0,
            t: 0))
        if val > 1 {
            val = 1
        }
        var perlinResults = Float(val * Float(CHUNK_SIZE)) //Set Height
        
        //Always Have A floor
//        if perlinResults < 1 {
//            perlinResults = 1
//        }
//        

        
        return Float(perlinResults)
    }
    
    
    init(width: Int, height: Int) {
        // Level data is stored in a 2D array
        data = Array2D(cols: width * 2, rows: height * 2, value: GameLevelDataType.obstacle.rawValue)
        
        
        
        generator.octaves = Int(4) //Definition
        generator.persistence = Float(0.1) //Height
        generator.zoom = Float(50) //Mountains

        
//        for row in 1...data.rowCount() - 2 {
//            for col in 1...data.columnCount() - 2 {
//                
//                
//
//                data[col, row] = GameLevelDataType.Grass.rawValue
//            }
//        }
        
        
        
        
        let a = (data.rowCount()/2 - width/2)
        let b = (data.rowCount()/2 + width/2)
        for row in a...b {
            let c = (data.columnCount()/2 - width/2)
            let d = (data.columnCount()/2 + width/2)
            
            for col in c...d {
                
                if (col % 5 != 0 || row % 5 != 0) {
                    data[col, row] = GameLevelDataType.road.rawValue

                } else {
                    data[col, row] = GameLevelDataType.obstacle.rawValue
 
                }
            }
        }

        
        
        
        
//
//        // Create the level procedurally
////        for row in 5...data.rowCount() - 6 {
//        for row in 1...data.rowCount() - 2 {
//
//            var type = GameLevelDataType.Grass.rawValue
//            
//            
//            data[row, 6] = type
//
////            // Determine if this should be a grass (0) or road (1)
////            if row < 8 || row > data.rowCount() - 10 {
////                // The first and last four rows will be grass
//////                type = GameLevelDataType.Grass
////                type = GameLevelDataType.Road
////
////            } else {
////                type = GameLevelDataType.Road
//////                type = Int(arc4random_uniform(2)) > 0 ? GameLevelDataType.Grass : GameLevelDataType.Road
////            }
//            
////            type = GameLevelDataType.Road
//
////            fillLevelDataRowWithType(type, row: row)
//        }
        
        
        
        // Always make sure the player spawn point is not an obstacle
        // TODO: Make sure this is not hardcoded
        data[7 + width/2, 6 + height/2] = GameLevelDataType.road.rawValue
    }
    
    
    func fillLevelDataRowWithType(_ type: GameLevelDataType, row: Int) {
//        let maze = Maze(width: data.rowCount(), height: data.columnCount())
//        var r = 0
//        for row in maze.data {
//            var i = 0
//            for cell in row {
//                if cell == Maze.Cell.Space {
////                    print("  ")
//                    data[i, r] = type.rawValue
//
//                } else {//DEBUG HERE MAZE
//                    data[i, r] = GameLevelDataType.Obstacle.rawValue
//                    
////                    print("[]")
//                }
//                i++
//            }
//            r++
//            println()
//        }
        
        

        
        for column in 0..<data.columnCount() {
            var obstacleCountInRow = 10
            if column < 1 || column > data.columnCount() - 2 { //INVISIBLE SIDE WALLS

//            if column < 5 || column > data.columnCount() - 6 {
                // Always obstacles at borders
                
//                data[column, row] =  GameLevelDataType.Coin.rawValue

                
//                data[column, row] = type.rawValue
                
                data[column, row] = GameLevelDataType.obstacle.rawValue
            }
            else {
//                if type == GameLevelDataType.Grass && obstacleCountInRow < maxObstaclesPerRow {
//                    // Determine if an obstacle should be added
//                    if arc4random_uniform(100) > 80 {
//                        // Add obstacle
//                        data[column, row] = GameLevelDataType.Road.rawValue
//                        
////                        obstacleCountInRow++
////                        data[column, row] = GameLevelDataType.Obstacle.rawValue
////                        obstacleCountInRow++
//                    } else {
//                        // Add grass
//                        data[column, row] = type.rawValue
//                    }
//                }
//            else {
                
//                data[column, row] = GameLevelDataType.Obstacle.rawValue

                    data[column, row] = type.rawValue
                
//                }
            }
        }
    }
    
    
    func coordinatesForGridPosition(column: Int, row: Int) -> SCNVector3 {
        // Raise an error is the column or row is out of bounds
        if column < 0 || column > data.columnCount() - 1 || row < 0 || row > data.rowCount() - 1 {
            fatalError("The row or column is out of bounds")
        }
        
        let x: Int = Int(column - data.cols / 2)
        let y: Int = -row
        
        
        let height = perlinForPosition(Float(column), y: Float(row))

        
        return SCNVector3(x: Float(x) * segmentSize, y: height, z: Float(y) * segmentSize)
    }
    
    
    func frogCoordinatesForGridPosition(column: Int, row: Int) -> SCNVector3 {
       
        let pos = coordinatesForGridPosition(column: column, row: row)
        let half = (segmentSize/2.0)
        
        return SCNVector3(x: pos.x, y: pos.y + half, z: pos.z - half)
    }
    
    
    func gridColumnAndRowAfterMoveInDirection(_ direction: MoveDirection, currentGridColumn: Int, currentGridRow: Int) -> (didMove: Bool, newGridColumn: Int, newGridRow: Int) {
        
        // Calculate the new grid position after the move
        var newGridColumn = currentGridColumn
        var newGridRow = currentGridRow
        
        switch direction {
        case .forward:
            newGridRow += 1
            break;
        case .backward:
            newGridRow -= 1
            break
        case .left:
            newGridColumn -= 1
            break
        case .right:
            newGridColumn += 1
        }
        
        // Determine the type of data at new position
        let type = gameLevelDataTypeForGridPosition(column: newGridColumn, row: newGridRow)
        
        switch type {
        case .invalid, .obstacle:
            // Cannot move here, so return the column and row passed.
            return (false, currentGridColumn, currentGridRow)
        default:
            // Move is valid, so return the new column and row
            return (true, newGridColumn, newGridRow)
        }
    }
    
    
    func gameLevelDataTypeForGridPosition(column: Int, row: Int) -> GameLevelDataType {
        // Raise an error is the column or row is out of bounds
        if column < 0 || column > data.columnCount() - 1 || row < 0 || row > data.rowCount() - 1 {
            return GameLevelDataType.invalid
        }
        
        let type = GameLevelDataType(rawValue: data[column, row] as Int)
        return type!
    }
    
    
    func gameLevelWidth() -> Float {
        return Float(data.columnCount()) * segmentSize
    }
    
    
    func gameLevelHeight() -> Float {
        return Float(data.rowCount()) * segmentSize
    }
    
    
    func setupLevelAtPosition(_ position: SCNVector3, parentNode: SCNNode) {
        
        mapNode = parentNode
        let levelNode = SCNNode()
        
        // Create light grass material
        let lightGrassMaterial = SCNMaterial()
        lightGrassMaterial.diffuse.contents = UIColor(red: 190.0/255.0, green: 244.0/255.0, blue: 104.0/255.0, alpha: 1.0)
        lightGrassMaterial.locksAmbientWithDiffuse = false
        
        // Create dark grass material
        let darkGrassMaterial = SCNMaterial()
        darkGrassMaterial.diffuse.contents = UIColor(red: 183.0/255.0, green: 236.0/255.0, blue: 96.0/255.0, alpha: 1.0)
        darkGrassMaterial.locksAmbientWithDiffuse = false
        
        // Create tree top material
        let treeTopMaterial = SCNMaterial()
        treeTopMaterial.diffuse.contents = UIColor(red: 118.0/255.0, green: 141.0/255.0, blue: 25.0/255.0, alpha: 1.0)
        treeTopMaterial.locksAmbientWithDiffuse = false
        
        // Create tree trunk material
        let treeTrunkMaterial = SCNMaterial()
        treeTrunkMaterial.diffuse.contents = UIColor(red: 185.0/255.0, green: 122.0/255.0, blue: 87.0/255.0, alpha: 1.0)
        treeTrunkMaterial.locksAmbientWithDiffuse = false
        
        
        // Create tree trunk material
        let dirtMaterial = SCNMaterial()
        dirtMaterial.diffuse.contents = UIColor.brown
        dirtMaterial.locksAmbientWithDiffuse = false
        
        
        
        // Create road material
        let roadMaterial = SCNMaterial()
        roadMaterial.diffuse.contents = UIColor.darkGray
        roadMaterial.diffuse.wrapT = SCNWrapMode.repeat
        roadMaterial.locksAmbientWithDiffuse = false
        
     
        
        // First, create geometry for grass and roads
        for row in 0..<data.rowCount() {
            for column in 0..<data.columnCount() {
//                data[column, row] =  GameLevelDataType.Coin.rawValue

//                let roadGeometry = SCNPlane(width: CGFloat(segmentSize), height: CGFloat(segmentSize))
//                roadGeometry.widthSegmentCount = 1
//                roadGeometry.heightSegmentCount = 1
//                roadGeometry.firstMaterial = roadMaterial
                
               

                
                let roadGeometry = SCNBox(width: CGFloat(segmentSize), height: CGFloat(segmentSize), length: CGFloat(segmentSize), chamferRadius: 0)
                roadGeometry.widthSegmentCount = 1
                roadGeometry.heightSegmentCount = 1
                roadGeometry.firstMaterial = roadMaterial
                
                
                let roadNode = SCNNode(geometry: roadGeometry)
                roadNode.pivot = SCNMatrix4MakeTranslation(0, 0,0.2)
                roadNode.position = coordinatesForGridPosition(column: column, row: row)
                
                
                if (roadNode.position.y > 0.5) {
                    roadGeometry.firstMaterial = ((row % 2 == 0) ? lightGrassMaterial : darkGrassMaterial)

                }
                
                roadNode.position.y += (segmentSize * 0.8)
                roadNode.rotation = SCNVector4(x: 1.0, y: 0.0, z: 0.0, w: -3.1415 / 2.0)
                roadNode.name = "\(column) \(row)"
                levelNode.addChildNode(roadNode)
            
            // HACK: Check column 5 as column 0 to 4 will always be obstacles
            let type = gameLevelDataTypeForGridPosition(column: column, row: row)
            switch type {
                
//            case GameLevelDataType.Coin:
//                let geometry = SCNBox(width: CGFloat(segmentSize * 0.66), height: CGFloat(segmentSize * 0.66), length: CGFloat(segmentSize * 0.5), chamferRadius: 0)
//
//                    geometry.widthSegmentCount = 1
//                    geometry.heightSegmentCount = 1
//                
//                let material = SCNMaterial()
//                material.diffuse.contents = UIColor.yellowColor()
//                material.diffuse.wrapT = SCNWrapMode.Repeat
//                material.locksAmbientWithDiffuse = false
//
//                geometry.firstMaterial = material
//                
//                let node = SCNNode(geometry: geometry)
//                node.pivot = SCNMatrix4MakeTranslation(0, 0,0.2)
//                node.position = coordinatesForGridPosition(column: column, row: row)
//                node.position.y += Float(segmentSize)
//
//                node.rotation = SCNVector4(x: 1.0, y: 0.0, z: 0.0, w: -3.1415 / 2.0)
//                node.name = "\(column) \(row)"
//                levelNode.addChildNode(node)
//
//                break

            case GameLevelDataType.road:
//
//                // Create a road row
//                let roadGeometry = SCNPlane(width: CGFloat(gameLevelWidth()), height: CGFloat(segmentSize))
//                roadGeometry.widthSegmentCount = 1
//                roadGeometry.heightSegmentCount = 1
//                roadGeometry.firstMaterial = roadMaterial
//                
//                let roadNode = SCNNode(geometry: roadGeometry)
//                roadNode.position = coordinatesForGridPosition(column: Int(data.columnCount() / 2), row: row)
//                roadNode.rotation = SCNVector4(x: 1.0, y: 0.0, z: 0.0, w: -3.1415 / 2.0)
//                levelNode.addChildNode(roadNode)
//                
//                // Create a spawn node at one side of the road depending on whether the row is even or odd
//                
//                // Determine if the car should start from the left of the right
//                let startCol = row % 2 == 0 ? 0 : data.columnCount() - 1
//                let moveDirection : Float = row % 2 == 0 ? 1.0 : -1.0
//                
//                // Determine the position of the node
//                var position = coordinatesForGridPosition(column: startCol, row: row)
//                position = SCNVector3(x: position.x, y: 0.15, z: position.z)
//                
//                // Create node
//                let spawnNode = SCNNode()
//                spawnNode.position = position
//                
//                // Create an action to make the node spawn cars
//                let spawnAction = SCNAction.runBlock({ node in
//                    self.spawnDelegate!.spawnCarAtPosition(node.position)
//                })
//                
//                // Will spawn a new car every 5 + (random time interval up to 5 seconds)
//                let delayAction = SCNAction.waitForDuration(5.0, withRange: 5.0)
//                
//                spawnNode.runAction(SCNAction.repeatActionForever(SCNAction.sequence([delayAction, spawnAction])))
//                
//                parentNode.addChildNode(spawnNode)
//                
                break
            case GameLevelDataType.obstacle :
                
                roadGeometry.firstMaterial = dirtMaterial

                
                let treeHeight = CGFloat((arc4random_uniform(5) + 2)) / 10.0
                let treeTopPosition = Float(treeHeight / 2.0 + 0.1)
                // Create a tree
                let treeTopGeomtery = SCNBox(width: 0.1, height: treeHeight, length: 0.1, chamferRadius: 0.0)
                treeTopGeomtery.firstMaterial = treeTopMaterial
                let treeTopNode = SCNNode(geometry: treeTopGeomtery)
                var gridPosition = coordinatesForGridPosition(column: column, row: row)
                
                gridPosition.y += treeTopPosition
                
                treeTopNode.position = gridPosition
                
                gridPosition.y -= treeTopPosition

                
                gridPosition.y += 0.05

                levelNode.addChildNode(treeTopNode)
                
                let treeTrunkGeometry = SCNBox(width: 0.05, height: 0.1, length: 0.05, chamferRadius: 0.0)
                treeTrunkGeometry.firstMaterial = treeTrunkMaterial
                let treeTrunkNode = SCNNode(geometry: treeTrunkGeometry)
                treeTrunkNode.position = gridPosition
                
                
                levelNode.addChildNode(treeTrunkNode)


                
                break
                
            default:

                
                break
            }
            }
        }
        
        // Combine all the geometry into one - this will reduce the number of draw calls and improve performance
//        let flatLevelNode = levelNode.flattenedClone()
//        flatLevelNode.name = "Level"
        
        // Add the flattened node
        parentNode.position = position
        levelNode.name = "level"
//        parentNode.addChildNode(flatLevelNode)
        parentNode.addChildNode(levelNode)
    }
    
}
