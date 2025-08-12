package com.example.street_buddy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register the native ad factories
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine, 
            "exploreNativeAd", 
            ExploreNativeAdFactory(layoutInflater)
        )
        
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine, 
            "feedNativeAd", 
            FeedNativeAdFactory(layoutInflater)
        )
    }
    
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "exploreNativeAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "feedNativeAd")
    }
}
