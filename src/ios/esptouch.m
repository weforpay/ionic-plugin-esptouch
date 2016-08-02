/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#include <sys/types.h>

#import <Cordova/CDV.h>
#import "esptouch.h"
#import "ESPTouchResult.h"
#import "ESPTouchTask.h"
#import "ESPTouchDelegate.h"

@interface EspTouchDelegateImpl : NSObject<ESPTouchDelegate>

@end

@implementation EspTouchDelegateImpl

-(void) dismissAlert:(UIAlertView *)alertView
{
    [alertView dismissWithClickedButtonIndex:[alertView cancelButtonIndex] animated:YES];
}

-(void) showAlertWithResult: (ESPTouchResult *) result
{
    NSString *title = nil;
    NSString *message = [NSString stringWithFormat:@"%@ is connected to the wifi" , result.bssid];
    NSTimeInterval dismissSeconds = 3.5;
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alertView show];
    [self performSelector:@selector(dismissAlert:) withObject:alertView afterDelay:dismissSeconds];
}

-(void) onEsptouchResultAddedWithResult: (ESPTouchResult *) result
{
    NSLog(@"EspTouchDelegateImpl onEsptouchResultAddedWithResult bssid: %@", result.bssid);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithResult:result];
    });
}

@end

@interface esptouch () {
}
@property (atomic, strong) ESPTouchTask *_esptouchTask;
@property (nonatomic, strong) NSCondition *_condition;
@property (nonatomic, strong) EspTouchDelegateImpl *_esptouchDelegate;

@property (strong, nonatomic) NSString* ssid;
@property (strong, nonatomic) NSString* bssid;
@property (strong, nonatomic) NSString* pwd;
@property (nonatomic, nonatomic) Boolean hiden;
@property (strong, nonatomic) NSString* scanCallbackId;
@end



@implementation esptouch


- (void)scan:(CDVInvokedUrlCommand*)command
{
    NSLog(@"see");
    
    NSString* ssid = [command.arguments objectAtIndex:0];
    NSString* bssid = [command.arguments objectAtIndex:1];
    NSString* pwd = [command.arguments objectAtIndex:2];
    BOOL hiden = [command.arguments objectAtIndex:3];
    
    self.ssid = [[NSString alloc]initWithString:ssid];
    self.bssid = [[NSString alloc]initWithString:bssid];
    self.pwd = [[NSString alloc]initWithString:pwd];
    self.hiden = hiden;
    self.scanCallbackId = [[NSString alloc]initWithString:[command callbackId]];
    
    dispatch_queue_t  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSLog(@"ESPViewController do the execute work...");
        // execute the task
        NSArray *esptouchResultArray = [self executeForResults];
        // show the result to the user in UI Main Thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            ESPTouchResult *firstResult = [esptouchResultArray objectAtIndex:0];
            // check whether the task is cancelled and no results received
            if (!firstResult.isCancelled)
            {
                Byte* ipbytes = [firstResult.ipAddrData bytes];
                NSString* ip = [[ NSString alloc] initWithData:firstResult.ipAddrData encoding:NSUTF8StringEncoding];
                NSLog(@"scaned ip:%s",ip);
                NSDictionary* dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"address" ,ip, nil];
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:(CDVCommandStatus_OK) messageAsDictionary:dict];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
            
        });
    });
}

- (ESPTouchResult *) executeForResults
{
    [self._condition lock];
    NSString *apSsid = self.ssid;
    NSString *apPwd = self.pwd;
    NSString *apBssid = self.bssid;
    BOOL isSsidHidden = self.hiden;
    self._esptouchTask =
    [[ESPTouchTask alloc]initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd andIsSsidHiden:isSsidHidden];
    // set delegate
    [self._esptouchTask setEsptouchDelegate:self._esptouchDelegate];
    [self._condition unlock];
    ESPTouchResult * esptouchResult = [self._esptouchTask executeForResult];
    NSLog(@"ESPViewController executeForResult() result is: %@",esptouchResult);
    return esptouchResult;
}


@end
