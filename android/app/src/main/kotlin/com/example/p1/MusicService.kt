package com.example.p1

import android.app.*
import android.content.Intent
import android.media.MediaPlayer
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import kotlinx.coroutines.*

class MusicService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private lateinit var mediaSession: MediaSessionCompat
    private val handler = Handler(Looper.getMainLooper())
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val CHANNEL_ID = "music_channel"
    private val NOTIF_ID = 1
    private var currentTitle  = "Music Player"
    private var currentArtist = ""

    companion object {
        const val ACTION_TOGGLE        = "ACTION_TOGGLE"
        const val ACTION_NEXT          = "ACTION_NEXT"
        const val ACTION_PREVIOUS      = "ACTION_PREVIOUS"
        const val ACTION_STOP          = "ACTION_STOP"
        const val ACTION_SEEK          = "ACTION_SEEK"
        const val ACTION_SET_PLAYLIST  = "ACTION_SET_PLAYLIST"
        const val EXTRA_AUDIO_PATH     = "audio_path"
        const val EXTRA_TITLE          = "song_title"
        const val EXTRA_ARTIST         = "song_artist"
        const val EXTRA_SEEK_POSITION  = "seek_position"
        const val EXTRA_PLAYLIST_PATHS  = "playlist_paths"
        const val EXTRA_PLAYLIST_TITLES = "playlist_titles"
        const val EXTRA_PLAYLIST_ARTISTS = "playlist_artists"
        const val EXTRA_PLAYLIST_INDEX  = "playlist_index"

        var isPlaying = false

        // Callbacks vers Flutter
        var onNext:     (() -> Unit)? = null
        var onPrevious: (() -> Unit)? = null
        var onStop:     (() -> Unit)? = null
        var onPause:    (() -> Unit)? = null

        private var instance: MusicService? = null
        fun getCurrentPositionStatic(): Int = instance?.getCurrentPosition() ?: 0
        fun getDurationStatic(): Int        = instance?.getDuration()        ?: 0
        fun isPlayingStatic(): Boolean      = isPlaying
        fun setLoopingStatic(looping: Boolean) { instance?.setLooping(looping) }
    }

    // Playlist interne du service
    private var internalPlaylist = mutableListOf<Triple<String, String, String>>() // path, title, artist
    private var internalIndex    = 0

    private val progressUpdater = object : Runnable {
        override fun run() {
            if (isPlaying) {
                updatePlaybackState()
                handler.postDelayed(this, 1000)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()

        mediaSession = MediaSessionCompat(this, "MusicService").apply {
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay()           { resume() }
                override fun onPause()          { pause()  }
                override fun onSkipToNext()     { playNext() }
                override fun onSkipToPrevious() { playPrevious() }
                override fun onSeekTo(pos: Long) {
                    mediaPlayer?.seekTo(pos.toInt())
                    updatePlaybackState()
                }
            })
            isActive = true
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val audioPath = intent?.getStringExtra(EXTRA_AUDIO_PATH)
        intent?.getStringExtra(EXTRA_TITLE)?.let  { currentTitle  = it }
        intent?.getStringExtra(EXTRA_ARTIST)?.let { currentArtist = it }

        startForeground(NOTIF_ID, buildNotification())

        when (intent?.action) {
            ACTION_TOGGLE   -> togglePlayPause()
            ACTION_NEXT     -> playNext()
            ACTION_PREVIOUS -> playPrevious()
            ACTION_SEEK -> {
                val pos = intent.getIntExtra(EXTRA_SEEK_POSITION, 0)
                mediaPlayer?.seekTo(pos)
                updatePlaybackState()
            }
            ACTION_STOP -> {
                onStop?.invoke()
                isPlaying = false
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            else -> {
                if (audioPath != null) {
                    // Mettre à jour la playlist interne si fournie
                    val paths   = intent.getStringArrayListExtra(EXTRA_PLAYLIST_PATHS)
                    val titles  = intent.getStringArrayListExtra(EXTRA_PLAYLIST_TITLES)
                    val artists = intent.getStringArrayListExtra(EXTRA_PLAYLIST_ARTISTS)
                    val idx     = intent.getIntExtra(EXTRA_PLAYLIST_INDEX, 0)

                    if (paths != null && titles != null && artists != null) {
                        internalPlaylist.clear()
                        for (i in paths.indices) {
                            internalPlaylist.add(Triple(paths[i], titles[i], artists.getOrElse(i) { "" }))
                        }
                        internalIndex = idx
                    }
                    stopCurrent()
                    play(audioPath)
                }
            }
        }
        return START_STICKY
    }

    // ── Play next dans la playlist interne ─────────────────────────────────

    private fun playNext() {
        if (internalPlaylist.isEmpty()) {
            onNext?.invoke()
            return
        }
        internalIndex = (internalIndex + 1) % internalPlaylist.size
        val (path, title, artist) = internalPlaylist[internalIndex]
        currentTitle  = title
        currentArtist = artist
        stopCurrent()
        play(path)
        // Notifier Flutter pour mettre à jour l'UI
        onNext?.invoke()
    }

    private fun playPrevious() {
        if (internalPlaylist.isEmpty()) {
            onPrevious?.invoke()
            return
        }
        internalIndex = (internalIndex - 1 + internalPlaylist.size) % internalPlaylist.size
        val (path, title, artist) = internalPlaylist[internalIndex]
        currentTitle  = title
        currentArtist = artist
        stopCurrent()
        play(path)
        // Notifier Flutter pour mettre à jour l'UI
        onPrevious?.invoke()
    }

    fun play(audioPath: String) {
        serviceScope.launch {
            try {
                val player = withContext(Dispatchers.IO) {
                    MediaPlayer().apply {
                        if (audioPath.startsWith("/")) {
                            setDataSource(audioPath)
                        } else {
                            val afd = assets.openFd("flutter_assets/$audioPath")
                            setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                            afd.close()
                        }
                        isLooping = true
                        prepare()
                    }
                }
                mediaPlayer = player
                mediaPlayer?.start()
                isPlaying = true
                updateMetadata()
                updatePlaybackState()
                updateNotification()
                handler.post(progressUpdater)
            } catch (e: Exception) {
                e.printStackTrace()
                isPlaying = false
            }
        }
    }

    fun pause() {
        mediaPlayer?.pause()
        isPlaying = false
        handler.removeCallbacks(progressUpdater)
        updatePlaybackState()
        updateNotification()
        onPause?.invoke()
    }

    fun resume() {
        mediaPlayer?.start()
        isPlaying = true
        updatePlaybackState()
        updateNotification()
        handler.post(progressUpdater)
    }

    private fun togglePlayPause() {
        if (isPlaying) pause() else resume()
    }

    fun stopCurrent() {
        handler.removeCallbacks(progressUpdater)
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        isPlaying = false
    }

    fun setLooping(looping: Boolean) { mediaPlayer?.isLooping = looping }
    fun getCurrentPosition(): Int = mediaPlayer?.currentPosition ?: 0
    fun getDuration(): Int        = mediaPlayer?.duration        ?: 0

    private fun updateMetadata() {
        mediaSession.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE,  currentTitle)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, currentArtist)
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION,
                    mediaPlayer?.duration?.toLong() ?: 0L)
                .build()
        )
    }

    private fun updatePlaybackState() {
        val state = if (isPlaying) PlaybackStateCompat.STATE_PLAYING
                    else           PlaybackStateCompat.STATE_PAUSED
        mediaSession.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_PLAY_PAUSE or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_SEEK_TO
                )
                .setState(state, mediaPlayer?.currentPosition?.toLong() ?: 0L, 1f)
                .build()
        )
    }

    private fun updateNotification() {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification())
    }

    private fun makePendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, MusicService::class.java).apply { this.action = action }
        return PendingIntent.getService(this, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun buildNotification(): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPending = PendingIntent.getActivity(this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(currentTitle)
            .setContentText(currentArtist)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(openAppPending)
            .setAutoCancel(false)
            .setColor(0xFFE0E0E0.toInt())
            .setColorized(true)
            .addAction(android.R.drawable.ic_media_previous, "Précédent",
                makePendingIntent(ACTION_PREVIOUS, 1))
            .addAction(
                if (isPlaying) android.R.drawable.ic_media_pause
                else           android.R.drawable.ic_media_play,
                if (isPlaying) "Pause" else "Play",
                makePendingIntent(ACTION_TOGGLE, 2))
            .addAction(android.R.drawable.ic_media_next, "Suivant",
                makePendingIntent(ACTION_NEXT, 3))
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Fermer",
                makePendingIntent(ACTION_STOP, 4))
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setStyle(MediaStyle()
                .setMediaSession(mediaSession.sessionToken)
                .setShowActionsInCompactView(0, 1, 2))
            .build()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(CHANNEL_ID, "Music Playback",
            NotificationManager.IMPORTANCE_LOW)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        isPlaying = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        serviceScope.cancel()
        handler.removeCallbacks(progressUpdater)
        mediaSession.release()
        instance = null
        stopCurrent()
        super.onDestroy()
    }
}