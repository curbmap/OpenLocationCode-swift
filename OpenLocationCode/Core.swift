//
//  Core.swift
//  OpenLocationCode
//
//  Created by Eli Selkin on 7/25/17.
//  Copyright © 2017 curbmap. All rights reserved.

import Foundation

// https://github.com/google/open-location-code/blob/master/python/openlocationcode.py
// Obviously stealing ideas, Google has the best ideas. Please see the LICENSE file

enum OpenLocationCodeError:Error {
    case invalidCode
    case invalidShortCode
    case invalidLongCode
    case encodingError
    case decodingError
    case dissimilarRegions
    case exceedsMaxCodeLength
}

// Future version may switch from Float64 to NSDecimalNumber to handle more places of precision
public class OpenLocationCode : NSObject {
    static public let DEFAULT_CODE_LENGTH: Int = 10 // Not including + IMPORTANT!! This is the point where lat/lng diverge in relationship
    static public let LENGTH_BASE: Int = 8 // For a long code
    static public let MAX_CODE_LENGTH: Int = 15 // Not including +
    static public let CODE_ALPHABET: [Character] = ["2","3","4","5","6","7","8","9","C","F","G","H","J","M","P","Q","R","V","W","X"]
    static public let PLUS_SEPARATOR: Character = "+"
    static public let BASE_FOR_PREFIX: Float64 = 20
    static public let MATRIX_FOR_PLUS:[[Character]] = [["2", "3", "4", "5"],
                                                       ["6", "7", "8", "9"],
                                                       ["C", "F", "G", "H"],
                                                       ["J", "M", "P", "Q"],
                                                       ["R", "V", "W", "X"]]
    static public let MATRIX_FOR_PLUS_DIM: (rows: Float64, cols: Float64) = (rows: 5.0, cols: 4.0)
    static public let PADDING_CHARACTER: Character = "0"
    static public let LONGITUDE_MIN: Float64 = -180.0
    static public let LONGITUDE_MAX: Float64 = 180.0
    static public let LATITUDE_MIN: Float64 = -90.0
    static public let LATITUDE_MAX: Float64 = 90.0
    static public let RESOLUTION_STEPS:[Float64] = [20.0, 1.0, 0.05, 0.0025, 0.000125] // 5 pairs of Lat, Lng
    private var _code: String = ""
    private var _code_type: Int = -1
    private var _LatLng: (latitude: Float64, longitude: Float64) = (latitude: 0.0, longitude: 0.0)
    private var _codeArea: CodeArea?
    //MARK: - Initializers
    /*
     * From code string, will decode to LatLng pair
     * From lat lng, will encode to OLC code of 10 or given length code
     *
     */
    public init(_ code: String) throws {
        let code_type = OpenLocationCode.isValidOLC(code: code.uppercased())
        _code_type = code_type
        if (code_type == 0 || code_type == 1) {
            let _code = code.uppercased()
            let codeLength = min(_code.count, OpenLocationCode.MAX_CODE_LENGTH)
            let characterEnd = _code.index(_code.startIndex, offsetBy: codeLength)
            let sub_code = String(code.uppercased()[..<characterEnd])
            // It's already a valid code, so get the code area for it as well
            _codeArea = try! OpenLocationCode.decode(code: sub_code)
        } else {
            throw OpenLocationCodeError.invalidCode
        }
        // If we throw an error in creation, it wasn't a valid code
    }
    /*
     * Initializers from lat/lng which do both a forward and backward pass
     */
    public init(latitude: Float64, longitude: Float64, codeLength: Int) throws {
        var _codeLength = codeLength
        if (codeLength > 15) {
            _codeLength  = 15
        }
        self._LatLng = (latitude: latitude, longitude: longitude)
        self._code = try! OpenLocationCode.encode(latitude: latitude, longitude: longitude, codeLength: _codeLength)
        self._codeArea = try! OpenLocationCode.decode(code: self._code)
    }
    public convenience init(latitude: Float64, longitude: Float64) throws {
        try! self.init(latitude: latitude, longitude: longitude, codeLength: 10)
    }
    //MARK: - Getters
    public func getCode() -> String {
        return self._code
    }
    public func getCodeArea() -> CodeArea? {
        return self._codeArea
    }
    //MARK: - Validating
    public static func isValidOLC(code: String) -> Int {
        // Some might argue that an empty code is valid, but we won't here
        if (code == "") {
            return -1
        }
        var pos = 0
        var separators = 0
        var separator_position = -1
        var paddingPos = -1
        var paddingEnd = -1
        for letter in code {
            let checkedLetter = OpenLocationCode.CODE_ALPHABET.index(of: letter)
            // Verifies all characters come from the alphabet or +, 0
            if (letter != OpenLocationCode.PADDING_CHARACTER && letter != OpenLocationCode.PLUS_SEPARATOR && checkedLetter == nil) {
                return -1
            }
            // Padding cannot be separated by non-padding characters
            if (checkedLetter != nil && paddingPos != -1) {
                return -1
            }
            // Keep track of how many separators
            if (letter == OpenLocationCode.PLUS_SEPARATOR) {
                separators += 1
                separator_position = pos
            }
            if (letter == OpenLocationCode.PADDING_CHARACTER){
                if (paddingPos == -1) { paddingPos = pos }
                paddingEnd = pos
                // Check if that beginning padding position is in an incorrect position
                if (paddingPos == 0 || paddingPos % 2 == 1) {
                    return -1
                }
            }
            pos += 1
        }
        
        /*
         * Must have even padding. Padding can only happen before the separator.
         */
        if ((paddingPos != -1) && ((paddingEnd - paddingPos + 1) % 2 != 0)) {
            return -1
        }
        /*
         * There must only be exactly one separator, it cannot be past the 9th character, and it cannot be at an odd position
         */
        if (separators != 1 || separator_position > OpenLocationCode.LENGTH_BASE || separator_position % 2 == 1) {
            return -1
        }
        if (isValidShortOLC(code: code, separator_pos: separator_position)) {
            return 0
        } else if (isValidLongOLC(code: code, separator_pos: separator_position)) {
            return 1
        }
        return -1
    }
    
