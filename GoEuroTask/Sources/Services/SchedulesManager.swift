//
//  SchedulesManager.swift
//  GoEuroTask
//
//  Created by Roman Sinelnikov on 18/02/17.
//  Copyright © 2017 Roman Sinelnikov. All rights reserved.
//

import Foundation

public typealias Callback = ((Swift.Error?) -> ())
@objc public protocol SchedulesManager {
    @objc func refreshSchedule(withType: GEScheduleItemType, completion: @escaping Callback)
}

class TestTaskSchedulesManager: SchedulesManager {
    enum Error: Swift.Error {
        case unspecified
    }
    private var session: URLSession! = nil
    var dataMapper: DataMapper? = nil
    let urlMapping: [GEScheduleItemType:String] = [
        .flight : "https://api.myjson.com/bins/w60i",
        .bus : "https://api.myjson.com/bins/37yzm",
        .train : "https://api.myjson.com/bins/3zmcy"
    ]
    
    
    public func refreshSchedule(withType type: GEScheduleItemType, completion: @escaping Callback) {
        guard let urlString = urlMapping[type], let url = URL(string: urlString) else {
            assertionFailure("Schedule with type \(type) not found!")
            return
        }
        guard let dataMapper = self.dataMapper else {
            assertionFailure("Uninitialized")
            return
        }
        
        if self.session == nil {
            let configuration = URLSessionConfiguration.default
            let queue = OperationQueue()
            queue.qualityOfService = .utility
            self.session = URLSession(configuration: configuration, delegate: nil, delegateQueue: queue)
        }
        
        let task = self.session.dataTask(with: url) { data, response, error  in
            if let error = error {
                completion(error)
            } else if let data = data{
                do {
                    try dataMapper.map(data: data, for: type)
                } catch let error {
                    completion(error)
                }
            } else {
                completion(Error.unspecified)
            }
        }
        task.resume()
    }


}
