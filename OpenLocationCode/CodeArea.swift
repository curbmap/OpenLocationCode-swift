//
//  CodeArea.swift
//  OpenLocationCode
//
//  Created by Eli Selkin on 7/27/17.
//  Copyright © 2017 curbmap. All rights reserved.
//

import Foundation
/*
 * Since Open Location Codes are not actually supposed to represent a point, but rather a region,
 * the code area represents the range of possiblities in a grid of latitude and longitude. Generally,
 * on google's http://plus.codes website the position of OLC is returned as one set of latitude and longitude.
 * You might ask, "how can that be?"... They take the average.
 * Remember that the specificity of a CodeArea is actually representative of length of resolution of the initial code.
 * You'll get a larger CodeArea for a shorter code.
 */
public struct CodeArea {
    public let latitudeLow: Float64;
    public let longitudeLow: Float64;
    public let latitudeHigh: Float64;
    public let longitudeHigh: Float64;
    let latitudeCenter: Float64;
    let longitudeCenter: Float64;
    public let codeLength: Int;
    init(latitudeLow: Float64, longitudeLow: Float64, latitudeHigh: Float64, longitudeHigh: Float64, codeLength: Int) {
        self.latitudeLow = latitudeLow
        self.longitudeLow = longitudeLow
        self.latitudeHigh = latitudeHigh
        self.longitudeHigh = longitudeHigh
        self.latitudeCenter = min( (latitudeLow + latitudeHigh)/2, OpenLocationCode.LATITUDE_MAX )
        self.longitudeCenter = min( (longitudeLow + longitudeHigh)/2, OpenLocationCode.LONGITUDE_MAX )
        self.codeLength = codeLength
    }
    
    public func LatLng() -> (latitude: Float64, longitude: Float64){
        return (latitude: self.latitudeCenter, longitude: self.longitudeCenter)
    }
}