    // MARK: - Short Open Location Codes
    /**
     * Short codes should be 4 characters, a +, followed by 0 or more characters.
     * Generally, these codes are 4-7 characters long, not including the +
     */
    public static func isValidShortOLC(code: String, separator_pos: Int) -> Bool {
        if (separator_pos >= 0 && separator_pos < OpenLocationCode.LENGTH_BASE) {
            return true
        }
        return false
    }
    
    // MARK: - Long Open Location Codes
    /**
     * Long codes are at least 8 characters long. They may then include a + followed by 
     * 0-x number of further code characters. The appended string of code characters follows
     * a different decoding/encoding scheme but using the same character space.
     
     * Here we check the bounds of the code to make sure it's within
     */
    public static func isValidLongOLC(code: String, separator_pos: Int) -> Bool {
        // If it's a short code, it's not a long code... See google python implementation
        if (OpenLocationCode.isValidShortOLC(code: code, separator_pos: separator_pos)) {
            return false
        }
        // We can use ! because we are sure all characters exist in the alphabet at this time
        let firstLat = Float64(OpenLocationCode.CODE_ALPHABET.index(of: code[code.startIndex])!) * OpenLocationCode.BASE_FOR_PREFIX
        if (firstLat >= OpenLocationCode.LATITUDE_MAX * 2.0) {
            return false
        }
        if (code.count >= 2) {
            let firstLng = Float64(OpenLocationCode.CODE_ALPHABET.index(of: code[code.index(code.startIndex, offsetBy: 1)])!) * OpenLocationCode.BASE_FOR_PREFIX
            if (firstLng >= OpenLocationCode.LONGITUDE_MAX * 2.0) {
                return false
            }
        }
        return true
    }
    
    // MARK: - Encoding From LatLng pair
    public static func encode(latitude: Float64, longitude: Float64, codeLength: Int = OpenLocationCode.DEFAULT_CODE_LENGTH) throws -> String {
        var _codeLength = codeLength
        if (codeLength > OpenLocationCode.MAX_CODE_LENGTH) {
            _codeLength = OpenLocationCode.MAX_CODE_LENGTH
        }
        if ((_codeLength < 2) || (_codeLength < LENGTH_BASE && _codeLength % 2 == 1)) {
            throw OpenLocationCodeError.encodingError
        }
        var working_latitude = clipLatitude(latitude: latitude)
        let working_longitude = normalizeLongitude(longitude: longitude)
        if (working_latitude == 90.0) {
            working_latitude = working_latitude - precision_code_length(codeLength: _codeLength)
        }
        var code: String = encodePairs(latitude: working_latitude, longitude: working_longitude, codeLength: min(_codeLength, DEFAULT_CODE_LENGTH))
        if (_codeLength > DEFAULT_CODE_LENGTH) {
            code += encodeGrid(latitude: working_latitude, longitude: working_longitude, codeLenAfterDefaultLen: _codeLength - DEFAULT_CODE_LENGTH)
        }
        return code
    }
    
