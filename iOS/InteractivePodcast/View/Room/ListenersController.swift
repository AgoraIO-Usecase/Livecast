//
//  MembersController.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/9.
//

import Foundation
import IGListKit
import UIKit

final class ListenersController: ListSectionController {
    private var group: MemberGroup!
    private weak var delegate: RoomControlDelegate?
    
    init(delegate: RoomControlDelegate) {
        super.init()
        self.delegate = delegate
    }
    
    override func didUpdate(to object: Any) {
        self.group = object as? MemberGroup
    }
    
    override func numberOfItems() -> Int {
        return group.list.count
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        let width = (collectionContext!.insetContainerSize.width) / 2
        return ListenerView.sizeForItem(width: width)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let view = collectionContext!.dequeueReusableCell(of: ListenerView.self, for: self, at: index) as! ListenerView
        view.model = group.list[index]
        view.delegate = delegate
        return view
    }
}
