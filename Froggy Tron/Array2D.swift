//
//  Array2D.swift
//  Crossy Road
//
//  Created by Evan Bacon on 02/20/15.
//  Copyright (c) 2015 brix. All rights reserved.
//

class Array2D {
    
    var cols: Int, rows: Int
    var data: [Int]
    
    init(cols columnCount: Int, rows rowCount: Int, value defaultValue: Int) {
        self.cols = columnCount
        self.rows = rowCount
        data = Array(repeating: defaultValue, count: cols * rows)
    }
    
    subscript(column: Int, row: Int) -> Int {
        get {
            return data[cols * row + column]
        }
        set {
            data[cols * row + column] = newValue
        }
    }
    
    func columnCount() -> Int {
        return self.cols
    }
    
    func rowCount() -> Int {
        return self.rows
    }
    
}
