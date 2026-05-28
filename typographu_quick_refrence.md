# Mega Transportation - Typography Quick Reference Guide

## 📋 Quick Access

This guide provides a quick reference for all typography used in Mega Transportation. For detailed information, refer to:
- **TEXT_STYLES.md** - Complete documentation with usage examples
- **text_styles.json** - Structured data for programmatic access
- **FLUTTER_TEXT_STYLES.dart** - Ready-to-use Flutter implementation

---

## 🎯 Text Styles At a Glance

### Hierarchy Summary

```
Display
├─ H1 (24px, 700) ........... Page Titles
├─ H2 (20px, 600) ........... Section Headers
└─ H3 (18px, 600) ........... Card Titles

Body
├─ Body Large (16px, 400) ... Main Content
├─ Body Medium (14px, 500) .. Important Text
└─ Body Small (14px, 400) ... Secondary Text

Labels & Captions
├─ Label Large (12px, 500) .. Form Labels
├─ Label Small (12px, 400) .. Small Labels
└─ Caption (12px, 400) ...... Muted Text

Interactive
├─ Button (14px, 500) ....... Button Labels
└─ Button Large (16px, 600) . Prominent Buttons

Special
├─ Badge (11px, 500) ........ Status Badges
├─ Price (18px, 700) ........ Amounts (Mono)
└─ Numeric (14px, 600) ..... Small Amounts (Mono)
```

---

## 📐 Complete Specifications

| Style | Size | Weight | Line Height | Letter Spacing | Font Family | Usage |
|-------|------|--------|-------------|----------------|-------------|-------|
| **H1** | 24px | 700 | 1.3 | -0.25px | Geist | Page titles, user greetings |
| **H2** | 20px | 600 | 1.4 | 0px | Geist | Section headers |
| **H3** | 18px | 600 | 1.4 | 0px | Geist | Card titles |
| **Body Large** | 16px | 400 | 1.5 | 0px | Geist | Main content |
| **Body Medium** | 14px | 500 | 1.5 | 0.25px | Geist | Important text |
| **Body Small** | 14px | 400 | 1.5 | 0.25px | Geist | Secondary text |
| **Label Large** | 12px | 500 | 1.6 | 0.5px | Geist | Form labels |
| **Label Small** | 12px | 400 | 1.6 | 0.5px | Geist | Small labels |
| **Caption** | 12px | 400 | 1.5 | 0px | Geist | Muted text |
| **Button** | 14px | 500 | 1.4 | 0.25px | Geist | Button labels |
| **Button Large** | 16px | 600 | 1.4 | 0px | Geist | Primary CTAs |
| **Badge** | 11px | 500 | 1.4 | 0.4px | Geist | Status badges |
| **Price** | 18px | 700 | 1.2 | 0px | Geist Mono | Prices, metrics |
| **Numeric** | 14px | 600 | 1.4 | 0px | Geist Mono | Seat numbers, IDs |

---

## 🎨 Screen-by-Screen Typography Map

### Home Screen
```
Good Morning                    → Label Small
Ahmed Hassan                    → H1
├─ Today's Booking             → H3
├─ Pickup: Banha Center        → Body Medium
├─ Destination: Smart Village  → Body Medium
├─ ETA: 8:45 AM                → Body Medium
├─ 3 min away                  → Caption
├─ Active                       → Badge
├─ Ahmed Mohamed               → Body Medium
├─ Vehicle #MT-2847            → Caption
├─ Quick Actions               → H2
└─ [Daily Booking, Monthly...] → Label Large
```

### Daily Booking Flow
```
Daily Booking                   → H1
Select your route             → Body Small
├─ Step 1: Pickup Point        → H2
├─ Select Pickup Point        → Label Large
├─ Banha Center               → Body Medium
├─ Banha Station              → Body Medium
├─ [Continue Button]          → Button Large
└─ ...
```

### Subscription Screen
```
Monthly Subscription           → H1
Setup your permanent route     → Body Small
├─ Pickup Point               → Label Large
├─ Destination                → Label Large
├─ Preferred Arrival Time     → Label Large
├─ Select Plan                → H2
├─ Monthly                    → Body Medium
├─ EGP 1,200                  → Price
├─ per month                  → Caption
├─ Save 15%                   → Badge
├─ What's Included            → H2
├─ Unlimited daily rides...   → Body Large
└─ [Subscribe Now Button]     → Button Large
```

