# Mega Transportation - Typography & Text Styles Guide

## Overview
This document defines all text styles used throughout the Mega Transportation mobile app. All styles are designed for the Material 3 design system with dark mode optimization.

**Font Family**: Geist (Primary), Geist Mono (Code)

---

## Core Typography System

### Font Specifications

| Property | Value | Notes |
|----------|-------|-------|
| **Font Family - Primary** | Geist | Used for all body text, buttons, labels |
| **Font Family - Mono** | Geist Mono | Used for technical data, pricing, IDs |
| **Default Font Weight** | 400 (Regular) | Standard text weight |
| **Default Line Height** | 1.5 (24px @ 16px) | For better readability |
| **Letter Spacing** | 0px (normal) | Standard throughout |

---

## Text Styles Hierarchy

### 1. Display/Hero Styles

#### Display Large (H0)
- **Size**: 32px
- **Weight**: 700 (Bold)
- **Line Height**: 1.2 (38px)
- **Letter Spacing**: -0.5px
- **Usage**: Not used in this project (reserved for future hero sections)
- **Flutter**: 
```dart
TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  height: 1.2,
  letterSpacing: -0.5,
  fontFamily: 'Geist',
)
```

---

### 2. Heading Styles

#### Heading 1 (H1) - Page Titles
- **Size**: 24px
- **Weight**: 700 (Bold)
- **Line Height**: 1.3 (32px)
- **Letter Spacing**: -0.25px
- **Usage**: Main page headers (e.g., "Ahmed Hassan" greeting in home screen)
- **Tailwind Class**: `text-2xl font-bold`
- **Example**: User name greeting on home screen
- **Flutter**:
```dart
TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w700,
  height: 1.3,
  letterSpacing: -0.25,
  fontFamily: 'Geist',
)
```

#### Heading 2 (H2) - Section Headers
- **Size**: 20px
- **Weight**: 600 (SemiBold)
- **Line Height**: 1.4 (28px)
- **Letter Spacing**: 0px
- **Usage**: Major section titles like "Quick Actions", "Select Plan", "Route Summary"
- **Tailwind Class**: `text-xl font-semibold`
- **Flutter**:
```dart
TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  height: 1.4,
  letterSpacing: 0,
  fontFamily: 'Geist',
)
```

#### Heading 3 (H3) - Card Titles
- **Size**: 18px
- **Weight**: 600 (SemiBold)
- **Line Height**: 1.4 (25px)
- **Letter Spacing**: 0px
- **Usage**: Card headers, section subtitles like "Today's Booking", "Driver Info"
- **Tailwind Class**: `text-lg font-semibold`
- **Flutter**:
```dart
TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.4,
  letterSpacing: 0,
  fontFamily: 'Geist',
)
```

---

### 3. Body Text Styles

#### Body Large (Regular)
- **Size**: 16px
- **Weight**: 400 (Regular)
- **Line Height**: 1.5 (24px)
- **Letter Spacing**: 0px
- **Usage**: Main body text, primary content, form inputs, button labels
- **Tailwind Class**: `text-base` (default body)
- **Example**: Regular text in cards, paragraph content
- **Flutter**:
```dart
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.5,
  letterSpacing: 0,
  fontFamily: 'Geist',
)
```

#### Body Medium
- **Size**: 14px
- **Weight**: 500 (Medium)
- **Line Height**: 1.5 (21px)
- **Letter Spacing**: 0.25px
- **Usage**: Important body text, section labels, vehicle seat info
- **Tailwind Class**: `text-sm font-medium`
- **Example**: "Ahmed Mohamed" driver name, seat numbers
- **Flutter**:
```dart
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: 1.5,
  letterSpacing: 0.25,
  fontFamily: 'Geist',
)
```

#### Body Small
- **Size**: 14px
- **Weight**: 400 (Regular)
- **Line Height**: 1.5 (21px)
- **Letter Spacing**: 0.25px
- **Usage**: Secondary body text, descriptions, hints
- **Tailwind Class**: `text-sm`
- **Example**: "Monthly plan details", helper text
- **Flutter**:
```dart
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.5,
  letterSpacing: 0.25,
  fontFamily: 'Geist',
)
```

