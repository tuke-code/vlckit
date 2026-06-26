/*****************************************************************************
 * VLCMediaSlave.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VLCMediaSlaveType) {
    VLCMediaSlaveTypeSubtitle = 0,
    VLCMediaSlaveTypeAudio
};

@interface VLCMediaSlave : NSObject

@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) VLCMediaSlaveType type;
@property (nonatomic, readonly) NSUInteger priority;

/**
 * Initializes a new media slave.
 * \param URL the location of the slave resource
 * \param type the slave type
 * \param priority the selection priority
 * \return a newly created media slave
 */
- (instancetype)initWithURL:(NSURL *)URL
                       type:(VLCMediaSlaveType)type
                   priority:(NSUInteger)priority NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
