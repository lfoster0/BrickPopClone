//
//  AudioManager.swift
//  BrickPop
//
//  Created by Lee Foster on 2017-07-03.
//  Copyright © 2017 Lee Foster. All rights reserved.
//

import Foundation
import AVFoundation

class AudioManager: NSObject, AVAudioPlayerDelegate {
    static let sharedInstance = AudioManager()
    static let maxAudioPlayers = 10
    
    let brickTappedAudioURL =
        URL(fileURLWithPath: Bundle.main.path(forResource: "tap", ofType: "mp3")!)
    let brickBadTapAudioURL =
        URL(fileURLWithPath: Bundle.main.path(forResource: "badTap", ofType: "mp3")!)
    let brickFallAudioURL =
        URL(fileURLWithPath: Bundle.main.path(forResource: "fall", ofType: "mp3")!)
    
    var audioPlayers = [AVAudioPlayer]()
    
    private override init(){
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        try! AVAudioSession.sharedInstance().setActive(true)
    }
    
    
    // MARK: Public
    func playBrickTappedSound() {
        self.playSoundWithURL(url: self.brickTappedAudioURL)
    }
    
    func playBadTapSound() {
        self.playSoundWithURL(url: self.brickBadTapAudioURL)
    }
    
    func playBrickFallSound() {
        self.playSoundWithURL(url: self.brickFallAudioURL)
    }
    
    // Mark: Private
    private func playSoundWithURL(url: URL) {
        if audioPlayers.count > AudioManager.maxAudioPlayers {
            return
        }
        
        let player = try! AVAudioPlayer(contentsOf: url)
        audioPlayers.append(player)
        player.delegate = self
        player.prepareToPlay()
        player.play()
    }
    // MARK: Audio Player Delegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if audioPlayers.contains(player) {
            audioPlayers.remove(at: audioPlayers.index(of: player)!)
        }
    }
    
}
