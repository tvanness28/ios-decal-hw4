//
//  PlayerViewController.swift
//  Play
//
//  Created by Gene Yoo on 11/26/15.
//  Copyright © 2015 cs198-1. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class PlayerViewController: UIViewController {
    var tracks: [Track]!
    var scAPI: SoundCloudAPI!

    var currentIndex: Int!
    var player: AVPlayer!
    var trackImageView: UIImageView!

    var playPauseButton: UIButton!
    var nextButton: UIButton!
    var previousButton: UIButton!

    var artistLabel: UILabel!
    var titleLabel: UILabel!
    var didPlay: [Track]!
    
    var slider: UISlider!
    var sliderMinLabel: UILabel!
    var sliderMaxLabel: UILabel!

    var paused = true
    var attemptingToPlay = false
    var msecs = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        let _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTrackSlider), userInfo: nil, repeats: true)

        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.white

        scAPI = SoundCloudAPI()
        scAPI.loadTracks(didLoadTracks)
        self.didPlay = []
        currentIndex = 0

        player = AVPlayer()

        loadVisualElements()
        loadTrackSlider()
        loadPlayerButtons()
    }

    func loadVisualElements() {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let offset = height - width


        trackImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0,
                                                   width: width, height: width))
        trackImageView.contentMode = UIViewContentMode.scaleAspectFill
        trackImageView.clipsToBounds = true
        view.addSubview(trackImageView)

        titleLabel = UILabel(frame: CGRect(x: 0.0, y: width + offset * 0.15,
                                           width: width, height: 20.0))
        titleLabel.textAlignment = NSTextAlignment.center
        view.addSubview(titleLabel)

        artistLabel = UILabel(frame: CGRect(x: 0.0, y: width + offset * 0.25,
                                            width: width, height: 20.0))
        artistLabel.textAlignment = NSTextAlignment.center
        artistLabel.textColor = UIColor.gray
        view.addSubview(artistLabel)
    }


    func loadPlayerButtons() {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let offset = height - width

        let playImage = UIImage(named: "play")?.withRenderingMode(.alwaysTemplate)
        let pauseImage = UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate)
        let nextImage = UIImage(named: "next")?.withRenderingMode(.alwaysTemplate)
        let previousImage = UIImage(named: "previous")?.withRenderingMode(.alwaysTemplate)

        playPauseButton = UIButton(type: UIButtonType.custom)
        playPauseButton.frame = CGRect(x: width / 2.0 - width / 30.0,
                                       y: width + offset * 0.5,
                                       width: width / 15.0,
                                       height: width / 15.0)
        playPauseButton.setImage(playImage, for: UIControlState())
        playPauseButton.setImage(pauseImage, for: UIControlState.selected)
        playPauseButton.addTarget(self, action: #selector(playOrPauseTrack),
                                  for: .touchUpInside)
        view.addSubview(playPauseButton)

        previousButton = UIButton(type: UIButtonType.custom)
        previousButton.frame = CGRect(x: width / 2.0 - width / 30.0 - width / 5.0,
                                      y: width + offset * 0.5,
                                      width: width / 15.0,
                                      height: width / 15.0)
        previousButton.setImage(previousImage, for: UIControlState())
        previousButton.addTarget(self, action: #selector(previousTrackTapped(_:)),
                                 for: UIControlEvents.touchUpInside)
        view.addSubview(previousButton)

        nextButton = UIButton(type: UIButtonType.custom)
        nextButton.frame = CGRect(x: width / 2.0 - width / 30.0 + width / 5.0,
                                  y: width + offset * 0.5,
                                  width: width / 15.0,
                                  height: width / 15.0)
        nextButton.setImage(nextImage, for: UIControlState())
        nextButton.addTarget(self, action: #selector(nextTrackTapped(_:)),
                             for: UIControlEvents.touchUpInside)
        view.addSubview(nextButton)

    }

    func loadTrackElements() {
        let track = tracks[currentIndex]
        asyncLoadTrackImage(track)
        titleLabel.text = track.title
        artistLabel.text = track.artist
    }
    
    func loadTrackSlider() {
        let height = UIScreen.main.bounds.size.height

        
        slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 100.0
        slider.isContinuous = false
        slider.setThumbImage(#imageLiteral(resourceName: "trackThumb.png"), for: .normal)
        slider.addTarget(self, action: #selector(sliderGrabbed), for: UIControlEvents.touchDown)
        slider.addTarget(self, action: #selector(sliderReleased), for: UIControlEvents.valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        slider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -height/15).isActive = true
        slider.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        slider.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        
        sliderMinLabel = UILabel()
        sliderMinLabel.text = "0:00"
        sliderMinLabel.font = UIFont.boldSystemFont(ofSize: 8.0)
        sliderMinLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderMinLabel)
        
        sliderMinLabel.topAnchor.constraint(equalTo: slider.bottomAnchor).isActive = true
        sliderMinLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor).isActive = true
        
        sliderMaxLabel = UILabel()
        sliderMaxLabel.text = "0:00"
        sliderMaxLabel.font = UIFont.boldSystemFont(ofSize: 8.0)
        sliderMaxLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderMaxLabel)
        
        sliderMaxLabel.topAnchor.constraint(equalTo: slider.bottomAnchor).isActive = true
        sliderMaxLabel.trailingAnchor.constraint(equalTo: slider.trailingAnchor).isActive = true
        
    }
    
    func getTimeStamp(_ seconds: Float) -> String {
        let minutes = Int(seconds/60)
        let remaining_seconds = Int(Int(seconds) - (minutes * 60))
        var sec_string = String(remaining_seconds)
        if remaining_seconds < 10 {
            sec_string = "0\(sec_string)"
        }
        return "\(String(minutes)):\(sec_string)"
    }
    
    func playSong() -> Bool {
        if let cur_song = player.currentItem {
            if cur_song.status == .readyToPlay {
                player.play()
                playPauseButton.isSelected = true
                slider.maximumValue = Float(CMTimeGetSeconds((player.currentItem!.duration)))
                sliderMaxLabel.text = getTimeStamp(slider.maximumValue)
                paused = !paused
                attemptingToPlay = false
                return true
            }
        }
        return false
    }
    
    func updateTrackSlider() {
        msecs += 1
        
        let curSeconds = Float(CMTimeGetSeconds((player.currentTime())))
        if curSeconds > 0.0 && msecs % 10 == 0 {
            sliderMinLabel.text = getTimeStamp(curSeconds)
        }
        
        if !slider.isSelected {
            slider.setValue(curSeconds, animated: true)
        }
        
        if curSeconds == slider.maximumValue {
            nextTrackTapped(nextButton)
        }
        
        if attemptingToPlay {
            playPauseButton.isEnabled = false
            if !playSong() {
                attemptingToPlay = true
            }
        } else {
            playPauseButton.isEnabled = true
        }
        
    }
    
    func sliderGrabbed() {
        slider.isSelected = true
    }
    
    func sliderReleased() {
        slider.isSelected = false
        player.seek(to: CMTimeMakeWithSeconds(Double(slider.value), 10000))
        sliderMinLabel.text = getTimeStamp(slider.value)
    }

    /*
     *  This Method should play or pause the song, depending on the song's state
     *  It should also toggle between the play and pause images by toggling
     *  sender.selected
     *
     *  If you are playing the song for the first time, you should be creating
     *  an AVPlayerItem from a url and updating the player's currentitem
     *  property accordingly.
     */
    
    func playOrPauseTrack(_ sender: UIButton) {
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")
        let clientID = NSDictionary(contentsOfFile: path!)?.value(forKey: "client_id") as! String
        let track = tracks[currentIndex]
        let url = URL(string: "https://api.soundcloud.com/tracks/\(track.id as Int)/stream?client_id=\(clientID)")!
        // FILL ME IN
        
        let item = AVPlayerItem(url: url)

        if player.currentItem != item && (player.currentItem == nil
            || sender == nextButton || sender == previousButton) {
            player.replaceCurrentItem(with: item)
            sliderMinLabel.text = "0:00"
            playPauseButton.isSelected = true
            paused = true
        }
        
        if paused {
            if !playSong() {
                attemptingToPlay = true
            }
        } else {
            player.pause()
            playPauseButton.isSelected = false
            paused = !paused
        }

    }
    
    func backForward (_ sender: UIButton) {
        loadTrackElements()
        playOrPauseTrack(sender)

    }

    /*
     * Called when the next button is tapped. It should check if there is a next
     * track, and if so it will load the next track's data and
     * automatically play the song if a song is already playing
     * Remember to update the currentIndex
     */
    func nextTrackTapped(_ sender: UIButton) {
        // FILL ME IN
        if (currentIndex + 1) < tracks.count {
            currentIndex = currentIndex + 1
            backForward(sender)
        } else if currentIndex == (tracks.count - 1) {
            currentIndex = 0
            backForward(sender)
        }
    }

    /*
     * Called when the previous button is tapped. It should behave in 2 possible
     * ways:
     *    a) If a song is more than 3 seconds in, seek to the beginning (time 0)
     *    b) Otherwise, check if there is a previous track, and if so it will
     *       load the previous track's data and automatically play the song if
     *      a song is already playing
     *  Remember to update the currentIndex if necessary
     */

    func previousTrackTapped(_ sender: UIButton) {
        let curSeconds = CMTimeGetSeconds((player.currentTime()))
        if curSeconds >= 3 {
            player.seek(to: kCMTimeZero)
            sliderMinLabel.text = "0:00"
        } else {
            if currentIndex - 1 >= 0 {
                currentIndex = currentIndex - 1
                backForward(sender)
            } else if currentIndex == 0 {
                currentIndex = tracks.count - 1
                backForward(sender)
            }
        }
    }


    func asyncLoadTrackImage(_ track: Track) {
        let url = URL(string: track.artworkURL)
        let session = URLSession(configuration: URLSessionConfiguration.default)

        let task = session.dataTask(with: url!) {(data, response, error) -> Void in
            if error == nil {
                let image = UIImage(data: data!)
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                    DispatchQueue.main.async {
                        self.trackImageView.image = image
                    }
                }
            }
        }
        task.resume()
    }
    
    func didLoadTracks(_ tracks: [Track]) {
        self.tracks = tracks
        loadTrackElements()
    }
}

