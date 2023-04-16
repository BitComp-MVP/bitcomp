The smart contract consists of the following functions:

1. add-order: Adds an order to the order book. Takes the is-buy flag (0 for sell order, 1 for buy order), the quantity of BTC being lent/borrowed, the price of BTC in STX, and the sender of the order.
2. remove-order: Removes an order from the order book. Takes the id of the order, the is-buy flag, and the sender of the order.
3. update-order: Updates an existing order in the order book. Takes the id of the order, the is-buy flag, the new quantity of BTC being lent/borrowed, the new price of BTC in STX, and the sender of the order.
4. transfer-btc: Transfers BTC from the from address to the to address. Takes the from address, the to address, and the quantity of BTC being transferred.
5. transfer-stx: Transfers STX from the from address to the to address. Takes the from address, the to address, and the quantity of STX being transferred.
6. match-orders: Matches the top buy and sell orders in the order book and executes the transaction. If there are no matching orders, does nothing. Calls transfer-btc and transfer-stx to execute the transaction.
7. add-sell-order: Adds a sell order to the order book. Takes the quantity of BTC being lent and the price of BTC in STX.
8. remove-sell-order: Removes a sell order from the order book. Takes the id of the order.
9. update-sell-order: Updates an existing sell order in the order book. Takes the id of the order, the new quantity of BTC being lent, and the new price of BTC in STX.
10. add-buy-order: Adds a buy order to the order book. Takes the quantity of BTC being borrowed and the price of BTC in STX.
11. remove-buy-order: Removes a buy order from the order book. Takes the id of the order.
12. update-buy-order: Updates an existing buy order in the order book. Takes the id of the order, the new quantity of BTC being borrowed, and the new price of BTC in STX.
13. deposit-stx: Deposits STX collateral. Takes the quantity of STX being deposited.
14. withdraw-stx: Withdraws STX collateral. Takes the quantity of STX being withdrawn.
15. withdraw-btc: Withdraws lent BTC. Takes the quantity of BTC being withdrawn.
16. get-sell-orders: Returns the current sell orders in the order book.
17. get-buy-orders: Returns the current buy orders in the order book.
18. get-balance: Returns the STX and BTC balances of the caller.
19. get-btc-price: Returns the current price of BTC in STX from the oracle.

The order book is maintained using two separate stacks - one for buy orders and one for sell orders. Each order has a unique id generated using the sha256 hash function, which is used to reference the order in other functions. The order book is implemented using a map data structure with the order id as the key and the order information (quantity, price, sender, etc.) as the value.

The match-orders function is responsible for executing transactions between matching buy and sell orders. It first checks if there are any matching orders by comparing the top buy order price to the top sell order price. If there is a match, the function calculates the amount of BTC and STX to be transferred and calls the transfer-btc and transfer-stx functions to execute the transaction.

The deposit-stx function is responsible for depositing STX collateral into the contract. It first transfers the STX from the caller's account to the contract's account, and then updates the caller's balance in the balances map.

The withdraw-stx function is responsible for withdrawing STX collateral from the contract. It first transfers the STX from the contract's account to the caller's account, and then updates the caller's balance in the balances map.

The withdraw-btc function is responsible for withdrawing lent BTC from the contract. It first checks that the caller has enough BTC available to withdraw, and then transfers the BTC from the contract's account to the caller's account. The caller's balance in the balances map is also updated.

The get-sell-orders and get-buy-orders functions return the current sell and buy orders in the order book, respectively.

The get-balance function returns the STX and BTC balances of the caller.

The get-btc-price function retrieves the current price of BTC in STX from an external oracle. This value is used to determine the price of BTC in STX for orders in the order book.

Overall, this smart contract allows users to lend and borrow BTC using STX as collateral. The order book mechanism ensures that transactions are executed at fair market prices. The use of the sha256 hash function ensures that each order is unique and that orders can be referenced using a single id. The balances map tracks the STX and BTC balances of each user.