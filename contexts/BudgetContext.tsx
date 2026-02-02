import React, { createContext, useState, useEffect, ReactNode } from 'react';
import { Budget } from '@/types/budget';
import { budgetService } from '@/services/budgetService';

interface BudgetContextType {
  budgets: Budget[];
  loading: boolean;
  refreshBudgets: () => Promise<void>;
  createBudget: (budget: Omit<Budget, 'id' | 'createdAt'>) => Promise<Budget>;
  updateBudget: (id: string, updates: Partial<Budget>) => Promise<Budget>;
  deleteBudget: (id: string) => Promise<void>;
}

export const BudgetContext = createContext<BudgetContextType | undefined>(undefined);

export function BudgetProvider({ children }: { children: ReactNode }) {
  const [budgets, setBudgets] = useState<Budget[]>([]);
  const [loading, setLoading] = useState(true);

  const refreshBudgets = async () => {
    try {
      setLoading(true);
      const data = await budgetService.getAllBudgets();
      setBudgets(data);
    } catch (error) {
      console.error('Error refreshing budgets:', error);
      setBudgets([]);
    } finally {
      setLoading(false);
    }
  };

  const createBudget = async (budget: Omit<Budget, 'id' | 'createdAt'>) => {
    const newBudget = await budgetService.createBudget(budget);
    setBudgets(prev => [newBudget, ...prev]);
    return newBudget;
  };

  const updateBudget = async (id: string, updates: Partial<Budget>) => {
    const updatedBudget = await budgetService.updateBudget(id, updates);
    setBudgets(prev => prev.map(b => b.id === id ? updatedBudget : b));
    return updatedBudget;
  };

  const deleteBudget = async (id: string) => {
    try {
      console.log('Context: Deletando orçamento:', id);
      await budgetService.deleteBudget(id);
      console.log('Context: Atualizando lista de orçamentos');
      setBudgets(prev => prev.filter(b => b.id !== id));
      console.log('Context: Lista atualizada');
    } catch (error) {
      console.error('Context: Erro ao deletar:', error);
      throw error;
    }
  };

  useEffect(() => {
    refreshBudgets();
  }, []);

  return (
    <BudgetContext.Provider value={{
      budgets,
      loading,
      refreshBudgets,
      createBudget,
      updateBudget,
      deleteBudget
    }}>
      {children}
    </BudgetContext.Provider>
  );
}