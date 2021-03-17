//
//  LeanCloud.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/7.
//

import Foundation
import LeanCloud
import RxSwift

class LeanCloud {
    
    static let completionQueue = DispatchQueue(label: "leanCloud")
    
    static func save(
        transform: @escaping () throws -> LCObject
    ) -> Observable<Result<String>> {
        return Single.create { single in
            do {
                let object = try transform()
                let acl = LCACL()
                // deafult allow all user can read write
                acl.setAccess([.read, .write], allowed: true)
                object.ACL = acl
                
                object.save(completionQueue: LeanCloud.completionQueue, completion: { result in
                    switch result {
                    case .success:
                        single(.success(Result(success:true, data: object.objectId?.value)))
                    case .failure(error: let error):
                        single(.success(Result(success:false, message: error.description)))
                    }
                })
            } catch {
                single(.success(Result(success: false, message: error.localizedDescription)))
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func query<T>(
        className: String,
        objectId: String,
        queryWhere: ((LCQuery) throws -> Void)?,
        transform: @escaping (LCObject) throws -> T
    ) -> Observable<Result<T>> {
        return Single.create { single in
            let _query = LCQuery(className: className)
            do {
                if let _where = queryWhere {
                    try _where(_query)
                }
                _query.get(objectId, completionQueue: LeanCloud.completionQueue, completion: { result in
                    do {
                        switch result {
                        case .success(object: let data):
                            single(.success(Result(success:true, data: try transform(data))))
                        case .failure(error: let error):
                            single(.success(Result(success:false, message: error.description)))
                        }
                    } catch {
                        single(.success(Result(success:false, message: error.localizedDescription)))
                    }
                })
            } catch {
                single(.success(Result(success:false, message: error.localizedDescription)))
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func query<T>(
        className: String,
        queryWhere: ((LCQuery) throws -> Void)?,
        transform: @escaping ([LCObject]) throws -> T
    ) -> Observable<Result<T>> {
        return Single.create { single in
            let _query = LCQuery(className: className)
            do {
                if let _where = queryWhere {
                    try _where(_query)
                }
                _query.find (completionQueue: LeanCloud.completionQueue, completion: { result in
                    do {
                        switch result {
                        case .success(objects: let list):
                            single(.success(Result(success:true, data: try transform(list))))
                        case .failure(error: let error):
                            single(.success(Result(success:false, message: error.description)))
                        }
                    } catch {
                        Logger.log(message: "query0 \(className) error:\(error)", level: .error)
                        single(.success(Result(success:false, message: "出错了")))
                    }
                })
            } catch {
                Logger.log(message: "query1 \(className) error:\(error)", level: .error)
                single(.success(Result(success:false, message: "出错了")))
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func delete(
        className: String,
        objectId: String
    ) -> Observable<Result<Void>> {
        return Single.create { single in
            let object = LCObject(className: className, objectId: objectId)
            object.delete { _result in
                switch _result {
                case .success:
                    single(.success(Result(success:true)))
                case .failure(error: let error):
                    single(.success(Result(success:false, message: error.description)))
                }
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func delete(
        className: String,
        queryWhere: ((LCQuery) throws -> Void)?
    ) -> Observable<Result<Void>> {
        return Single.create { single in
            let _query = LCQuery(className: className)
            do {
                if let _where = queryWhere {
                    try _where(_query)
                }
                _query.find (completionQueue: LeanCloud.completionQueue, completion: { result in
                    switch result {
                    case .success(objects: let list):
                        LCObject.delete(list) { _result in
                            switch _result {
                            case .success:
                                single(.success(Result(success:true)))
                            case .failure(error: let error):
                                single(.success(Result(success:false, message: error.description)))
                            }
                        }
                    case .failure(error: let error):
                        if (error.code == 101) {
                            single(.success(Result(success:true)))
                        } else {
                            single(.success(Result(success:false, message: error.description)))
                        }
                    }
                })
            } catch {
                Logger.log(message: "delete \(className) error:\(error)", level: .error)
                single(.success(Result(success:false, message: "出错了")))
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func subscribe<T>(
        className: String,
        queryWhere: ((LCQuery) throws -> Void)?,
        onEvent: @escaping ((LiveQuery.Event) throws -> T?)
    ) -> Observable<Result<T>> {
        return Observable.create { observer -> Disposable in
            let query = LCQuery(className: className)
            var liveQuery: LiveQuery?
            do {
                if let _where = queryWhere {
                    try _where(query)
                }
                liveQuery = try LiveQuery(query: query, eventHandler: { (liveQuery, event) in
                    Logger.log(message: "liveQueryEvent event:\(event)", level: .info)
                    do {
                        let result = try onEvent(event)
                        observer.onNext(Result<T>(success: result != nil, data: result))
                    } catch {
                        observer.onNext(Result<T>(success: false, message: "出错了"))
                    }
                    
                })
                liveQuery!.subscribe { result in
                    switch result {
                    case .success:
                        observer.onNext(Result(success: true))
                        Logger.log(message: "----- subscribe \(className) success -----", level: .info)
                        return
                    case .failure(error: let error):
                        Logger.log(message: "subscribe1 \(className) error:\(error)", level: .error)
                        observer.onNext(Result(success: false, message: error.reason))
                        observer.onCompleted()
                        return
                    }
                }
            } catch {
                Logger.log(message: "subscribe0 \(className) error:\(error)", level: .error)
                observer.onNext(Result(success: false, message: "出错了"))
                observer.onCompleted()
            }
            return Disposables.create {
                liveQuery?.unsubscribe { (result) in
                    switch result {
                    case .success:
                        Logger.log(message: "----- unsubscribe \(className) success -----", level: .info)
                        break
                    case .failure(error: let error):
                        Logger.log(message: "----- unsubscribe \(className) error:\(error) -----", level: .error)
                    }
                }
            }
        }
    }
}

