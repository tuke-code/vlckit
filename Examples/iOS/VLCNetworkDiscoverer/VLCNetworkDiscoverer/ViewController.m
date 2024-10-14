/* Copyright (c) 2024, Felix Paul Kühne, VideoLabs SAS and VideoLAN
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE. */

#import "ViewController.h"
#import <VLCKit/VLCKit.h>

@interface ViewController () <VLCMediaDiscovererDelegate, VLCMediaParserDelegate>
{
    UITextView *_textView;
    UIActivityIndicatorView *_activityIndicatorView;
    VLCMediaDiscoverer *_discoverer;
    VLCMediaParser *_parser;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor darkGrayColor];

    _textView = [[UITextView alloc] initWithFrame:self.view.frame];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.textColor = [UIColor whiteColor];
    _textView.editable = NO;
    [self.view addSubview:_textView];

    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicatorView.center = self.view.center;
    [self.view addSubview:_activityIndicatorView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [_activityIndicatorView startAnimating];

    _parser = [VLCMediaParser sharedParser];
    _parser.delegate = self;

    _textView.text = [NSString stringWithFormat:@"available discoverers: %@", [VLCMediaDiscoverer availableMediaDiscovererForCategoryType:(VLCMediaDiscovererCategoryTypeLAN)]];

    _discoverer = [[VLCMediaDiscoverer alloc] initWithName:@"dsm"];
    _discoverer.delegate = self;
    [_discoverer startDiscoverer];

    [super viewDidAppear:animated];
}

#pragma mark - VLCMediaDiscovererDelegate

- (void)mediaAdded:(VLCMedia *)media parent:(VLCMedia *)parent
{
    NSLog(@"%s: %@", __func__, media);
    [_parser queueMedia:media options:VLCMediaParseNetwork];
}

- (void)mediaRemoved:(VLCMedia *)media
{
    NSLog(@"%s: %@", __func__, media);
}

- (void)mediaFinishedParsing:(nonnull VLCMedia *)media withStatus:(VLCMediaParsedStatus)status
{
    VLCMediaList *subitems = media.subitems;
    NSUInteger count = subitems.count;
    for (int x = 0 ; x < count; x++) {
        VLCMedia *iter = [subitems mediaAtIndex:x];
        [_parser queueMedia:iter options:VLCMediaParseNetwork|VLCMediaDoInteract];
    }

    NSMutableString *parsingOutput = [[NSMutableString alloc] initWithFormat:@"\n\n%@ (Status: %i)\nNumber of tracks: %lu\n",
                                      media, status, (unsigned long)[[media tracksInformation] count]];

    VLCMediaMetaData *metaData = media.metaData;
    [metaData prefetch];

    NSArray *tracks = media.tracksInformation;
    for (VLCMediaTrack *track in tracks) {
        [parsingOutput appendString:@"\n"];
        VLCMediaTrackType type = track.type;
        if (type == VLCMediaTrackTypeVideo) {
            [parsingOutput appendFormat:@"Video Track:\nDimensions: %ux%u\n",
             track.video.width,
             track.video.height];
        } else if (type == VLCMediaTrackTypeAudio) {
            [parsingOutput appendFormat:@"Audio Track:\nSample rate: %u\nNumber of Channels: %u\n",
             track.audio.rate,
             track.audio.channelsNumber];
        } else if (type == VLCMediaTrackTypeText) {
            [parsingOutput appendFormat:@"SPU track:\nText Encoding: %@\n", track.text.encoding];
        }

        int fourcc = track.fourcc;
        [parsingOutput appendFormat:@"Bitrate: %i\nCodec: %@\nFourCC: %4.4s\nCodec Level: %i\nCodec Profile: %i\nLanguage: %@\n",
         track.bitrate,
         [VLCMedia codecNameForFourCC:track.fourcc trackType:track.type],
         (char *)&fourcc,
         track.level,
         track.profile,
         track.language];
    }
    [parsingOutput appendFormat:@"\nDuration: %@\n", [[media length] stringValue]];

    [parsingOutput appendFormat:@"\nContent Info:\nTitle: %@\nArtist: %@\nAlbum Artist: %@\nAlbum name: %@\nGenre: %@\nTrack number: %u\nDisc number: %u\nArtwork URL: %@",
     metaData.title, metaData.artist, metaData.albumArtist, metaData.album, metaData.genre, metaData.trackNumber, metaData.discNumber, metaData.artworkURL];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_activityIndicatorView stopAnimating];
        self->_textView.text = [self->_textView.text stringByAppendingFormat:@"\n%@", parsingOutput];
    });
}

@end
