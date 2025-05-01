import { useState } from 'react';
import styles from './TransactionForm.module.css';

function TransactionForm({ onAdd }) {
  const [name, setName] = useState('');
  const [amount, setAmount] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!name || !amount) return;
    onAdd({
      id: Date.now(),
      name,
      amount: parseFloat(amount),
    });
    setName('');
    setAmount('');
  };

  return (
    <form onSubmit={handleSubmit} className={styles.form}>
      <div className={styles.inputs}>
        <input
          type="text"
          placeholder="Description"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <input
          type="number"
          placeholder="Amount"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />
      </div>
      <button type="submit">Add Transaction</button>
    </form>
  );
}

export default TransactionForm;
