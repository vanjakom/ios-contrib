//
//  CloudKitExchange.swift
//  TrekMate
//
//  Created by Vanja Komadinovic on 12/17/16.
//  Copyright © 2016 mungolab.com. All rights reserved.
//

import Foundation
import CloudKit

enum CloudKitExchangeRequestStatus {
    case ok
    case fail
}

class CloudKitExchange {
    let database: CKDatabase
    let exchangeRecordType: String
    init(_ containerName: String, _ exchangeRecordType: String) {
        let container = CKContainer(identifier: containerName)
        self.database = container.publicCloudDatabase
        self.exchangeRecordType = exchangeRecordType
    }
    
    func put(
        _ type: String,
        data: Dictionary<String, AnyObject>,
        _ handler: @escaping (_ status: CloudKitExchangeRequestStatus) -> Void) -> Void {
        
        let temporaryPath = self.temporaryFilePath()
        if let serializedData = self.serializeDictionary(data) {
            do {
                try serializedData.write(to: temporaryPath)
                
                self.put(type, dataUrl: temporaryPath, handler)
            } catch {
                DispatchQueue.main.async {
                    handler(.fail)
                }
            }
        } else {
            DispatchQueue.main.async {
                handler(.fail)
            }
        }
    }
    
    func put(
        _ type: String,
        dataUrl: URL,
        _ handler: @escaping (_ status: CloudKitExchangeRequestStatus) -> Void) -> Void {
        
        let exchangeMessage = CKRecord(recordType: self.exchangeRecordType)
        exchangeMessage.setObject(Date() as CKRecordValue?, forKey: "timestamp")
        exchangeMessage.setObject(0 as CKRecordValue?, forKey: "marked")
        exchangeMessage.setObject(type as CKRecordValue?, forKey: "type")
        
        let dataAsset = CKAsset(fileURL: dataUrl)
        exchangeMessage.setObject(dataAsset, forKey: "data")
        
        self.database.save(exchangeMessage) { (record, error) in
            if record != nil && error == nil {
                DispatchQueue.main.async {
                    handler(.fail)
                }
            } else {
                DispatchQueue.main.async {
                    handler(.fail)
                }
            }
        }
    }

    private func serializeDictionary(_ dictionary: Dictionary<String, AnyObject>) -> Data? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions())
            return data
        } catch {
            return nil
        }
    }
    
    private func temporaryFilePath() -> URL {
        return NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(NSUUID().uuidString + ".tmp")!
    }
}
