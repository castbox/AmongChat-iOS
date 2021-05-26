//
//  FeedListCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 25/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class FeedListCell: UITableViewCell {

    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var shareButton: BottomTitleButton!
    @IBOutlet weak var commentButton: BottomTitleButton!
    @IBOutlet weak var moreButton: BottomTitleButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var emotes: [Post] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionView.register(nibWithCellClass: FeedEmojiCollectionCell.self)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}


extension FeedListCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emotes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let notice = emotes.safe(indexPath.item) else {
            return UICollectionViewCell()
        }
        
        let cell = collectionView.dequeueReusableCell(withClass: FeedEmojiCollectionCell.self, for: indexPath)
//            if let cell = cell as? SocialMessageCell {
//                cell.bindNoticeData(notice)
//            }
        
        return cell
    }
}

extension FeedListCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
//        guard let notice = emotes.safe(indexPath.item) else {
            return .zero
//        }

//        return notice.itemsSize
    }
    
}

extension FeedListCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let notice = emotes.safe(indexPath.item) else {
            return
        }
        
//        notice.action()
    }
    
}
