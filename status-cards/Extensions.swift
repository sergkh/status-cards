//
//  Extensions.swift
//  status-cards
//
//  Created by Sergey Khruschak on 5/15/20.
//  Copyright © 2020 Sergey Khruschak. All rights reserved.
//

import Foundation


extension String {
    func regexpMatch(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }

    var lines: [String] {
        return self.components(separatedBy: "\n")
    }
    
    func removingRegexMatches(pattern: String, replaceWith: String = "") -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return self
        }
    }
}
