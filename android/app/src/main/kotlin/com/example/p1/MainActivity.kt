package com.example.p1

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.p1/music_service"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        MusicService.onNext = {
            runOnUiThread { methodChannel?.invokeMethod("onNext", null) }
        }
        MusicService.onPrevious = {
            runOnUiThread { methodChannel?.invokeMethod("onPrevious", null) }
        }
        MusicService.onStop = {
            runOnUiThread { methodChannel?.invokeMethod("onStop", null) }
        }
        MusicService.onPause = {
            runOnUiThread { methodChannel?.invokeMethod("onPause", null) }
        }

        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val audioPath = call.argument<String>("audioPath") ?: ""
                    val title     = call.argument<String>("title")     ?: "Music"
                    val artist    = call.argument<String>("artist")    ?: ""
                    val paths     = call.argument<List<String>>("playlistPaths")
                    val titles    = call.argument<List<String>>("playlistTitles")
                    val artists   = call.argument<List<String>>("playlistArtists")
                    val idx       = call.argument<Int>("playlistIndex") ?: 0

                    val intent = Intent(this, MusicService::class.java).apply {
                        putExtra(MusicService.EXTRA_AUDIO_PATH, audioPath)
                        putExtra(MusicService.EXTRA_TITLE,      title)
                        putExtra(MusicService.EXTRA_ARTIST,     artist)
                        if (paths != null && titles != null && artists != null) {
                            putStringArrayListExtra(
                                MusicService.EXTRA_PLAYLIST_PATHS,
                                ArrayList(paths))
                            putStringArrayListExtra(
                                MusicService.EXTRA_PLAYLIST_TITLES,
                                ArrayList(titles))
                            putStringArrayListExtra(
                                MusicService.EXTRA_PLAYLIST_ARTISTS,
                                ArrayList(artists))
                            putExtra(MusicService.EXTRA_PLAYLIST_INDEX, idx)
                        }
                    }
                    startForegroundService(intent)
                    result.success(null)
                }
                "togglePlayPause" -> {
                    val intent = Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_TOGGLE
                    }
                    startForegroundService(intent)
                    result.success(MusicService.isPlaying)
                }
                "stopService" -> {
                    stopService(Intent(this, MusicService::class.java))
                    result.success(null)
                }
                "isPlaying"   -> result.success(MusicService.isPlayingStatic())
                "getPosition" -> result.success(listOf(
                    MusicService.getCurrentPositionStatic(),
                    MusicService.getDurationStatic()
                ))
                "seekTo" -> {
                    val position = call.argument<Int>("position") ?: 0
                    val intent = Intent(this, MusicService::class.java).apply {
                        action = MusicService.ACTION_SEEK
                        putExtra(MusicService.EXTRA_SEEK_POSITION, position)
                    }
                    startForegroundService(intent)
                    result.success(null)
                }
                "setLooping" -> {
                    val looping = call.argument<Boolean>("looping") ?: true
                    MusicService.setLoopingStatic(looping)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        runOnUiThread {
            methodChannel?.invokeMethod("openPlayer", null)
        }
    }
}