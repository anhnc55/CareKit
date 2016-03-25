/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "OCKConnectDetailViewController.h"
#import "OCKConnectTableViewHeader.h"
#import "OCKDefines_Private.h"


static const CGFloat HeaderViewHeight = 225.0;

typedef NS_ENUM(NSInteger, OCKConnectDetailSection) {
    OCKConnectDetailSectionContactInfo = 0,
    OCKConnectDetailSectionSharing
};

@implementation OCKConnectDetailViewController {
    OCKConnectTableViewHeader *_headerView;
    NSArray<NSArray *> *_tableViewData;
}

- (instancetype)initWithContact:(OCKContact *)contact {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _contact = contact;
        [self createTableViewDataArray];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self prepareView];
}

- (void)setContact:(OCKContact *)contact {
    _contact = contact;
    [self createTableViewDataArray];
    [self prepareView];
    [self.tableView reloadData];
}

- (void)setDelegate:(id<OCKConnectViewControllerDelegate>)delegate {
    _delegate = delegate;
    [self prepareView];
    [self.tableView reloadData];
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKConnectTableViewHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
    }
    _headerView.contact = _contact;
    
    self.tableView.tableHeaderView = _headerView;
}


#pragma mark - Helpers

- (void)createTableViewDataArray {
    NSMutableArray *contactInfoSection = [NSMutableArray new];
    if (_contact.phoneNumber) {
        [contactInfoSection addObject:@(OCKConnectTypePhone)];
    }
    if (_contact.messageNumber) {
        [contactInfoSection addObject:@(OCKConnectTypeMessage)];
    }
    if (_contact.emailAddress) {
        [contactInfoSection addObject:@(OCKConnectTypeEmail)];
    }
    
    NSMutableArray *sharingSection = [NSMutableArray new];
    if (_delegate) {
        [sharingSection addObject:[_delegate connectViewController:_masterViewController titleForSharingCellForContact:_contact]];
    } else {
        [sharingSection addObject:OCKLocalizedString(@"SHARING_CELL_TITLE", nil)];
    }
    
    _tableViewData = @[[contactInfoSection copy], [sharingSection copy]];
}

- (void)makeCallToNumber:(NSString *)number {
    NSString *stringURL = [NSString stringWithFormat:@"tel:%@", number];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringURL]];
}

- (void)sendMessageToNumber:(NSString *)number {
    MFMessageComposeViewController *messageViewController = [MFMessageComposeViewController new];
    if ([MFMessageComposeViewController canSendText]) {
        messageViewController.messageComposeDelegate = self;
        messageViewController.recipients = @[number];
        [self presentViewController:messageViewController animated:YES completion:nil];
    }
}

- (void)sendEmailToAddress:(NSString *)address {
    MFMailComposeViewController *emailViewController = [MFMailComposeViewController new];
    if ([MFMailComposeViewController canSendMail]) {
        emailViewController.mailComposeDelegate = self;
        [emailViewController setToRecipients:@[address]];
        [self presentViewController:emailViewController animated:YES completion:nil];
    }
}


#pragma mark - OCKContactInfoTableViewCellDelegate

- (void)contactInfoTableViewCellDidSelectConnection:(OCKContactInfoTableViewCell *)cell {
    switch (cell.connectType) {
        case OCKConnectTypePhone:
            [self makeCallToNumber:cell.contact.phoneNumber.stringValue];
            break;
        
        case OCKConnectTypeMessage:
            [self sendMessageToNumber:cell.contact.messageNumber.stringValue];
            break;
            
        case OCKConnectTypeEmail:
            [self sendEmailToAddress:cell.contact.emailAddress];
            break;
    }
}


#pragma mark - OCKContactSharingTableViewCellDelegate

- (void)sharingTableViewCellDidSelectShareButton:(OCKContactSharingTableViewCell *)cell {
    if (_delegate &&
        [_delegate respondsToSelector:@selector(connectViewController:didSelectShareButtonForContact:)]) {
        [_delegate connectViewController:_masterViewController didSelectShareButtonForContact:cell.contact];
    }
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
        case OCKConnectDetailSectionContactInfo:
            sectionTitle = OCKLocalizedString(@"CONTACT_INFO_SECTION_TITLE", nil);
            break;
            
        case OCKConnectDetailSectionSharing:
            sectionTitle = OCKLocalizedString(@"CONTACT_SHARING_SECTION_TITLE", nil);
            break;
    }
    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tableViewData[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == OCKConnectDetailSectionContactInfo) {
        static NSString *ContactCellIdentifier = @"ContactInfoCell";
        OCKContactInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactCellIdentifier];
        if (!cell) {
            cell = [[OCKContactInfoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                      reuseIdentifier:ContactCellIdentifier];
        }
        cell.contact = _contact;
        cell.delegate = self;
        cell.connectType = [_tableViewData[indexPath.section][indexPath.row] intValue];
        return cell;
    
    } else if (indexPath.section == OCKConnectDetailSectionSharing && _delegate) {
        static NSString *SharingCellIdentifier = @"SharingCell";
        OCKContactSharingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SharingCellIdentifier];
        if (!cell) {
            cell = [[OCKContactSharingTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                         reuseIdentifier:SharingCellIdentifier];
        }
        cell.title = _tableViewData[indexPath.section][indexPath.row];
        cell.contact = _contact;
        cell.delegate = self;
        return cell;
    }
    return nil;
}


#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MessageComposeResultFailed) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:OCKLocalizedString(@"ERROR_TITLE", nil)
                                                                                 message:OCKLocalizedString(@"MESSAGE_SEND_ERROR", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MFMailComposeResultFailed) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:OCKLocalizedString(@"ERROR_TITLE", nil)
                                                                                 message:OCKLocalizedString(@"EMAIL_SEND_ERROR", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

@end