//
//  LabelCell.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/9.
//

import IGListKit
import UIKit

final class LabelCell: UICollectionViewCell {

    fileprivate static let insets = UIEdgeInsets(top: 40, left: 0, bottom: 16, right: 0)
    fileprivate static let font = UIFont.systemFont(ofSize: 15)

    static var singleLineHeight: CGFloat {
        return font.lineHeight + insets.top + insets.bottom
    }

    static func textHeight(_ text: String, width: CGFloat) -> CGFloat {
        let constrainedSize = CGSize(width: width - insets.left - insets.right, height: CGFloat.greatestFiniteMagnitude)
        let attributes = [ NSAttributedString.Key.font: font ]
        let options: NSStringDrawingOptions = [.usesFontLeading, .usesLineFragmentOrigin]
        let bounds = (text as NSString).boundingRect(with: constrainedSize, options: options, attributes: attributes, context: nil)
        return ceil(bounds.height) + insets.top + insets.bottom
    }

    fileprivate let label: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.font = LabelCell.font
        label.textColor = UIColor(hex: Colors.White)
        return label
    }()

    let separator: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor(hex: Colors.Black).cgColor
        return layer
    }()

    var text: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.clear
        contentView.addSubview(label)
        contentView.layer.addSublayer(separator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = contentView.bounds
        label.frame = bounds.inset(by: LabelCell.insets)
        addConstraint(NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 0))
        addConstraint(NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1.0, constant: 0))
        label.updateConstraints()
        label.textAlignment = .center
        let height: CGFloat = 5
        let left = LabelCell.insets.left
        separator.frame = CGRect(x: left, y: 20, width: bounds.width - left, height: height)
    }

//    override var isHighlighted: Bool {
//        didSet {
//            let color = isHighlighted ? UIColor.gray.withAlphaComponent(0.3) : UIColor.clear
//            contentView.backgroundColor = color
//        }
//    }
//
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        separator.backgroundColor = UIColor.defaultSeparator.cgColor
//    }

}

extension LabelCell: ListBindable {

    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? String else { return }
        label.text = viewModel
    }

}
