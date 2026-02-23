import { Tabs } from 'expo-router';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Platform, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function TabLayout() {
  const insets = useSafeAreaInsets();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#ef4444',
        tabBarInactiveTintColor: '#6b7280',
        tabBarShowLabel: false,
        tabBarItemStyle: { justifyContent: 'center' },
        tabBarStyle: {
          backgroundColor: '#0a0a0a',
          borderTopColor: '#1f1f1f',
          borderTopWidth: 1,
          height: Platform.select({
            ios: insets.bottom + 68,
            android: insets.bottom + 68,
            default: 72
          }),
          paddingTop: 10,
          paddingBottom: Platform.select({
            ios: insets.bottom + 8,
            android: insets.bottom + 8,
            default: 10
          }),
          paddingHorizontal: 16
        },
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '600',
          marginTop: 4
        }
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Orçamentos',
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons name="file-document-multiple" size={size} color={color} />
          )
        }}
      />
      <Tabs.Screen
        name="new-budget"
        options={{
          title: 'Novo',
          tabBarIcon: () => (
            <View style={{
              width: 46,
              height: 46,
              borderRadius: 23,
              backgroundColor: '#ef4444',
              justifyContent: 'center',
              alignItems: 'center',
              shadowColor: '#ef4444',
              shadowOffset: { width: 0, height: 3 },
              shadowOpacity: 0.45,
              shadowRadius: 6,
              elevation: 8,
            }}>
              <MaterialCommunityIcons name="plus" size={26} color="#ffffff" />
            </View>
          )
        }}
      />
      <Tabs.Screen
        name="services"
        options={{
          title: 'Catálogo',
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons name="tools" size={size} color={color} />
          )
        }}
      />
    </Tabs>
  );
}
