import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import Summary from './components/Summary';
import TransactionForm from './components/TransactionForm';
import TransactionList from './components/TransactionList';

function App() {
  const [transactions, setTransactions] = useState([]);

  // ✅ Fetch data on component mount
  useEffect(() => {
    fetch('https://l1uae3hhuj.execute-api.us-west-1.amazonaws.com/budget')
      .then(response => {
        if (!response.ok) throw new Error('Network response was not ok');
        return response.json();
      })
      .then(data => {
        const clean = Array.isArray(data)
          ? data.filter(t => t && typeof t.amount === 'number')
          : [];
        setTransactions(clean);
      })
      .catch(error => console.error('Error fetching transactions:', error));
  }, []);

  // ✅ Add new transaction via backend
  const handleAdd = (tx) => {
    fetch('https://l1uae3hhuj.execute-api.us-west-1.amazonaws.com/budget', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(tx),
    })
      .then(response => response.json())
      .then(data => {
        console.log('POST response:', data);
        setTransactions(prev => [data.item, ...prev]);
      })
      .catch(error => console.error('Error adding transaction:', error));
  };

  const income = transactions
    .filter((t) => t && typeof t.amount === 'number' && t.amount >= 0)
    .reduce((sum, t) => sum + t.amount, 0);
  const expense = transactions
    .filter((t) => t && typeof t.amount === 'number' && t.amount < 0)
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

