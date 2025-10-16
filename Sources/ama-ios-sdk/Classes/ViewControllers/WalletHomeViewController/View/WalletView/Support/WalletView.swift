//
//  WalletView.swift
//  dataWallet
//
//  Created by sreelekh N on 07/12/21.
//

import UIKit
import WXNavigationBar
open class WalletView: UIView {
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        prepareWalletView()
        addObservers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareWalletView()
        addObservers()
    }
    
    open func reload(cardViews: [CardView]) {
        insert(cardViews: cardViews)
        calculateLayoutValues()
    }
    
    open func present(cardView: CardView, animated: Bool, completion: LayoutCompletion? = nil) {
        present(cardView: cardView, animated: animated, animationDuration: animated ? WalletView.presentingAnimationSpeed : nil, completion: completion)
    }
    
    open func dismissPresentedCardView(animated: Bool, completion: LayoutCompletion? = nil) {
        dismissPresentedCardView(animated: animated, animationDuration: animated ? WalletView.dismissingAnimationSpeed : nil, completion: completion)
    }
    
    open func insert(cardView: CardView, animated: Bool = false, presented: Bool = false,  completion: InsertionCompletion? = nil) {
        presentedCardView = presented ? cardView : self.presentedCardView
        if animated {
            let y = scrollView.convert(CGPoint(x: 0, y: frame.maxY), from: self).y
            cardView.frame = CGRect(x: 0, y: y, width: frame.width, height: cardViewHeight)
            cardView.layoutIfNeeded()
            scrollView.insertSubview(cardView, at: 0)
            UIView.animateKeyframes(withDuration: WalletView.insertionAnimationSpeed, delay: 0, options: [.beginFromCurrentState, .calculationModeCubic], animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0, animations: {
                    self?.insert(cardViews: [cardView] + (self?.insertedCardViews ?? []))
                    self?.layoutWalletView(placeVisibleCardViews: false)
                })
                
            }, completion: { [weak self] (_) in
                self?.reload(cardViews: self?.insertedCardViews ?? [])
                completion?()
            })
        } else {
            reload(cardViews: [cardView] + insertedCardViews)
            placeVisibleCardViews()
            completion?()
        }
    }
    
    open func remove(cardView: CardView, animated: Bool = false,  completion: RemovalCompletion? = nil) {
        if animated {
            let removalBlock = removalAnimation()
            present(cardView: cardView, animated: true, completion: { [weak self] (_) in
                self?.presentedCardView = nil
                removalBlock(cardView, completion)
            })
        } else {
            remove(cardViews: [cardView])
            completion?()
        }
    }
    
    open func remove(cardViews: [CardView]) {
        let newInsertedCardViews = insertedCardViews.filter { !cardViews.contains($0) }
        if let presentedCardView = presentedCardView, !newInsertedCardViews.contains(presentedCardView) {
            self.presentedCardView = nil
        }
        
        if newInsertedCardViews.count == 1 {
            presentedCardView = newInsertedCardViews.first
        }
        
        reload(cardViews: newInsertedCardViews)
    }
    
    
    public var preferableCardViewHeight: CGFloat = 150 { didSet { calculateLayoutValues() } }
    
    public var maximimNumberOfCollapsedCardViewsToShow: Int = 0 { didSet { calculateLayoutValues() } }
    
    public var minimalDistanceBetweenStackedCardViews: CGFloat = 45 { didSet { calculateLayoutValues() } }
    
    public var useHeaderDistanceForStackedCards: Bool = false { didSet { calculateLayoutValues() } }
    
    public var minimalDistanceBetweenCollapsedCardViews: CGFloat = 40 { didSet { calculateLayoutValues() } }
    
    public var distanceBetweetCollapsedAndPresentedCardViews: CGFloat = 0 { didSet { calculateLayoutValues() } }
    
    public var grabPopupOffset: CGFloat = 20 { didSet { calculateLayoutValues() } }
    
    public static var presentingAnimationSpeed: TimeInterval = 0.35
    
    public static var dismissingAnimationSpeed: TimeInterval = 0.35
    
    public static var insertionAnimationSpeed: TimeInterval = 0.6
    public static var removalAnimationSpeed: TimeInterval = 1.0
    public static var grabbingAnimationSpeed: TimeInterval = 0.2
    public var didPresentCardViewBlock: PresentedCardViewDidUpdateBlock?
    
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    var screenStatusBarHeight: CGFloat {
        return AppData.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }
    
    var topAreaHeight: CGFloat {
        return (AppData.keyWindow?.rootViewController as? UINavigationController)?.navigationBar.frame.height ?? 0.0
    }
    
    @IBOutlet public weak var walletHeader: UIView? {
        willSet {
            if let walletHeader = newValue {
                scrollView.addSubview(walletHeader)
            }
        }
        didSet {
            oldValue?.removeFromSuperview()
            calculateLayoutValues()
        }
    }
    
    public var presentedCardView: CardView? {
        didSet {
            oldValue?.presented = false
            presentedCardView?.presented = true
            didPresentCardViewBlock?(presentedCardView)
        }
    }
    
    public var insertedCardViews = [CardView]()    {
        didSet {
            calculateLayoutValues(shouldLayoutWalletView: false)
        }
    }
    
    public var contentInset: UIEdgeInsets {
        set {
            let padding = (AppData.keyWindow?.safeAreaInsets.bottom ?? 0.0) + 160
            scrollView.contentInset = UIEdgeInsets(top: newValue.top, left: newValue.left, bottom: newValue.bottom + padding, right: newValue.right)
            calculateLayoutValues()
        }
        get {
            return scrollView.contentInset
        }
    }
    
    public typealias PresentedCardViewDidUpdateBlock    = (CardView?) -> ()
    public typealias CardViewShouldAllowBlock           = () -> (Bool)
    public typealias CardViewBeganPanBlock              = () -> ()
    
    public typealias LayoutCompletion                   = (Bool) -> ()
    public typealias InsertionCompletion                = () -> ()
    public typealias RemovalCompletion                  = () -> ()
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &WalletView.observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(UIScrollView.bounds) {
            layoutWalletView()
        } else if keyPath == #keyPath(UIScrollView.frame) {
            calculateLayoutValues()
        }
    }
    
    // MARK: Private methods
    
    private static var observerContext = 0
    
    deinit {
        scrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.frame), context: &WalletView.observerContext)
        scrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.bounds), context: &WalletView.observerContext)
    }
    
    
    func addObservers() {
        
        let options: NSKeyValueObservingOptions = [.new, .old, .initial]
        
        scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.frame), options: options, context: &WalletView.observerContext)
        
        scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.bounds), options: options, context: &WalletView.observerContext)
    }
    
    func prepareScrollView() {
        addSubview(scrollView)
        scrollView.clipsToBounds = false
        scrollView.isExclusiveTouch = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleHeight, .flexibleWidth]
        scrollView.frame = bounds
        let topFull = screenStatusBarHeight + topAreaHeight
        let minus = AriesMobileAgent.shared.getViewMode() == .BottomSheet ? 210 : 210 + topFull
        let height = screenHeight - minus
        maximimNumberOfCollapsedCardViewsToShow = 8
        minimalDistanceBetweenCollapsedCardViews = height/12.5
        
    }
    
    public let scrollView = UIScrollView()
    
    func prepareWalletView() {
        prepareScrollView()
    }
    
    func insert(cardViews: [CardView]) {
        self.insertedCardViews = cardViews
        if insertedCardViews.count == 1 {
            presentedCardView = insertedCardViews.first
        }
    }
    
    func present(cardView: CardView, animated: Bool, animationDuration: TimeInterval?, completion: LayoutCompletion? = nil) {
        
        if cardView == presentedCardView {
            completion?(true)
            return
        } else if presentedCardView != nil {
            dismissPresentedCardView(animated: animated, completion: nil)
            present(cardView: cardView, animated: animated, completion: completion)
        } else {
            presentedCardView = cardView
            layoutWalletView(animationDuration: animated ? animationDuration : nil, placeVisibleCardViews: false, completion: { [weak self] (_) in
                self?.placeVisibleCardViews()
                completion?(true)
            })
        }
    }
    
    func dismissPresentedCardView(animated: Bool, animationDuration: TimeInterval?, completion: LayoutCompletion? = nil) {
        
        if let cardView = presentedCardView,
           cardView.cardViewCanReleaseBlock?() == false {
            layoutWalletView(animationDuration: WalletView.grabbingAnimationSpeed)
            return
        }
        
        if insertedCardViews.count <= 1 || presentedCardView == nil {
            completion?(true)
            return
        }
        
        presentedCardView = nil
        layoutWalletView(animationDuration: animated ? animationDuration : nil, placeVisibleCardViews: true, completion: { [weak self] (_) in
            self?.calculateLayoutValues()
            completion?(true)
        })
    }
    
    typealias RemovalAnimation = (CardView, RemovalCompletion?) -> ()
    func removalAnimation() -> RemovalAnimation {
        
        return { [weak self] (cardView: CardView,  completion: RemovalCompletion?) in
            
            guard let strongSelf = self else {
                return
            }
            
            let removalSuperview = UIView()
            
            removalSuperview.clipsToBounds = true
            
            let overlay = UIView()
            self?.addSubview(removalSuperview)
            removalSuperview.addSubview(overlay)
            removalSuperview.addSubview(cardView)
            
            removalSuperview.frame = strongSelf.scrollView.convert(cardView.frame, to: self)
            cardView.frame = removalSuperview.bounds
            overlay.frame = removalSuperview.bounds
            
            overlay.alpha = 0.0
            
            removalSuperview.layoutIfNeeded()
            removalSuperview.setNeedsDisplay()
            
            UIView.animateKeyframes(withDuration: WalletView.removalAnimationSpeed, delay: 0, options: [.calculationModeCubic], animations: {
                
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.7, animations: {
                    self?.remove(cardViews: [cardView])
                })
                
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.7, animations: {
                    
                    removalSuperview.frame = removalSuperview.frame.insetBy(dx: 0, dy: removalSuperview.frame.height/2)
                    cardView.alpha = 0.0
                    
                    cardView.layoutIfNeeded()
                    cardView.setNeedsDisplay()
                    
                    removalSuperview.layoutIfNeeded()
                    removalSuperview.setNeedsDisplay()
                })
                
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.4, animations: {
                    overlay.alpha = 1.0
                    overlay.setNeedsDisplay()
                })
                
            }, completion: { (_) in
                completion?()
                removalSuperview.removeFromSuperview()
                
            })
            
        }
    }
    
    weak var grabbedCardView: CardView?
    
    var grabbedCardViewOriginalY: CGFloat = 0
    
    func grab(cardView: CardView, popup: Bool) {
        
        if (presentedCardView != nil && presentedCardView != cardView) {
            return
        }
        scrollView.isScrollEnabled = false
        
        grabbedCardView = cardView
        grabbedCardViewOriginalY = cardView.frame.minY - (popup ? grabPopupOffset : 0)
        
        var cardViewFrame = cardView.frame
        cardViewFrame.origin.y = grabbedCardViewOriginalY
        
        UIView.animate(withDuration: WalletView.grabbingAnimationSpeed, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            self?.grabbedCardView?.frame = cardViewFrame
            self?.grabbedCardView?.layoutIfNeeded()
        }, completion: nil)
        
    }
    
    func updateGrabbedCardView(offset: CGFloat) {
        var cardViewFrame = grabbedCardView?.frame ?? CGRect.zero
        cardViewFrame.origin.y = grabbedCardViewOriginalY + offset
        grabbedCardView?.frame = cardViewFrame
    }
    
    func releaseGrabbedCardView() {
        defer {
            grabbedCardView = nil
        }
        
        if let grabbedCardView = grabbedCardView,
           grabbedCardView == presentedCardView && grabbedCardView.presented == true,
           grabbedCardView.frame.origin.y > grabbedCardViewOriginalY + maximumCardViewHeight / 4 {
            
            let presentationCenter = convert(self.presentationCenter, from: scrollView)
            let yPoints = frame.maxY - (presentationCenter.y - maximumCardViewHeight / 2)
            let velocityY = grabbedCardView.panGestureRecognizer.velocity(in: grabbedCardView).y
            let animationDuration = min(WalletView.dismissingAnimationSpeed * 1.5, TimeInterval(yPoints / velocityY))
            if insertedCardViews.count > 1 {
                dismissPresentedCardView(animated: true, animationDuration: animationDuration)
            } else {
                layoutWalletView(animationDuration: WalletView.grabbingAnimationSpeed)
            }
        } else if let grabbedCardView = grabbedCardView,
                  presentedCardView == nil && grabbedCardView.presented == false,
                  grabbedCardView.frame.origin.y < grabbedCardViewOriginalY - maximumCardViewHeight / 4 {
            present(cardView: grabbedCardView, animated: true)
        } else {
            layoutWalletView(animationDuration: WalletView.grabbingAnimationSpeed)
        }
        
    }
    
    
    
    var presentationCenter: CGPoint {
        let centerRect = CGRect(x: 0, y: cardViewTopInset,
                                width: frame.width,
                                height: frame.height - collapsedCardViewStackHeight - cardViewTopInset)
        return scrollView.convert( CGPoint(x: centerRect.midX, y: centerRect.midY), from: self)
    }
    
    var collapsedCardViewStackHeight:   CGFloat = 0
    var walletHeaderHeight:         CGFloat = 0
    var cardViewTopInset:               CGFloat = 0
    var maximumCardViewHeight:          CGFloat = 0
    var cardViewHeight:                 CGFloat = 170
    var distanceBetweenCardViews:       CGFloat = 0
    
    func calculateLayoutValues(shouldLayoutWalletView: Bool = true) {
        
        
        walletHeaderHeight = walletHeader?.frame.height ?? 0
        
        cardViewTopInset = scrollView.contentInset.top + walletHeaderHeight
        
        collapsedCardViewStackHeight = (minimalDistanceBetweenCollapsedCardViews * CGFloat(maximimNumberOfCollapsedCardViewsToShow)) + distanceBetweetCollapsedAndPresentedCardViews
        
        maximumCardViewHeight = frame.height - (cardViewTopInset + collapsedCardViewStackHeight)
        cardViewHeight = min(preferableCardViewHeight, maximumCardViewHeight)
        
        
        let usableCardViewsHeight = walletHeaderHeight + insertedCardViews.map { _ in cardViewHeight }.reduce(0, { $0 + $1 } )
        
        let distance = max(minimalDistanceBetweenStackedCardViews, usableCardViewsHeight/CGFloat(insertedCardViews.count)/CGFloat(insertedCardViews.count))
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            distanceBetweenCardViews = distance
        } else {
            distanceBetweenCardViews = distance
        }
        
        if shouldLayoutWalletView {
            layoutWalletView()
            updateScrolViewContentSize()
        }
        
    }
    
    func layoutWalletHeader() {
        
        if let walletHeader = walletHeader {
            
            var walletHeaderFrame = walletHeader.frame
            walletHeaderFrame.origin = convert(.zero, to: scrollView)
            walletHeaderFrame.origin.y += scrollView.contentInset.top
            walletHeaderFrame.size = CGSize(width: frame.width, height: walletHeader.frame.height)
            walletHeader.frame = walletHeaderFrame
            
        }
        
    }
    
    func layoutWalletView(animationDuration: TimeInterval? = nil,
                          animationOptions: UIView.KeyframeAnimationOptions = [.beginFromCurrentState, .calculationModeCubic],
                          placeVisibleCardViews: Bool = true,
                          completion: LayoutCompletion? = nil) {
        
        let animations = { [weak self] in
            
            self?.layoutWalletHeader()
            
            if let presentedCardView = self?.presentedCardView,
               let insertedCardViews = self?.insertedCardViews {
                self?.makeCollapseLayout(collapsePresentedCardView: !insertedCardViews.contains(presentedCardView))
            } else {
                self?.makeStackLayout()
            }
            
            if placeVisibleCardViews {
                self?.placeVisibleCardViews()
            }
            
            self?.layoutIfNeeded()
            
        }
        
        if let animationDuration = animationDuration, animationDuration > 0 {
            UIView.animateKeyframes(withDuration: animationDuration, delay: 0, options: animationOptions, animations: animations, completion: completion)
        } else {
            animations()
            completion?(true)
        }
    }
    
    func updateScrolViewContentSize() {
        
        var contentSize = CGSize(width: frame.width, height: 0)
        
        let walletHeaderHeight = walletHeader?.frame.height ?? 0
        
        contentSize.height = (insertedCardViews.last?.frame.maxY ?? walletHeaderHeight) - (maximumCardViewHeight/2)
        
        if !contentSize.equalTo(scrollView.contentSize) {
            scrollView.contentSize = contentSize
        }
        
    }
    
    
    func makeStackLayout() {
        
        scrollView.isScrollEnabled = true
        
        let zeroRectConvertedFromWalletView: CGRect = {
            var rect = convert(CGRect.zero, to: scrollView)
            rect.origin.y += scrollView.contentInset.top
            return rect
        }()
        
        let stretchingDistanse: CGFloat? = {
            
            let negativeScrollViewContentInsetTop = -(scrollView.contentInset.top)
            let scrollViewContentOffsetY = scrollView.contentOffset.y
            
            if negativeScrollViewContentInsetTop > scrollViewContentOffsetY {
                return abs(abs(negativeScrollViewContentInsetTop) + scrollViewContentOffsetY)
            }
            
            return nil
        }()
        
        let walletHeaderY = walletHeader?.frame.origin.y ?? zeroRectConvertedFromWalletView.origin.y
        
        var cardViewYPoint = walletHeaderHeight
        
        let cardViewHeight = self.cardViewHeight
        
        let firstCardView = insertedCardViews.first
        
        for cardViewIndex in 0..<insertedCardViews.count {
            
            let cardView = insertedCardViews[cardViewIndex]
            var cardViewFrame = CGRect(x: 0, y: max(cardViewYPoint, walletHeaderY), width: frame.width, height: cardViewHeight)
            
            if cardView == firstCardView {
                
                cardViewFrame.origin.y = min(cardViewFrame.origin.y, walletHeaderY + walletHeaderHeight)
                cardView.frame = cardViewFrame
                
            } else {
                
                if let stretchingDistanse = stretchingDistanse {
                    cardViewFrame.origin.y += stretchingDistanse * CGFloat((cardViewIndex - 1))
                }
                
                cardView.frame = cardViewFrame
            }
            
            if useHeaderDistanceForStackedCards {
                cardViewYPoint += minimalDistanceBetweenStackedCardViews
            } else {
                cardViewYPoint += distanceBetweenCardViews
            }
            
        }
        
    }
    
    func makeCollapseLayout(collapsePresentedCardView: Bool = false) {
        
        scrollView.isScrollEnabled = false
        
        let scrollViewFrameMaxY = scrollView.convert(CGPoint(x: 0, y: scrollView.frame.maxY), from: self).y
        var cardViewYPoint = scrollViewFrameMaxY - collapsedCardViewStackHeight
        
        cardViewYPoint += distanceBetweetCollapsedAndPresentedCardViews
        //cardViewYPoint -= 45
        let cardViewHeight = self.cardViewHeight
        
        let distanceBetweenCardViews = minimalDistanceBetweenCollapsedCardViews
        
        let firstIndexToMoveY: Int = {
            
            guard let presentedCardView = presentedCardView,
                  let presentedCardViewIndex = insertedCardViews.firstIndex(of: presentedCardView) else {
                      return 0
                  }
            
            let halfMaximimNumberOfCollapsedCardViewsToShow = Int(Darwin.round(CGFloat(maximimNumberOfCollapsedCardViewsToShow)/2))
            
            if presentedCardViewIndex >= insertedCardViews.count - 1 {
                return presentedCardViewIndex - (maximimNumberOfCollapsedCardViewsToShow - 1)
            } else {
                return presentedCardViewIndex - halfMaximimNumberOfCollapsedCardViewsToShow
            }
            
        }()
        
        var collapsedCardViewsCount = maximimNumberOfCollapsedCardViewsToShow
        
        for cardViewIndex in 0..<insertedCardViews.count {
            
            let cardView = insertedCardViews[cardViewIndex]
            
            var cardViewFrame = CGRect(x: 0, y: scrollViewFrameMaxY + (collapsedCardViewStackHeight * 2), width: frame.width, height: cardViewHeight)
            
            if cardViewIndex >= firstIndexToMoveY && collapsedCardViewsCount > 0 {
                
                if presentedCardView != cardView || collapsePresentedCardView {
                    
                    //let widthDelta = distanceBetweenCardViews * CGFloat(collapsedCardViewsCount)
                    cardViewFrame.size.width = cardViewFrame.size.width
                    //- widthDelta
                    //cardViewFrame.origin.x += widthDelta/2
                    
                    collapsedCardViewsCount -= 1
                    cardViewFrame.origin.y = cardViewYPoint
                    cardViewYPoint += distanceBetweenCardViews
                }
                
            }
            
            cardView.frame = cardViewFrame
            
            if presentedCardView == cardView && !collapsePresentedCardView {
                cardView.center = presentationCenter
            }
            
        }
        
    }
    
    func placeVisibleCardViews() {
        
        var cardViewIndex = [CGFloat: (index: Int, cardView: CardView)]()
        
        var viewsToRemoveFromScrollView = [CardView]()
        
        let shownScrollViewRect = CGRect(x: scrollView.contentOffset.x,
                                         y: scrollView.contentOffset.y,
                                         width: scrollView.frame.width,
                                         height: scrollView.frame.height)
        
        for index in 0..<insertedCardViews.count {
            
            let cardView = insertedCardViews[index]
            
        
            let intersection = shownScrollViewRect.intersection(cardView.frame)
            
            guard intersection.height > 0 || intersection.width > 0 else {
                viewsToRemoveFromScrollView.append(cardView)
                continue
            }
            
            let cardViewMinY = cardView.frame.minY
            
            if cardView == presentedCardView {
                cardViewIndex[CGFloat.greatestFiniteMagnitude] = (index, cardView)
                continue
            } else if let previousCardView = cardViewIndex[cardViewMinY]?.cardView {
                viewsToRemoveFromScrollView.append(previousCardView)
            }
            
            cardViewIndex[cardViewMinY] = (index, cardView)
        }
        
        for cardView in viewsToRemoveFromScrollView {
            cardView.removeFromSuperview()
        }
        
        let indexCardViewPairs = cardViewIndex.sorted(by: { $0.value.index < $1.value.index }).map { $0.value }
        
        guard let firstCardView = indexCardViewPairs.first?.cardView else { return }
        
        var previousCardView = firstCardView
        for pair in indexCardViewPairs {
            if pair.cardView == firstCardView {
                scrollView.addSubview(pair.cardView)
            } else {
                scrollView.insertSubview(pair.cardView, aboveSubview: previousCardView)
            }
            previousCardView = pair.cardView
        }
    }
}
