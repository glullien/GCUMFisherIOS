//
//  Chars.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 06/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

private let firstLegalChar = Character(UnicodeScalar(32))
private let lastLegalChar = Character(UnicodeScalar(126))

func toStdChar(_ a: Character) -> Character {
    switch a {
    case "à", "â", "ä":
        return "a"
    case "é", "è", "ê", "ë":
        return "e"
    case "ï", "î":
        return "i"
    case "ö", "ô":
        return "o"
    case "ù", "û", "ü":
        return "u"
    case "ç":
        return "c"
    case "œ":
        return "o"
    case "À", "Â", "Ä":
        return "A"
    case "É", "È", "Ê", "Ë":
        return "E"
    case "Ï", "Î":
        return "I"
    case "Ö", "Ô":
        return "O"
    case "Ù", "Û", "Ü":
        return "U"
    case "Ç":
        return "C"
    case "Œ":
        return "O"
    default:
        if a >= firstLegalChar && a <= lastLegalChar {
            return a
        }
        else {
            return "?"
        }
        //  int c = (int) a
        // if ((c >= 32) && (c < 127)) return a
        // else return "?"
    }
}

func toStdChars(_ a: Character) -> String {
    switch a {
    case "œ":
        return "oe"
    case "Œ":
        return "Oe"
    default:
        return String(a)
    }
}

func toStdChars(_ a: String) -> String {
   var res = ""
    for c in a.characters {
        res.append(toStdChars(c))
    }
    return res
}


func toStdLowerChars(_ a: String) -> String {
    return toStdChars(a).lowercased()
}


