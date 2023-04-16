(define-data-var order 
	(
		(id uint)
		(quantity uint)
		(price uint)
		(type uint)))
        
;; Order type:  0 - sell, 1 - buy
(define-data-var order-book 
	(sell-orders 
		(list order))
	(buy-orders 
		(list order)))
(define-data-var balances 
	(
		(sender principal)
		(stx uint)
		(btc uint)))
(define-read-only 
	(get-balance 
		(address principal))
	(tuple 
		(balances-get address)))
(define-read-only 
	(get-orders)
	(tuple 
		(sell-orders-get)
		(buy-orders-get)))
(define-read-only 
	(get-order 
		(id uint)
		(order-type uint))
	(if 
		(= order-type 0)
		(list-find 
			(fun 
				(order)
				(= 
					(order-id order)id))
			(sell-orders-get))
		(list-find 
			(fun 
				(order)
				(= 
					(order-id order)id))
			(buy-orders-get))))
(define-private 
	(add-order 
		(order-type uint)
		(quantity uint)
		(price uint)
		(sender principal))
	(let 
		(
			(order 
				(tuple 
					(id 
						(block-height))
					(quantity quantity)
					(price price)
					(type order-type))))
		(if 
			(= order-type 0)
			(sell-orders-push order)
			(buy-orders-push order))
		(event! "order-added" order sender)))
(define-private 
	(remove-order 
		(id uint)
		(order-type uint)
		(sender principal))
	(let 
		(
			(order 
				(get-order id order-type)))
		(if 
			(= order-type 0)
			(sell-orders-set 
				(list-remove 
					(fun 
						(order)
						(= 
							(order-id order)id))
					(sell-orders-get)))
			(buy-orders-set 
				(list-remove 
					(fun 
						(order)
						(= 
							(order-id order)id))
					(buy-orders-get))))
		(event! "order-removed" order sender)))
(define-private 
	(update-order 
		(id uint)
		(order-type uint)
		(quantity uint)
		(price uint)
		(sender principal))
	(let 
		(
			(order 
				(get-order id order-type)))
		(if 
			(not 
				(none? order))
			(begin
				(if 
					(> quantity 
						(order-quantity order))
					(raise "Quantity cannot be increased"))
				(remove-order id order-type)
				(add-order order-type quantity price sender)))
		(event! "order-updated" order sender)))
(define-private 
	(transfer-btc 
		(from principal)
		(to principal)
		(quantity uint))
	(let 
		(
			(from-balance 
				(balances-get from))
			(to-balance 
				(balances-get to)))
		(if 
			(< quantity 
				(balances-btc from-balance))
			(raise "Insufficient BTC balance"))
		(balances-set from 
			(tuple 
				(stx 
					(balances-stx from-balance))
				(btc 
					(- 
						(balances-btc from-balance)quantity))))
		(balances-set to 
			(tuple 
				(stx 
					(balances-stx to-balance))
				(btc 
					(+ 
						(balances-btc to-balance)quantity))))
		(event! "btc-transfer" from to quantity)))
(define-private 
	(transfer-stx 
		(from principal)
		(to principal)
		(quantity uint))
	(let 
		(
			(from-balance 
				(balances-get from))
			(to-balance 
				(balances-get to)))
		(if 
			(< quantity 
				(balances-stx from-balance))
			(raise "Insufficient STX balance"))
		(balances-set from 
			(tuple 
				(stx 
					(- 
						(balances-stx from-balance)quantity))
				(btc 
					(balances-btc from-balance))))
		(balances-set to 
			(tuple 
				(stx 
					(+ 
						(balances-stx to-balance)quantity))
				(btc 
					(balances-btc to-balance))))
		(event! "stx-transfer" from to quantity)))
