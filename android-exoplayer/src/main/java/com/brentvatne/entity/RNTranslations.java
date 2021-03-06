package com.brentvatne.entity;

import androidx.annotation.NonNull;

import java.util.Map;

public class RNTranslations {

    private static final String KEY_EPG_LABEL = "player_epg_button";
    private static final String KEY_STATS_LABEL = "player_stats_button";
    private static final String KEY_PLAY_LABEL = "player_play_button";
    private static final String KEY_PAUSE_LABEL = "player_pause_button";
    private static final String KEY_LIVE_LABEL = "live";
    private static final String KEY_FAVORITE_LABEL = "favourite";
    private static final String KEY_WATCHLIST_LABEL = "watchlist";
    private static final String KEY_MORE_VIDEOS_LABEL = "moreVideos";
    private static final String KEY_CAPTIONS_LABEL = "captions";
    private static final String KEY_REWIND_LABEL = "rewind";
    private static final String KEY_FAST_FORWARD_LABEL = "fastForward";
    private static final String KEY_AUDIO_TRACKS_LABEL = "audioTracks";
    private static final String KEY_INFO_LABEL = "info";
    private static final String KEY_ADS_COUNTDOWN_AD_LABEL = "adsCountdownAd";
    private static final String KEY_ADS_COUNTDOWN_OF_LABEL = "adsCountdownOf";

    private static final String DEFAULT_EPG_LABEL = "Schedule";
    private static final String DEFAULT_STATS_LABEL = "Stats";
    private static final String DEFAULT_PLAY_LABEL = "Play";
    private static final String DEFAULT_PAUSE_LABEL = "Pause";
    private static final String DEFAULT_LIVE_LABEL = "Live";
    private static final String DEFAULT_FAVORITE_LABEL = "Favourite";
    private static final String DEFAULT_MORE_VIDEOS_LABEL = "More Videos";
    private static final String DEFAULT_WATCHLIST_LABEL = "Watchlist";
    private static final String DEFAULT_CAPTIONS_LABEL = "Subtitles";
    private static final String DEFAULT_REWIND_LABEL = "Rewind";
    private static final String DEFAULT_FAST_FORWARD_LABEL = "Fast Forward";
    private static final String DEFAULT_AUDIO_TRACKS_LABEL = "Audio Languages";
    private static final String DEFAULT_INFO_LABEL = "Information";
    private static final String DEFAULT_ADS_COUNTDOWN_AD_LABEL = "Ad";
    private static final String DEFAULT_ADS_COUNTDOWN_OF_LABEL = "Of";

    private final Map<String, Object> translations;
    private final String epgLabel;
    private final String statsLabel;
    private final String playLabel;
    private final String pauseLabel;
    private final String liveLabel;
    private final String favoriteLabel;
    private final String watchlistLabel;
    private final String moreVideosLabel;
    private final String captionsLabel;
    private final String rewindLabel;
    private final String fastForwardLabel;
    private final String audioTracksLabel;
    private final String infoLabel;
    private final String adsCountdownAdLabel;
    private final String adsCountdownOfLabel;

    public RNTranslations(@NonNull Map<String, Object> translations) {
        this.translations = translations;

        this.epgLabel = getStringFromMap(KEY_EPG_LABEL, DEFAULT_EPG_LABEL);
        this.statsLabel = getStringFromMap(KEY_STATS_LABEL, DEFAULT_STATS_LABEL);
        this.playLabel = getStringFromMap(KEY_PLAY_LABEL, DEFAULT_PLAY_LABEL);
        this.pauseLabel = getStringFromMap(KEY_PAUSE_LABEL, DEFAULT_PAUSE_LABEL);
        this.liveLabel = getStringFromMap(KEY_LIVE_LABEL, DEFAULT_LIVE_LABEL);
        this.favoriteLabel = getStringFromMap(KEY_FAVORITE_LABEL, DEFAULT_FAVORITE_LABEL);
        this.watchlistLabel = getStringFromMap(KEY_WATCHLIST_LABEL, DEFAULT_WATCHLIST_LABEL);
        this.moreVideosLabel = getStringFromMap(KEY_MORE_VIDEOS_LABEL, DEFAULT_MORE_VIDEOS_LABEL);
        this.captionsLabel = getStringFromMap(KEY_CAPTIONS_LABEL, DEFAULT_CAPTIONS_LABEL);
        this.rewindLabel = getStringFromMap(KEY_REWIND_LABEL, DEFAULT_REWIND_LABEL);
        this.fastForwardLabel = getStringFromMap(KEY_FAST_FORWARD_LABEL, DEFAULT_FAST_FORWARD_LABEL);
        this.audioTracksLabel = getStringFromMap(KEY_AUDIO_TRACKS_LABEL, DEFAULT_AUDIO_TRACKS_LABEL);
        this.infoLabel = getStringFromMap(KEY_INFO_LABEL, DEFAULT_INFO_LABEL);
        this.adsCountdownAdLabel = getStringFromMap(KEY_ADS_COUNTDOWN_AD_LABEL, DEFAULT_ADS_COUNTDOWN_AD_LABEL);
        this.adsCountdownOfLabel = getStringFromMap(KEY_ADS_COUNTDOWN_OF_LABEL, DEFAULT_ADS_COUNTDOWN_OF_LABEL);
    }

    private String getStringFromMap(String key, String defaultValue) {
        return translations.get(key) != null ? (String) translations.get(key) : defaultValue;
    }

    public String getEpgLabel() {
        return epgLabel;
    }

    public String getStatsLabel() {
        return statsLabel;
    }

    public String getPlayLabel() {
        return playLabel;
    }

    public String getPauseLabel() {
        return pauseLabel;
    }

    public String getLiveLabel() {
        return liveLabel;
    }

    public String getFavoriteLabel() {
        return favoriteLabel;
    }

    public String getWatchlistLabel() {
        return watchlistLabel;
    }

    public String getMoreVideosLabel() {
        return moreVideosLabel;
    }

    public String getCaptionsLabel() {
        return captionsLabel;
    }

    public String getRewindLabel() {
        return rewindLabel;
    }

    public String getFastForwardLabel() {
        return fastForwardLabel;
    }

    public String getAudioTracksLabel() {
        return audioTracksLabel;
    }

    public String getInfoLabel() {
        return infoLabel;
    }

    public String getAdsCountdownAdLabel() {
        return adsCountdownAdLabel;
    }

    public String getAdsCountdownOfLabel() {
        return adsCountdownOfLabel;
    }
}
