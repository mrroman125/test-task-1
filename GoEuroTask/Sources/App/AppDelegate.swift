//
//  AppDelegate.swift
//  GoEuroTask
//
//  Created by Roman Sinelnikov on 18/02/17.
//  Copyright © 2017 Roman Sinelnikov. All rights reserved.
//

import Foundation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var coreDataManager: CoreDataManager!
    private var schedulesManager: SchedulesManager!
    func applicationDidFinishLaunching(_ application: UIApplication) {

        self.coreDataManager = try! CoreDataSwiftManager()
        let dataMapper = CoreDataDataMapper()
        dataMapper.coreDataManager = self.coreDataManager
        let manager = TestTaskSchedulesManager()
        manager.dataMapper = dataMapper
        self.schedulesManager = manager
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let controller = UITabBarController()
        let viewControllers: [GEScheduleViewController] = [
            GEScheduleViewController(itemType: .train),
            GEScheduleViewController(itemType: .bus),
            GEScheduleViewController(itemType: .flight)
        ]
        
        for viewController in viewControllers {
            viewController.managedObjectContext = self.coreDataManager.viewContext
            viewController.schedulesManager = self.schedulesManager
        }
        
        
        controller.viewControllers = viewControllers.map { input in
            let controller = UINavigationController(rootViewController: input)
            switch(input.itemType) {
                case .train:
                    controller.tabBarItem.image = #imageLiteral(resourceName: "ic_train")
                case .bus:
                    controller.tabBarItem.image = #imageLiteral(resourceName: "ic_directions_bus")
                case .flight:
                    controller.tabBarItem.image = #imageLiteral(resourceName: "ic_flight")
                default: break
            }
            return controller
        }
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
    }
}
