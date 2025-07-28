//
//  String+Extensions.swift
//  Infakt
//
//  Created by Łukasz Stoiński on 28/07/2025.
//

// Extension for String to safely escape for JavaScript
extension String {
    func replacingOccences(of target: String, with replacement: String) -> String {
        return self.replacingOccurrences(of: target, with: replacement)
    }
}
