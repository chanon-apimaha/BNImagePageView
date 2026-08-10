import UIKit

class BNImagePageGridHideShareView: BNImagePageGridView {
    override func viewDidLoad() {
        super.viewDidLoad()
        mButtonClose.setImage(BNSetting.closeImage, for: .normal)
        mButtonClose.tintColor = .white
        mButtonClose.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        mButtonClose.backgroundColor = .clear
        mButtonShare.backgroundColor = .clear
    }

    override func handleOneTapScrollView(recognizer: UITapGestureRecognizer) {
        toggleBuutonCloseAndShareFinFIn()
    }
}
