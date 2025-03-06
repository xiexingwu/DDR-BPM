//
//  HashUtil.swift
//  DDR BPM
//
//  Created by Michael Xie on 4/7/2022.
//

import Foundation
import CryptoKit

typealias HashDigest = Insecure.SHA1Digest

enum FileError: Error {
    case fileNotFound
    case readFailed
    case fileCorrupted
}

func responseSucceeded(_ response: URLResponse) -> Bool {
    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
        return statusCode >= 200 && statusCode <= 299
    } else {
        return false
    }
}

private func getMagnitude(_ val: Int64) -> Int {
    // magnitude 1000^?: 1 -> KiB, 2-> MiB, 3-> GiB ...
    return Int(log(Float(val)) / log(1024))
}

private func getBytesUnit(_ mult: Int) -> String {
    switch mult{
    case 0:
        return "B"
    case 1:
        return "KB"
    case 2:
        return "MB"
    case 3:
        return "GB"
    default:
        return "?B"
    }
}

func formatBytes(_ bytes: Int64) -> String{
    let mult = getMagnitude(bytes)
    let base = Int(pow(Float(1024), Float(mult)))
    let sig = Float(bytes)/Float(base)
    let sigStr = sig >= 10 ? String(format:"%.1f", sig) : String(format: "%.0f", sig)
    return sigStr + getBytesUnit(mult)
}


func readLines(contentsOf url: URL) throws -> [String] {

    do {
        let data = try String(contentsOf: url, encoding: .utf8)
        var lines = data.components(separatedBy: "\n")
        if let isEmpty = lines.last?.isEmpty {
            if isEmpty { lines.removeLast() }
        }
        return lines
    } catch {
        defaultLogger.error("Failed to readLines of \(String(describing: url))")
        throw FileError.readFailed
    }
}

func hashFile(_ file: URL) throws -> HashDigest {
    let data: Data
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        defaultLogger.error("Couldn't read \(file) for hashing")
        throw FileError.readFailed
    }
    
    return Insecure.SHA1.hash(data: data)
}

func getFileHash(_ file: URL) throws -> HashDigest {
    if !FileManager.default.fileExists(atPath: file.path){
        defaultLogger.error("Failed to find file for hashing: \(file.path)")
        throw FileError.fileNotFound
    }
    
    let hash = try hashFile(file)
    return hash
}
