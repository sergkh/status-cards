//
//  DictionaryManager.swift
//  status-cards
//
//  Created by Sergey Khruschak on 4/2/15.
//  Copyright (c) 2015 Sergey Khruschak. All rights reserved.
//

import Cocoa

class DictionaryManager {
    let managedContext: NSManagedObjectContext;
    
    init(context: NSManagedObjectContext) {
        self.managedContext = context
    }
    
    func nextWord() -> Word? {
        // Fetching
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Word")
        // request.predicate = NSPredicate(format: "knownPercent < %@", 100)
        
        let sortByViewDate = NSSortDescriptor(key: "lastShown", ascending: true)
        let sortByViews = NSSortDescriptor(key: "shownTimes", ascending: true)
        
        request.sortDescriptors = [sortByViewDate, sortByViews]
        request.fetchLimit = 1
        
        let result = try? self.managedContext.fetch(request)
        
        if let res = result {
            if res.count == 0 {
                print("No records found")
                return nil
            }
            
            let word = res[0] as! Word
            word.shownTimes += 1
            word.lastShown = Date().timeIntervalSince1970
            
            // TODO: do not save context on each read
            do {
                try managedContext.save()
            } catch {
                print("Error saving context \(error.localizedDescription)")
            }
            
            print("Got word: \(word.displayText())")
            
            return word
        }
        
        return nil
    }
    
    func importFromURL(_ url: URL) throws {
        if url.scheme == "file" && url.path.hasSuffix(".srt") {
            try self.importSrt(fileName: url.path)
        } else if url.scheme == "file" {
            try self.importFromFile(url.path, params: parseUrlParams(url))
        } else {
            print("URL is not supported Yet \(url)")
        }
    }
    
    func importFromFile(_ fileName: String, params: [String:String]) throws {
        print("Importing file: \(fileName)")
        
        let fileContents = try? String(contentsOfFile:fileName, encoding: .utf8)
        
        if let contents = fileContents {
            let fileLines = contents.components(separatedBy: "\n")
            
            print("Got \(fileLines.count) lines in file")
                        
            let allowedDelimeters = CharacterSet(charactersIn:":–=—")
            let spaces = CharacterSet.whitespaces
                                    
            var text = ""
            for line in fileLines {
                let pairsArray = line.components(separatedBy: allowedDelimeters as CharacterSet)
                if pairsArray.count == 2 {
                    text.append(pairsArray[0]);
                    text.append(" ")
                }
            }
            
            let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
            tagger.string = text
            let lang = try! findOrAddLang(tagger.dominantLanguage ?? "en")
            print("Detected language is: \(lang)")
            
            var importedCount = 0
            
            for line in fileLines {
                let pairsArray = line.components(separatedBy: allowedDelimeters as CharacterSet)
                
                if pairsArray.count == 2 {
                    let words = pairsArray[0].components(separatedBy: ",")
                    let translations = pairsArray[1].components(separatedBy: ",")
                    
                    for w in words {
                        for t in translations {
                            let trimmedWord1 = w.trimmingCharacters(in: spaces)
                            let trimmedWord2 = t.trimmingCharacters(in: spaces)
                            
                            do {
                                if try !trimmedWord1.isEmpty && !trimmedWord2.isEmpty && addWord(word: trimmedWord1, lang: lang, definition: trimmedWord2) {
                                    importedCount = importedCount + 1
                                }
                            } catch {
                                print("Error storing words: \(error.localizedDescription) for words '\(trimmedWord1)' – '\(trimmedWord2)'")
                            }
                        }
                    }
                } else {
                    // skip empty lines
                    if !line.trimmingCharacters(in: NSCharacterSet.whitespaces).isEmpty {
                        print("Ignored line: \(line) with pairs: \(pairsArray.count)")
                    }
                }
            }        
            
            print("Imported \(importedCount) of total \(fileLines.count) lines from file: \(fileName)")
        }
    }
    
