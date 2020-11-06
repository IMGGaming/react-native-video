package com.brentvatne.entity;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class VideoMetadata {

    private static final String KEY_ID = "id";
    private static final String KEY_TITLE = "title";
    private static final String KEY_DESCRIPTION = "description";
    private static final String KEY_VIDEO_TYPE = "type";
    private static final String KEY_THUMBNAIL_URL = "thumbnailUrl";

    private final String id;
    private final String title;
    private final String description;
    private final String type;
    private final String thumbnailUrl;

    public VideoMetadata(
            String id,
            String title,
            String description,
            String type,
            String thumbnailUrl) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.type = type;
        this.thumbnailUrl = thumbnailUrl;
    }

    @NonNull
    public String getId() {
        return id;
    }

    @NonNull
    public String getTitle() {
        return title;
    }

    @Nullable
    public String getDescription() {
        return description;
    }

    @NonNull
    public String getType() {
        return type;
    }

    @Nullable
    public String getThumbnailUrl() {
        return thumbnailUrl;
    }
}