//
//  OpenPGPMPI.m
//  ObjectivePGP
//
//  Created by Marcin Krzyzanowski on 04/05/14.
//  Copyright (c) 2014 Marcin Krzyżanowski. All rights reserved.
//
//  Multiprecision integers (also called MPIs) are unsigned integers used
//  to hold large integers such as the ones used in cryptographic
//  calculations.

#import "PGPMPI.h"
#import <openssl/bn.h>

@interface PGPMPI ()
@property (assign) UInt16 mpiBitsLengthBE; //check _bn->dmax
@end

@implementation PGPMPI {
    BIGNUM *_bn;
}

- (instancetype) initWithData:(NSData *)data atPosition:(NSUInteger)position
{
    if (self = [self init]) {
        _mpiBitsLengthBE = 0;
        [data getBytes:&_mpiBitsLengthBE range:(NSRange){position,2}];
        NSUInteger mpiBytesLength = (CFSwapInt16BigToHost(_mpiBitsLengthBE) + 7) / 8;

        NSData *intdata = [data subdataWithRange:(NSRange){position + 2, mpiBytesLength}];
        _bn = BN_bin2bn(intdata.bytes, (int)intdata.length, NULL);

        // Additinal rule: The size of an MPI is ((MPI.length + 7) / 8) + 2 octets.
        _length = intdata.length + 2;
    }
    return self;
}

- (NSData *) buildData
{
    if (!_bn) {
        return nil;
    }

    NSMutableData *outData = [NSMutableData data];

    NSUInteger mpiBytesLength = (CFSwapInt16BigToHost(_mpiBitsLengthBE) + 7) / 8;
    UInt8 *buf = calloc(mpiBytesLength, sizeof(UInt8));
    UInt16 bytes = BN_bn2bin(_bn, buf);

    //FIXME: _mpiBitsLengthBE should be calculated from BN

    [outData appendBytes:&_mpiBitsLengthBE length:2];
    [outData appendBytes:buf length:bytes];

    return [outData copy];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, \"%@\", %@ bytes, total: %@ bytes", [super description], self.identifier, @(BN_num_bytes(_bn)), @(_length)];
}

- (void)dealloc
{
    if (_bn != NULL) {
        BN_clear_free(_bn);
    }
}

@end