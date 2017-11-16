# OpenLocationCode-swift
Open location code framework for swift
For original code, see @google [Google's code](https://github.com/google/open-location-code)

**Make sure you follow all of the general installation procedures for CocoaPods**

**To install this framework for your project**
* add this line to your Podfile:
```
pod 'OpenLocationCode' '~>0.0.4.7'
```

* follow that with a pod install (you may have to update if you don't have the newest spec list)

Then, in your project swift file.
```
import OpenLocationCode
```

Currently there are two public static methods which can be used from the class itself.
1. OpenLocationCode.encode which takes a latitude and longitude (Double/Float64s) named pair and a desired code length. It returns the string of a full Open Location Code.
```
OpenLocationCode.encode(LatLng: (latitude: y, longitude: x), codeLength: Int)
```
2. OpenLocationCode.decode which takes an Open Location Code string and returns a CodeArea. Open Location Codes aren't really meant for a point, but rather a region (even if it's a very small region) so there will necessarily be some range associated with decoding.
```
OpenLocationCode.decode(code: String)
```
