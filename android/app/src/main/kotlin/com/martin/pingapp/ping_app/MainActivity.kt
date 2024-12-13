package com.martin.pingapp.ping_app

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity(){
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("FlutterWatchConnectivity:","configureFlutterEngine");
        flutterEngine.plugins.add(WearOSPlugin())
    }
}
