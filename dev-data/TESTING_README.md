# Testing Setup - Quick Access Sign-in

## 🚀 Quick Start

The app now includes **Quick Access buttons** for instant testing without creating accounts manually!

### Available Test Accounts

| Role | Email | Password | Description |
|------|-------|----------|-------------|
| Athletic Director | `ad.test@efficials.com` | `test123456` | Manage games & schedules |
| Coach | `coach.test@efficials.com` | `test123456` | Request officials for games |
| Assigner | `assigner.test@efficials.com` | `test123456` | Assign officials to games |
| Official | `official.test@efficials.com` | `test123456` | View assigned games |

### How to Use

1. **Start the app** - Launch the Efficials v2.0 app
2. **Look for the Quick Access section** - It's prominently displayed on the home screen
3. **Click any button** - You'll be automatically signed in and taken to the appropriate home screen
4. **Test the features** - Each account has the appropriate permissions and data

## 📋 Setting Up Test Accounts

### Option 1: Manual Setup (Recommended)

1. Go through the normal registration flow for each account type
2. Use the email/password combinations above
3. Fill in the required profile information

### Option 2: Firebase Console

1. Open Firebase Console
2. Go to Authentication > Users
3. Add users with the emails and passwords above
4. Manually create corresponding Firestore documents in the `users` collection

## 🎯 What You Can Test

### Athletic Director Account
- ✅ Game creation flow (Use Template / Start from Scratch)
- ✅ Games list with pull-to-refresh
- ✅ FAB expand/collapse animation
- ✅ Navigation drawer
- ✅ Template management

### Coach Account
- ✅ Quick game requests
- ✅ Team-specific scheduling

### Assigner Account
- ✅ Official assignment workflow
- ✅ Game management

### Official Account
- ✅ View assigned games
- ✅ Availability management

## 🔧 Development Features

- **Instant Sign-in**: No more manual authentication
- **Role-specific Testing**: Test different user experiences
- **Consistent Data**: Each account has appropriate mock data
- **Error Handling**: Proper error messages for failed sign-ins
- **Loading States**: Visual feedback during sign-in

## 📱 Screenshots

The Quick Access section appears on the main home screen with:
- Clean, organized button layout
- Role-specific descriptions
- Color-coded indicators
- One-click sign-in functionality

## 🐛 Troubleshooting

### Sign-in Fails
- Make sure you've created the test accounts first
- Check Firebase Authentication console
- Verify email/password combinations match exactly

### Wrong Home Screen
- Each account type routes to its specific home screen
- Check the route configuration in `main.dart`

### Missing Features
- Some screens may show "Coming Soon" placeholders
- This is normal during development

## 🎨 Design Compliance

All Quick Access components follow the v2.0 design system:
- ✅ Theme-aware colors and styling
- ✅ Proper contrast ratios
- ✅ Responsive layout
- ✅ Consistent with app branding

---

**Happy Testing!** 🎉

The Quick Access system makes development and testing much faster. You can now focus on building features instead of managing authentication during development.
