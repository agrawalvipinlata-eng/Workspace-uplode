package com.srbs.never_miss_bus

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Screenshot and Android MediaProjection screen recording are intentionally
        // allowed. The in-app Capture & Report tool needs both capabilities.
    }
}
