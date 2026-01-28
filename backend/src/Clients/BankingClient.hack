namespace Banking\Clients;

use type Banking\Models\Transaction;

final class BankingClient implements IBankingClient {
  const int TRANSACTION_COUNT = 100;

  private vec<string> $sampleDescriptions = vec[
    'AMAZON.COM AMZN.COM/BILL WA',
    'TRADER JOE\'S #123 SAN FRANCISCO CA',
    'CHEVRON 0012345 SAN FRANCISCO CA',
    'NETFLIX.COM LOS GATOS CA',
    'SPOTIFY USA NEW YORK NY',
    'TARGET 00012345 DALY CITY CA',
    'WHOLE FOODS MKT SAN FRANCISCO CA',
    'UBER TRIP HELP.UBER.COM CA',
    'LYFT RIDE SUN 5PM SAN FRANCISCO CA',
    'STARBUCKS STORE 12345 SAN FRANCISCO',
    'SHELL OIL 57442234123 SAN MATEO CA',
    'WALGREENS #1234 SAN FRANCISCO CA',
    'CVS/PHARMACY #1234 DALY CITY CA',
    'SAFEWAY #1234 SAN FRANCISCO CA',
    'PG&E DES:UTILITY ID:XXXXX1234 INDN:HUNTER STERN',
    'COMCAST CALIFORNIA 800-266-2278 CA',
    'AT&T MOBILITY 800-331-0500 TX',
    'GOOGLE *GOOGLE STORAGE CC@GOOGLE.COM CA',
    'APPLE.COM/BILL 866-712-7753 CA',
    'DOORDASH DASHER SAN FRANCISCO CA',
    'GRUBHUB ORDER CHICAGO IL',
    'VENMO PAYMENT 855-812-4430 NY',
    'ZELLE PAYMENT FROM JOHN DOE',
    'ACH DEPOSIT EMPLOYER PAYROLL',
    'CHECK DEPOSIT MOBILE',
    'ATM WITHDRAWAL CHASE BANK',
    'TRANSFER TO SAVINGS',
    'INTEREST PAYMENT',
    'COSTCO WHSE #1234 DALY CITY CA',
    'HOME DEPOT #1234 SAN FRANCISCO CA',
  ];

  public async function getTransactionsAsync(string $_bank_login_token): AsyncGenerator<int, Transaction, void> {
    $baseTime = \time();
    $insuranceIndex = \mt_rand(0, self::TRANSACTION_COUNT - 1);

    for ($i = 0; $i < self::TRANSACTION_COUNT; $i++) {
      if ($i === $insuranceIndex) {
        yield $i => shape(
          'id' => $this->generateTransactionId(),
          'description' => 'UNITED FIN CAS DES:INS PREM ID:XXXXX9825 Hunte INDN:Hunter Stern CO ID:XXXXX48062 PPD',
          'amount' => -127.45,
          'created_at' => $baseTime - ($i * 86400),
        );
      } else {
        $descIndex = \mt_rand(0, \count($this->sampleDescriptions) - 1);
        $isDebit = \mt_rand(0, 10) < 9;
        $amount = \mt_rand(100, 50000) / 100.0;

        yield $i => shape(
          'id' => $this->generateTransactionId(),
          'description' => $this->sampleDescriptions[$descIndex],
          'amount' => $isDebit ? -$amount : $amount,
          'created_at' => $baseTime - ($i * 86400),
        );
      }
    }
  }

  private function generateTransactionId(): string {
    return \sprintf('txn_%s', \bin2hex(\random_bytes(12)));
  }
}
