//
//  FollowerListVCViewController.swift
//  GHFollowers
//
//  Created by Nima Bahrami on 8/12/22.
//

import UIKit

protocol FollowerListVCDelegate : AnyObject  {
    
    func didrequstFollowers(for username: String)
    
}

class FollowerListVCViewController: UIViewController {
   
    enum Section {
        case main
    }
    
    var userName: String!
    var followers: [Follower] = []
    var filteredFollowers: [Follower]  = []
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Follower>!
    var page = 1
    var hasMoreFollowers = true
    var isSearching  = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureSearchController()
        configureCollectionView()
        getFollowers(userName: userName, page: page)
        configureDataSource()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func configureViewController () {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    func createThreeColumnFlowLayout() -> UICollectionViewFlowLayout {
        
        let width = view.bounds.width
        let padding: CGFloat = 12
        let miniimumSpacing: CGFloat = 10
        let availableWidth = width - (padding * 2) - (miniimumSpacing * 2)
        let itemWidth = availableWidth / 3
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth + 40 )
        
        return flowLayout
        
    }
    
    func  configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createThreeColumnFlowLayout())
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(GHFollowers.FollowerCellCollectionViewCell.self, forCellWithReuseIdentifier: GHFollowers.FollowerCellCollectionViewCell.reuseId)
        
            
    }
    
    func configureSearchController() {
        let searchController = UISearchController()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search for user"
//        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        
        
    }
    
    func getFollowers(userName: String, page: Int) {
        showLoadingView()
        NetworkManager.shared.getFollowers(for: userName, page: page) { [weak self] result in
          
            //unwrapping weak self optional error
            guard let self = self else { return}
            self.dismissLoadingView()
            
            switch result {
            case .success(let followers):
                if (followers.count < 100) {self.hasMoreFollowers = false}
                self.followers.append(contentsOf: followers)
                self.followers = followers
                if self.followers.isEmpty {
                    let message = "This user does not have any follower , go Follow them :)"
                    DispatchQueue.main.async { self.showEmptyStateView(with: message, in: self.view) }
                    return
                }
                self.updateData(on: self.followers)
                
            case.failure(let error):
                self.presentGFAlertOnMainThread(title: "Bad Stuff Happend", message: error.rawValue, buttonTitle: "Dismiss")
                
            }
            
        }
        
    }
    
    func configureDataSource(){
        dataSource = UICollectionViewDiffableDataSource<Section, Follower>(collectionView: collectionView, cellProvider: { (collectionView, indexPath, follower) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowerCellCollectionViewCell.reuseId, for: indexPath) as! FollowerCellCollectionViewCell
            cell.set(follower: follower)
            return cell

        })
    }
    
    func updateData(on followers: [Follower]) {
        var snapShot = NSDiffableDataSourceSnapshot<Section, Follower>()
        snapShot.appendSections([.main])
        snapShot.appendItems(followers)
        
        DispatchQueue.main.async { self.dataSource.apply(snapShot, animatingDifferences: true) }
        
    }

}

extension FollowerListVCViewController: UICollectionViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if (offsetY > contentHeight - height) {
            guard hasMoreFollowers else {return}
            page += 1
            getFollowers(userName: userName, page: page)
            
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let activeArray = isSearching ? filteredFollowers : followers
        let follower = activeArray[indexPath.item]
        
        let destVC =  UserInfoVC()
        destVC.username = follower.login
        destVC.delegate = self 
        let navController = UINavigationController(rootViewController: destVC)
        present(navController, animated: true)
    }
}

extension FollowerListVCViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let filter = searchController.searchBar.text, !filter.isEmpty else {return }
    isSearching = true
        //
        filteredFollowers = followers.filter {$0.login.lowercased().contains(filter.lowercased())}
        updateData(on: filteredFollowers)
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        updateData(on: followers)
    }
}


extension FollowerListVCViewController: FollowerListVCDelegate {
    func didrequstFollowers(for username: String) {
        //getFollowers fo that user
        self.userName = username
        title = username
        page = 1
        followers.removeAll()
        filteredFollowers.removeAll()
        collectionView.setContentOffset(.zero, animated: true)
        getFollowers(userName: username, page: page)
        
        
    }
    
    
    
}
