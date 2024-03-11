//
//  String+convertToURL.swift
//  
//
//  Created by Bunga Mungil on 11/03/24.
//

import Foundation


extension String {
    
    public func convertToURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw URLError(.badURL)
        }
        return url
    }
    
}
