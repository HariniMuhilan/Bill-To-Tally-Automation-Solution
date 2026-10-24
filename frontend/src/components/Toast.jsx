import React, { useEffect } from 'react';

export default function Toast({ message, type, onClose }) {
  useEffect(() => {
    const timer = setTimeout(() => {
      onClose();
    }, 4000);
    return () => clearTimeout(timer);
  }, [onClose]);

  let icon = 'fa-circle-check';
  if (type === 'warning') icon = 'fa-triangle-exclamation';
  if (type === 'error') icon = 'fa-circle-xmark';

  return (
    <div className={`toast ${type}`}>
      <i 
        className={`fa-solid ${icon}`} 
        style={{ 
          fontSize: '1.1rem', 
          color: type === 'success' ? '#10b981' : (type === 'warning' ? '#f59e0b' : '#ef4444') 
        }}
      ></i>
      <span>{message}</span>
    </div>
  );
}
