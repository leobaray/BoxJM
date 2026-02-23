import { Stack } from 'expo-router';
import { BudgetProvider } from '@/contexts/BudgetContext';
import { CatalogProvider } from '@/contexts/CatalogContext';

export default function RootLayout() {
  return (
    <CatalogProvider>
      <BudgetProvider>
        <Stack screenOptions={{ headerShown: false }}>
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          <Stack.Screen name="budget/[id]" options={{ headerShown: false }} />
        </Stack>
      </BudgetProvider>
    </CatalogProvider>
  );
}