package com.example.grahvani

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // OWASP Hardening: Block screenshots and screen recording on Android
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}

