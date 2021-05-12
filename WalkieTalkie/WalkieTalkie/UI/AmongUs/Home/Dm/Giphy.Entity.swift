//
//  Conversation.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 11/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Giphy {
    struct GPHImage: Codable {
        let height: String
        let width: String
        let size: String?
        let url: URL
        let mp4Size: String?
        let mp4: URL?
        let webpSize: String?
        let webp: URL?
        private enum CodingKeys: String, CodingKey {
            case height
            case width
            case size
            case url
            case mp4Size = "mp4_size"
            case mp4
            case webpSize = "webp_size"
            case webp
        }
    }
    
    struct GPHImages: Codable {
        let downsizedMedium: GPHImage?
        let fixedHeight: GPHImage?
        let previewGif: GPHImage?
//        let fixedHeight: GPHImage?
        
        private enum CodingKeys: String, CodingKey {
            case downsizedMedium = "downsized_medium"
            case fixedHeight = "fixed_height"
            case previewGif = "preview_gif"
//            case fixedHeight = "fixed_height"
        }
    }
    
    struct GPHMedia: Codable {
        let type: String
        let id: String
        let url: URL
        let title: String
        let rating: String
        let contentUrl: String
        let isSticker: Int
//        let importDatetime: Date
        let images: GPHImages
        
        var height: CGFloat {
            //calculate height
            let rawHeight = images.downsizedMedium?.height.cgFloat() ?? 40
            let rawWidth = images.downsizedMedium?.width.cgFloat() ?? 40
            let leftEdge: CGFloat = 20
            let itemSpace: CGFloat = 12
            let itemWidth: CGFloat = ((Frame.Screen.width - leftEdge * 2 - itemSpace) / 2).floor
            return itemWidth * rawHeight / rawWidth
        }
        
        var imageWidth: Double? {
            images.fixedHeight?.width.double()
        }
        var imageHeight: Double? {
            images.fixedHeight?.height.double()
        }

        
        var previewGifUrl: URL? {
            images.fixedHeight?.url
        }
        var gifUrl: URL? {
            images.fixedHeight?.url
        }
        
        private enum CodingKeys: String, CodingKey {
            case type
            case id
            case url
            case title
            case rating
            case contentUrl = "content_url"
            case isSticker = "is_sticker"
//            case importDatetime = "import_datetime"
            case images
        }
    }
    
//    struct Model: Codable {
//        let data: [Any]
//        struct Pagination: Codable {
//            let totalCount: Int
//            let count: Int
//            let offset: Int
//            private enum CodingKeys: String, CodingKey {
//                case totalCount = "total_count"
//                case count
//                case offset
//            }
//        }
//        let pagination: Pagination
//        struct Meta: Codable {
//            let status: Int
//            let msg: String
//            let responseId: String
//            private enum CodingKeys: String, CodingKey {
//                case status
//                case msg
//                case responseId = "response_id"
//            }
//        }
//        let meta: Meta
//    }
}



//{
//"type": "gif",
//"id": "Y8ocCgwtdj29O",
//"url": "https://giphy.com/gifs/marty-culp-Y8ocCgwtdj29O",
//"title": "Bill Hader Hello GIF",
//"rating": "g",
//"content_url": "",
//"is_sticker": 0,
//"import_datetime": "2015-03-31 19:22:20",
//    "images": {
//        "downsized_medium": {
//            "height": "404",
//            "width": "444",
//            "size": "391945",
//            "url": "https://media4.giphy.com/media/Y8ocCgwtdj29O/giphy.gif?cid=2481978bmg64p7z6jvaurs8sjge6gntb6c5avefxrdaa5nxt&rid=giphy.gif&ct=g"
//        },
//        "fixed_height": {
//            "height": "200",
//            "width": "220",
//            "size": "92120",
//            "url": "https://media4.giphy.com/media/Y8ocCgwtdj29O/200.gif?cid=2481978bmg64p7z6jvaurs8sjge6gntb6c5avefxrdaa5nxt&rid=200.gif&ct=g",
//            "mp4_size": "14202",
//            "mp4": "https://media4.giphy.com/media/Y8ocCgwtdj29O/200.mp4?cid=2481978bmg64p7z6jvaurs8sjge6gntb6c5avefxrdaa5nxt&rid=200.mp4&ct=g",
//            "webp_size": "21128",
//            "webp": "https://media4.giphy.com/media/Y8ocCgwtdj29O/200.webp?cid=2481978bmg64p7z6jvaurs8sjge6gntb6c5avefxrdaa5nxt&rid=200.webp&ct=g"
//        },
//        "preview_gif": {
//            "height": "108",
//            "width": "119",
//            "size": "49993",
//            "url": "https://media4.giphy.com/media/Y8ocCgwtdj29O/giphy-preview.gif?cid=2481978bmg64p7z6jvaurs8sjge6gntb6c5avefxrdaa5nxt&rid=giphy-preview.gif&ct=g"
//        }
//    }
//}
