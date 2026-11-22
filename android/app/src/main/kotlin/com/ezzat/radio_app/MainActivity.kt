package com.ezzat.radio_app

import com.ryanheise.audioservice.AudioServiceActivity

// audio_service needs its own Activity base class for background playback.
class MainActivity : AudioServiceActivity()
