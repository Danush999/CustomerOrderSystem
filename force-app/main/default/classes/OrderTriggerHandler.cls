/**
 * OrderTriggerHandler - Handles automatic actions when Order Items change
 * 
 * This class is called by triggers and handles the business logic
 * Think of it as the "brain" that decides what to do when data changes
 */
public class OrderTriggerHandler {
    
    /**
     * Called when NEW Order Items are created
     * Automatically recalculates the order total
     * 
     * @param newItems - The new Order Items that were just added
     */
    public static void handleAfterInsert(List<Order_Item__c> newItems) {
        System.debug('🔥 TRIGGER: New order items added! Count: ' + newItems.size());
        
        // Get all the Order IDs that need to be updated
        Set<Id> orderIds = new Set<Id>();
        
        for(Order_Item__c item : newItems) {
            orderIds.add(item.Order__c);
            System.debug('📦 Added item to Order: ' + item.Order__c + 
                        ', Product: ' + item.Product__c + 
                        ', Quantity: ' + item.Quantity__c);
        }
        
        // Recalculate totals for these orders
        if(!orderIds.isEmpty()) {
            OrderService.calculateOrderTotals(new List<Id>(orderIds));
        }
    }
    
    /**
     * Called when Order Items are UPDATED (quantity or price changed)
     * Recalculates order totals
     * 
     * @param newItems - The updated Order Items (new values)
     * @param oldItems - The old Order Items (previous values)
     */
    public static void handleAfterUpdate(List<Order_Item__c> newItems, List<Order_Item__c> oldItems) {
        System.debug('🔄 TRIGGER: Order items updated! Count: ' + newItems.size());
        
        Set<Id> orderIds = new Set<Id>();
        
        // Check what changed and decide if we need to recalculate
        for(Integer i = 0; i < newItems.size(); i++) {
            Order_Item__c newItem = newItems[i];
            Order_Item__c oldItem = oldItems[i];
            
            // Check if quantity or price changed
            Boolean quantityChanged = newItem.Quantity__c != oldItem.Quantity__c;
            Boolean priceChanged = newItem.Unit_Price__c != oldItem.Unit_Price__c;
            
            if(quantityChanged || priceChanged) {
                orderIds.add(newItem.Order__c);
                System.debug('📝 Item changed - Order: ' + newItem.Order__c + 
                            ', Old Qty: ' + oldItem.Quantity__c + 
                            ', New Qty: ' + newItem.Quantity__c +
                            ', Old Price: $' + oldItem.Unit_Price__c +
                            ', New Price: $' + newItem.Unit_Price__c);
            }
        }
        
        // Recalculate totals for orders with changes
        if(!orderIds.isEmpty()) {
            OrderService.calculateOrderTotals(new List<Id>(orderIds));
        }
    }
    
    /**
     * Called when Order Items are DELETED
     * Recalculates order totals (they'll be lower now)
     * 
     * @param deletedItems - The Order Items that were just deleted
     */
    public static void handleAfterDelete(List<Order_Item__c> deletedItems) {
        System.debug('🗑️ TRIGGER: Order items deleted! Count: ' + deletedItems.size());
        
        Set<Id> orderIds = new Set<Id>();
        
        for(Order_Item__c item : deletedItems) {
            orderIds.add(item.Order__c);
            System.debug('❌ Deleted item from Order: ' + item.Order__c + 
                        ', Product: ' + item.Product__c);
        }
        
        // Recalculate totals (will be lower or zero)
        if(!orderIds.isEmpty()) {
            OrderService.calculateOrderTotals(new List<Id>(orderIds));
        }
    }
    
    /**
     * Called BEFORE Order Items are saved (for validation)
     * Checks business rules and prevents bad data
     * 
     * @param newItems - The Order Items being created/updated
     */
    public static void handleBeforeInsert(List<Order_Item__c> newItems) {
        System.debug('✅ TRIGGER: Validating new order items...');
        validateOrderItems(newItems);
    }
    
    /**
     * Called BEFORE Order Items are updated (for validation)
     * 
     * @param newItems - The Order Items being updated
     */
    public static void handleBeforeUpdate(List<Order_Item__c> newItems) {
        System.debug('✅ TRIGGER: Validating updated order items...');
        validateOrderItems(newItems);
    }
    
    /**
     * Validates Order Items to ensure they follow business rules
     * 
     * @param items - Order Items to validate
     */
    private static void validateOrderItems(List<Order_Item__c> items) {
        // Get all Product IDs for bulk query (efficient!)
        Set<Id> productIds = new Set<Id>();
        for(Order_Item__c item : items) {
            if(item.Product__c != null) {
                productIds.add(item.Product__c);
            }
        }
        
        // Get all product information at once
        Map<Id, Product__c> productsMap = new Map<Id, Product__c>([
            SELECT Id, Name, Price__c, Stock_Quantity__c, Is_Active__c
            FROM Product__c 
            WHERE Id IN :productIds
        ]);
        
        // Validate each item
        for(Order_Item__c item : items) {
            String itemName = 'Order Item';
            
            // Basic validations
            if(item.Product__c == null) {
                item.addError('Product is required');
                continue;
            }
            
            if(item.Quantity__c == null || item.Quantity__c <= 0) {
                item.addError('Quantity must be greater than 0');
                continue;
            }
            
            // Get product details
            Product__c product = productsMap.get(item.Product__c);
            if(product == null) {
                item.addError('Invalid product selected');
                continue;
            }
            
            itemName = product.Name;
            
            // Business rule validations
            if(!product.Is_Active__c) {
                item.addError('Product "' + product.Name + '" is no longer available');
            }
            
            if(item.Quantity__c > product.Stock_Quantity__c) {
                item.addError('Not enough stock for "' + product.Name + 
                             '". Available: ' + product.Stock_Quantity__c + 
                             ', Requested: ' + item.Quantity__c);
            }
            
            // Auto-populate unit price if not provided
            if(item.Unit_Price__c == null || item.Unit_Price__c == 0) {
                item.Unit_Price__c = product.Price__c;
                System.debug('💰 Auto-populated price for ' + product.Name + ': $' + product.Price__c);
            }
            
            // Validate price is reasonable (within 50% of list price)
            Decimal minPrice = product.Price__c * 0.5;
            Decimal maxPrice = product.Price__c * 1.5;
            
            if(item.Unit_Price__c < minPrice || item.Unit_Price__c > maxPrice) {
                item.addError('Price for "' + product.Name + '" must be between $' + 
                             minPrice.setScale(2) + ' and $' + maxPrice.setScale(2));
            }
            
            System.debug('✅ Validated: ' + product.Name + 
                        ', Qty: ' + item.Quantity__c + 
                        ', Price: $' + item.Unit_Price__c);
        }
    }
}