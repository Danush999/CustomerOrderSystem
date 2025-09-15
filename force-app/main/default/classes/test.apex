Decimal tax = OrderService.calculateTax(100.00);
System.debug('Tax for $100: $' + tax);

Decimal shipping = OrderService.calculateShipping(30.00);
System.debug('Shipping for $30: $' + shipping);

Decimal freeShipping = OrderService.calculateShipping(60.00);
System.debug('Shipping for $60: $' + freeShipping);