(define-private 
	(match-orders)
	(let 
		(
			(sell-orders 
				(sell-orders-get))
			(buy-orders 
				(buy-orders-get)))
		(if 
			(or 
				(empty? sell-orders)
				(empty? buy-orders))
			(ok)
			(let 
				(
					(best-sell 
						(first sell-orders))
					(best-buy 
						(first buy-orders)))
				(if 
					(< 
						(order-price best-sell)
						(order-price best-buy))
					(ok)
					(let 
						(
							(match-quantity 
								(min 
									(order-quantity best-sell)
									(order-quantity best-buy))))
						(transfer-btc 
							(order-sender best-buy)
							(order-sender best-sell)match-quantity)
						(transfer-stx 
							(order-sender best-sell)
							(order-sender best-buy)
							(order-price best-sell))
						(if 
							(= match-quantity 
								(order-quantity best-buy))
							(remove-order 
								(order-id best-buy)1)
							(update-order 
								(order-id best-buy)1
								(- 
									(order-quantity best-buy)match-quantity)
								(order-price best-buy)))
						(if 
							(= match-quantity 
								(order-quantity best-sell))
							(remove-order 
								(order-id best-sell)0)
							(update-order 
								(order-id best-sell)0
								(- 
									(order-quantity best-sell)match-quantity)
								(order-price best-sell)))
						(match-orders)))))))
(define-public 
	(add-sell-order 
		(quantity uint)
		(price uint))
	(let 
		(
			(sender tx-sender))
		(add-order 0 quantity price sender)
		(match-orders)))
(define-public 
	(remove-sell-order 
		(id uint))
	(let 
		(
			(sender tx-sender))
		(remove-order id 0 sender)
		(match-orders)))
(define-public 
	(update-sell-order 
		(id uint)
		(quantity uint)
		(price uint))
	(let 
		(
			(sender tx-sender))
		(update-order id 0 quantity price sender)
		(match-orders)))
(define-public 
	(add-buy-order 
		(quantity uint)
		(price uint))
	(let 
		(
			(sender tx-sender))
		(add-order 1 quantity price sender)
		(match-orders)))
(define-public 
	(remove-buy-order 
		(id uint))
	(let 
		(
			(sender tx-sender))
		(remove-order id 1 sender)
		(match-orders)))
(define-public 
	(update-buy-order 
		(id uint)
		(quantity uint)
		(price uint))
	(let 
		(
			(sender tx-sender))
		(update-order id 1 quantity price sender)
		(match-orders)))
(define-public 
	(deposit-stx 
		(quantity uint))
	(let 
		(
			(sender tx-sender))
		(balances-set sender 
			(tuple 
				(stx 
					(+ 
						(balances-stx 
							(balances-get sender))quantity))
				(btc 
					(balances-btc 
						(balances-get sender)))))
		(event! "stx-deposit" sender quantity)))
(define-public 
	(withdraw-stx 
		(quantity uint))
	(let 
		(
			(sender tx-sender))
		(let 
			(
				(balance 
					(balances-get sender)))
			(if 
				(< quantity 
					(balances-stx balance))
				(raise "Insufficient STX balance"))
			(balances-set sender 
				(tuple 
					(stx 
						(- 
							(balances-stx balance)quantity))
					(btc 
						(balances-btc balance))))
			(event! "stx-withdrawal" sender quantity))))
(define-public 
	(withdraw-btc 
		(quantity uint))
	(let 
		(
			(sender tx-sender))
		(let 
			(
				(balance 
					(balances-get sender)))
			(if 
				(< quantity 
					(balances-btc balance))
				(raise "Insufficient BTC balance"))
			(balances-set sender 
				(tuple 
					(stx 
						(balances-stx balance))
					(btc 
						(- 
							(balances-btc balance)quantity))))
			(event! "btc-withdrawal" sender quantity))))
(define-public 
	(get-sell-orders)
	(sell-orders-get))
(define-public 
	(get-buy-orders)
	(buy-orders-get))
(define-public 
	(get-balance)
	(balances-get tx-sender))
(define-public 
	(get-btc-price)
	(get-btc-price-from-oracle))
