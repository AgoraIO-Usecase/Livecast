//
//  SpeakersController.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/9.
//

import Foundation
import IGListKit
import UIKit

final class SpeakersController: ListSectionController {
    private var group: SpeakerGroup!
    private weak var delegate: RoomControlDelegate?
    
    init(delegate: RoomControlDelegate) {
        super.init()
        minimumLineSpacing = 16
        inset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        self.delegate = delegate
    }
    
    override func didUpdate(to object: Any) {
        self.group = object as? SpeakerGroup
    }
    
    override func numberOfItems() -> Int {
        return group.list.count
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        Logger.log(message: "sizeForItem index:\(index) \(inset)", level: .info)
        let width = (collectionContext!.insetContainerSize.width - inset.left - inset.right) / 3
        return SpeakerView.sizeForItem(width: width)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let view = collectionContext!.dequeueReusableCell(of: SpeakerView.self, for: self, at: index) as! SpeakerView
        view.model = group.list[index]
        view.delegate = delegate
        return view
    }
}
