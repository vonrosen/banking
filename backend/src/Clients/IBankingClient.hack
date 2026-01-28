namespace Banking\Clients;

use type Banking\Models\Transaction;

interface IBankingClient {
  /**
   * Get transactions for a bank account.
   * Returns an AsyncGenerator that yields Transaction shapes.
   */
  public function getTransactionsAsync(string $bank_login_token): AsyncGenerator<int, Transaction, void>;
}
