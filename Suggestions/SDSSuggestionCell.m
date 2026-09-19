#import "SDSSuggestionCell.h"
#import "../Models/SDSSuggestion.h"

@interface SDSSuggestionCell ()
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UILabel *numberLabel;
@property(nonatomic, strong) UILabel *metaLabel;
@end

@implementation SDSSuggestionCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        _nameLabel = [[UILabel alloc] init];
        _numberLabel = [[UILabel alloc] init];
        _metaLabel = [[UILabel alloc] init];
        for (UILabel *label in @[_nameLabel, _numberLabel, _metaLabel]) {
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.adjustsFontForContentSizeCategory = YES;
            label.numberOfLines = 1;
            [self.contentView addSubview:label];
        }
        _nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _nameLabel.textColor = UIColor.labelColor;
        _numberLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _numberLabel.textColor = UIColor.secondaryLabelColor;
        _metaLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _metaLabel.textColor = UIColor.secondaryLabelColor;
        [_metaLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [NSLayoutConstraint activateConstraints:@[
            [_nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor],
            [_nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
            [_metaLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_nameLabel.trailingAnchor constant:8],
            [_metaLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
            [_metaLabel.firstBaselineAnchor constraintEqualToAnchor:_nameLabel.firstBaselineAnchor],
            [_numberLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [_numberLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
            [_numberLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:2],
            [_numberLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6]
        ]];
    }
    return self;
}
- (void)configureWithSuggestion:(SDSSuggestion *)s {
    self.nameLabel.text = s.displayName.length ? s.displayName : @"Unknown";
    self.numberLabel.text = s.displayNumber;
    NSMutableArray *meta = [NSMutableArray array];
    if (s.phoneLabel.length) [meta addObject:s.phoneLabel];
    if (s.inCallHistory && s.callKind.length) [meta addObject:s.callKind];
    self.metaLabel.text = [meta componentsJoinedByString:@" • "];
    self.accessibilityLabel = [@[self.nameLabel.text ?: @"", s.phoneLabel ?: @"", s.displayNumber ?: @""] componentsJoinedByString:@", "];
}
@end
