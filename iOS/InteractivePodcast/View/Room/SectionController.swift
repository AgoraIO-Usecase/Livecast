//
//  SectionController.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/9.
//

import IGListKit
import UIKit

final class SectionController: ListSectionController {

    private var object: String?

    override func sizeForItem(at index: Int) -> CGSize {
        let width = collectionContext!.insetContainerSize.width
        let height = LabelCell.singleLineHeight
        return CGSize(width: width, height: height)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell: LabelCell = collectionContext!.dequeueReusableCell(of: LabelCell.self, for: self, at: index) as! LabelCell
        cell.text = object
        return cell
    }

    override func didUpdate(to object: Any) {
        self.object = object as? String
    }
}
