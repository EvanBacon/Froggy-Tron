//
//  Constants.swift
//  Crossy Road
//
//  Created by Evan Bacon on 02/20/15.
//  Copyright (c) 2015 brix. All rights reserved.
//

enum GameState {
    case waitingForFirstTap
    case playing
    case gameOver
    case restartLevel
}


enum MoveDirection {
    case forward
    case backward
    case left
    case right
}


struct PhysicsCategory {
    static let None: Int              = 0
    static let Player: Int            = 0b1      // 1
    static let Car: Int               = 0b10     // 2
    static let Obstacle: Int          = 0b100    // 4
}
