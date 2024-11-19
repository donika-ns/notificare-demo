//
//  ViewController.swift
//  NotificareDemo
//
//  Created by Donka Nesheva on 19.11.24.
//

import UIKit
import CoreLocation
import NotificareKit
import NotificareGeoKit
import OneSignal

class ViewController: UIViewController {
    
    private var locationManager: CLLocationManager!

    @IBOutlet weak var notificareSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        OneSignal.promptForPushNotifications(userResponse: { _ in
        })
        
    }

    @IBAction func notificareSwitchValueChanged(_ sender: Any) {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        
        if let notifSwitch = sender as? UISwitch {
            if notifSwitch.isOn {
                delegate?.enableTalkOnTheRoad()
            } else {
                delegate?.disableTalkOnTheRoad()
            }
        }
    }
    
    private func enableNotificare() {
        
    }
}

extension ViewController: CLLocationManagerDelegate {

    // /////////////////////////////////////////////////////////////////////////
    // MARK: - CLLocationManager
    // /////////////////////////////////////////////////////////////////////////
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleLocationAuthorizationChanges()
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleLocationAuthorizationChanges()
    }
    
    private func handleLocationAuthorizationChanges() {
        Task {
            let status = CLLocationManager.authorizationStatus()
            
            if status == .denied || status == .restricted {
                if let delegate = UIApplication.shared.delegate as? AppDelegate {
                    delegate.disableTalkOnTheRoad()
                }
            }
            
            if status == .authorizedWhenInUse {
                locationManager.requestAlwaysAuthorization()
            }
            
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                if notificareSwitch.isOn {
                    Notificare.shared.geo().enableLocationUpdates()
                }
            }
        }
    }
}


