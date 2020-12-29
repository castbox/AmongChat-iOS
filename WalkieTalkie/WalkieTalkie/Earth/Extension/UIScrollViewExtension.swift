//
//  UIScrollViewExtension.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import MJRefresh

extension UIScrollView {
    
    /// down pull to refresh
    public func pullToRefresh(withBlock block: @escaping MJRefreshComponentAction) {
       
        let header = MJRefreshNormalHeader(refreshingBlock: block)
        header.loadingView?.color = .white
        header.isAutomaticallyChangeAlpha = true
        header.lastUpdatedTimeLabel?.isHidden = true
        header.stateLabel?.textColor = .white
        header.setTitle("loading...", for: MJRefreshState.refreshing)
        self.mj_header = header
    }
    
     ///up pull to load more
    public func pullToLoadMore(withBlock block: @escaping MJRefreshComponentAction) {
       
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: block)
        footer.loadingView?.color = .white
        footer.stateLabel?.textColor = .white
        footer.setTitle("loading...", for: .refreshing)
        footer.setTitle("", for: .noMoreData)
        footer.setTitle("", for: .idle)

        self.mj_footer = footer
        self.mj_footer?.isHidden = false
    }
    
    public func endLoadMore(_ hasNext: Bool) {
        endRefresh()
        if !hasNext {
            if let footer =  self.mj_footer {
                footer.endRefreshingWithNoMoreData()
            }
        } else {
            if self.mj_footer != nil {
                self.resetMyFooterViewState()
            }
        }
    }
    
    public func resetMyFooterViewState() {
        self.mj_footer?.isHidden = false
        self.mj_footer?.state = MJRefreshState.idle
    }
    ///结束刷新
    public func endRefresh() {
        
        if let header =  self.mj_header {
            header.endRefreshing()
        }
        if let footer =  self.mj_footer {
            footer.endRefreshing()
            footer.isHidden = false
        }
    }
    
    ///开始刷新
    func beginRefreshing() {
        self.mj_header?.beginRefreshing()
    }
}

extension UITableView {
    ///deefault count is 20
    func endLoadMore(by array:[Any]){
        if !array.isEmpty {
            self.reloadData()
        }
        if array.count < 20 {
            endLoadMore(false)
        } else {
            endLoadMore(!array.isEmpty)
        }
    }
    
    ///
    func endLoadMore(by array:[Any],and listOrignalCount:Int){
        if !array.isEmpty {
            self.reloadData()
        }
        if array.count < listOrignalCount {
            endLoadMore(false)
        } else {
            endLoadMore(!array.isEmpty)
        }
    }

}
