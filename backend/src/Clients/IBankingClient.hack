namespace Banking\Clients;

use type Banking\Models\Transaction;

interface IBankingClient {
  public function getTransactionsAsync(string $bank_login_token): AsyncGenerator<int, Transaction, void>;
}
