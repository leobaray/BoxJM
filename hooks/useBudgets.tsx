import { useContext } from 'react';
import { BudgetContext } from '@/contexts/BudgetContext';

export function useBudgets() {
  const context = useContext(BudgetContext);
  if (!context) {
    throw new Error('useBudgets must be used within BudgetProvider');
  }
  return context;
}