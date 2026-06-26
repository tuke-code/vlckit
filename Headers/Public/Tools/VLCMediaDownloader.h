/*****************************************************************************
 * VLCMediaDownloader.h
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
#import "VLCMedia.h"
#import "VLCMediaList.h"
#import "VLCMediaSlave.h"

NS_ASSUME_NONNULL_BEGIN

@class VLCLibrary;
@class VLCMediaDownloader;
@class VLCMediaDownloadTask;

typedef NS_ENUM(NSInteger, VLCMediaDownloadStatus) {
    VLCMediaDownloadStatusPending = 0,
    VLCMediaDownloadStatusRunning,
    VLCMediaDownloadStatusPaused,
    VLCMediaDownloadStatusFinished,
    VLCMediaDownloadStatusCancelled,
    VLCMediaDownloadStatusError
};

FOUNDATION_EXPORT const NSInteger VLCMediaDownloadConsumedError;
FOUNDATION_EXPORT const NSInteger VLCMediaDownloadConsumedCancel;

@protocol VLCMediaDownloaderDelegate <NSObject>

@required

/**
 * Called when a chunk of downloaded data is available.
 * \param task the task delivering the data
 * \param data backed by a downloader-owned buffer that is valid only for the
 * duration of this call and must not be retained; copy it if you need it afterwards
 * \param position the total number of bytes read so far
 * \param total the total size of the media in bytes
 * \return the number of bytes consumed; if less than data.length the download
 * auto-pauses, resume via -setPaused:NO. Return VLCMediaDownloadConsumedError or
 * VLCMediaDownloadConsumedCancel to abort. Invoked synchronously on a background queue.
 */
- (NSInteger)mediaDownloadTask:(VLCMediaDownloadTask *)task
                didReceiveData:(NSData *)data
                      position:(uint64_t)position
                         total:(uint64_t)total;

/**
 * Called whenever the task status changes.
 * \param task the task whose status changed
 * \param status the new status
 */
- (void)mediaDownloadTask:(VLCMediaDownloadTask *)task
          didUpdateStatus:(VLCMediaDownloadStatus)status;

@optional

/**
 * Called when the media is a playlist or directory; the download does not proceed.
 * \param task the task
 * \param subitems the discovered subitems
 */
- (void)mediaDownloadTask:(VLCMediaDownloadTask *)task
        didReceiveSubitems:(VLCMediaList *)subitems;

/**
 * Called when the media has slaves such as external subtitles or audio.
 * \param task the task
 * \param slaves the discovered slaves
 */
- (void)mediaDownloadTask:(VLCMediaDownloadTask *)task
          didReceiveSlaves:(NSArray<VLCMediaSlave *> *)slaves;

@end

@interface VLCMediaDownloadTask : NSObject

@property (nonatomic, readonly) VLCMedia *media;
@property (nonatomic, readonly) VLCMediaDownloadStatus status;
@property (nonatomic, getter=isPaused) BOOL paused;

- (void)cancel;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface VLCMediaDownloader : NSObject

- (instancetype)init;

/**
 * Initializes a downloader using the provided library instance.
 * \param library a custom VLCLibrary configured for the specific client app
 * \return a VLCMediaDownloader instance using the provided VLCLibrary
 */
- (instancetype)initWithLibrary:(VLCLibrary *)library NS_DESIGNATED_INITIALIZER;

/**
 * Queues a media for asynchronous download.
 * \param media the finite-size media to download
 * \param delegate the delegate receiving data and status callbacks
 * \return a download task on success, or nil in case of error
 */
- (nullable VLCMediaDownloadTask *)downloadMedia:(VLCMedia *)media
                                        delegate:(id<VLCMediaDownloaderDelegate>)delegate;

- (void)cancelAll;

@end

NS_ASSUME_NONNULL_END
