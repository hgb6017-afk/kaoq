#import "SDSSuggestionView.h"
#import "SDSSuggestionCell.h"
#import "../Models/SDSSuggestion.h"

@interface SDSSuggestionView () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, copy) NSArray<SDSSuggestion *> *suggestions;
@end

@implementation SDSSuggestionView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = UIColor.clearColor;
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 52;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:SDSSuggestionCell.class forCellReuseIdentifier:@"Suggestion"];
        [self addSubview:_tableView];
        [NSLayoutConstraint activateConstraints:@[
            [_tableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_tableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_tableView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_tableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        self.hidden = YES;
    }
    return self;
}
- (void)showSuggestions:(NSArray<SDSSuggestion *> *)suggestions {
    self.suggestions = suggestions ?: @[];
    self.hidden = self.suggestions.count == 0;
    [self.tableView reloadData];
}
- (void)hideSuggestions { self.suggestions = @[]; self.hidden = YES; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.suggestions.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SDSSuggestionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Suggestion" forIndexPath:indexPath];
    [cell configureWithSuggestion:self.suggestions[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.selectionHandler) self.selectionHandler(self.suggestions[indexPath.row]);
}
@end