    // MARK: - Helper Functions
    /*
     * If the latitude is greater than 90.0, make it 90.0, if less than -90.0, make it -90.0
     */
    public static func clipLatitude(latitude: Float64) -> Float64 {
        return fmin(90.0, fmax(-90.0, latitude))
    }
    
    // MARK: Normalize Longitude
    /*
     * If longitude is less than min, make it a positive angle (less than 180). 
     * If a longitude is greater than max, make it a negative one (greater than -180).
     */
    public static func normalizeLongitude(longitude: Float64) -> Float64 {
        var tempLongitude = longitude
        while (tempLongitude < OpenLocationCode.LONGITUDE_MIN) {
            tempLongitude = longitude + (2.0 * LONGITUDE_MAX)
        }
        while (tempLongitude >= 180) {
            tempLongitude = tempLongitude + (2.0 * LONGITUDE_MIN)
        }
        return tempLongitude;
    }
    
    // MARK: Powers With Negative Exponents
    /*
     * From C++ version of OLC implementation
     * https://github.com/google/open-location-code/blob/master/cpp/openlocationcode.cc
     */
    public static func powNeg(base: Float64, exponent: Float64) -> Float64 {
        if (exponent == 0) {
            return 1.0
        } else if (exponent > 0) {
            return pow(base, exponent)
        } else {
            return 1/(pow(base, fabs(exponent)))
        }
    }
    
    // MARK: Calculate Precision For OLC length
    public static func precision_code_length(codeLength: Int) -> Float64 {
        if (codeLength <= DEFAULT_CODE_LENGTH) {
            return powNeg(base: BASE_FOR_PREFIX, exponent: floor(Double(Int(codeLength / -2) + 2)));
        }
        return powNeg(base: BASE_FOR_PREFIX, exponent: -3) / pow(5.0, Float64(codeLength - DEFAULT_CODE_LENGTH));
    }
    
    // MARK: - Encode LatLng Pairs up to 10 places
    /*
     * https://github.com/google/open-location-code/blob/master/python/openlocationcode.py
     */
    private static func encodePairs(latitude: Float64, longitude: Float64, codeLength: Int) -> String {
        var code: [Character] = []
        var adjustedLatitude = latitude + LATITUDE_MAX
        var adjustedLongitude = longitude + LONGITUDE_MAX
        var char_count = 0
        while (char_count < codeLength) {
            /* I don't know what the limitations are here rather than the mathematical way the C++ from google handles this.
             * For the moment, I will use the array of preset values for resolution values, which is the way the rust and python do it.
             *
             * Either way, we handle one resolution step for a pair of characters in the OLC
             * Remembering, that this can go past the PLUS_SEPARATOR, we must add it at the 8th position (counting from 0)
             */
            let placeMultiplier = RESOLUTION_STEPS[Int(char_count/2)] // Int already does the floor
            var digitValue = Int(adjustedLatitude / placeMultiplier)
            adjustedLatitude -= (Float64(digitValue) * placeMultiplier)
            code.append(CODE_ALPHABET[digitValue])
            char_count += 1
            digitValue = Int(adjustedLongitude / placeMultiplier)
            adjustedLongitude -= (Float64(digitValue) * placeMultiplier)
            code.append(CODE_ALPHABET[digitValue])
            char_count += 1
            if (char_count == LENGTH_BASE && char_count < codeLength) {
                code.append(PLUS_SEPARATOR)
            }
        }
        /*
         * If we have finished a short code it needs to be filled to the separator with the padding character
         */
        while (char_count < LENGTH_BASE) {
            code.append(PADDING_CHARACTER)
            char_count += 1
        }
        if (char_count == LENGTH_BASE) {
            code.append(PLUS_SEPARATOR)
        }
        return String(code)
    }
    
