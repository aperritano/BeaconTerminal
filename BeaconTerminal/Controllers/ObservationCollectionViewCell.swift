//
//  ObservationCollectionViewCell.swift
//  BeaconTerminal
//
//  Created by Anthony Perritano on 6/7/16.
//  Copyright © 2016 aperritano@gmail.com. All rights reserved.
//

import Foundation
import UIKit
import Material

class ObservationCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var featuredImageView: UIImageView!
    @IBOutlet weak var observationTitleLabel : UILabel!
    @IBOutlet weak var testLabel : UILabel!
    
    
    
    @IBOutlet var observationViewsCollection: [ObservationView]!
   // @IBOutlet weak var profileImageView: SpringImageView!
    @IBOutlet var testTextView: UITextView!
    
    var species: Species! {
        didSet {
            updateUI()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func updateUI() {
        
        backgroundColor = UIColor.blueColor()

        let speciesImage = RealmDataController.generateImageForSpecies(species.index)

//        profileImageView.image = speciesImage
//        profileImageView.contentMode = .ScaleAspectFit

        for obView in observationViewsCollection {
            obView.mainSpiecesImage.image = speciesImage
        }

        
    }

    override func layoutSubviews() {


        //self.addSubview(testView)
        super.layoutSubviews()
        self.layer.cornerRadius = 10.0
        self.clipsToBounds = true
        
        //self.backgroundColor = UIColor.blueColor()
        
//        let header = UIView(frame: CGRectMake(0, 0, self.bounds.width, 48))
//        header.backgroundColor = MaterialColor.white
        
        //self.addSubview(header)
        //self.layout.centerHorizontally(header)
    }
}