//
//  Item.swift
//  New Updated poltek action classifier
//
//  Created by Kaushik Manian on 16/7/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
