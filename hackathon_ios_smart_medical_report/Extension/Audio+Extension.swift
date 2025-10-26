//
//  Audio+Extension.swift
//  goat
//
//  Created by Mohamad Lobo on 22/04/25.
//

import Foundation
import AVFoundation

var audioPlayer : AVAudioPlayer?

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        } catch {
            print("Could not play the sound file.")
        }
    }
}

func stopSound(resetToStart: Bool = true) {
    audioPlayer?.stop()
    if resetToStart {
        audioPlayer?.currentTime = 0
    }
}

extension Notification.Name {
    static let audioDidStart   = Notification.Name("audioDidStart")
    static let audioDidFinish  = Notification.Name("audioDidFinish")
}

final class AudioCenter: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioCenter()
    private(set) var currentId: String?
    private var finishHandlers: [String: () -> Void] = [:]

    func play(soundName: String, type: String, id: String, onFinish: @escaping () -> Void) {
        // Se outro áudio estiver tocando, pare-o
        if let current = currentId, current != id {
            stop(force: true)
        }

        guard let path = Bundle.main.path(forResource: soundName, ofType: type) else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.delegate = self
            audioPlayer?.play()
            currentId = id
            finishHandlers[id] = onFinish

            NotificationCenter.default.post(name: .audioDidStart, object: nil, userInfo: ["id": id])
        } catch {
            print("Could not play sound: \(error)")
        }
    }

    func stop(id: String? = nil, force: Bool = false) {
        // force = true para parar independente de quem pediu
        guard force || currentId == id else { return }
        audioPlayer?.stop()
        audioPlayer = nil

        if let cid = currentId, let handler = finishHandlers[cid] {
            handler()
        }
        if let cid = currentId {
            NotificationCenter.default.post(name: .audioDidFinish, object: nil, userInfo: ["id": cid])
        }
        finishHandlers.removeAll()
        currentId = nil
    }

    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop(force: true) // dispara handlers e notificação
    }
}
