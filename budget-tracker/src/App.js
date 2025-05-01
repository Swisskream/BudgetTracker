import React, { useState } from 'react';
import Header from './components/Header';
import Summary from './components/Summary';
import TransactionForm from './components/TransactionForm';
import TransactionList from './components/TransactionList';

function App() {
  const [transactions, setTransactions] = useState([]);

  const handleAdd = (tx) => {
    setTransactions([tx, ...transactions]);
  };

  const income = transactions
    .filter((t) => t.amount >= 0)
    .reduce((sum, t) => sum + t.amount, 0);
  const expense = transactions
    .filter((t) => t.amount < 0)
    .reduce((sum, t) => sum + Math.abs(t.amount), 0);

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto', padding: '1rem' }}>
      <Header />
      <Summary income={income} expense={expense} />
      <TransactionForm onAdd={handleAdd} />
      <TransactionList transactions={transactions} />
    </div>
  );
}

export default App;