    func importSrt(fileName: String) throws {
        let fileContents = try? stripSrt(String(contentsOfFile:fileName, encoding: .utf8))

        // see: https://developer.apple.com/documentation/naturallanguage/identifying_parts_of_speech
        if let text = fileContents {
            let tagger = NSLinguisticTagger(tagSchemes: [.language, .tokenType, .lexicalClass, .lemma, .nameType], options: 0)
            
            let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
            
            tagger.string = text
            
            let lang = try! findOrAddLang(tagger.dominantLanguage ?? "en")
            print("The Language is: \(lang)")
            
            let range = NSRange(location: 0, length: text.utf16.count)
                            
            var candidates: [String:NSRange] = [:]
            var ignored: [String: Int] = [:]
            
            // Find words only of specific classes
            // let tags: [NSLinguisticTag] = [.V, .placeName, .organizationName]
            tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { (tag, tokenRange, stop) in
                if let tag = tag {
                    let word = (text as NSString).substring(with: tokenRange)
                    if ["Verb", "Noun", "Adverb", "Adjective", "OtherWord"].contains(tag.rawValue) {
                        candidates[word] = tokenRange
                    } else {
                        ignored[word] = 1
                    }
                }
            }
                            
            // remove personal names and places
            let tags: [NSLinguisticTag] = [.personalName, .placeName, .organizationName]
            tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { (tag, tokenRange, stop) in
                if let tag = tag, tags.contains(tag) {
                    let name = (text as NSString).substring(with: tokenRange)
                    candidates.removeValue(forKey: name)
                }
            }
            
            var ranges: [NSRange:String] = [:]
            
            for (word, range) in candidates {
                ranges[range] = word
            }
            
            print("Ignored words \(ignored.keys.joined(separator: ", "))")
            
            tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { (tag, tokenRange, stop) in
                if let lemma = tag?.rawValue, let word = ranges[tokenRange] {
                    let known = try? findKnownWord(word: lemma, lang: lang)
                    let learning = try? findWord(word: lemma, lang: lang)
                    
                    if known == nil && learning == nil {
                        print("New word: \(word) - \(lemma)")
                    } else {
                        print("Old: \(lemma)")
                    }
                }
            }
        }
    }
    
    func importFromLingualeo(login: String, pass: String) throws {
        let url = URL(string: "https://api.lingualeo.com/api/login")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        /*
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) {(response, data, error) in
            print(data!)
            
          //curl -X POST -H 'Content-Type: application/json' --data '{ "page": "1", "sortBy": "date", "filter": "all", "groupId": "dictionary"}' https://lingualeo.com/userdict/json
        }*/
        
    }
    
    func addWord(word: String, lang: Language, definition: String) throws -> Bool {
        let existingWord = try findWord(word: word, lang: lang)
    
        if (existingWord != nil) {
            return false
        }
    
        _ = Word(word: word, definition: definition, lang: lang, context: managedContext)
        try managedContext.save()
        
        return true
    }
        
    func findWord(word: String, lang: Language) throws -> Word? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Word")
        request.predicate = NSPredicate(format: "word == %@", word.lowercased())
        
        let wordsRes = try managedContext.fetch(request)
        
        if wordsRes.count == 0 {
            return nil
        }
            
        return wordsRes[0] as? Word
    }
    
    func addKnownWord(word: String, lang: Language) throws -> Bool {
        let existingWord = try findKnownWord(word: word, lang: lang)
    
        if (existingWord != nil) {
            return false
        }
    
        _ = KnownWord(word: word, lang: lang, context: managedContext)
        try managedContext.save()
        
        return true
    }
    
    func findKnownWord(word: String, lang: Language) throws -> KnownWord? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "KnownWord")
        request.predicate = NSPredicate(format: "word == %@", word.lowercased())
        
        let wordsRes = try managedContext.fetch(request)
        
        if wordsRes.count == 0 {
            return nil
        }
            
        return wordsRes[0] as? KnownWord
    }
    
    func findOrAddLang(_ iso: String) throws -> Language {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Language")
        request.predicate = NSPredicate(format: "iso == %@", iso)
        
        let langRes = try? managedContext.fetch(request)
        
        if let result = langRes {
            if result.count > 0 {
                return result[0] as! Language
            }
        }
        
        let l = Language(iso: iso, context: managedContext)
        
        try managedContext.save()
        
        return l
    }
    
    func countAll() throws -> Int {
        return try managedContext.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Word"))
    }
    
    func removeAll() throws {
        let allWords = NSFetchRequest<NSFetchRequestResult>(entityName: "Word")
        allWords.includesPropertyValues = false

        let pairs = try self.managedContext.fetch(allWords)
        
        for p in pairs {
           managedContext.delete(p as! NSManagedObject)
        }
        
        try managedContext.save()
    }
    
    fileprivate func parseUrlParams(_ url: URL) -> [String : String] {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let itemsOpt = urlComponents?.queryItems

        var dict = [String: String]()
        
        if let items = itemsOpt {
            for item in items {
                dict[item.name] = item.value
            }
        }
        
        return dict
    }
    
    fileprivate func stripSrt(_ text: String) -> String {
        text.lines.filter { (line) -> Bool in
            !(line.regexpMatch("^\\d+") || line.regexpMatch("^\\d{2}:d{2}:d{2}.*")) // filter out: 1 and 00:02:10,244 --> 00:02:12,788
        }.map { (line) -> String in
            line.removingRegexMatches(pattern: "</?.+?>") // remove tags
        }.joined(separator:" ")
    }
}
