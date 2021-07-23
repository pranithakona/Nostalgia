//
//  NSDate+NSDateHelper.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/23/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (NSDateHelper)

+ (NSString *)fullDateString:(NSDate *)date;
+ (NSString *)dateOnlyString:(NSDate *)date;
+ (NSString *)timeOnlyString:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
