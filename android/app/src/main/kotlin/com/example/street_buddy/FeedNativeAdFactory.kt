package com.example.street_buddy

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class FeedNativeAdFactory(private val layoutInflater: LayoutInflater) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.feed_native_ad, null) as NativeAdView

        with(adView) {
            val headlineView = findViewById<TextView>(R.id.ad_headline)
            val bodyView = findViewById<TextView>(R.id.ad_body)
            val callToActionView = findViewById<Button>(R.id.ad_call_to_action)
            val iconView = findViewById<ImageView>(R.id.ad_icon)
            val starRatingView = findViewById<RatingBar>(R.id.ad_stars)
            val advertiserView = findViewById<TextView>(R.id.ad_advertiser)
            val priceView = findViewById<TextView>(R.id.ad_price)
            val mediaView = findViewById<MediaView>(R.id.ad_media)

            this.headlineView = headlineView
            this.bodyView = bodyView
            this.callToActionView = callToActionView
            this.iconView = iconView
            this.starRatingView = starRatingView
            this.advertiserView = advertiserView
            this.priceView = priceView
            this.mediaView = mediaView

            // Populate the native ad
            headlineView.text = nativeAd.headline
            bodyView.text = nativeAd.body
            callToActionView.text = nativeAd.callToAction

            if (nativeAd.icon == null) {
                iconView.visibility = View.GONE
            } else {
                iconView.setImageDrawable(nativeAd.icon?.drawable)
                iconView.visibility = View.VISIBLE
            }

            if (nativeAd.starRating == null) {
                starRatingView.visibility = View.GONE
            } else {
                starRatingView.rating = nativeAd.starRating!!.toFloat()
                starRatingView.visibility = View.VISIBLE
            }

            if (nativeAd.advertiser == null) {
                advertiserView.visibility = View.GONE
            } else {
                advertiserView.text = nativeAd.advertiser
                advertiserView.visibility = View.VISIBLE
            }

            if (nativeAd.price == null) {
                priceView.visibility = View.GONE
            } else {
                priceView.text = nativeAd.price
                priceView.visibility = View.VISIBLE
            }

            // Set the native ad to the view
            this.setNativeAd(nativeAd)
        }

        return adView
    }
}
