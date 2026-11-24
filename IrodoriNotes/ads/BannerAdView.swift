import GoogleMobileAds
import SwiftUI
import UIKit

/// 画面の幅に合わせたバナー広告（アダプティブバナー。Android 版の BannerAd にあたる）。
/// 読み込めたときだけ上に区切り線を付けて出し、読み込めないとき・`isHidden` のときは高さ 0 にする。
/// 隠しても作り直さない（広告を読み込み直さないように）。
struct BannerAdSlot: View {
    let adUnitID: String
    let ads: AdsManager
    var isHidden = false
    @State private var isLoaded = false

    var body: some View {
        if ads.canShowBanners {
            let visible = isLoaded && !isHidden
            VStack(spacing: 0) {
                if visible { Divider() }
                BannerAdRepresentable(adUnitID: adUnitID, isVisible: visible) { isLoaded = $0 }
                    .padding(.vertical, visible ? 4 : 0)
            }
            .background(Color(.systemBackground))
            .accessibilityHidden(!visible)
        }
    }
}

private struct BannerAdRepresentable: UIViewRepresentable {
    let adUnitID: String
    let isVisible: Bool
    let onLoadedChanged: (Bool) -> Void

    func makeUIView(context: Context) -> BannerContainerView {
        BannerContainerView(adUnitID: adUnitID, onLoadedChanged: onLoadedChanged)
    }

    func updateUIView(_ view: BannerContainerView, context: Context) {
        view.isHidden = !isVisible
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BannerContainerView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        guard isVisible, width > 0 else { return CGSize(width: width, height: 0) }
        return CGSize(width: width, height: cgSize(for: largeAnchoredAdaptiveBanner(width: width)).height)
    }
}

/// バナーを入れる箱。幅が決まったら、その幅の広告を1回だけ読み込む（その後は SDK が自動で入れ替える）。
final class BannerContainerView: UIView, BannerViewDelegate {
    private let bannerView = BannerView()
    private let adUnitID: String
    private let onLoadedChanged: (Bool) -> Void
    private var loadedWidth: CGFloat = 0

    init(adUnitID: String, onLoadedChanged: @escaping (Bool) -> Void) {
        self.adUnitID = adUnitID
        self.onLoadedChanged = onLoadedChanged
        super.init(frame: .zero)
        clipsToBounds = true
        bannerView.adUnitID = adUnitID
        bannerView.delegate = self
        addSubview(bannerView)
    }

    required init?(coder: NSCoder) { fatalError("コードからだけ作る") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        guard width > 0, window != nil else { return }
        let size = largeAnchoredAdaptiveBanner(width: width)
        bannerView.frame = CGRect(origin: CGPoint(x: (width - cgSize(for: size).width) / 2, y: 0), size: cgSize(for: size))
        // 幅が変わったとき（初めて・画面の回転）だけ読み込む
        if abs(width - loadedWidth) > 1 {
            loadedWidth = width
            bannerView.adSize = size
            bannerView.rootViewController = window?.rootViewController
            bannerView.load(Request())
        }
    }

    // MARK: BannerViewDelegate

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        onLoadedChanged(true)
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
        AppLog.error("バナー広告を読み込めなかった: \(error)")
        onLoadedChanged(false)
    }
}
