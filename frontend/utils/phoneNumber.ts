export function isValidUSPhoneNumber(phone: string): boolean {
  const digits = phone.replace(/\D/g, '');
  if (digits.length === 10) {
    return true;
  }
  if (digits.length === 11 && digits.startsWith('1')) {
    return true;
  }
  return false;
}

export function formatPhoneNumber(value: string): string {
  const digits = value.replace(/\D/g, '');
  if (digits.length <= 3) {
    return digits;
  }
  if (digits.length <= 6) {
    return `(${digits.slice(0, 3)}) ${digits.slice(3)}`;
  }
  return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6, 10)}`;
}
