import UIKit

final class CommunityViewController: UIViewController {
    private let communityViewModel = CommunityViewModel.shared
    private let userViewModel = UserViewModel.shared
    private var posts: [CommunityPost] { communityViewModel.posts }
    private var cancellables: Set<AnyCancellable> = []
    private var isHeartFilled = false

    private lazy var tableView = UITableView().then {
        $0.dataSource = self
        $0.delegate = self
        $0.keyboardDismissMode = .onDrag
        $0.refreshControl = UIRefreshControl()
        $0.register(CommunityTableViewCell.self, forCellReuseIdentifier: "CommunityTableViewCell")
        $0.applyCustomSeparator()
        view.addSubview($0)
    }

    private lazy var searchBar = UISearchBar().then {
        $0.delegate = self
        $0.searchTextField.delegate = self
        view.addSubview($0)
    }

    private lazy var loadingView = UIActivityIndicatorView().then {
        $0.startAnimating()
        view.addSubview($0)
    }

    private lazy var footerLoadingView = UIActivityIndicatorView().then {
        tableView.tableFooterView = $0
        $0.frame = .init(x: 0, y: 0, width: tableView.bounds.width, height: 100)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        communityViewModel.delegate = self
        communityViewModel.load { [weak self] _ in
            guard let self else { return }
            loadingView.stopAnimating()
            loadingView.isHidden = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        communityViewModel.refresh()
        WKWebViewWarmer.shared.prepare()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        WKWebViewWarmer.shared.clear()
    }

    override func viewDidLayoutSubviews() {
        searchBar.pin.top(view.pin.safeArea).horizontally().height(60)
        tableView.pin.top(to: searchBar.edge.bottom).horizontally().bottom(view.pin.safeArea)
        loadingView.pin.center()
    }

    @objc private func heartButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
}

extension CommunityViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "CommunityTableViewCell",
            for: indexPath
        ) as? CommunityTableViewCell else {
            return UITableViewCell()
        }

        let post = posts[indexPath.row]
        cell.customCommunityTILView.setup(post: post)
        if let authUser = AuthViewModel.shared.user, post.user.id == authUser.id {
            cell.customCommunityTILView.variant = .hidden
        } else if userViewModel.isMyFollowing(user: post.user) {
            cell.customCommunityTILView.variant = .unfollow
        } else {
            cell.customCommunityTILView.variant = .follow
        }

        cell.customCommunityTILView.followButtonTapped = { [weak self, weak cell] in
            guard let self, let cell else { return }
            switch cell.customCommunityTILView.variant {
            case .follow:
                userViewModel.follow(user: post.user) { [weak cell] result in
                    guard case .success(let success) = result, success else {
                        // TODO: 에러 처리
                        return
                    }
                    cell?.customCommunityTILView.variant = .unfollow
                }
            case .unfollow:
                userViewModel.unfollow(user: post.user) { [weak cell] result in
                    guard case .success(let success) = result, success else {
                        // TODO: 에러 처리
                        return
                    }
                    cell?.customCommunityTILView.variant = .follow
                }
            default:
                break
            }
        }

        cell.selectionStyle = .none

        cell.customCommunityTILView.userProfileTapped = { [weak self] in
            guard let self, let authUser = AuthViewModel.shared.user, post.user.id != authUser.id else { return }
            let userProfileViewController = UserProfileViewController()
            userProfileViewController.user = post.user
            userProfileViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(userProfileViewController, animated: true)
        }

        cell.customCommunityTILView.postTapped = { [weak self] in
            guard let self else { return }
            let likeButton = LikeButton(liked: post.liked)
            likeButton.buttonTapped = { (liked: Bool, completion: @escaping () -> Void) in
                APIService.shared.request(liked ? .unlikePost(post.id) : .likePost(post.id)) { result in
                    guard case .success = result else { return }
                    completion()
                }
            }

            let webViewController = WebViewController()
            webViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: likeButton)
            webViewController.hidesBottomBarWhenPushed = true
            webViewController.url = post.url
            navigationController?.pushViewController(webViewController, animated: true)
        }

        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 180
    }
}

extension CommunityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastSectionIndex = tableView.numberOfSections - 1
        let lastRowIndex = tableView.numberOfRows(inSection: 0) - 1
        if indexPath.section == lastSectionIndex && indexPath.row == lastRowIndex {
            communityViewModel.loadMore()
        }
    }

    func scrollViewDidEndDragging(_: UIScrollView, willDecelerate _: Bool) {
        guard let refreshControl = tableView.refreshControl, refreshControl.isRefreshing else { return }
        communityViewModel.refresh { _ in
            refreshControl.endRefreshing()
        }
    }
}

extension CommunityViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            communityViewModel.search(query: text)
        }
        searchBar.resignFirstResponder()
    }
}

extension CommunityViewController: UITextFieldDelegate {
    func textFieldShouldClear(_: UITextField) -> Bool {
        communityViewModel.reload()
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in
            self?.searchBar.resignFirstResponder()
        }
        return true
    }
}

extension CommunityViewController: CommunityViewModelDelegate {
    func itemsUpdated(_: CommunityViewModel, items _: [CommunityPost], range: Range<Int>) {
        if range.lowerBound > 0 {
            let indexPaths = range.map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .automatic)
        } else {
            tableView.reloadData()
        }
    }

    func errorOccurred(_: CommunityViewModel, error: String) {
        // TODO: 에러처리
        debugPrint(#function, error)
    }
}
