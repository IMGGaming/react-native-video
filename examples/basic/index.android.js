'use strict';

import React, { Component } from 'react';

import {
  AppRegistry,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';

import Video from 'react-native-video';

class VideoPlayer extends Component {
  state = {
    rate: 1,
    volume: 1,
    muted: false,
    resizeMode: 'contain',
    duration: 0.0,
    currentTime: 0.0,
    paused: true,
  };

  video: Video;

  onLoad = (data) => {
    this.setState({ duration: data.duration });
  };

  onProgress = (data) => {
    this.setState({ currentTime: data.currentTime });
  };

  onEnd = () => {
    this.setState({ paused: true });
    this.video.seek(0);
  };

  onAudioBecomingNoisy = () => {
    this.setState({ paused: true });
  };

  onAudioFocusChanged = (event: { hasAudioFocus: boolean }) => {
    this.setState({ paused: !event.hasAudioFocus });
  };

  getCurrentTimePercentage() {
    if (this.state.currentTime > 0) {
      return (
        parseFloat(this.state.currentTime) / parseFloat(this.state.duration)
      );
    }
    return 0;
  }

  renderRateControl(rate) {
    const isSelected = this.state.rate === rate;

    return (
      <TouchableOpacity
        onPress={() => {
          this.setState({ rate });
        }}
      >
        <Text
          style={[
            styles.controlOption,
            { fontWeight: isSelected ? 'bold' : 'normal' },
          ]}
        >
          {rate}x
        </Text>
      </TouchableOpacity>
    );
  }

  renderResizeModeControl(resizeMode) {
    const isSelected = this.state.resizeMode === resizeMode;

    return (
      <TouchableOpacity
        onPress={() => {
          this.setState({ resizeMode });
        }}
      >
        <Text
          style={[
            styles.controlOption,
            { fontWeight: isSelected ? 'bold' : 'normal' },
          ]}
        >
          {resizeMode}
        </Text>
      </TouchableOpacity>
    );
  }

  renderVolumeControl(volume) {
    const isSelected = this.state.volume === volume;

    return (
      <TouchableOpacity
        onPress={() => {
          this.setState({ volume });
        }}
      >
        <Text
          style={[
            styles.controlOption,
            { fontWeight: isSelected ? 'bold' : 'normal' },
          ]}
        >
          {volume * 100}%
        </Text>
      </TouchableOpacity>
    );
  }

  render() {
    const flexCompleted = this.getCurrentTimePercentage() * 100;
    const flexRemaining = (1 - this.getCurrentTimePercentage()) * 100;

    return (
      <View style={styles.container}>
        <View
          style={styles.fullScreen}
          onPress={() => this.setState({ paused: !this.state.paused })}
        >
          <Video
            ref={(ref: Video) => {
              this.video = ref;
            }}
            /* For ExoPlayer */
            /* source={{ uri: 'http://www.youtube.com/api/manifest/dash/id/bf5bb2419360daf1/source/youtube?as=fmp4_audio_clear,fmp4_sd_hd_clear&sparams=ip,ipbits,expire,source,id,as&ip=0.0.0.0&ipbits=0&expire=19000000000&signature=51AF5F39AB0CEC3E5497CD9C900EBFEAECCCB5C7.8506521BFC350652163895D4C26DEE124209AA9E&key=ik0', type: 'mpd' }} */
            /* source={require('./broadchurch.mp4')} */
            source={{
                uri: 'http://public_seriously.s3.amazonaws.com/shaka_encrypted/dash/DashBigBuckBunny.mpd',
                type: 'mpd',
                config: {
                    muxData: {
                        envKey: "4004c26186c29919e27fa9f6c",
                        viewerUserId: "fake_exid",
                        experimentName: "A/B test one",
                        subPropertyId: "realmInformation",
                        videoId: "fake_id",
                        videoTitle: "Big Buck Bunny",
                        videoSeries: "Test Show",
                        //videoDuration: 48000,
                        videoIsLive: false,
                        videoStreamType: "VOD",
                        videoCdn: "standard"
                    },
                },
                drm: '{\"drmScheme\": \"widevine\", \"licensingServerUrl\": \"https:\/\/poc-dynopkgwidevine.sd-ngp.net\/proxy\",\"croToken\": \"bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJkaWNlIiwiaXNzIjoiaHR0cDovL2R5bmFtaWNfcGFja2FnZXJfYXBpX2FwaS5zZC1ucGcubmV0IiwiaWF0IjoxNTM2MTM1MTYwLCJkaWQiOiJ0ZXN0X2RldmljZV9pZCIsImp0aSI6IjEwMjRmZmZjLWNmZDctNDQ5Ny1iNjUxLWJkODQ4MzkwNWY1MSIsImVpZCI6ImRpY2Vfc3RyZWFtXzEiLCJleHAiOjE1OTEzOTQ5MjMsImFpZCI6InRlc3RfYWNjb3VudF9pZCIsInBsYyI6dHJ1ZSwiZGVmIjoiaGQifQ.Y5eU0V11RWh4f65Ir_qlT0kJL4XPCkr5P5LCbSvIvRk\"}'
            	/* drm: '{\"drmScheme\": \"widevine\", \"offlineLicense\": \"a3NpZDVFRUI2QkM1\"}' */ //offline playback action token
            	}}
            style={[
              styles.fullScreen,
              { paddingBottom: this.state.fullScreen ? 8 : 90 },
            ]}
            rate={this.state.rate}
            paused={this.state.paused}
            volume={this.state.volume}
            muted={this.state.muted}
            resizeMode={this.state.resizeMode}
            onLoad={this.onLoad}
            onProgress={this.onProgress}
            onEnd={this.onEnd}
            onAudioBecomingNoisy={this.onAudioBecomingNoisy}
            onAudioFocusChanged={this.onAudioFocusChanged}
            repeat={false}
            colorProgressBar={'#FFFF00'}
            iconBottomRight={
              this.state.fullScreen ? 'fullscreenOn' : 'fullscreenOff'
            }
            progressBarMarginBottom={this.state.fullScreen ? 12 : -12}
            stateOverlay={'ACTIVE'}
            stateMiddleCoreControls={'ACTIVE'}
            stateProgressBar={'ACTIVE'}
            controlsVisibilityGestureDisabled={true}
            fullscreen={this.state.fullScreen}
            live={false}
            controlsOpacity={1}
            onBottomRightIconClick={() => {
              this.setState({ fullScreen: !this.state.fullScreen });
            }}
            onTouchActionMove={(event) => {
              /* event.nativeEvent touchSwipeHorizontal */
            }}
            onTouchActionUp={(event) => {
              /* event.nativeEvent null */
            }}
          />
        </View>

        <View style={styles.controls}>
          <View style={styles.generalControls}>
            <View style={styles.rateControl}>
              {this.renderRateControl(0.25)}
              {this.renderRateControl(0.5)}
              {this.renderRateControl(1.0)}
              {this.renderRateControl(1.5)}
              {this.renderRateControl(2.0)}
            </View>

            <View style={styles.volumeControl}>
              {this.renderVolumeControl(0.5)}
              {this.renderVolumeControl(1)}
              {this.renderVolumeControl(1.5)}
            </View>

            <View style={styles.resizeModeControl}>
              {this.renderResizeModeControl('cover')}
              {this.renderResizeModeControl('contain')}
              {this.renderResizeModeControl('stretch')}
            </View>
          </View>

          <View style={styles.trackingControls}>
            <View style={styles.progress}>
              <View
                style={[styles.innerProgressCompleted, { flex: flexCompleted }]}
              />
              <View
                style={[styles.innerProgressRemaining, { flex: flexRemaining }]}
              />
            </View>
          </View>
        </View>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'black',
  },
  fullScreen: {
    position: 'absolute',
    top: 0,
    left: 0,
    bottom: 0,
    right: 0,
  },
  controls: {
    backgroundColor: 'transparent',
    borderRadius: 5,
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
  },
  progress: {
    flex: 1,
    flexDirection: 'row',
    borderRadius: 3,
    overflow: 'hidden',
  },
  innerProgressCompleted: {
    height: 20,
    backgroundColor: '#cccccc',
  },
  innerProgressRemaining: {
    height: 20,
    backgroundColor: '#2C2C2C',
  },
  generalControls: {
    flex: 1,
    flexDirection: 'row',
    borderRadius: 4,
    overflow: 'hidden',
    paddingBottom: 10,
  },
  rateControl: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
  },
  volumeControl: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
  },
  resizeModeControl: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  controlOption: {
    alignSelf: 'center',
    fontSize: 11,
    color: 'white',
    paddingLeft: 2,
    paddingRight: 2,
    lineHeight: 12,
    display: 'none',
  },
  trackingControls: {
    display: 'none',
  },
});

AppRegistry.registerComponent('VideoPlayer', () => VideoPlayer);
