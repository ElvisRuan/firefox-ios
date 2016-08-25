import Foundation
import Shared
import WebImage


struct TopSiteItem {
    let urlTitle: String
    let faviconURL: NSURL?
    let siteURL: NSURL
}

struct TopSiteCellUX {
    static let TitleInsetPercent: CGFloat = 0.66
    static let TitleBackgroundColor = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.7)
    static let TitleTextColor = UIColor.blackColor()
    static let TitleFont = DynamicFontHelper.defaultHelper.DefaultSmallFont
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)

    static let CellCornerRadius: CGFloat = 4
}

/*
 *  The TopSite cell that appears in the ASHorizontalScrollView.
*/
class TopSiteCell: UICollectionViewCell {

    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.layer.masksToBounds = true
        titleLabel.textAlignment = .Center
        titleLabel.font = TopSiteCellUX.TitleFont
        titleLabel.textColor = TopSiteCellUX.TitleTextColor
        titleLabel.backgroundColor = TopSiteCellUX.TitleBackgroundColor
        return titleLabel
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = TopSiteCellUX.SelectedOverlayColor
        selectedOverlay.hidden = true
        return selectedOverlay
    }()

    override var selected: Bool {
        didSet {
            self.selectedOverlay.hidden = !selected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = TopSiteCellUX.CellCornerRadius
        contentView.layer.masksToBounds = true

        contentView.addSubview(titleLabel)
        contentView.addSubview(imageView)

        let heightInset = frame.height * TopSiteCellUX.TitleInsetPercent
        titleLabel.snp_makeConstraints { make in
            make.edges.equalTo(self).inset(UIEdgeInsetsMake(heightInset, 0, 0, 0))
        }

        imageView.snp_makeConstraints { make in
            make.size.equalTo(CGSize(width: self.frame.width/2, height: self.frame.height/2))

            // Add an offset to the image to make it appear centered with the titleLabel
            let offset = self.frame.height - CGFloat(heightInset)
            make.center.equalTo(self.snp_center).offset(UIEdgeInsets(top: -offset/2, left: 0, bottom: 0, right: 0))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        contentView.backgroundColor = UIColor.lightGrayColor()
        imageView.image = nil
        titleLabel.text = ""
    }

    private func setImageWithURL(url: NSURL) {
        imageView.sd_setImageWithURL(url) { [unowned self] (img, err, type, url) -> Void in
            guard let img = img else {
                self.imageView.image = FaviconFetcher.getDefaultFavicon(url)
                self.contentView.backgroundColor = UIColor.lightGrayColor()
                return
            }

            // Get dominant colors using a scaled 25/25 image.
            img.getColors(CGSize(width: 25, height: 25)) { colors in
                //In cases where the background is white. Force the background color to a different color
                var bgColor: UIColor
                if colors.backgroundColor.isWhite {
                    let colorArr = [colors.detailColor, colors.primaryColor].filter { !$0.isWhite }
                    if colorArr.isEmpty {
                        bgColor = UIColor.lightGrayColor()
                    } else {
                        bgColor = colorArr.first!
                    }
                } else {
                    bgColor = colors.backgroundColor
                }
                self.contentView.backgroundColor = bgColor
            }
        }
    }

    func configureWithTopSiteItem(site: TopSiteItem) {
        titleLabel.text = site.urlTitle
        if let favURL = site.faviconURL {
            setImageWithURL(favURL)
        } else {
            imageView.image = FaviconFetcher.getDefaultFavicon(site.siteURL)
        }
    }

}

struct ASHorizontalScrollCellUX {
    static let TopSiteCellIdentifier = "TopSiteCell"
    static let TopSiteItemSize = CGSize(width: 100, height: 100)
    static let BackgroundColor = UIColor.whiteColor()
    static let PageControlRadius: CGFloat = 3
    static let PageControlSize = CGSize(width: 30, height: 15)
    static let PageControlOffset = -5
}

/*
 The View that describes the topSite cell that appears in the tableView.
 */
class ASHorizontalScrollCell: UITableViewCell {

    lazy private var collectionView: UICollectionView = {
        let layout  = HorizontalFlowLayout()
        layout.itemSize = ASHorizontalScrollCellUX.TopSiteItemSize
        layout.heightShouldChange = { [weak self] num in
            self?.heightChanged(num)
        }
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        collectionView.registerClass(TopSiteCell.self, forCellWithReuseIdentifier: ASHorizontalScrollCellUX.TopSiteCellIdentifier)
        collectionView.backgroundColor = ASHorizontalScrollCellUX.BackgroundColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.pagingEnabled = true
        return collectionView
    }()

    lazy private var pageControl: FilledPageControl = {
        let pageControl = FilledPageControl()
        pageControl.tintColor = UIColor.grayColor()
        pageControl.indicatorRadius = ASHorizontalScrollCellUX.PageControlRadius
        pageControl.userInteractionEnabled = false
        return pageControl
    }()

    weak var parentTableView: UITableView?
//    weak var delegate: ASHorizontalScrollSource? {
//        didSet {
//            collectionView.delegate = delegate
//            collectionView.dataSource = delegate
//            delegate!.pageChangedHandler = { [weak self] progress in
//                self?.currentPageChanged(progress)
//            }
//            dispatch_async(dispatch_get_main_queue()) {
//                            self.collectionView.reloadData()
//                        }
//
//        }
//    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = ASHorizontalScrollCellUX.BackgroundColor
        contentView.addSubview(collectionView)
        contentView.addSubview(pageControl)

        collectionView.snp_makeConstraints { make in
            make.edges.equalTo(contentView).priorityLow()
        }

        pageControl.snp_makeConstraints { make in
            make.size.equalTo(ASHorizontalScrollCellUX.PageControlSize)
            make.top.equalTo(collectionView.snp_bottom).offset(ASHorizontalScrollCellUX.PageControlOffset)
            make.centerX.equalTo(self.snp_centerX)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = collectionView.collectionViewLayout as! HorizontalFlowLayout
        pageControl.pageCount = layout.numberOfPages
        pageControl.hidden = pageControl.pageCount <= 1
    }

   func setDelegate(delegate: ASHorizontalScrollSource) {
           collectionView.delegate = delegate
               collectionView.dataSource = delegate
               delegate.pageChangedHandler = { [weak self] progress in
                   self?.currentPageChanged(progress)
               }
               dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.reloadData()
               }
}


    func heightChanged(newHeight: Int) {
        collectionView.snp_updateConstraints { make in
            make.edges.equalTo(contentView).priorityLow()
            make.height.equalTo(newHeight).priorityMedium()
        }
        self.layoutSubviews()
        parentTableView?.reloadData()
    }

    func currentPageChanged(currentPage: CGFloat) {
        pageControl.progress = currentPage
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/*
    A custom layout used to show a horizontal scrolling list with paging. Similar to iOS springboard.
    A modified version of http://stackoverflow.com/a/34167915
 */

class HorizontalFlowLayout: UICollectionViewLayout {
    var itemSize = CGSize.zero
    private var cellCount = 0
    private var boundsSize = CGSize.zero
    private var insets = UIEdgeInsetsZero
    private let minimumInsets: CGFloat = 20
    var numberOfPages = 0
    var heightShouldChange: ((Int) -> ())?

    override func prepareLayout() {
        cellCount = self.collectionView!.numberOfItemsInSection(0)
        boundsSize = self.collectionView!.bounds.size
    }

    override func collectionViewContentSize() -> CGSize {
        return collectionViewSizeForRect(boundsSize)
    }

    func maxVerticalItemsCount() -> Int {
        let verticalItemsCount =  Int(floor(boundsSize.height / (itemSize.height + insets.top)))
        let delegate = self.collectionView?.delegate as! ASHorizontalScrollDelegate
        return delegate.numberOfVerticalItems(verticalItemsCount)
    }

    func maxHorizontalItemsCount() -> Int {
        let horizontalItemsCount =  Int(floor(boundsSize.width / (itemSize.width + insets.left)))
        let delegate = self.collectionView?.delegate as! ASHorizontalScrollDelegate
        return delegate.numberOfHorizontalItems(horizontalItemsCount)
    }
    func collectionViewSizeForRect(contentSize: CGSize) -> CGSize {
        let horizontalItemsCount = maxHorizontalItemsCount()
        let verticalItemsCount = maxVerticalItemsCount()


        // Take the number of cells and subtract its space in the view from the height. The left over space is the white space.
        // The left over space is then devided evenly into (n + 1) parts to figure out how much space should be inbetween a cell
        var verticalInsets = (contentSize.height - (CGFloat(verticalItemsCount) * itemSize.height)) / CGFloat(verticalItemsCount + 1)
        var horizontalInsets = (contentSize.width - (CGFloat(horizontalItemsCount) * itemSize.width)) / CGFloat(horizontalItemsCount + 1)

        // We want a minimum inset to make things not look crowded. We also don't want uneven spacing.
        // If we dont have this. Set a minimum inset and recalculate the size of a cell
        if horizontalInsets < minimumInsets || horizontalInsets != verticalInsets {
            verticalInsets = minimumInsets
            horizontalInsets = minimumInsets
            itemSize.width = (contentSize.width - (CGFloat(horizontalItemsCount + 1) * horizontalInsets)) / CGFloat(horizontalItemsCount)
            itemSize.height = itemSize.width
        }

        let itemsPerPage = verticalItemsCount * horizontalItemsCount

        let delegate = self.collectionView?.delegate as! ASHorizontalScrollDelegate
        let numberOfItems = delegate.collectionView(self.collectionView!, numberOfItemsInSection: 0)
        numberOfPages = Int(ceil(Double(numberOfItems) / Double(itemsPerPage)))


        insets = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)

        var size = contentSize
        size.width = CGFloat(numberOfPages) * contentSize.width

        // When Cells are resized the amount of vertical space they need might change. Recalculate the height and layout the view again.
        let newHeight = Int(verticalInsets) * (verticalItemsCount + 1) + Int(itemSize.height) * verticalItemsCount
        if Int(size.height) != newHeight {
            heightShouldChange?(newHeight)
        }
        
        return size
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var allAttributes = [UICollectionViewLayoutAttributes]()
        for i in 0 ..< cellCount {
            let indexPath = NSIndexPath(forRow: i, inSection: 0)
            let attr = self.computeLayoutAttributesForCellAtIndexPath(indexPath)
            allAttributes.append(attr)
        }
        return allAttributes
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return self.computeLayoutAttributesForCellAtIndexPath(indexPath)
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }

    func computeLayoutAttributesForCellAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let row = indexPath.row
        let bounds = self.collectionView!.bounds

        let verticalItemsCount = maxVerticalItemsCount()
        let horizontalItemsCount = maxHorizontalItemsCount()


        let itemsPerPage = verticalItemsCount * horizontalItemsCount

        let columnPosition = row % horizontalItemsCount
        let rowPosition = (row/horizontalItemsCount)%verticalItemsCount
        let itemPage = Int(floor(Double(row)/Double(itemsPerPage)))

        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)

        var frame = CGRectZero
        frame.origin.x = CGFloat(itemPage) * bounds.size.width + CGFloat(columnPosition) * (itemSize.width + insets.left) + insets.left
        frame.origin.y = CGFloat(rowPosition) * (itemSize.height + insets.top) + insets.top
        frame.size = itemSize
        attr.frame = frame
        
        return attr
    }
}

