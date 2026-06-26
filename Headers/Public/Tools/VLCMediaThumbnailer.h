/*****************************************************************************
 * VLCKit: VLCMediaThumbnailer
 *****************************************************************************
 * Copyright (C) 2010-2026 Pierre d'Herbemont and VideoLAN
 *
 * Authors: Pierre d'Herbemont
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
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCMedia, VLCLibrary, VLCTime;
@protocol VLCMediaThumbnailerDelegate;

/**
 * a facility allowing you to do thumbnails in an efficient manner
 */
OBJC_VISIBLE
@interface VLCMediaThumbnailer : NSObject

/**
 * initializer
 * \param media the media item to thumbnail
 * \param delegate the delegate implementing the required protocol
 * \return the thumbnailer instance
 * \note This will use the default shared library instance
 */
+ (VLCMediaThumbnailer *)thumbnailerWithMedia:(VLCMedia *)media andDelegate:(id<VLCMediaThumbnailerDelegate>)delegate;
/**
 * initializer
 * \param media the media item to thumbnail
 * \param delegate the delegate implementing the required protocol
 * \param library a library instance, potentially configured by you in a special way
 * \return the thumbnailer instance
 */
+ (VLCMediaThumbnailer *)thumbnailerWithMedia:(VLCMedia *)media delegate:(id<VLCMediaThumbnailerDelegate>)delegate andVLCLibrary:(nullable VLCLibrary *)library;

/**
 * Starts the thumbnailing process
 */
- (void)fetchThumbnail;

/**
 * Cancels an ongoing thumbnailing process
 * \note no delegate callback will be sent once cancelled
 */
- (void)cancel;

/**
 * delegate object associated with the thumbnailer instance implementing the required protocol
 */
@property (readwrite, weak, nonatomic, nullable) id<VLCMediaThumbnailerDelegate> delegate;
/**
 * the media object that is being thumbnailed
 */
@property (readwrite, nonatomic) VLCMedia *media;
/**
 * The thumbnail created for the media object
 */
@property (readwrite, assign, nonatomic, nullable) CGImageRef thumbnail;
/**
 * Thumbnail Height
 * \note Any change made after -fetchThumbnail has been called is ignored.
 * @return thumbnail height. Default value 240.
 */
@property (readwrite, assign, nonatomic) CGFloat thumbnailHeight;

/**
 * Thumbnail Width
 * \note Any change made after -fetchThumbnail has been called is ignored.
 * @return thumbnail height. Default value 320
 */
@property (readwrite, assign, nonatomic) CGFloat thumbnailWidth;

/**
 * Snapshot Position
 * \note Any change made after -fetchThumbnail has been called is ignored.
 * @return snapshot position. Default value 0.3
 */
@property (readwrite, assign, nonatomic) float snapshotPosition;

/**
 * Snapshot Time
 * When set, the thumbnail is taken at this time and snapshotPosition is ignored.
 * \note Any change made after -fetchThumbnail has been called is ignored.
 */
@property (readwrite, nonatomic, nullable) VLCTime *snapshotTime;

/**
 * Whether hardware decoding is used while thumbnailing. Default NO.
 * \note Any change made after -fetchThumbnail has been called is ignored.
 */
@property (readwrite, assign, nonatomic) BOOL hardwareDecodingEnabled;

/**
 * Whether the thumbnailer seeks precisely rather than fast (the default). Default NO.
 * \note Any change made after -fetchThumbnail has been called is ignored.
 */
@property (readwrite, assign, nonatomic) BOOL preciseSeek;

/**
 * Whether the thumbnail is cropped to fit thumbnailWidth x thumbnailHeight.
 * Only meaningful when both width and height are non-zero. Default NO.
 * \note Any change made after -fetchThumbnail has been called is ignored.
 */
@property (readwrite, assign, nonatomic) BOOL cropsToFit;
@end

/**
 * the required delegate protocol for VLCMediaThumbnailer
 */
@protocol VLCMediaThumbnailerDelegate
@required
/**
 * called when the thumbnailing process timed-out
 * \param mediaThumbnailer the thumbnailer instance that timed out
 * \note The time-out duration depends on various factors outside your control and will not be the same for different media
 */
- (void)mediaThumbnailerDidTimeOut:(VLCMediaThumbnailer *)mediaThumbnailer;
/**
 * called when the thumbnailer did successfully created a thumbnail
 * \param mediaThumbnailer the thumbnailer instance that was successful
 * \param thumbnail the thumbnail that was created
 */
- (void)mediaThumbnailer:(VLCMediaThumbnailer *)mediaThumbnailer didFinishThumbnail:(CGImageRef)thumbnail;
@end

NS_ASSUME_NONNULL_END
