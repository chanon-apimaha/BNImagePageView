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

    private let imageURL = "https://picsum.photos/id/237/400/300.jpg"
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
                    ImgaePageData(atIndex: IndexPath(row: 0, section: 0), sImageUrl: "https://picsum.photos/id/237/400/300.jpg", fWidth: 400, fHeight: 300),
                    ImgaePageData(atIndex: IndexPath(row: 1, section: 0), sImageUrl: "https://picsum.photos/id/10/400/300.jpg", fWidth: 400, fHeight: 300)
                ],
                atIndexPath: IndexPath(row: 0, section: 0)
            )
            .ignoresSafeArea()
        }
    }
}

@available(iOS 15.0, *)
class SwiftUIExampleViewController: UIHostingController<BNImagePageSwiftUIExample> {
    init() {
        super.init(rootView: BNImagePageSwiftUIExample())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: BNImagePageSwiftUIExample())
    }
}
