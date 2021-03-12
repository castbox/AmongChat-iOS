//
// Created by LXH on 2019/12/18.
// Copyright (c) 2019 CavanSu. All rights reserved.
//

import Foundation

struct KeyCenter {
    struct Agora {
        static let AppId: String = "db4ec67c84774be1ad7b1414fdca7979"

        /* assign Token to nil if you have not enabled app certificate
         * before you deploy your own token server, you can easily generate a temp token for dev use
         * at https://dashboard.agora.io note the token generated are allowed to join corresponding room ONLY.
         */
        /* 如果没有打开鉴权Token, 这里的token值给nil就好
         * 生成Token需要参照官方文档部署Token服务器，开发阶段若想先不部署服务器, 可以在https://dashbaord.agora.io生成
         * 临时Token. 请注意生成Token时指定的频道名, 该Token只允许加入对应的频道
         */
        static let Token: String? = nil

        static let RtmToken: String? = nil

    }
    
    struct Zego {
        
        static let AppId: UInt32 = 3873664533

        static let appSign = "c9490d982905e328c0bd8f44badfb2a4628b60e439dafa21c9a22e40e46d1408"

    }
}