### Seat Selection
```
Seat Selection                 → H1
Choose your seat              → Body Small
├─ A1                         → Numeric
├─ B2                         → Numeric
├─ C1                         → Numeric
├─ Reserved                   → Label Large
├─ Booking Summary            → H3
└─ [Confirm Button]           → Button Large
```

### Tracking Screen
```
Live Tracking                  → H1
Route in Progress             → Body Small
├─ ETA: 8:45 AM               → Price (large)
├─ 3 mins away                → Body Medium
├─ Ahmed Mohamed              → Body Large
├─ Vehicle MT-2847            → Numeric
├─ Banha Center → Smart Vill. → Caption
└─ [Share Location Button]    → Button
```

### Driver Dashboard
```
Driver Dashboard              → H1
├─ Total Passengers          → Label Large
├─ 24                        → Price
├─ Active Trips              → Label Large
├─ 3                         → Price
├─ Vehicle Status            → H2
├─ MT-2847                   → Numeric
├─ Status: Active            → Body Medium
└─ Next Trip: Smart Village  → Caption
```

### Admin Dashboard
```
Admin Dashboard               → H1
├─ Active Trips              → Label Large
├─ 12                        → Price
├─ Total Revenue             → Label Large
├─ EGP 45,000                → Price
├─ Fleet Status              → H2
├─ 8 vehicles active         → Body Small
└─ Route 5: Banha → Smart V. → Body Medium
```

---

## 🔤 Font Families

