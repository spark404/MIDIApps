//
//  SMShowControlUtilities.m
//  SnoizeMIDI
//
//  Created by Hugo Trippaers on 22/12/2018.
//

#import <Foundation/Foundation.h>

#import "SMShowControlUtilities.h"

#define BIT(n)                  ( 1<<(n) )
#define BIT_MASK(len)           ( BIT(len)-1 )
#define BITFIELD_MASK(start, len)     ( BIT_MASK(len)<<(start) )
#define BITFIELD_GET(y, start, len)   ( ((y)>>(start)) & BIT_MASK(len) )

Timecode parseTimecodeBytes(NSData *timecodeBytes) {
    Timecode timecode;
    const Byte *byte = timecodeBytes.bytes;
    // Hours and type: 0 tt hhhhh
    timecode.timecodeType = BITFIELD_GET(*byte, 5, 2);
    timecode.hours = BITFIELD_GET(*byte++, 0, 5);
    
    // Minutes and color frame bit: 0 c mmmmmm
    timecode.colorFrameBit = BITFIELD_GET(*byte, 6, 1);
    timecode.minutes = BITFIELD_GET(*byte++, 0, 5);
    
    // Seconds: 0 k ssssss
    timecode.seconds = BITFIELD_GET(*byte++, 0, 5);
    
    // Frames, byte 5 ident and sign: 0 g i fffff
    timecode.sign = BITFIELD_GET(*byte, 6, 1);
    timecode.form = BITFIELD_GET(*byte, 5, 1);
    timecode.frames = BITFIELD_GET(*byte++, 0, 5);
    
    if (timecode.form) {
        // code status bit map:0 e v d xxxx
        timecode.statusEstimatedCodeFlag = BITFIELD_GET(*byte, 6, 1);
        timecode.statusInvalidCode = BITFIELD_GET(*byte, 5, 1);
        timecode.statusVideoFieldIndentification = BITFIELD_GET(*byte, 4, 1);
    } else {
        // fractional frames: 0 bbbbbbb
        timecode.subframes = BITFIELD_GET(*byte, 0, 7);
    }
    
    return timecode;
}

NSArray *parseCueItemsBytes(NSData *cueItemsBytes) {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSUInteger length = [cueItemsBytes length];
    
    const Byte *cueData = cueItemsBytes.bytes;
    
    NSUInteger startIndex = 0;
    for (NSUInteger i = 0; i < [cueItemsBytes length]; i++) {
        Byte currentByte = *(cueData + i);
        NSUInteger copyLength = (currentByte != 0x00 ? i - startIndex + 1: i - startIndex);
        
        if ((currentByte == 0x0 || i == length - 1) && copyLength > 0) {
            [result addObject:[[NSString alloc] initWithBytes:cueItemsBytes.bytes + startIndex length:copyLength encoding:NSASCIIStringEncoding]];
            startIndex = i + 1;
        }
    }
    
    return result;
}
