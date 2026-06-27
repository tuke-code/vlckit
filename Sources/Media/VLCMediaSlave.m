/*****************************************************************************
 * VLCMediaSlave.m
 *****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCMediaSlave.h"
#import "VLCLibVLCBridging.h"
#import <vlc/libvlc.h>

@implementation VLCMediaSlave

- (instancetype)initWithURL:(NSURL *)URL
                       type:(VLCMediaSlaveType)type
                   priority:(NSUInteger)priority
{
    self = [super init];
    if (self) {
        _URL = URL;
        _type = type;
        _priority = priority;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ type: %lu, priority: %lu, URL: %@",
            NSStringFromClass([self class]), (unsigned long)_type, (unsigned long)_priority, _URL];
}

@end

@implementation VLCMediaSlave (LibVLCBridging)

+ (nullable instancetype)mediaSlaveWithLibVLCSlave:(const libvlc_media_slave_t *)slave
{
    if (slave == NULL || slave->psz_uri == NULL)
        return nil;

    NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:slave->psz_uri]];
    if (url == nil)
        return nil;

    VLCMediaSlaveType type = (slave->i_type == libvlc_media_slave_type_subtitle)
                             ? VLCMediaSlaveTypeSubtitle : VLCMediaSlaveTypeAudio;
    return [[VLCMediaSlave alloc] initWithURL:url type:type priority:slave->i_priority];
}

@end
