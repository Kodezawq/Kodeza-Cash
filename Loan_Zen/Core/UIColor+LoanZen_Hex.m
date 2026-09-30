#import "UIColor+LoanZen_Hex.h"

@implementation UIColor (LoanZen_Hex)

+ (UIColor *)LZ_colorWithHex:(uint32_t)hex alpha:(CGFloat)alpha {
    CGFloat r = ((hex >> 16) & 0xFF) / 255.0;
    CGFloat g = ((hex >> 8) & 0xFF) / 255.0;
    CGFloat b = (hex & 0xFF) / 255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

@end
