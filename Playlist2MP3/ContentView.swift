import SwiftUI
import Foundation

struct VideoItem: Identifiable {
    let id: String
    let title: String
    var selected = true
}

struct ContentView: View {
    @State private var youtubeLink = ""
    @State private var songs: [VideoItem] = []
    @State private var status = "Ready"
    @State private var quality = "320"
    @State private var isBusy = false
    @State private var completed = 0
    @State private var total = 0

    // Development version: tools installed using Homebrew, not bundled.
    private let downloader = "/opt/homebrew/bin/yt-dlp"
    private let ffmpeg = "/opt/homebrew/bin/ffmpeg"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 42))
                .foregroundStyle(.blue)
            Text("Playlist2MP3").font(.largeTitle).bold()
            Text("Song & Playlist Converter").foregroundStyle(.secondary)
            Divider()
            TextField("Paste YouTube song or playlist link", text: $youtubeLink)
                .textFieldStyle(.roundedBorder)
                .disabled(isBusy)
            Button("Load Songs") { loadSongs() }
                .disabled(isBusy || youtubeLink.isEmpty)
            if !songs.isEmpty {
                HStack {
                    Text("\(songs.count) Songs").font(.headline)
                    Spacer()
                    Button("Select All") {
                        for i in songs.indices { songs[i].selected = true }
                    }
                    Button("Clear") {
                        for i in songs.indices { songs[i].selected = false }
                    }
                }
                List {
                    ForEach($songs) { $song in
                        Toggle(isOn: $song.selected) {
                            Text(song.title).lineLimit(2)
                        }
                    }
                }.frame(minHeight: 100)
            }
            HStack {
                Text("MP3 Quality")
                Spacer()
                Picker("Quality", selection: $quality) {
                    Text("320 kbps").tag("320")
                    Text("256 kbps").tag("256")
                    Text("192 kbps").tag("192")
                    Text("128 kbps").tag("128")
                }
                .labelsHidden()
                .frame(width: 140)
            }
            Button { downloadSongs() } label: {
                Label("Download MP3", systemImage: "arrow.down.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy || !songs.contains(where: { $0.selected }))
            if isBusy { ProgressView() }
            if total > 0 {
                ProgressView(value: Double(completed), total: Double(total))
            }
            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
        .padding(25)
        .frame(width: 560, height: 560)
    }

    private func validYouTubeLink(_ string: String) -> Bool {
        guard let url = URL(string: string),
              url.scheme == "https",
              let host = url.host?.lowercased() else { return false }
        return ["youtube.com", "www.youtube.com", "m.youtube.com",
                "music.youtube.com", "youtu.be"].contains(host)
    }

    private func runTool(arguments: [String]) -> (Bool, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: downloader)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        do {
            try process.run()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let text = String(data: data, encoding: .utf8) ?? ""
            return (process.terminationStatus == 0, text)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func loadSongs() {
        let link = youtubeLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validYouTubeLink(link) else {
            status = "Enter a valid HTTPS YouTube link."
            return
        }
        isBusy = true
        songs = []
        completed = 0
        total = 0
        status = "Loading songs..."
        DispatchQueue.global(qos: .userInitiated).async {
            let (success, output) = runTool(arguments: [
                "--flat-playlist", "--print", "%(id)s\t%(title)s",
                "--no-warnings", "--ignore-errors", link
            ])
            var loaded: [VideoItem] = []
            for line in output.components(separatedBy: .newlines) {
                let parts = line.split(separator: "\t", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let id = String(parts[0])
                let title = String(parts[1])
                let validID = id.count == 11 && id.allSatisfy {
                    $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-")
                }
                if validID { loaded.append(VideoItem(id: id, title: title)) }
            }
            DispatchQueue.main.async {
                songs = loaded
                isBusy = false
                status = loaded.isEmpty
                    ? (success ? "No songs found." : "Could not load songs. Check playlist access.")
                    : "Loaded \(loaded.count) song(s)."
            }
        }
    }

    private func downloadSongs() {
        let chosen = songs.filter { $0.selected }
        guard !chosen.isEmpty else {
            status = "Select at least one song."
            return
        }
        isBusy = true
        completed = 0
        total = chosen.count
        status = "Starting conversion..."
        let bitrate = quality
        DispatchQueue.global(qos: .userInitiated).async {
            var failures = 0
            for (index, song) in chosen.enumerated() {
                DispatchQueue.main.async {
                    status = "Processing \(index + 1) of \(chosen.count): \(song.title)"
                }
                let link = "https://www.youtube.com/watch?v=\(song.id)"
                let (success, _) = runTool(arguments: [
                    "--no-playlist", "--extract-audio", "--audio-format", "mp3",
                    "--audio-quality", "\(bitrate)K", "--ffmpeg-location", ffmpeg,
                    "--paths", FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Downloads").path,
                    "--output", "%(title).180B [%(id)s].%(ext)s", "--no-warnings", link
                ])
                if !success { failures += 1 }
                DispatchQueue.main.async { completed = index + 1 }
            }
            DispatchQueue.main.async {
                isBusy = false
                status = failures == 0
                    ? "Finished! MP3 files saved in Downloads."
                    : "Finished with \(failures) failed download(s)."
            }
        }
    }
}

#Preview {
    ContentView()
}
