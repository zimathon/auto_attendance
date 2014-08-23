//
//  ViewController.m
//  ibeacon
//
//  Created by 笹島 祐介 on 2014/08/16.
//  Copyright (c) 2014年 sasajimay. All rights reserved.
//

#import "ViewController.h"

NSString * const kProximityUUID = @"AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA";

@interface ViewController ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) NSUUID *proximityUUID;

//for disp label
@property (weak, nonatomic) IBOutlet UILabel *statuslabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property(nonatomic)BOOL isInRegion;
@property(nonatomic)BOOL isOutRegion;
@property(nonatomic)BOOL isFirstEnterNear;
@property(nonatomic)BOOL isFirstOutNear;

@property(nonatomic, strong)NSDate* inTime;
@end

@implementation ViewController
@synthesize locationManager;
@synthesize beaconRegion;
@synthesize proximityUUID;

@synthesize isInRegion;
@synthesize isFirstEnterNear;
@synthesize isOutRegion;
@synthesize isFirstOutNear;
@synthesize inTime;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // CLLocationManagerの生成とデリゲート
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        
        self.proximityUUID = [[NSUUID alloc] initWithUUIDString:kProximityUUID];
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID
                                                               identifier:@"com.ikyusasajima.test"];
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
    }
    
    self.isInRegion = false;
    self.isFirstEnterNear = false;
    self.isFirstOutNear = false;
    self.isOutRegion = false;
    
    self.messageLabel.text = @"出社前";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - locationManager delegate
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self.locationManager requestStateForRegion:self.beaconRegion];
}
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside: // リージョン内にいる
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
                isInRegion = true;
            }
            break;
        case CLRegionStateOutside:{
                isInRegion = false;
            }
            break;
        case CLRegionStateUnknown:
        default:
            break;
    }
}
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    isInRegion = true;
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if(isInRegion || [self compareWithInTime]){
        isInRegion = false;
    }
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0) {
        CLBeacon *nearestBeacon = beacons.firstObject;
        
        NSString *rangeMessage;
        rangeMessage = [self proxiMessage:nearestBeacon.proximity];
        
        NSString *message = [NSString stringWithFormat:@"major:%@ \nminor:%@ \naccuracy:%f \nrssi:%d \nstatus:%@ \n",
                             nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy,
                             (int)nearestBeacon.rssi, [self proxiMessage:nearestBeacon.proximity]];
        
        self.statuslabel.text = message;
        
        // 最初にNearになったとき「出社」
        if(((nearestBeacon.proximity == CLProximityNear) ||
           (nearestBeacon.proximity == CLProximityImmediate)) && !isFirstEnterNear){
            self.messageLabel.text = @"出社";
            isFirstEnterNear = true;
            inTime = [NSDate dateWithTimeIntervalSinceNow:0.0f];
        }
        if(isInRegion && [self compareWithInTime] &&
           ((nearestBeacon.proximity == CLProximityUnknown) && !isFirstOutNear)){
            isInRegion = false;
            isFirstOutNear = true;
            self.messageLabel.text = @"退社";
        }
    }
}

#pragma private method
-(NSString*)proxiMessage:(CLProximity)proximatery{

    NSString* rangeMessage ;
    switch (proximatery) {
        case CLProximityImmediate:
            rangeMessage = @"Range Immediate ";
            break;
        case CLProximityNear:
            rangeMessage = @"Range Near ";
            break;
        case CLProximityFar:
            rangeMessage = @"Range Far ";
            break;
        default:
            rangeMessage = @"Range Unknown ";
            break;
    }
    return rangeMessage;
}
- (BOOL)compareWithInTime{
    
    if(!inTime)return false;
    
    NSDate *now = [NSDate date];
    float tmp= [now timeIntervalSinceDate:inTime];
    int hh = (int)(tmp / 3600);
    int mm = (int)((tmp-hh) / 60);
    float ss = tmp -(float)(hh*3600+mm*60);
    if(ss > 3){
        return true;
    }
    else{
        return false;
    }
}

@end