---

### 4. Label & Caption Styles

#### Label Large
- **Size**: 12px
- **Weight**: 500 (Medium)
- **Line Height**: 1.6 (19px)
- **Letter Spacing**: 0.5px
- **Usage**: Form labels, input labels, status badges
- **Tailwind Class**: `text-xs font-medium`
- **Example**: "Pickup", "Destination", "Preferred Arrival Time" form labels
- **Flutter**:
```dart
TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.6,
  letterSpacing: 0.5,
  fontFamily: 'Geist',
)
```

#### Label Medium
- **Size**: 12px
- **Weight**: 400 (Regular)
- **Line Height**: 1.6 (19px)
- **Letter Spacing**: 0.5px
- **Usage**: Small labels, subtext, helper text
- **Tailwind Class**: `text-xs`
- **Example**: "Good Morning" greeting, helper hints
- **Flutter**:
```dart
TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  height: 1.6,
  letterSpacing: 0.5,
  fontFamily: 'Geist',
)
```

#### Caption / Muted Text
- **Size**: 12px
- **Weight**: 400 (Regular)
- **Line Height**: 1.5 (18px)
- **Letter Spacing**: 0px
- **Usage**: Muted foreground text, timestamps, secondary info
- **Tailwind Class**: `text-xs text-muted-foreground`
- **Color**: `--muted-foreground` token
- **Example**: "Vehicle #MT-2847", "3 min away", "per month"
- **Flutter**:
```dart
TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  height: 1.5,
  letterSpacing: 0,
  fontFamily: 'Geist',
  color: AppColors.mutedForeground,
)
```

---

### 5. Button & Interactive Styles

#### Button Text - Default
- **Size**: 14px
- **Weight**: 500 (Medium)
- **Line Height**: 1.4 (20px)
- **Letter Spacing**: 0.25px
- **Usage**: All primary and secondary buttons
- **Tailwind Class**: `text-sm font-medium`
- **Example**: "Subscribe Now", "Review Plans", "Driver Dashboard"
- **Flutter**:
```dart
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: 1.4,
  letterSpacing: 0.25,
  fontFamily: 'Geist',
)
```

#### Button Text - Large
- **Size**: 16px
- **Weight**: 600 (SemiBold)
- **Line Height**: 1.4 (22px)
- **Letter Spacing**: 0px
- **Usage**: Large primary action buttons, prominent CTAs
- **Tailwind Class**: `text-base font-semibold`
- **Example**: "Subscribe Now - EGP 1,200/month"
- **Flutter**:
```dart
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  height: 1.4,
  letterSpacing: 0,
  fontFamily: 'Geist',
)
```

---

### 6. Badge & Status Styles

#### Badge Text
- **Size**: 11px
- **Weight**: 500 (Medium)
- **Line Height**: 1.4 (16px)
- **Letter Spacing**: 0.4px
- **Usage**: Status badges, tags, pills
- **Tailwind Class**: `text-xs font-medium`
- **Example**: "Active" badge on booking card, "Save 15%" on subscription
- **Flutter**:
```dart
TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  height: 1.4,
  letterSpacing: 0.4,
  fontFamily: 'Geist',
)
```

---

### 7. Data & Numeric Styles

#### Price / Numeric Emphasis
- **Size**: 18px
- **Weight**: 700 (Bold)
- **Line Height**: 1.2 (22px)
- **Letter Spacing**: 0px
- **Font Family**: Geist Mono (for prices)
- **Usage**: Prices, amounts, important numbers
- **Tailwind Class**: `text-lg font-bold`
- **Example**: "EGP 1,200", "EGP 3,300"
- **Flutter**:
```dart
TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  height: 1.2,
  letterSpacing: 0,
  fontFamily: 'Geist Mono',
)
```

