import styles from './TransactionList.module.css';

function TransactionList({ transactions }) {
  return (
    <ul className={styles.list}>
      {transactions.map((tx) => (
        <li key={tx.id} className={tx.amount >= 0 ? styles.income : styles.expense}>
          <span>{tx.name}</span>
          <span>{tx.amount >= 0 ? '+' : '-'}${Math.abs(tx.amount)}</span>
        </li>
      ))}
    </ul>
  );
}

export default TransactionList;
