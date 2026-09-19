#import "SDSPRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>

static NSString * const Domain = @"com.smartdialsim.preferences";
static NSString * const Notify = @"com.smartdialsim.preferences.changed";
static NSString * const DiagnosticRequest = @"com.smartdialsim.diagnostic.request";
static NSString * const DiagnosticReportKey = @"diagnosticReport";
static NSString * const DiagnosticArmedKey = @"diagnosticArmed";

@implementation SDSPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    return _specifiers;
}

- (void)resetPreferences {
    NSArray *keys = @[@"enabled", @"smartDialEnabled", @"contactsEnabled", @"callHistoryEnabled", @"t9Enabled", @"maxSuggestions", @"compactSIMEnabled", @"sim1Name", @"sim2Name"];
    for (NSString *key in keys) CFPreferencesSetAppValue((__bridge CFStringRef)key, NULL, (__bridge CFStringRef)Domain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)Domain);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)Notify, NULL, NULL, YES);
    [self reloadSpecifiers];
}

- (void)requestDiagnostics {
    CFPreferencesSetAppValue((__bridge CFStringRef)DiagnosticArmedKey, kCFBooleanTrue, (__bridge CFStringRef)Domain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)Domain);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)DiagnosticRequest,
                                         NULL, NULL, YES);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Đã yêu cầu chẩn đoán"
                                                                   message:@"Mở app Điện thoại → Bàn phím và test Smart Dial/SIM khoảng 6 giây. G6 chỉ ghi snapshot trong lần kiểm tra này; dùng Phone bình thường sẽ không quét diagnostic."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)copyDiagnostics {
    CFPreferencesAppSynchronize((__bridge CFStringRef)Domain);
    NSString *report = (__bridge_transfer NSString *)CFPreferencesCopyAppValue((__bridge CFStringRef)DiagnosticReportKey,
                                                                               (__bridge CFStringRef)Domain);
    if (report.length) {
        UIPasteboard.generalPasteboard.string = report;
    }
    NSString *message = report.length ? [NSString stringWithFormat:@"Đã sao chép %lu ký tự. Dán nguyên báo cáo vào ChatGPT.", (unsigned long)report.length] : @"Chưa có báo cáo. Hãy mở Phone → Keypad trong 12 giây rồi thử lại.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:report.length ? @"Đã sao chép" : @"Chưa có dữ liệu"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearDiagnostics {
    CFPreferencesSetAppValue((__bridge CFStringRef)DiagnosticReportKey, NULL, (__bridge CFStringRef)Domain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)Domain);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Đã xóa"
                                                                   message:@"Báo cáo runtime cũ đã được xóa."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
