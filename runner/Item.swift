//
//  Item.swift
//  runner
//
//  Created by Viren Mohindra on 9/26/25.
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
