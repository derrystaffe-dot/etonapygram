import Foundation

/// Telegram has no API for an account's creation date. User ids are handed out in increasing
/// order, so the date is interpolated between known (id, registration date) points. The
/// result is only good to a few months, which is why callers show month and year only.
public enum EtonaRegistrationDate {
    private static let knownPoints: [(id: Int64, timestamp: Int64)] = [
        (1_000_000, 1_380_326_400),       // 2013-09
        (2_768_409, 1_383_264_000),       // 2013-11
        (7_679_610, 1_388_448_000),       // 2013-12
        (11_538_514, 1_391_212_000),      // 2014-02
        (15_835_244, 1_392_940_000),      // 2014-02
        (23_646_077, 1_393_459_000),      // 2014-02
        (38_015_510, 1_393_632_000),      // 2014-03
        (44_634_663, 1_399_334_000),      // 2014-05
        (46_145_305, 1_400_198_000),      // 2014-05
        (54_845_238, 1_411_257_000),      // 2014-09
        (63_263_518, 1_414_454_000),      // 2014-10
        (101_260_938, 1_425_600_000),     // 2015-03
        (111_220_210, 1_429_574_000),     // 2015-04
        (116_812_045, 1_437_696_000),     // 2015-07
        (130_029_930, 1_441_324_000),     // 2015-09
        (157_242_073, 1_446_768_000),     // 2015-11
        (171_295_414, 1_457_481_000),     // 2016-03
        (181_783_990, 1_460_246_000),     // 2016-04
        (222_021_233, 1_465_344_000),     // 2016-06
        (225_034_354, 1_466_208_000),     // 2016-06
        (278_941_742, 1_473_465_000),     // 2016-09
        (285_253_072, 1_476_835_000),     // 2016-10
        (294_851_037, 1_479_600_000),     // 2016-11
        (328_594_461, 1_482_969_000),     // 2016-12
        (337_808_429, 1_487_707_000),     // 2017-02
        (369_669_043, 1_490_918_000),     // 2017-03
        (400_169_472, 1_501_459_000),     // 2017-07
        (616_816_630, 1_529_625_600),     // 2018-06
        (805_158_066, 1_563_208_000),     // 2019-07
        (1_000_000_000, 1_577_836_800),   // 2020-01
        (1_400_000_000, 1_601_510_400),   // 2020-10
        (1_974_255_900, 1_634_000_000),   // 2021-10
        (5_000_000_000, 1_640_995_200),   // 2022-01, 64-bit ids start
        (5_500_000_000, 1_659_312_000),   // 2022-08
        (6_000_000_000, 1_672_531_200),   // 2023-01
        (6_500_000_000, 1_690_848_000),   // 2023-08
        (7_000_000_000, 1_709_251_200),   // 2024-03
        (7_500_000_000, 1_725_148_800),   // 2024-09
        (8_000_000_000, 1_740_787_200),   // 2025-03
        (8_500_000_000, 1_759_276_800),   // 2025-10
    ]

    /// Approximate registration date of the user with this id, or `nil` for ids outside the table
    /// (bots and service accounts mostly).
    public static func approximateDate(userId: Int64) -> Date? {
        let points = EtonaRegistrationDate.knownPoints
        guard userId > 0, let first = points.first, let last = points.last else {
            return nil
        }
        if userId <= first.id {
            return Date(timeIntervalSince1970: TimeInterval(first.timestamp))
        }
        if userId >= last.id {
            // Past the table: extrapolate with the slope of its last segment, capped at now.
            let previous = points[points.count - 2]
            let slope = Double(last.timestamp - previous.timestamp) / Double(last.id - previous.id)
            let timestamp = Double(last.timestamp) + slope * Double(userId - last.id)
            return Date(timeIntervalSince1970: min(timestamp, Date().timeIntervalSince1970))
        }
        for i in 1 ..< points.count {
            let lower = points[i - 1]
            let upper = points[i]
            if userId <= upper.id {
                let fraction = Double(userId - lower.id) / Double(upper.id - lower.id)
                let timestamp = Double(lower.timestamp) + fraction * Double(upper.timestamp - lower.timestamp)
                return Date(timeIntervalSince1970: timestamp)
            }
        }
        return nil
    }
}
