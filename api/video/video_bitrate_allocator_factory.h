/*
 *  Copyright (c) 2018 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#ifndef API_VIDEO_VIDEO_BITRATE_ALLOCATOR_FACTORY_H_
#define API_VIDEO_VIDEO_BITRATE_ALLOCATOR_FACTORY_H_

#include <memory>

#include "api/environment/environment.h"
#include "api/video/video_bitrate_allocator.h"
#include "api/video_codecs/video_codec.h"
#include "rtc_base/checks.h"

namespace webrtc {

// A factory that creates VideoBitrateAllocator.
// NOTE: This class is still under development and may change without notice.
class VideoBitrateAllocatorFactory {
 public:
  virtual ~VideoBitrateAllocatorFactory() = default;

  // Creates a VideoBitrateAllocator for a specific video codec.
  virtual std::unique_ptr<VideoBitrateAllocator> Create(
      const Environment& env,
      const VideoCodec& codec) {
    return CreateVideoBitrateAllocator(codec);
  }
  virtual std::unique_ptr<VideoBitrateAllocator> CreateVideoBitrateAllocator(
      const VideoCodec& codec) {
    // Newer code shouldn't call this function,
    // Older code should implement it in derived classes.
    RTC_CHECK_NOTREACHED();
  }
};

}  // namespace webrtc

#endif  // API_VIDEO_VIDEO_BITRATE_ALLOCATOR_FACTORY_H_
