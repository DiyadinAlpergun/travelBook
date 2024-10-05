//
//  ViewController.swift
//  TravelBook
//
//  Created by neodiyadin on 17.08.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenlongtude = Double()
    
    
    var selectedTitle = ""
    var selectedTitleId : UUID?
    
    var annotationtitle = ""
    var annotationsubtitle = ""
    var annotationlatitude = Double()
    var annotationlongtude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if selectedTitle != "" {
            //CoreData
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let context = appDelegate?.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context!.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String{
                            annotationtitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationsubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationlatitude = latitude
                                    
                                    if let longtude = result.value(forKey: "longtude") as? Double{
                                        annotationlongtude = longtude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationtitle
                                        annotation.subtitle = annotationsubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationlatitude, longitude: annotationlongtude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationtitle
                                        commentText.text = annotationsubtitle
                                        
                                        locationManager.startUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                    
            } catch {
                print("error")
            }
            
            
        } else {
            
        }
        
        
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            let touchpoint = gestureRecognizer.location(in: self.mapView)
            let touchcoordinates = self.mapView.convert(touchpoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchcoordinates.latitude
            chosenlongtude = touchcoordinates.longitude
            
            let annatation = MKPointAnnotation()
            annatation.coordinate = touchcoordinates
            annatation.title = nameText.text
            annatation.subtitle = commentText.text
            self.mapView.addAnnotation(annatation)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle != ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        } else{
            //
        }
            
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        
        
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            var requestlocation = CLLocation(latitude: annotationlatitude, longitude: annotationlongtude)
            
            CLGeocoder().reverseGeocodeLocation(requestlocation) { (placemarks, error) in
                //closure
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationtitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
                
            }
        }
    }
    
    
    
    
    
    
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let context = appDelegate?.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context!)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenlongtude, forKey: "longtude")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        
        do {
            try context?.save()
            print("success")
        } catch {
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    

}

