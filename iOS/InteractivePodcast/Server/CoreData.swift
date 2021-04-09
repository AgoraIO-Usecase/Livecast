//
//  CoreData.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/7.
//

import Foundation
import UIKit
import CoreData
import RxSwift

class CoreData {
    
    static func getSingleNSManagedObject(entityName: String, create: Bool = false) throws -> NSManagedObject? {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let nSManagedObjects = try managedContext.fetch(fetchRequest)
        if (nSManagedObjects.count > 0) {
            return nSManagedObjects[0]
        } else if (create) {
            let entity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext)!
            return NSManagedObject(entity: entity, insertInto: managedContext)
        } else {
            return nil
        }
    }
    
    static func getAccount() -> User? {
        do {
            let account = try getSingleNSManagedObject(entityName: "Account")
            if let account = account {
                return User(id: account.value(forKey: "id") as! String, name: account.value(forKey: "name") as! String, avatar: nil)
            } else {
                return nil
            }
        } catch {
            Logger.log(message: "CoreData getAccount error:\(error)", level: .error)
            return nil
        }
    }
    
    static func saveAccount(user: User) -> Observable<Result<User>> {
        return Single.create { single in
            if let appDelegate =
                UIApplication.shared.delegate as? AppDelegate {
                let managedContext = appDelegate.persistentContainer.viewContext
                do {
                    let account = try getSingleNSManagedObject(entityName: "Account", create: true)
                    if let account = account {
                        account.setValue(user.id, forKey: "id")
                        account.setValue(user.name, forKey: "name")
                        try managedContext.save()
                        single(.success(Result(success: true, data: user)))
                    } else {
                        single(.success(Result(success: false, message: "save accunt error!")))
                    }
                } catch let error as NSError {
                    Logger.log(message: "CoreData saveAccount error:\(error)", level: .error)
                    single(.success(Result(success: false, message: "save accunt error!")))
                }
            } else {
                single(.success(Result(success: false, message: "appDelegate is nil!")))
            }
            return Disposables.create()
        }
        .asObservable()
        .subscribe(on: MainScheduler.instance)
    }
    
    static func getSetting() -> LocalSetting? {
        do {
            let setting = try getSingleNSManagedObject(entityName: "Setting")
            if let setting = setting {
                return LocalSetting(audienceLatency: setting.value(forKey: "audienceLatency") as! Bool)
            } else {
                return LocalSetting()
            }
        } catch {
            Logger.log(message: "CoreData getSetting error:\(error)", level: .error)
            return nil
        }
    }
    
    static func saveSetting(setting: LocalSetting) -> Observable<Result<LocalSetting>> {
        return Single.create { single in
            if let appDelegate =
                UIApplication.shared.delegate as? AppDelegate {
                let managedContext = appDelegate.persistentContainer.viewContext
                do {
                    let _setting = try getSingleNSManagedObject(entityName: "Setting", create: true)
                    if let _setting = _setting {
                        _setting.setValue(setting.audienceLatency, forKey: "audienceLatency")
                        try managedContext.save()
                        single(.success(Result(success: true, data: setting)))
                    } else {
                        single(.success(Result(success: false, message: "save setting error!")))
                    }
                } catch let error as NSError {
                    Logger.log(message: "CoreData saveSetting error:\(error)", level: .error)
                    single(.success(Result(success: false, message: "save setting error!")))
                }
            } else {
                single(.success(Result(success: false, message: "appDelegate is nil!")))
            }
            return Disposables.create()
        }
        .asObservable()
        .subscribe(on: MainScheduler.instance)
    }
}
