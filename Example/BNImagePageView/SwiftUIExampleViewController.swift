//
//  SwiftUIExampleViewController.swift
//  BNImagePageView_Example
//

import UIKit
import SwiftUI
import BNImagePageView

@available(iOS 15.0, *)
struct BNImagePageSwiftUIExample: View {
    @State private var showSingle = false
    @State private var showMultiple = false

    private let imageURL = "https://homepages.cae.wisc.edu/~ece533/images/airplane.png"
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        return iv
    }()

    var body: some View {
        VStack(spacing: 20) {
            AsyncImage(url: URL(string: imageURL)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 200, height: 100)
            .onTapGesture { showSingle = true }

            Button("Show Single Image") { showSingle = true }
            Button("Show Multiple Images") { showMultiple = true }
        }
        .fullScreenCover(isPresented: $showSingle) {
            BNImagePageViewRepresentable(imageView: imageView, imageURL: imageURL)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showMultiple) {
            BNImagePageViewRepresentable(
                imageView: imageView,
                pageData: [
                    ImgaePageData(atIndex: IndexPath(row: 0, section: 0), sImageUrl: imageURL, fWidth: 800, fHeight: 600),
                    ImgaePageData(atIndex: IndexPath(row: 1, section: 0), sImageUrl: "https://homepages.cae.wisc.edu/~ece533/images/baboon.png", fWidth: 512, fHeight: 512)
                ],
                atIndexPath: IndexPath(row: 0, section: 0)
            )
            .ignoresSafeArea()
        }
    }
}

@available(iOS 15.0, *)
class SwiftUIExampleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let hostingVC = UIHostingController(rootView: BNImagePageSwiftUIExample())
        addChild(hostingVC)
        view.addSubview(hostingVC.view)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingVC.didMove(toParent: self)
    }
}
