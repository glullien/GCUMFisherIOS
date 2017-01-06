//
//  RequestOpenDataParisFr.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 05/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

private let maxNumber = 10

private let parisStreets = readParisStreets()

private func readParisStreets() -> [Address] {
    var result = [Address]()
    let path = Bundle.main.path(forResource: "streets", ofType: "csv")
    let content = try! String(contentsOfFile: path!, encoding: .utf8)
    let lines = content.components(separatedBy: "\n")
    for line in lines {
        let rows = line.components(separatedBy: ";")
        if rows.count == 2  {
            result.append(Address(street: rows[0], district: Int(rows[1])!))
        }
    }
    return result
}

private struct AddressLevenshtein {
    let address: Address
    let distance: UInt8
    init(address: Address, distance: UInt8){
        self.address = address
        self.distance = distance
    }
    
}

typealias OpenParisStreetsHandler = ([Address]) -> Swift.Void

private extension String {
    var length: Int {
        return self.characters.count
    }
    func charAt(_ i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)];
    }
    func letterize() -> [Character] {
        return Array(self.characters)
    }
}

private func levenshtein(lhs: [Character], rhs: [Character], rhsStart: Int, rhsEnd: Int) -> Int {
    let lhsLength = lhs.count
    let rhsLength = rhsEnd-rhsStart
    
    var cost = Array(repeating: 0, count: lhsLength + 1)
    for i in 0...lhsLength {
        cost[i] = i
    }
    var newCost = Array(repeating: 0, count: lhsLength + 1)
    
    for i in 1...rhsLength {
        newCost[0] = i
        
        for j in 1...lhsLength {
            let match = lhs[j - 1] == rhs[rhsStart + i - 1] ? 0 : 1
            
            let costReplace = cost[j - 1] + match
            let costInsert = cost[j] + 1
            let costDelete = newCost[j - 1] + 1
            
            newCost[j] = min(min(costInsert, costDelete), costReplace)
        }
        
        let swap = cost
        cost = newCost
        newCost = swap
    }
    
    return cost[lhsLength]
}

private func levenshtein(_ extract: [Character], in text: [Character]) -> UInt8 {
    var res = UInt8.max;
    let diffLength = text.count - extract.count
    for i in 0...diffLength {
        let bonus = i == 0 || text[i-1] == " "
        let distance = levenshtein(lhs: extract, rhs: text, rhsStart: i, rhsEnd: i + extract.count)
        res = min(res, UInt8(distance) * 2 + (bonus ? 0 : 1))
    }
    // debugPrint("distance \(extract) \(text) = \(res)")
    return res;
}

class OpenParisStreetsCancelFlag {
    private var atomicValue:UInt32 = 0
    func cancel() {
        atomicValue = 1
    }
    func isCancelled() -> Bool {
        return atomicValue != 0
    }
}

func searchOpenParisStreets(for pattern: String, handler: OpenParisStreetsHandler, cancelFlag: OpenParisStreetsCancelFlag) {
    debugPrint("Starting search for \(pattern)")
    var res = [Address]()
    
    var tmp = [AddressLevenshtein]()
    let letterizedPattern = toStdLowerChars(pattern).letterize()
    for street in parisStreets {
        if cancelFlag.isCancelled() || (tmp.count == maxNumber && tmp.last!.distance == 0) {
            break
        }
        let distance = levenshtein(letterizedPattern, in: toStdLowerChars(street.street).letterize())
        
        if tmp.count < maxNumber || tmp.last!.distance > distance {
            tmp.append(AddressLevenshtein(address: street, distance: distance))
            tmp.sort {
                return $0.distance < $1.distance
            }
            while tmp.count > maxNumber {
                tmp.removeLast()
            }
        }
        
    }
    
    for r in tmp {
        res.append(r.address)
    }
    debugPrint("Found \(res.count) elements for \(pattern), cancel=\(cancelFlag.isCancelled())")
    handler(res)
}
