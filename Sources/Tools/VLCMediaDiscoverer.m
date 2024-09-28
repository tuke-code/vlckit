/*****************************************************************************
 * VLCMediaDiscoverer.m: VLCKit.framework VLCMediaDiscoverer implementation
 *****************************************************************************
 * Copyright (C) 2007 Pierre d'Herbemont
 * Copyright (C) 2014-2017, 2024 Felix Paul Kühne
 * Copyright (C) 2007, 2015 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan dot org>
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

#import <VLCMediaDiscoverer.h>
#import <VLCLibrary.h>
#import <VLCLibVLCBridging.h>
#import <VLCEventsHandler.h>

#include <vlc/vlc.h>
#include <vlc/libvlc.h>
#include <vlc/libvlc_media_discoverer.h>

NSString *const VLCMediaDiscovererName = @"VLCMediaDiscovererName";
NSString *const VLCMediaDiscovererLongName = @"VLCMediaDiscovererLongName";
NSString *const VLCMediaDiscovererCategory = @"VLCMediaDiscovererCategory";
NSString *const VLCMediaDiscovererUpdatedNotification = @"VLCMediaDiscovererUpdatedNotification";

@interface VLCMediaDiscoverer ()
{
    VLCMediaList *_discoveredMedia;
    libvlc_media_discoverer_t *_mdis;

    VLCLibrary *_privateLibrary;
    dispatch_queue_t _libVLCBackgroundQueue;

    VLCEventsHandler *_eventsHandler;
}
- (void)itemAdded:(VLCMedia *)media parent:(VLCMedia *)parent;
- (void)itemRemoved:(VLCMedia *)media;

@end

static void
discoverer_item_added(void *opaque, libvlc_media_t *libvlc_parent, libvlc_media_t *libvlc_media)
{
    @autoreleasepool {
        VLCEventsHandler *eventsHandler = (__bridge VLCEventsHandler *)opaque;
        [eventsHandler handleEvent:^(id _Nonnull object) {
            VLCMediaDiscoverer *mediaDiscoverer = (VLCMediaDiscoverer *)object;
            VLCMedia *parent;
            if (libvlc_parent != NULL) {
                parent = [VLCMedia mediaWithLibVLCMediaDescriptor:libvlc_parent];
            }
            VLCMedia *media = [VLCMedia mediaWithLibVLCMediaDescriptor:libvlc_media];
            [mediaDiscoverer itemAdded:media parent:parent];
        }];
    }
}

static void
discoverer_item_removed(void *opaque, libvlc_media_t *libvlc_media)
{
    @autoreleasepool {
        VLCEventsHandler *eventsHandler = (__bridge VLCEventsHandler *)opaque;
        [eventsHandler handleEvent:^(id _Nonnull object) {
            VLCMediaDiscoverer *mediaDiscoverer = (VLCMediaDiscoverer *)object;
            VLCMedia *media = [VLCMedia mediaWithLibVLCMediaDescriptor:libvlc_media];
            [mediaDiscoverer itemRemoved:media];
        }];
    }
}

@implementation VLCMediaDiscoverer
@synthesize libraryInstance = _privateLibrary;

+ (NSArray *)availableMediaDiscovererForCategoryType:(VLCMediaDiscovererCategoryType)categoryType
{
    libvlc_media_discoverer_description_t **discoverers;
    ssize_t numberOfDiscoverers = libvlc_media_discoverer_list_get([VLCLibrary sharedInstance], (libvlc_media_discoverer_category_t)categoryType, &discoverers);

    if (numberOfDiscoverers == 0) {
        libvlc_media_discoverer_list_release(discoverers, numberOfDiscoverers);
        return @[];
    }

    NSMutableArray *mutArray = [NSMutableArray arrayWithCapacity:numberOfDiscoverers];
    for (unsigned u = 0; u < numberOfDiscoverers; u++) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              discoverers[u]->psz_name ? [NSString stringWithUTF8String:discoverers[u]->psz_name] : @"",
                              VLCMediaDiscovererName,
                              discoverers[u]->psz_longname ? [NSString stringWithUTF8String:discoverers[u]->psz_longname] : @"",
                              VLCMediaDiscovererLongName,
                              @(discoverers[u]->i_cat),
                              VLCMediaDiscovererCategory,
                              nil];
        [mutArray addObject:dict];
    }

    libvlc_media_discoverer_list_release(discoverers, numberOfDiscoverers);
    return [mutArray copy];
}

- (instancetype)initWithName:(NSString *)aServiceName
{
    return [self initWithName:aServiceName libraryInstance:nil];
}

- (instancetype)initWithName:(NSString *)aServiceName libraryInstance:(nullable VLCLibrary *)libraryInstance
{
    if (self = [super init]) {
        _discoveredMedia = [[VLCMediaList alloc] init];
        _libVLCBackgroundQueue = dispatch_queue_create("libvlcQueue", DISPATCH_QUEUE_SERIAL);

        if (libraryInstance != nil) {
            _privateLibrary = libraryInstance;
        } else {
            _privateLibrary = [VLCLibrary sharedLibrary];
        }

        _eventsHandler = [VLCEventsHandler handlerWithObject:self configuration:[VLCLibrary sharedEventsConfiguration]];

        static const struct libvlc_media_discoverer_cbs cbs = {
            .version = 0,
            .on_media_added = discoverer_item_added,
            .on_media_removed = discoverer_item_removed,
        };

        _mdis = libvlc_media_discoverer_new([_privateLibrary instance],
                                            [aServiceName UTF8String],
                                            &cbs, (__bridge void *)(_eventsHandler));

        if (_mdis == NULL) {
            VKLog(@"media discovery initialization failed, maybe no such module?");
            return NULL;
        }
    }
    return self;
}

- (void)dealloc
{
    _discoveredMedia = nil;

    if (_mdis) {
        if (libvlc_media_discoverer_is_running(_mdis))
            libvlc_media_discoverer_stop(_mdis);
        libvlc_media_discoverer_destroy(_mdis);
    }
}

- (int)startDiscoverer
{
    int returnValue = libvlc_media_discoverer_start(_mdis);
    if (returnValue == -1) {
        VKLog(@"media discovery start failed");
        return returnValue;
    }

    return returnValue;
}

- (void)stopDiscoverer
{
    if (![self isRunning]) {
        return;
    }

    dispatch_async(_libVLCBackgroundQueue, ^{
        libvlc_media_discoverer_stop(_mdis);
    });
}

- (void)itemAdded:(VLCMedia *)media parent:(VLCMedia *)parent
{
    [self willChangeValueForKey:@"discoveredMedia"];
    if (parent == nil) {
        [_discoveredMedia addMedia:media];
    } else {
        /* FIXME: not sure what to do with with parents */
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCMediaDiscovererUpdatedNotification object:self];
    [self didChangeValueForKey:@"discoveredMedia"];

    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaAdded:parent:)]) {
        [self.delegate mediaAdded:media parent:parent];
    }
}

- (void)itemRemoved:(VLCMedia *)media
{
    [self willChangeValueForKey:@"discoveredMedia"];
    NSUInteger mediaIndex = [_discoveredMedia indexOfMedia:media];
    [_discoveredMedia removeMediaAtIndex:mediaIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCMediaDiscovererUpdatedNotification object:self];
    [self didChangeValueForKey:@"discoveredMedia"];

    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaRemoved:)]) {
        [self.delegate mediaRemoved:media];
    }
}

- (nullable VLCMediaList *)discoveredMedia
{
    return _discoveredMedia;
}

- (BOOL)isRunning
{
    return libvlc_media_discoverer_is_running(_mdis);
}

@end