    // Also stealing from the python and rust implementations from google
    // https://github.com/google/open-location-code/blob/master/python/openlocationcode.py
    private static func encodeGrid(latitude: Float64, longitude: Float64, codeLenAfterDefaultLen: Int) -> String {
        var code: [Character] = []
        // Initialize the multipliers to the same value, but they will change according to the dimensions of the grid
        var latPlaceMultiplier = RESOLUTION_STEPS.last!
        var lngPlaceMultiplier = RESOLUTION_STEPS.last!
        // Adjust to positive range.
        var adjustedLatitude = latitude + LATITUDE_MAX
        var adjustedLongitude = longitude + LONGITUDE_MAX
        // To avoid problems with floating point, get rid of the degrees.
        adjustedLatitude = adjustedLatitude.truncatingRemainder(dividingBy: 1.0)
        adjustedLongitude = adjustedLongitude.truncatingRemainder(dividingBy: 1.0)
        // This is the remainder after we have calculated up to the last RESOLUTION step
        adjustedLatitude = adjustedLatitude.truncatingRemainder(dividingBy: latPlaceMultiplier)
        adjustedLongitude = adjustedLongitude.truncatingRemainder(dividingBy: lngPlaceMultiplier)
        for _ in 0..<codeLenAfterDefaultLen {
            // FP Multiplication is usually less costly than division
            let row = Int((adjustedLatitude * MATRIX_FOR_PLUS_DIM.rows) / latPlaceMultiplier)
            let col = Int((adjustedLongitude * MATRIX_FOR_PLUS_DIM.cols) / lngPlaceMultiplier)
            // Every subsequent iteration for a SINGLE character is a factor smaller from that last RESOLUTION step
            latPlaceMultiplier /= MATRIX_FOR_PLUS_DIM.rows
            lngPlaceMultiplier /= MATRIX_FOR_PLUS_DIM.cols
            adjustedLatitude -= Float64(row) * latPlaceMultiplier
            adjustedLongitude -= Float64(col) * lngPlaceMultiplier
            code.append(MATRIX_FOR_PLUS[row][col])
        }
        return String(code)
    }
    
    //MARK: - Decoding
    public static func decode(code: String) throws -> CodeArea {
        if (OpenLocationCode.isValidOLC(code: code) != 1){
            throw OpenLocationCodeError.decodingError
        }
        let preprep_code = String(code.uppercased().filter{ CODE_ALPHABET.contains($0) })
        let codeLength = min(preprep_code.lengthOfBytes(using: .ascii), OpenLocationCode.MAX_CODE_LENGTH)
        let codeOffset = preprep_code.index(preprep_code.startIndex, offsetBy: codeLength)
        let _code = preprep_code[..<codeOffset]
        // Separate the first 10 from the rest
        var code_prefix = ""
        var code_suffix = ""
        if (codeLength >= 10) {
            let suffix_start = _code.index(_code.startIndex, offsetBy: 10)
            code_prefix = String(_code[_code.startIndex..<suffix_start])
            code_suffix = String(_code[suffix_start..<_code.endIndex])
        } else {
            code_prefix = String(_code)
        }
        // Decode the first 10 or fewer
        let prefixArea = decodePairs(code_prefix)
        if (code_suffix.isEmpty) {
            return prefixArea
        }
        // Decode the extra characters
        let gridArea = decodeGrid(code_suffix)
        /*
         * This narrows the space from the low point to the grid's refinement region
         * There is a chance the actual original encoded point was between the center and the high,
         * but I'm not sure how much that matters after the 10 character prefix
         */
        return CodeArea(latitudeLow: prefixArea.latitudeLow + gridArea.latitudeLow,
                        longitudeLow: prefixArea.longitudeLow + gridArea.longitudeLow,
                        latitudeHigh: prefixArea.latitudeLow + gridArea.latitudeHigh,
                        longitudeHigh: prefixArea.longitudeLow + gridArea.longitudeHigh,
                        codeLength: prefixArea.codeLength + gridArea.codeLength)
    }
    
    /*
     * Decode pairs works from the first pair up to the 5th pair (5 steps of resolution).
     * So the maximum length of the codePrefix is 10, which is split into two arrays of 
     * equal length (max 5 each).
     */
    private static func decodePairs(_ codePrefix: String) -> CodeArea {
        let latArray = codePrefix.enumerated().filter{ $0.offset % 2 == 0 }
        let lngArray = codePrefix.enumerated().filter{ $0.offset % 2 == 1 }
        let latRange: (low: Float64, high: Float64) = decodeSequence(codePart: latArray)
        let lngRange: (low: Float64, high: Float64) = decodeSequence(codePart: lngArray)
        return CodeArea(latitudeLow: latRange.low - LATITUDE_MAX,
                        longitudeLow: lngRange.low - LONGITUDE_MAX,
                        latitudeHigh: latRange.high - LATITUDE_MAX,
                        longitudeHigh: lngRange.high - LONGITUDE_MAX,
                        codeLength: latArray.count + lngArray.count)
    }
    
