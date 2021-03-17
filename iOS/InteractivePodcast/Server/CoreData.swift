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
    
    static func getAccount() -> User? {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Account")
        do {
            let accounts = try managedContext.fetch(fetchRequest)
            if (accounts.count > 0) {
                let account = accounts[0]
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
                let entity = NSEntityDescription.entity(forEntityName: "Account", in: managedContext)!
                
                do {
                    let account = NSManagedObject(entity: entity, insertInto: managedContext)
                    account.setValue(user.id, forKey: "id")
                    account.setValue(user.name, forKey: "name")
                    try managedContext.save()
                    single(.success(Result(success: true, data: user)))
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
}