/*
    Defines the number of items to show in topsites for different size classes.
*/
struct ASTopSiteSourceUX {
    static let verticalItemsForTraitSizes = [UIUserInterfaceSizeClass.Compact : 1, UIUserInterfaceSizeClass.Regular : 2]
    static let horizontalItemsForTraitSizes = [UIUserInterfaceSizeClass.Compact : 3, UIUserInterfaceSizeClass.Regular : 5]
    static let maxNumberOfPages = 2
    static let CellIdentifier = "TopSiteCell"
}

protocol ASHorizontalScrollDelegate {
    func numberOfVerticalItems(estimatedItems: Int) -> Int
    func numberOfHorizontalItems(estimatedItems: Int) -> Int
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
}

/*
 This Delegate/DataSource is used to manage the ASHorizontalScrollCell's UICollectionView. 
 This is left generic enough for it to be re used for other parts of Activity Stream.
 */

class ASHorizontalScrollSource: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, ASHorizontalScrollDelegate {

    var content: [TopSiteItem] = []
    var urlPressedHandler: ((NSURL) -> Void)?
    var pageChangedHandler: ((CGFloat) -> Void)?

    // The current traits that define the parent ViewController. Used to determine how many rows/columns should be created.
    var currentTraits: UITraitCollection?

    /*
        Size classes define how many items to show per row/column.
    */
    func numberOfVerticalItems(estimatedItems: Int) -> Int {
        if let traits = currentTraits {
            return ASTopSiteSourceUX.verticalItemsForTraitSizes[traits.verticalSizeClass]!
        } else {
            return estimatedItems
        }
    }

    func numberOfHorizontalItems(estimatedItems: Int) -> Int {
        if let traits = currentTraits {
            // An iPhone 5 in both landscape/portrait is considered compactWidth which means we need to let the layout determine how many items to show based on actual width.
            return max(ASTopSiteSourceUX.horizontalItemsForTraitSizes[traits.horizontalSizeClass]!, estimatedItems)
        } else {
            return estimatedItems
        }
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let layout = collectionView.collectionViewLayout as! HorizontalFlowLayout
        let maxItems = layout.maxVerticalItemsCount() * layout.maxHorizontalItemsCount() * ASTopSiteSourceUX.maxNumberOfPages
        return min(maxItems, self.content.count)
    }


    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ASTopSiteSourceUX.CellIdentifier, forIndexPath: indexPath) as! TopSiteCell

        let contentItem = content[indexPath.row]
        cell.configureWithTopSiteItem(contentItem)
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let contentItem = content[indexPath.row]
        urlPressedHandler?(contentItem.siteURL)
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let pageWidth = CGRectGetWidth(scrollView.frame)
        pageChangedHandler?(scrollView.contentOffset.x / pageWidth)
    }
}

