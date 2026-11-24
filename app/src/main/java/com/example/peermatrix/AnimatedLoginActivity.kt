package com.example.peermatrix

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient

class AnimatedLoginActivity : Activity() {

    private lateinit var webView: WebView

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        webView = WebView(this)
        setContentView(webView)

        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        
        webView.addJavascriptInterface(object {
            @JavascriptInterface
            fun onIntroDone() {
                runOnUiThread {
                    val intent = Intent(this@AnimatedLoginActivity, MainActivity::class.java)
                    intent.putExtra("introDone", true)
                    startActivity(intent)
                    finish()
                    overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
                }
            }
        }, "Android")

        webView.webViewClient = WebViewClient()
        webView.loadUrl("file:///android_asset/login.html")
    }
}
