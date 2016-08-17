/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

struct SimpleHighlightCellUX {
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
    static let BorderWidth: CGFloat = 1
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x353535)
    static let LabelBackgroundColor = UIColor(white: 1.0, alpha: 0.5)
    static let LabelAlignment: NSTextAlignment = .Left
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let PlaceholderImage = UIImage(named: "defaultTopSiteIcon")
    static let CornerRadius: CGFloat = 3
    static let NearestNeighbordScalingThreshold: CGFloat = 24
}

class SimpleHighlightCell: UITableViewCell {
    var siteImage: UIImage? = nil {
        didSet {
            if let image = siteImage {
                siteImageView.image = image
                siteImageView.contentMode = UIViewContentMode.ScaleAspectFit

                // Force nearest neighbor scaling for small favicons
                if image.size.width < SimpleHighlightCellUX.NearestNeighbordScalingThreshold {
                    siteImageView.layer.shouldRasterize = true
                    siteImageView.layer.rasterizationScale = 2
                    siteImageView.layer.minificationFilter = kCAFilterNearest
                    siteImageView.layer.magnificationFilter = kCAFilterNearest
                }

            } else {
                siteImageView.image = SimpleHighlightCellUX.PlaceholderImage
                siteImageView.contentMode = UIViewContentMode.Center
            }
        }
    }

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        titleLabel.font = DynamicFontHelper.defaultHelper.DefaultMediumBoldFont
        titleLabel.textColor = SimpleHighlightCellUX.LabelColor
        titleLabel.textAlignment = SimpleHighlightCellUX.LabelAlignment
        titleLabel.numberOfLines = 2
        return titleLabel
    }()

    lazy var descriptionLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        titleLabel.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
        titleLabel.textColor = SimpleHighlightCellUX.LabelColor
        titleLabel.textAlignment = SimpleHighlightCellUX.LabelAlignment
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    lazy var timeStamp: UILabel = {
        let titleLabel = UILabel()
        titleLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        titleLabel.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
        titleLabel.textColor = SimpleHighlightCellUX.LabelColor
        titleLabel.textAlignment = .Right
        return titleLabel
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.ScaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = SimpleHighlightCellUX.CornerRadius
        return siteImageView
    }()

    lazy var statusIcon: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.ScaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = SimpleHighlightCellUX.CornerRadius
        return siteImageView
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = SimpleHighlightCellUX.SelectedOverlayColor
        selectedOverlay.hidden = true
        return selectedOverlay
    }()

    override var selected: Bool {
        didSet {
            self.selectedOverlay.hidden = !selected
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.mainScreen().scale

        isAccessibilityElement = true

        contentView.addSubview(siteImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeStamp)
        contentView.addSubview(statusIcon)

        siteImageView.snp_makeConstraints { make in
            make.top.equalTo(contentView).offset(10)
            make.leading.equalTo(contentView).offset(15)
            make.size.equalTo(40)
        }

        selectedOverlay.snp_makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        titleLabel.snp_remakeConstraints { make in
            make.leading.equalTo(siteImageView.snp_trailing).offset(10)
            make.trailing.equalTo(timeStamp.snp_leading).offset(-5)
            make.top.equalTo(siteImageView)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.leading.equalTo(statusIcon.snp_trailing).offset(10)
            make.bottom.equalTo(statusIcon)
        }

        timeStamp.snp_makeConstraints { make in
            make.trailing.equalTo(contentView).inset(15)
            make.bottom.equalTo(descriptionLabel)
        }

        statusIcon.snp_makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp_bottom).offset(8)
            make.bottom.equalTo(contentView).offset(-10)
            make.size.equalTo(15)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
    }

    func setImageWithURL(url: NSURL) {
        siteImageView.sd_setImageWithURL(url) { (img, err, type, url) -> Void in
            guard let img = img else {
                return
            }
            self.siteImage = img
        }
        siteImageView.layer.masksToBounds = true
    }

    func configureSimpleHighlightCell(site: Site) {
        if let icon = site.icon {
            let url = icon.url
            self.setImageWithURL(NSURL(string: url)!)
        } else {
            self.siteImage = FaviconFetcher.getDefaultFavicon(NSURL(string: site.url)!)
            self.siteImageView.layer.borderWidth = 0.5
        }
        self.titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title
        self.titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        self.descriptionLabel.text = "Bookmarked"
        self.descriptionLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallHistoryPanel
        self.titleLabel.textColor = UIColor.blackColor()
        self.statusIcon.image = UIImage(named: "bookmarked_passive")
        self.timeStamp.text = "5 hrs"
    }
}