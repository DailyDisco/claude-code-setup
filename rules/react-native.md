---
paths: "**/*.{tsx,ts}"
alsoApplyIf: ["expo", "react-native"]
---

# React Native + Expo Rules

## Project Setup

- Use Expo SDK (managed workflow preferred)
- Expo Router for file-based navigation
- TypeScript with strict mode
- EAS Build for production builds

```bash
npx create-expo-app@latest --template tabs
```

---

## Project Structure

```
app/
├── (tabs)/           # Tab navigator group
│   ├── index.tsx     # Home tab
│   ├── profile.tsx   # Profile tab
│   └── _layout.tsx   # Tab layout
├── [id].tsx          # Dynamic routes
├── _layout.tsx       # Root layout
└── +not-found.tsx    # 404 screen
components/
├── ui/               # Reusable UI components
└── features/         # Feature-specific components
hooks/
lib/
constants/
```

---

## Navigation (Expo Router)

```tsx
// app/_layout.tsx
import { Stack } from 'expo-router';

export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen name="modal" options={{ presentation: 'modal' }} />
    </Stack>
  );
}

// Navigation
import { Link, router } from 'expo-router';

<Link href="/profile/123">View Profile</Link>
router.push('/profile/123');
router.replace('/home');
router.back();
```

---

## Component Patterns

```tsx
import { View, Text, Pressable, StyleSheet } from 'react-native';

interface UserCardProps {
  user: User;
  onPress?: () => void;
}

export function UserCard({ user, onPress }: UserCardProps) {
  return (
    <Pressable
      style={({ pressed }) => [styles.card, pressed && styles.pressed]}
      onPress={onPress}
    >
      <Text style={styles.name}>{user.name}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    padding: 16,
    backgroundColor: '#fff',
    borderRadius: 8,
  },
  pressed: {
    opacity: 0.7,
  },
  name: {
    fontSize: 16,
    fontWeight: '600',
  },
});
```

---

## Styling

| Approach | When to Use |
|----------|-------------|
| StyleSheet.create | Default - optimized and type-safe |
| NativeWind | TailwindCSS familiarity needed |
| Tamagui | Cross-platform web + native |

### StyleSheet Best Practices

- Define styles outside component (avoid re-creation)
- Use `StyleSheet.flatten()` for merging
- Avoid inline styles except for dynamic values

```tsx
// Dynamic styles
<View style={[styles.box, { backgroundColor: color }]} />
```

---

## State Management

Same patterns as React web:

| Type | Solution |
|------|----------|
| Server state | TanStack Query |
| Form state | react-hook-form |
| Navigation state | Expo Router |
| Global state | Zustand |
| Local state | useState |

---

## Data Fetching

```tsx
import { useQuery, useMutation } from '@tanstack/react-query';

function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => api.getUser(userId),
  });
}

function UserScreen() {
  const { data, isLoading, error } = useUser('123');

  if (isLoading) return <ActivityIndicator />;
  if (error) return <ErrorView error={error} />;

  return <UserProfile user={data} />;
}
```

---

## Platform-Specific Code

```tsx
import { Platform } from 'react-native';

// Inline
const padding = Platform.OS === 'ios' ? 20 : 16;
const paddingTop = Platform.select({ ios: 44, android: 24, default: 0 });

// File-based (automatic)
// Button.ios.tsx
// Button.android.tsx
// Button.tsx (fallback)
```

---

## Safe Areas

```tsx
import { SafeAreaView } from 'react-native-safe-area-context';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

// Wrap screens
export default function Screen() {
  return (
    <SafeAreaView style={{ flex: 1 }} edges={['top']}>
      <Content />
    </SafeAreaView>
  );
}

// Or use hook for custom positioning
function Header() {
  const insets = useSafeAreaInsets();
  return <View style={{ paddingTop: insets.top }} />;
}
```

---

## Lists

```tsx
import { FlashList } from '@shopify/flash-list';

// Prefer FlashList over FlatList for performance
<FlashList
  data={items}
  renderItem={({ item }) => <ItemCard item={item} />}
  estimatedItemSize={80}
  keyExtractor={(item) => item.id}
/>
```

---

## Images

```tsx
import { Image } from 'expo-image';

// Prefer expo-image over RN Image
<Image
  source={{ uri: imageUrl }}
  style={{ width: 100, height: 100 }}
  contentFit="cover"
  placeholder={blurhash}
  transition={200}
/>
```

---

## Haptics & Feedback

```tsx
import * as Haptics from 'expo-haptics';

// Button press feedback
const handlePress = () => {
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  // ... action
};

// Success feedback
Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
```

---

## Storage

```tsx
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as SecureStore from 'expo-secure-store';

// Non-sensitive data
await AsyncStorage.setItem('preferences', JSON.stringify(prefs));

// Sensitive data (tokens, credentials)
await SecureStore.setItemAsync('authToken', token);
```

---

## Environment Variables

```tsx
// app.config.ts
export default {
  expo: {
    extra: {
      apiUrl: process.env.EXPO_PUBLIC_API_URL,
    },
  },
};

// Usage
import Constants from 'expo-constants';
const apiUrl = Constants.expoConfig?.extra?.apiUrl;
```

---

## Testing

```tsx
import { render, fireEvent } from '@testing-library/react-native';

test('button triggers action', () => {
  const onPress = jest.fn();
  const { getByText } = render(<Button onPress={onPress}>Click</Button>);

  fireEvent.press(getByText('Click'));
  expect(onPress).toHaveBeenCalled();
});
```

---

## Performance

- Use `FlashList` instead of `FlatList`
- Use `expo-image` instead of `Image`
- Avoid anonymous functions in render
- Memoize expensive computations
- Use `useCallback` for event handlers passed to lists
- Profile with React DevTools and Flipper

---

## Common Pitfalls

- Don't use `TouchableOpacity` - use `Pressable`
- Don't use `FlatList` for long lists - use `FlashList`
- Don't store tokens in AsyncStorage - use SecureStore
- Don't forget SafeAreaView for notched devices
- Don't use fixed dimensions - use flex and percentages
- Don't block JS thread - use native driver for animations

---

## Expo Libraries (Preferred)

| Category | Library |
|----------|---------|
| Navigation | expo-router |
| Images | expo-image |
| Icons | @expo/vector-icons |
| Storage | expo-secure-store |
| Camera | expo-camera |
| Location | expo-location |
| Notifications | expo-notifications |
| Auth | expo-auth-session |
| Haptics | expo-haptics |
| Updates | expo-updates |
