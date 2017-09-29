//
//  Pair.swift
//  status-cards
//
//  Created by Sergey Khruschak on 9/18/17.
//  Copyright © 2017 Sergey Khruschak. All rights reserved.
//

import Foundation
import CoreData

@objc(Pair)
class Pair: NSManagedObject {
    @NSManaged var lastShown: TimeInterval
    @NSManaged var shownTimes: Int64
    @NSManaged var word1: Word
    @NSManaged var word2: Word
        
    convenience init(word1: Word, word2: Word, context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "Pair", in: context)!, insertInto: context)
        self.word1 = word1
        self.word2 = word2
    }
    
    func displayText() -> String {
        return word1.word + " – " + word2.word;
    }
}