### Primary Font: Geist
- **Use for**: Headings, body text, buttons, labels
- **Download**: Google Fonts (https://fonts.google.com/specimen/Geist)
- **Weights Available**: 400, 500, 600, 700
- **Optimized for**: Screen display with excellent hinting

### Monospace Font: Geist Mono
- **Use for**: Prices, numeric data, seat numbers, IDs
- **Download**: Google Fonts (https://fonts.google.com/specimen/Geist+Mono)
- **Weights Available**: 400, 600, 700
- **Optimized for**: Technical text and numeric alignment

---

## 🎯 When to Use Each Style

### Choose H1 When:
- ✓ It's the main heading of a page
- ✓ It's a major title (e.g., user name greeting)
- ✓ It needs maximum visual hierarchy

### Choose H2 When:
- ✓ It's a section header within a page
- ✓ It groups related content
- ✓ It's a major subsection

### Choose H3 When:
- ✓ It's a card or component header
- ✓ It's a subsection within H2
- ✓ It needs less emphasis than H2

### Choose Body Large When:
- ✓ It's main paragraph content
- ✓ It's important information
- ✓ It's a description or explanation

### Choose Body Medium When:
- ✓ It's important text that needs distinction
- ✓ It's a label or identifier (name, location)
- ✓ It's emphasized content

### Choose Body Small When:
- ✓ It's secondary description
- ✓ It's a subtitle or helper text
- ✓ It needs less emphasis than body large

### Choose Label Large When:
- ✓ It's a form input label
- ✓ It's a status badge text
- ✓ It needs clear distinction

### Choose Caption When:
- ✓ It's supplementary information
- ✓ It should be visually de-emphasized
- ✓ It's secondary metadata (timestamps, IDs)

### Choose Button When:
- ✓ It's a standard button label
- ✓ Button is medium-sized or smaller

### Choose Button Large When:
- ✓ It's the primary call-to-action
- ✓ Button is large/prominent

### Choose Badge When:
- ✓ It's a status indicator
- ✓ It's a tag or small label
- ✓ It needs high visual distinction

### Choose Price When:
- ✓ It's a money amount (EGP 1,200)
- ✓ It's a large metric or number
- ✓ It needs numeric precision (use Geist Mono)

### Choose Numeric When:
- ✓ It's a seat number (A1, B2)
- ✓ It's a vehicle ID (MT-2847)
- ✓ It's small numeric data

---

## 🌈 Text Color Combinations

### Light Theme
| Style | Color | Contrast |
|-------|-------|----------|
| Primary Text | --foreground (Dark) | ✓ WCAG AA |
| Secondary Text | --muted-foreground (Gray) | ✓ WCAG A |
| Brand Text | --primary (Blue) | ✓ WCAG AA |
| Accent Text | --accent (Orange) | ✓ WCAG AA |
| Error Text | --destructive (Red) | ✓ WCAG AA |

### Dark Theme
| Style | Color | Contrast |
|-------|-------|----------|
| Primary Text | --foreground (Light) | ✓ WCAG AA |
| Secondary Text | --muted-foreground (Gray) | ✓ WCAG A |
| Brand Text | --primary (Cyan) | ✓ WCAG AA |
| Accent Text | --accent (Orange) | ✓ WCAG AA |
| Error Text | --destructive (Red) | ✓ WCAG AA |

---

## 📱 Responsive Behavior

**Mega Transportation** uses mobile-first design:
- **Target Width**: 360px - 390px (typical smartphones)
- **Max Width**: 500px (contained mobile experience)
- **Text Scaling**: Absolute pixels (no responsive scaling)
- **Approach**: All text sizes remain constant across devices

---

## ✨ Best Practices

### DO ✓
- Use semantic text styles consistently
- Maintain visual hierarchy with text weights
- Keep line height between 1.4-1.6 for readability
- Use Geist Mono for numeric/technical content
- Follow WCAG AA contrast requirements
- Test text legibility on 6-inch screens

### DON'T ✗
- Mix multiple font families in one section
- Use text smaller than 11px
- Ignore line height for readability
- Use decorative fonts for body text
- Break the text hierarchy
- Override established text styles arbitrarily

---

## 🔧 Implementation Examples

### React/Next.js
```jsx
<h1 className="text-2xl font-bold text-foreground">Ahmed Hassan</h1>
<p className="text-sm text-muted-foreground">Good Morning</p>
<button className="text-sm font-medium">Subscribe Now</button>
```

### Flutter
```dart
Text(
  'Ahmed Hassan',
  style: AppTextThemes.headingH1.copyWith(
    color: AppColors.darkForeground,
  ),
)
```

### HTML/CSS
```html
<h1 style="font-size: 24px; font-weight: 700; line-height: 1.3; letter-spacing: -0.25px; font-family: Geist;">
  Ahmed Hassan
</h1>
```

### Android (XML)
```xml
<style name="TextStyleH1">
  <item name="android:textSize">24sp</item>
  <item name="android:textStyle">bold</item>
  <item name="android:lineSpacingMultiplier">1.3</item>
</style>
```

---

## 📊 Font Weight Reference

| Weight | Value | Usage |
|--------|-------|-------|
| Regular | 400 | Body text, secondary content |
| Medium | 500 | Emphasized text, labels, badges |
| SemiBold | 600 | Section headers, card titles |
| Bold | 700 | Page titles, large prices, emphasis |

---

## 🎨 Typography in Context

### Example: A Booking Card

```
┌─────────────────────────────────┐
│ Today's Booking            [H3] │  ← 18px, 600
├─────────────────────────────────┤
│ Pickup: Banha Center   [H3/Med] │  ← 14px, 500
│ To: Smart Village      [H3/Med] │  ← 14px, 500
│                                 │
│ ETA: 8:45 AM          [Body L]  │  ← 16px, 400
│ 3 min away             [Caption] │  ← 12px, 400 (muted)
│                                 │
│ [Subscribe] [Cancel]  [Button]  │  ← 14px, 500
└─────────────────────────────────┘
```

---

## 🚀 Getting Started

### For Web/React Developers
1. Reference **TEXT_STYLES.md** for detailed specifications
2. Use Tailwind classes (text-2xl, text-sm, font-bold, etc.)
3. Map Tailwind classes to text style constants
4. Test on mobile viewport (390px)

### For Mobile/Flutter Developers
1. Use **FLUTTER_TEXT_STYLES.dart** file directly
2. Copy `AppTextThemes` class into your project
3. Use predefined text styles with `.copyWith(color: ...)`
4. Import color constants from your color implementation

### For Designers
1. Review **TEXT_STYLES.md** for design specifications
2. Use Geist and Geist Mono fonts in design tools
3. Apply exact font sizes, weights, and line heights
4. Test layouts at 360px mobile width

---

## 📞 Support & Troubleshooting

**Q: Font not displaying correctly?**
A: Ensure Geist fonts are properly installed/imported. Download from Google Fonts.

**Q: Text looks blurry?**
A: Check line height is set to 1.4+ minimum. Verify anti-aliasing is enabled.

**Q: Can't achieve exact spacing?**
A: Use letter-spacing property for fine-tuning. Line height affects vertical spacing.

**Q: Need a different size?**
A: Create a new style using the naming convention. Don't arbitrarily modify sizes.

---

## 📄 Related Documentation

- **COLOR_PALETTE.md** - All color tokens and their usage
- **colors.json** - Color data in JSON format
- **FLUTTER_TEXT_STYLES.dart** - Production-ready Flutter code
- **TEXT_STYLES.md** - Complete detailed documentation

---

**Version**: 1.0
**Last Updated**: May 28, 2026
**Font License**: Open Source (Google Fonts)
**Design System**: Material 3
