//
//  CounterNode.swift
//  Tron
//
//  Created by Evan Bacon on 02/20/15.
//  Copyright (c) 2015 brix. All rights reserved.
//

import SpriteKit

class CounterNode : SKLabelNode {
    
    init(position: CGPoint, size: CGFloat, color: SKColor, text: String, name: String) {
        super.init()
        
        self.name = name
        self.text = text
        self.position = position
        
        fontName = "Early-Gameboy"
        fontSize = size
        fontColor = color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

