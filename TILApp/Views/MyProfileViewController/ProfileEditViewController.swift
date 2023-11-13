import UIKit

final class ProfileEditViewController: UIViewController {
    var username: String {
        get { nicknameTextFieldView.mainText }
        set { nicknameTextFieldView.mainText = newValue }
    }

    var avatarImage: UIImage? {
        get { editProfileImageView.image }
        set { editProfileImageView.image = newValue }
    }

    private lazy var componentView = UIView().then {
        view.addSubview($0)
    }

    private lazy var editProfileImageView = AvatarImageView().then {
        $0.isUserInteractionEnabled = true
        $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
    }

    private lazy var editProfileButton = UIButton().then {
        $0.setImage(UIImage(systemName: "photo.circle"), for: .normal)
        $0.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        $0.backgroundColor = .white
    }

    private lazy var memberWithdrawalButton = UIButton().then {
        $0.setTitle("회원 탈퇴", for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        $0.sizeToFit()
        view.addSubview($0)
        $0.addTarget(self, action: #selector(memberWithdrawalTapped), for: .touchUpInside)
    }

    private lazy var nicknameTextFieldView = CustomTextFieldViewWithValidation().then {
        $0.titleText = "유저 닉네임"
        $0.placeholder = "닉네임을 입력하세요"
        $0.validationText = ""
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .systemBackground

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideKeyboardWhenTappedAround()

        navigationItem.title = "프로필 수정"
        navigationItem.rightBarButtonItem = .init(
            title: "완료",
            style: .plain,
            target: self,
            action: #selector(completeButtonTapped)
        )
        
        componentView.flex.direction(.column).marginTop(40).define { flex in
            flex.addItem().direction(.row).justifyContent(.center).define { flex in
                flex.addItem(editProfileImageView).width(100).height(100)
                flex.addItem(editProfileButton).position(.absolute).size(24).cornerRadius(12)
                    .bottom(8%).right(38%)
            }
            flex.addItem(nicknameTextFieldView).marginTop(10)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        memberWithdrawalButton.pin.bottom(view.pin.safeArea).hCenter()
        componentView.pin.top(view.pin.safeArea).bottom(50%).horizontally(view.pin.safeArea)
        componentView.flex.layout()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    @objc private func profileTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }

    @objc private func completeButtonTapped() {
        Task {
            var avatarUrl: String?
            if let avatarImage {
                let file = try? await APIService.shared.request(.uploadImage(avatarImage), to: File.self)
                avatarUrl = file?.url
            }
            AuthViewModel.shared.update(.init(username: username, avatarUrl: avatarUrl)) { [weak self] result in
                guard let self else { return }
                if case let .failure(error) = result {
                    // TODO: 에러처리
                    debugPrint(#function, error)
                    return
                }
                navigationController?.popViewController(animated: true)
            }
        }
    }

    @objc private func memberWithdrawalTapped() {
        let alertController = UIAlertController(
            title: "회원 탈퇴",
            message: "정말로 회원 탈퇴를 하시겠어요?\n회원 탈퇴 시 저장한 블로그와 게시글이 모두 삭제되어 복구할 수 없습니다.",
            preferredStyle: .alert
        )
        alertController.addAction(.init(title: "탈퇴", style: .destructive) { _ in
            AuthViewModel.shared.withdraw()
        })
        alertController.addAction(.init(title: "취소", style: .cancel, handler: nil))
        present(alertController, animated: true)
    }

    private func validateNickname() {
        // TODO: 닉네임 유효성 검사 로직
//        let nickname = nicknameTextFieldView.text
//        if {
//            print("통과")
//            nicknameTextFieldView.validationText = "유효한 닉네임입니다."
//        } else {
//            print("불통")
//            nicknameTextFieldView.validationText = "사용 불가능한 닉네임입니다.."
//        }
    }
}

extension ProfileEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.editedImage] as? UIImage {
            editProfileImageView.image = image
            editProfileImageView.removeDefault()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
