//
//  DataAgreementPageViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 15/09/22.
//

import UIKit

final class DataAgreementPageViewController: UIViewController {
    
    let pageController: AppPageViewController
    var pageViews: [UIViewController] = []
    
    var dataAgreementContext: [DataAgreementContext?] = []
    var connectionRecordId: String? = nil
    var mode: DataAgreementMode? = nil
    
    private var currentIndex: Int = 0
    var navHandler: NavigationHandler!
    
    init(agreement: [DataAgreementContext?] = [],
         connectionRecordId: String? = nil,
         mode: DataAgreementMode? = nil) {
        
        self.dataAgreementContext = agreement
        self.connectionRecordId = connectionRecordId
        self.mode = mode

        pageController = AppPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view.addSubview(self.pageController.view)
        self.pageController.view.addAnchor(top: view.safeAreaLayoutGuide.topAnchor,
                                           bottom: view.bottomAnchor,
                                           left: view.leftAnchor,
                                           right: view.rightAnchor)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .appColor(.walletBg)
        self.title = "Data Agreement Policy".localize
        self.createPages()
        self.pageControlAppearence()
    }
    
    private func createPages() {
        for i in 0...0 {
            let vm = DataAgreementViewModel(dataAgreement: dataAgreementContext[safe: i] ?? nil,
                                            connectionRecordId: self.connectionRecordId,
                                            mode: self.mode
            )
            let vc = DataAgreementViewController(vm: vm)
            vc.pageIndex = i
            vc.delegate = self
            self.pageViews.append(vc)
        }
        
        if let initial = self.pageViews[safe: self.currentIndex] {
            self.pageController.delegate = self
            self.pageController.dataSource = self
            self.pageController.setViewControllers([initial], direction: .forward, animated: true, completion: nil)
            self.pageController.didMove(toParent: self)
        }
    }
    
    private func pageControlAppearence() {
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = .white
        pageControl.currentPageIndicatorTintColor = .black
    }
}
