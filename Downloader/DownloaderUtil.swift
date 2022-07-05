//
//  HashUtil.swift
//  DDR BPM
//
//  Created by Michael Xie on 4/7/2022.
//

import Foundation

import CryptoKit

typealias HashDigest = Insecure.SHA1Digest

private func hashFile(_ file: URL) -> HashDigest {
    let data: Data
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(file):\n\(error)")
    }
    
    return Insecure.SHA1.hash(data: data)
}
