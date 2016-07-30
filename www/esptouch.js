
var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec'),
    channel = require('cordova/channel');


//扫描到设备后通过ok得到设备的lan ip
exports.scan = function(ssid,bssid,pwd,hiden,ok,err){
	exec(ok,err, 'esptouch', 'scan', [ssid,bssid,pwd,hiden]);
}
exports.cancel = function(ok,err){
	exec(ok,err, 'esptouch', 'cancel', []);
}


