//
//  Word.swift
//  status-cards
//
//  Created by Sergey Khruschak on 4/6/15.
//  Copyright (c) 2015 Sergey Khruschak. All rights reserved.
//

import Foundation
import CoreData

@objc(Word)
class Word: NSManagedObject {

    @NSManaged var word: String
    @NSManaged var definition: String
    @NSManaged var knownPercent: Int16
    @NSManaged var lastShown: TimeInterval
    @NSManaged var shownTimes: Int32
    @NSManaged var language: Language
    @NSManaged var added: Date

    convenience init(word: String, definition: String, lang: Language, context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "Word", in: context)!, insertInto: context)
        self.word = word.lowercased()
        self.language = lang
        self.definition = definition
        self.knownPercent = 0
        self.shownTimes = 0
        self.added = Date.init()
    }
    
    func displayText() -> String {
        return word + " – " + definition;
    }
    
}
