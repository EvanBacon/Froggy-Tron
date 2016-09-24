//
//  Maze.swift
//  Tron
//
//  Created by Evan Bacon on 02/20/15.
//  Copyright (c) 2015 brix. All rights reserved.
//

import Foundation

class Maze {
    
    enum Cell {
        case space, wall
    }
    
    var data: [[Cell]] = []
    
    // Generate a random maze.
    init(width: Int, height: Int) {
        for i in 0 ..< height {
            data.append([Cell](repeating: Cell.wall, count: width))
        }
        for i in 0 ..< width {
            data[0][i] = Cell.space
            data[height - 1][i] = Cell.space
        }
        for i in 0 ..< height {
            data[i][0] = Cell.space
            data[i][width - 1] = Cell.space
        }
        data[2][2] = Cell.space
        self.carve(2, y: 2)
        data[1][2] = Cell.space
        data[height - 2][width - 3] = Cell.space
    }
    
    // Carve starting at x, y.
    func carve(_ x: Int, y: Int) {
        let upx = [1, -1, 0, 0]
        let upy = [0, 0, 1, -1]
        var dir = Int(arc4random_uniform(4))
        var count = 0
        while count < 4 {
            let x1 = x + upx[dir]
            let y1 = y + upy[dir]
            let x2 = x1 + upx[dir]
            let y2 = y1 + upy[dir]
            if data[y1][x1] == Cell.wall && data[y2][x2] == Cell.wall {
                data[y1][x1] = Cell.space
                data[y2][x2] = Cell.space
                carve(x2, y: y2)
            } else {
                dir = (dir + 1) % 4
                count += 1
            }
        }
    }
    
    // Show the maze.
    func show() {
        for row in data {
            for cell in row {
                if cell == Cell.space {
                    print("  ", terminator: "")
                } else {
                    print("[]", terminator: "")
                }
            }
            print("")
        }
    }
    
}
