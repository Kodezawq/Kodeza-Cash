#import "LoanZen_NetworkPermissionMonitor.h"
#include <Network/network.h>

@implementation LoanZen_NetworkPermissionMonitor

+ (void)LZ_whenNetworkAvailable:(void (^)(void))handler {
    if (!handler) return;

    nw_path_monitor_t monitor = nw_path_monitor_create();
    dispatch_queue_t queue = dispatch_queue_create("com.loanzen.network.monitor", DISPATCH_QUEUE_SERIAL);
    nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
        if (nw_path_get_status(path) != nw_path_status_satisfied) return;
        nw_path_monitor_cancel(monitor);
        dispatch_async(dispatch_get_main_queue(), handler);
    });
    nw_path_monitor_set_queue(monitor, queue);
    nw_path_monitor_start(monitor);
}

@end
