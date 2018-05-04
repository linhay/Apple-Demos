//
//  ViewController.swift
//  DownloadFont
//
//  Created by linhey on 2018/5/4.
//  Copyright © 2018年 Apple, Inc. All rights reserved.
//

import UIKit
import CoreText

class ViewController: UIViewController {
  
  var fontNames = [String]()
  var fontSamples = [String]()
  
  @IBOutlet weak var fTableView: UITableView!
  @IBOutlet weak var fTextView: UITextView!
  @IBOutlet weak var fProgressView: UIProgressView!
  @IBOutlet weak var fActivityIndicatorView: UIActivityIndicatorView!
  
  var errorMessage = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    fontNames = ["STXingkai-SC-Light",
                 "DFWaWaSC-W5",
                 "FZLTXHK--GBK1-0",
                 "STLibian-SC-Regular",
                 "LiHeiPro",
                 "HiraginoSansGB-W3"]
    fontSamples = ["汉体书写信息技术标准相",
                   "容档案下载使用界面简单",
                   "支援服务升级资讯专业制",
                   "作创意空间快速无线上网",
                   "兙兛兞兝兡兣嗧瓩糎",
                   "㈠㈡㈢㈣㈤㈥㈦㈧㈨㈩"]
  }
  
  
}

extension ViewController {
  
  
  func asynchronouslySetFontName(fontName: String) {
    // If the font is already downloaded
    if let aFont = UIFont(name: fontName, size: 12),
      aFont.fontName == fontName || aFont.familyName == fontName{
      // Go ahead and display the sample text.
      let sampleIndex = fontNames.index { (item) -> Bool in
        return item == fontName
        } ?? 0
      fTextView.text = fontSamples[sampleIndex]
      fTextView.font = UIFont(name: fontName, size: 24)
      return
    }
    
    // Create a dictionary with the font's PostScript name.
    let attrs = [kCTFontNameAttribute:fontName]
    // Create a new font descriptor reference from the attributes dictionary.
    let desc = CTFontDescriptorCreateWithAttributes(attrs as CFDictionary)
    let descs = [desc]
    var errorDuringDownload = false
    
    // Start processing the font descriptor..
    // This function returns immediately, but can potentially take long time to process.
    // The progress is notified via the callback block of CTFontDescriptorProgressHandler type.
    // See CTFontDescriptor.h for the list of progress states and keys for progressParameter dictionary.
    CTFontDescriptorMatchFontDescriptorsWithProgressHandler(descs as CFArray, nil) { (state, progressParameter) -> Bool in
      //NSLog( @"state %d - %@", state, progressParameter);
      
      /* progressParameter keys:
       CTFontDescriptorMatchingTotalAssetSize
       CTFontDescriptorMatchingCurrentAssetSize
       CTFontDescriptorMatchingDescriptors
       CTFontDescriptorMatchingTotalDownloadedSize
       CTFontDescriptorMatchingPercentage
       */
      
      let progressValue: Float = Float((progressParameter as NSDictionary).value(forKey: kCTFontDescriptorMatchingPercentage as String) as? Double ?? 0)
      
      switch state {
      case .didBegin:
        DispatchQueue.main.async {
          // Show an activity indicator
          self.fActivityIndicatorView.startAnimating()
          self.fActivityIndicatorView.isHidden = false
          // Show something in the text view to indicate that we are downloading
          self.fTextView.text = "Downloading: " + fontName
          self.fTextView.font = UIFont.systemFont(ofSize: 14)
          print("Begin Matching")
        }
      case .didFinish:
        DispatchQueue.main.async {
          // Remove the activity indicator
          self.fActivityIndicatorView.stopAnimating()
          self.fActivityIndicatorView.isHidden = true
          // Display the sample text for the newly downloaded font
          let sampleIndex = self.fontNames.index(where: { (item) -> Bool in
            return item == fontName
          }) ?? 0
          self.fTextView.text = self.fontSamples[sampleIndex]
          self.fTextView.font = UIFont(name: fontName, size: 24)
          // Log the font URL in the console
          let fontRef = CTFontCreateWithName(fontName as CFString, 0, nil)
          let fontURL = CTFontCopyAttribute(fontRef, kCTFontURLAttribute)
          print(fontURL ?? "")
          if (!errorDuringDownload) {
            print("\(fontName) downloaded");
          }
        }
      case .willBeginDownloading:
        DispatchQueue.main.async {
          // Show a progress bar
          self.fProgressView.progress = 0.0
          self.fProgressView.isHidden = false
          print("Begin Downloading")
        }
      case .didFinishDownloading:
        DispatchQueue.main.async {
          // Remove the progress bar
          self.fProgressView.isHidden = true
          print("Finish downloading")
        }
        
      case .downloading:
        DispatchQueue.main.async {
          // Use the progress bar to indicate the progress of the downloading
          self.fProgressView.setProgress(progressValue / 100, animated: true)
          print("Downloading \(progressValue)% complete")
        }
      case .didFailWithError:
        // An error has occurred.
        // Get the error message
        
        if let error = (progressParameter as NSDictionary).value(forKey: kCTFontDescriptorMatchingError as String) as? NSError {
          self.errorMessage = error.description
        } else {
          self.errorMessage = "ERROR MESSAGE IS NOT AVAILABLE!"
        }
        // Set our flag
        errorDuringDownload = true;
        DispatchQueue.main.async {
          self.fProgressView.isHidden = true
          print("Download error: \(self.errorMessage)");
        }
        
      default: break
      }
      
      return true
    }
  }
  
}

extension ViewController: UITableViewDelegate,UITableViewDataSource {
  
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fontNames.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let MyIdentifier = "MyIdentifier"
    
    // Try to retrieve from the table view a now-unused cell with the given identifier.
    let cell = tableView.dequeueReusableCell(withIdentifier: MyIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: MyIdentifier)
    
    // Set up the cell.
    cell.textLabel?.text = fontNames[indexPath.item]
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    asynchronouslySetFontName(fontName: fontNames[indexPath.item])
    if fTextView.isFirstResponder {
      fTextView.resignFirstResponder()
    }
  }
}
