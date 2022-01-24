//
//  AdapterURLResolver.swift
//  Minecraft Silicon
//
//  Created by Cole Feuer on 2021-12-27.
//

import Foundation
import CryptoKit

typealias LibraryAnalysisResult = (hash: String, count: Int)

///Calculates the size and hash of a URL
func analyzeLibraryURL(url: URL) async throws -> LibraryAnalysisResult {
	return try await withCheckedThrowingContinuation { continuation in
		let urlSessionDelegate = URLInfoSessionDelegate() { (result, error) in
			if let error = error {
				continuation.resume(throwing: error)
			} else {
				continuation.resume(returning: result!)
			}
		}
		let urlSession = URLSession(configuration: .default, delegate: urlSessionDelegate, delegateQueue: nil)
		
		//Open the URL for reading
		let task = urlSession.dataTask(with: url)
		task.resume()
	}
}

private class URLInfoSessionDelegate: NSObject, URLSessionDataDelegate {
	private let callback: (LibraryAnalysisResult?, Error?) -> Void
	
	private var fileHash = Insecure.SHA1()
	private var fileLength = 0
	
	init(callback: @escaping (LibraryAnalysisResult?, Error?) -> Void) {
		self.callback = callback
	}
	
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		//Progressively calculate the file hash and tally the file length
		fileHash.update(data: data)
		fileLength += data.count
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		//Invoke the callback
		if let error = error {
			callback(nil, error)
		} else {
			let md5Hash = fileHash.finalize().map { String(format: "%02hhx", $0) }.joined()
			callback((md5Hash, fileLength), nil)
		}
	}
}
