/*
 *  Copyright (c) 2013 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#ifndef COMMON_AUDIO_RESAMPLER_INCLUDE_PUSH_RESAMPLER_H_
#define COMMON_AUDIO_RESAMPLER_INCLUDE_PUSH_RESAMPLER_H_

#include <memory>
#include <vector>

#include "api/audio/audio_view.h"

namespace webrtc {

class PushSincResampler;

// Wraps PushSincResampler to provide stereo support.
// Note: This implementation assumes 10ms buffer sizes throughout.
template <typename T>
class PushResampler {
 public:
  PushResampler();
  virtual ~PushResampler();

  // Must be called whenever the parameters change. Free to be called at any
  // time as it is a no-op if parameters have not changed since the last call.
  int InitializeIfNeeded(int src_sample_rate_hz,
                         int dst_sample_rate_hz,
                         size_t num_channels);

  // Returns the total number of samples provided in destination (e.g. 32 kHz,
  // 2 channel audio gives 640 samples).
  int Resample(InterleavedView<const T> src, InterleavedView<T> dst);

 private:
  std::unique_ptr<T[]> source_;
  std::unique_ptr<T[]> destination_;
  DeinterleavedView<T> source_view_;
  DeinterleavedView<T> destination_view_;

  std::vector<std::unique_ptr<PushSincResampler>> resamplers_;
};
}  // namespace webrtc

#endif  // COMMON_AUDIO_RESAMPLER_INCLUDE_PUSH_RESAMPLER_H_