#### Small Numeric
- **Size**: 14px
- **Weight**: 600 (SemiBold)
- **Line Height**: 1.4 (20px)
- **Letter Spacing**: 0px
- **Font Family**: Geist Mono
- **Usage**: Seat numbers, vehicle IDs, small amounts
- **Tailwind Class**: `text-sm font-semibold`
- **Example**: Seat numbers "A1", "B2", IDs like "MT-2847"
- **Flutter**:
```dart
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  height: 1.4,
  letterSpacing: 0,
  fontFamily: 'Geist Mono',
)
```

---

## Color Combinations

### Light Theme Text Colors

| Style | Text Color | Usage |
|-------|-----------|-------|
| Primary Text | `--foreground` (oklch(0.15 0 0)) | Body text, headings |
| Secondary Text | `--muted-foreground` (oklch(0.55 0 0)) | Subtitles, hints |
| Brand Text | `--primary` (oklch(0.35 0.15 260)) | Primary CTAs, emphasized text |
| Accent Text | `--accent` (oklch(0.65 0.22 30)) | Important highlights, warnings |
| Error Text | `--destructive` (oklch(0.62 0.22 29)) | Error messages, deletions |

### Dark Theme Text Colors

| Style | Text Color | Usage |
|-------|-----------|-------|
| Primary Text | `--foreground` (oklch(0.95 0.01 0)) | Body text, headings |
| Secondary Text | `--muted-foreground` (oklch(0.65 0.05 0)) | Subtitles, hints |
| Brand Text | `--primary` (oklch(0.68 0.20 200)) | Primary CTAs, emphasized text |
| Accent Text | `--accent` (oklch(0.65 0.22 30)) | Important highlights |
| Error Text | `--destructive` (oklch(0.62 0.22 29)) | Error messages |

---

## Text Style Components by Screen

### Home Screen
- **User Greeting**: H1 (24px, 700) - "Ahmed Hassan"
- **Greeting Prefix**: Label (12px, 400) - "Good Morning"
- **Card Heading**: H3 (18px, 600) - "Today's Booking"
- **Card Body**: Body (16px, 400) - Route info
- **Badge**: Badge (11px, 500) - "Active"
- **Driver Name**: Body Medium (14px, 500) - "Ahmed Mohamed"
- **Vehicle ID**: Caption (12px, 400, muted) - "Vehicle #MT-2847"
- **Section Header**: H2 (20px, 600) - "Quick Actions"
- **Button Text**: Button Default (14px, 500)

### Daily Booking Flow
- **Page Title**: H1 (24px, 700) - "Daily Booking"
- **Step Header**: H2 (20px, 600) - Step titles
- **Subtitle**: Body Small (14px, 400) - "Select your route"
- **Form Label**: Label Large (12px, 500) - "Pickup Point"
- **Selection Button Text**: Body Medium (14px, 500)
- **Time Display**: Body Large (16px, 400)

### Subscription Screen
- **Page Title**: H1 (24px, 700) - "Monthly Subscription"
- **Subtitle**: Body Small (14px, 400) - "Setup your permanent route"
- **Plan Name**: Body Medium (14px, 500) - "Monthly", "Quarterly"
- **Plan Price**: Price Emphasis (18px, 700) - "EGP 1,200"
- **Savings Badge**: Badge (11px, 500) - "Save 15%"
- **Plan Period**: Caption (12px, 400, muted) - "per month"
- **Benefits Title**: H2 (20px, 600) - "What's Included"
- **Benefit Text**: Body (16px, 400)

### Seat Selection Screen
- **Vehicle Info**: Body Medium (14px, 500)
- **Seat Number**: Small Numeric (14px, 600, mono) - "A1", "B2"
- **Seat Status**: Label (12px, 500) - "Reserved", "Available"
- **Summary Header**: H3 (18px, 600)
- **Summary Detail**: Body (16px, 400)

### Tracking Screen
- **ETA Timer**: Price Emphasis (18px, 700) - Large prominent time
- **Status Text**: Body Medium (14px, 500)
- **Driver Name**: Body (16px, 400)
- **Route Info**: Caption (12px, 400, muted)

