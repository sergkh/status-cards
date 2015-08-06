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

    @NSManaged var lastShown: NSTimeInterval
    @NSManaged var learned: Float
    @NSManaged var shownTimes: Int32
    @NSManaged var word: String
    @NSManaged var language: Language
    @NSManaged var translation: NSMutableSet

    convenience init(word: String,  lang: Language, context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName("Word", inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
        self.word = word
        self.language = lang
    }
    
    func translationText() -> String {
        var str = ""
        //translation.allObjects
        for t in translation {
            str = str + t.word + ", "
        }

        return str; //String(format: "Results %d", translation.count)
    }
}
