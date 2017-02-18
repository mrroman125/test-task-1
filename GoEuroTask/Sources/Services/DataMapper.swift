//
//  DataMapper.swift
//  GoEuroTask
//
//  Created by Roman Sinelnikov on 18/02/17.
//  Copyright © 2017 Roman Sinelnikov. All rights reserved.
//

import Foundation

public protocol DataMapper {
    @discardableResult func map(data: Data, for: GEScheduleItemType) throws -> [Any]
}

public class CoreDataDataMapper: DataMapper {
    private let dateFormatter: DateFormatter
    enum Error: Swift.Error {
        case invalidJSON
    }
    var coreDataManager: CoreDataManager?
    
    init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "HH:mm"
    }
    
    public func map(data: Data, for type: GEScheduleItemType) throws -> [Any] {
        guard let coreDataManager = self.coreDataManager else {
            assertionFailure("Uninitialized")
            return []
        }
        
        guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? Array<Dictionary<String, Any>> else {
            throw Error.invalidJSON
        }
        var result = [Any]()
        try coreDataManager.write { context in
            let request = NSFetchRequest<GEScheduleItem>(entityName: "GEScheduleItem")
            request.predicate = NSPredicate(format: "type == %d", type.rawValue)
            let all = try context.fetch(request)
            for item in all {
                context.delete(item)
            }
            result = try array.map{ input -> NSManagedObjectID in
                if let id = input["id"] as? Int64,
                    let providerLogo = input["provider_logo"] as? String,
                    let departureTime = input["departure_time"] as? String,
                    let arrivalTime = input["arrival_time"] as? String,
                    let stops = input["number_of_stops"] as? Int {
                    let item = NSEntityDescription.insertNewObject(forEntityName: "GEScheduleItem", into: context) as! GEScheduleItem
                    item.id = id
                    item.providerLogo = providerLogo
                    if let price = input["price_in_euros"] as? Double {
                        item.price = price
                    } else if let price = input["price_in_euros"] as? String {
                        item.price = Double(price) ?? 0.0
                    }
                    item.departureTime = self.dateFormatter.date(from: departureTime)
                    item.arrivalTime = self.dateFormatter.date(from: arrivalTime)
                    item.numberOfStops = Int32(stops)
                    item.type = type.rawValue
                    return item.objectID
                } else {
                    throw Error.invalidJSON
                }
            }
        }
        
        return result
    }


}