### Driver Dashboard
- **Stats Title**: Label Large (12px, 500)
- **Stats Value**: Price Emphasis (18px, 700)
- **Trip Title**: Body Medium (14px, 500)
- **Trip Detail**: Caption (12px, 400, muted)
- **Passenger Name**: Body (16px, 400)
- **Status Badge**: Badge (11px, 500)

### Admin Dashboard
- **Metric Label**: Label (12px, 500)
- **Metric Value**: Price Emphasis (18px, 700)
- **Trip Header**: Body Medium (14px, 500)
- **Fleet Status**: Body Small (14px, 400)
- **Chart Label**: Caption (12px, 400, muted)

---

## Flutter Implementation Example

```dart
// Define text themes for the app
class AppTextThemes {
  // Headings
  static const headingH1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.25,
    fontFamily: 'Geist',
  );

  static const headingH2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    fontFamily: 'Geist',
  );

  static const headingH3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    fontFamily: 'Geist',
  );

  // Body Text
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    fontFamily: 'Geist',
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.25,
    fontFamily: 'Geist',
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
    fontFamily: 'Geist',
  );

  // Labels
  static const labelLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.6,
    letterSpacing: 0.5,
    fontFamily: 'Geist',
  );

  static const labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.5,
    fontFamily: 'Geist',
  );

  // Buttons
  static const buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.25,
    fontFamily: 'Geist',
  );

  static const buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    fontFamily: 'Geist',
  );

  // Badges
  static const badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.4,
    fontFamily: 'Geist',
  );

  // Numeric
  static const priceEmphasis = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    fontFamily: 'Geist Mono',
  );

  static const smallNumeric = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    fontFamily: 'Geist Mono',
  );
}

// Usage in widget
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Ahmed Hassan',
      style: AppTextThemes.headingH1.copyWith(
        color: AppColors.foreground,
      ),
    );
  }
}
```

---

## Accessibility Considerations

1. **Minimum Text Size**: No text should be smaller than 11px in production
2. **Line Height**: Minimum 1.4 for body text to ensure readability
3. **Color Contrast**: All text meets WCAG AA standards (4.5:1 for normal text, 3:1 for large text)
4. **Font Rendering**: Geist font is optimized for screen display with excellent hinting

---

## Responsive Adjustments (Mobile Focus)

The project uses a mobile-first approach with these viewport constraints:
- **Target Device Width**: 360px - 390px (typical smartphones)
- **Max App Width**: 500px (contained to mobile-like experience)

Text sizes remain consistent across devices as they're in absolute pixels, optimized for mobile screens.

---

## Summary Table

| Component | Size | Weight | Line Height | Letter Spacing | Example |
|-----------|------|--------|-------------|----------------|---------|
| H1 | 24px | 700 | 1.3 | -0.25 | User name |
| H2 | 20px | 600 | 1.4 | 0 | Section header |
| H3 | 18px | 600 | 1.4 | 0 | Card title |
| Body Large | 16px | 400 | 1.5 | 0 | Main text |
| Body Medium | 14px | 500 | 1.5 | 0.25 | Driver name |
| Body Small | 14px | 400 | 1.5 | 0.25 | Helper text |
| Label Large | 12px | 500 | 1.6 | 0.5 | Form label |
| Label Small | 12px | 400 | 1.6 | 0.5 | Subtext |
| Caption | 12px | 400 | 1.5 | 0 | Muted text |
| Button | 14px | 500 | 1.4 | 0.25 | Button label |
| Badge | 11px | 500 | 1.4 | 0.4 | Status |
| Price | 18px | 700 | 1.2 | 0 | Amounts |

---

## Font Downloads

- **Geist**: Google Fonts (https://fonts.google.com/specimen/Geist)
- **Geist Mono**: Google Fonts (https://fonts.google.com/specimen/Geist+Mono)

Both fonts are free and open-source, perfect for Flutter projects.
