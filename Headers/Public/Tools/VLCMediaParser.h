/*****************************************************************************
 * VLCMediaParser.h
 *****************************************************************************
 * Copyright (C) 2024-2026 VLC authors and VideoLAN
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

NS_ASSUME_NONNULL_BEGIN

@protocol VLCMediaParserDelegate <NSObject>

@required

/**
 * Delegate method called whenever a media was parsed.
 * \param media The media resource whose meta data has been changed.
 * \param status the resulting parsing status
 */
- (void)mediaFinishedParsing:(VLCMedia *)media withStatus:(VLCMediaParsedStatus)status;

@end

@interface VLCMediaParser : NSObject

/**
 * enum of available options for use with parseWithOptions
 * \note you may pipe multiple values for the single parameter
 */
typedef NS_OPTIONS(int, VLCMediaParsingOptions) {
    VLCMediaParseLocal          = 0x01,     ///< Parse media if it's a local file
    VLCMediaParseNetwork        = 0x02,     ///< Parse media even if it's a network file
    VLCMediaParseForced         = 0x04,     ///< Force parsing the media even if it would be skipped
    VLCMediaFetchLocal          = 0x08,     ///< Fetch meta and cover art using local resources
    VLCMediaFetchNetwork        = 0x10,     ///< Fetch meta and cover art using network resources
    VLCMediaDoInteract          = 0x20,     ///< Interact with the user when preparsing this item (and not its sub items). Set this flag in order to receive a callback when the input is asking for credentials.
};

/**
 * a delegate conforming to the VLCMediaParserDelegate protocol
 * \return the delegate object
 */
@property (weak, nullable) id<VLCMediaParserDelegate> delegate;

/**
 * Returns a shared instance of a parser using the default VLCLibrary instance
 *
 * \return a VLCMediaParser instance using the default VLCLibrary
 *
 * \note for performance reasons, you should re-use a VLCMediaParser instance once created
 */
+ (instancetype)sharedParser;

/**
 * Returns a instance of a parser using the provided VLCLibrary instance
 *
 * \param library a custom VLCLibrary configured for the specific client app
 * \param timeout a time-out value in milliseconds (-1 for default, 0 for infinite)
 * \return a VLCMediaParser instance using the provided VLCLibrary
 *
 * \note for performance reasons, you should re-use a VLCMediaParser instance once created
 */
- (instancetype)initWithLibrary:(VLCLibrary *)library timeout:(int)timeout;

/**
 * Triggers an asynchronous parse of the media item using the given options by queueing it
 *
 * \param media the media object to parse
 * \param options the option mask based on VLCMediaParsingOptions
 * \return 0 on success, -1 in case of error
 *
 * \note Listen to the "parsedStatus" key value or the mediaDidFinishParsing:
 * delegate method of the media to be notified about parsing results.
 *
 * \note Alternatively, register a delegate to this parser to be notified about all parsing events of all media
 *
 * \see VLCMediaParsingOptions
 */
- (int)queueMedia:(VLCMedia *)media options:(VLCMediaParsingOptions)options;

/**
 * Cancels a pending parse request for the given media.
 * \param media the media whose parsing should be cancelled
 */
- (void)cancelParsingForMedia:(VLCMedia *)media;

/**
 * Cancels all pending parse requests.
 */
- (void)cancelAllParsing;

@end

NS_ASSUME_NONNULL_END