    // Takes a sequence of the Latitude or Longitude array (the string that was enumerated string and decomposed)
    private static func decodeSequence(codePart: [(offset: Int, element: Character)]) -> (low: Float64, high: Float64) {
        var value: Float64 = 0.0
        var i = 0
        while (i < codePart.count) {
            value += Float64(CODE_ALPHABET.index(of: codePart[i].element)!) * RESOLUTION_STEPS[i]
            i += 1
        }
        return (low: value, high: value + RESOLUTION_STEPS[i - 1])
    }
    
    /*
     * Starting after the last step of resolution each subsequent character represents a combination of 
     * Latitude and longitude values which are ordered according to the MATRIX_FOR_PLUS (5 rows, 4 columns)
     * since the base is 20.
     */
    private static func decodeGrid(_ codeSuffix: String) -> CodeArea {
        var latitudeLow: Float64 = 0.0
        var longitudeLow: Float64 = 0.0
        var latPlaceMultiplier = RESOLUTION_STEPS.last!
        var lngPlaceMultiplier = RESOLUTION_STEPS.last!
        for char in codeSuffix {
            let rc = MATRIX_FOR_PLUS.indices(of: char)!
            // it must be found, so it can be unwrapped
            latPlaceMultiplier /= MATRIX_FOR_PLUS_DIM.rows
            lngPlaceMultiplier /= MATRIX_FOR_PLUS_DIM.cols
            latitudeLow += rc.row * latPlaceMultiplier
            longitudeLow += rc.col * lngPlaceMultiplier
        }
        return CodeArea(latitudeLow: latitudeLow, longitudeLow: longitudeLow, latitudeHigh: latitudeLow + latPlaceMultiplier, longitudeHigh: longitudeLow + lngPlaceMultiplier, codeLength: codeSuffix.count)
    }
    
    public static func smallestBoundingBox(_ code_a: String, _ code_b: String) throws -> OpenLocationCode? {
        let a_valid = isValidOLC(code: code_a)
        let b_valid = isValidOLC(code: code_b)
        if (a_valid != 1 || b_valid != 1) {
            throw OpenLocationCodeError.invalidCode
        }
        let code_a_chars = code_a.filter { CODE_ALPHABET.contains($0) }
        let code_b_chars = code_b.filter { CODE_ALPHABET.contains($0) }
        var similar = 0
        for i in 0..<code_a_chars.count {
            if (i >= code_b_chars.count) {
                break
            }
            let subset_a = code_a_chars[...code_a_chars.index(code_a_chars.startIndex, offsetBy:i)]
            let subset_b = code_b_chars[...code_b_chars.index(code_b_chars.startIndex, offsetBy:i)]
            if subset_a.elementsEqual(subset_b) {
                similar = i
            } else {
                break;
            }
        }
        if (similar <= 1) {
            throw OpenLocationCodeError.dissimilarRegions
        }
        if (similar <= 9 && similar % 2 == 1) {
            // Remove one more, because they are still in pairs
            similar -= 1
        }
        var new_chars = code_a_chars[...code_a_chars.index(code_a_chars.startIndex, offsetBy:similar+1)]
        while new_chars.count < LENGTH_BASE {
            new_chars.append(PADDING_CHARACTER)
        }
        if (new_chars.count == LENGTH_BASE) {
            new_chars.append(PLUS_SEPARATOR)
        } else if (new_chars.count > LENGTH_BASE) {
            // reinsert +
            new_chars.insert(PLUS_SEPARATOR, at: code_a_chars.index(code_a_chars.startIndex, offsetBy:(LENGTH_BASE+1)))
        }
        return try? OpenLocationCode(String(new_chars))
    }
}

// https://stackoverflow.com/questions/37314322/how-to-find-the-index-of-an-item-in-a-multidimensional-array-swiftily
// Martin R.'s very elegant optional pair return
extension Array where Element : Collection, Element.Iterator.Element : Equatable, Element.Index == Int {
    func indices(of x: Element.Iterator.Element) -> (row: Float64, col: Float64)? {
        for (i, row) in self.enumerated() {
            if let j = row.index(of: x) {
                return (row: Float64(i), col: Float64(j))
            }
        }
        return nil
    }
}
