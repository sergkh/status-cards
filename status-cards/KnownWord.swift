//
//  KnownWord.swift
//  status-cards
//
//  Created by Sergey Khruschak on 5/18/20.
//  Copyright © 2020 Sergey Khruschak. All rights reserved.
//

import Foundation

import Foundation
import CoreData

@objc(KnownWord)
class KnownWord: NSManagedObject {

    @NSManaged var word: String
    @NSManaged var language: Language
    @NSManaged var added: Date

    convenience init(word: String, lang: Language, context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "KnownWord", in: context)!, insertInto: context)
        self.word = word
        self.language = lang
        self.added = Date.init()
    }
}
