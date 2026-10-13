# Playlist2MP3

SwiftUI macOS Apple Silicon audio utility reconstructed from a ChatGPT-assisted Xcode development session.

## Features
- Load individual YouTube videos and YouTube Music playlists
- Select tracks
- Convert authorized audio to MP3 with selectable encoding bitrate (320/256/192/128 kbps)
- Save to Downloads

## Build (local prototype)
1. Install Xcode, Homebrew, XcodeGen, yt-dlp, and FFmpeg.
2. Run `brew install xcodegen yt-dlp ffmpeg`.
3. Run `xcodegen generate` and open `Playlist2MP3.xcodeproj`.
4. Build and launch on an Apple Silicon Mac.

This development version refers to `/opt/homebrew/bin/yt-dlp` and `/opt/homebrew/bin/ffmpeg`. **It is not yet a self-contained installer** and has not been rebuilt and tested from this repository. To share it with family without dependencies, additional bundling, license compliance, security review, and Mac testing are needed.

The full reconstructed source package and 10 icon images are also available as a ZIP in the originating ChatGPT conversation.

Use only audio you are authorized to download. Encoding 320 kbps does not improve original audio fidelity.
