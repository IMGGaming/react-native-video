package com.brentvatne.entity;

import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.diceplatform.doris.entity.TextTrack;

import java.util.ArrayList;
import java.util.Map;

public class RNSource {

    private Uri uri;
    private String extension;

    private final String id;
    private final String title;
    private final String description;
    private final String type;
    private final boolean isLive;
    private final TextTrack[] textTracks;
    private final Map<String, String> headers;
    private final Map<String, Object> muxData;
    private final String thumbnailUrl;
    private final String selectedAudioTrack;
    private final String locale;

    public RNSource(
            @NonNull Uri uri,
            @NonNull String id,
            @Nullable String extension,
            @Nullable String title,
            @Nullable String description,
            @Nullable String type,
            boolean isLive,
            @Nullable TextTrack[] textTracks,
            @Nullable Map<String, String> headers,
            @Nullable Map<String, Object> muxData,
            @Nullable String thumbnailUrl,
            @Nullable String selectedAudioTrack,
            @Nullable String locale) {
        this.uri = uri;
        this.id = id;
        this.extension = extension;
        this.title = title;
        this.description = description;
        this.type = type;
        this.isLive = isLive;
        this.textTracks = textTracks;
        this.headers = headers;
        this.muxData = muxData;
        this.thumbnailUrl = thumbnailUrl;
        this.selectedAudioTrack = selectedAudioTrack;
        this.locale = locale;
    }

    @NonNull
    public Uri getUri() {
        return uri;
    }

    public void setUri(Uri uri) {
        this.uri = uri;
    }

    @NonNull
    public String getId() {
        return id;
    }

    @Nullable
    public String getExtension() {
        return extension;
    }

    public void setExtension(String extension) {
        this.extension = extension;
    }

    @Nullable
    public String getTitle() {
        return title;
    }

    @Nullable
    public String getDescription() {
        return description;
    }

    @Nullable
    public String getType() {
        return type;
    }

    public boolean isLive() {
        return isLive;
    }

    @Nullable
    public TextTrack[] getTextTracks() {
        return textTracks;
    }

    @Nullable
    public Map<String, String> getHeaders() {
        return headers;
    }

    @Nullable
    public Map<String, Object> getMuxData() {
        return muxData;
    }

    @Nullable
    public String getThumbnailUrl() {
        return thumbnailUrl;
    }

    @Nullable
    public String getSelectedAudioTrack() {
        return selectedAudioTrack;
    }

    @Nullable
    public String getLocale() {
        return locale;
    }
}