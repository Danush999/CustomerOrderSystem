/**
 * OrderService - Simple version for beginners
 * This class handles basic order calculations
 */
public with sharing class OrderService {
    
    /**
     * Calculate total amount for orders
     * @param orderIds - List of Order IDs that need total recalculation
     */
    public static void calculateOrderTotals(List<Id> orderIds) {
        System.debug('Calculating totals for ' + orderIds.size() + ' orders');
        
        // Get sum of all order items for each order
        List<AggregateResult> orderTotals = [
            SELECT Order__c, SUM(Line_Total__c) totalAmount 
            FROM Order_Item__c 
            WHERE Order__c IN :orderIds 
            GROUP BY Order__c
        ];
        
        // Prepare orders for update
        List<Order__c> ordersToUpdate = new List<Order__c>();
        
        // Create order records with new totals
        for(AggregateResult result : orderTotals) {
            ordersToUpdate.add(new Order__c(
                Id = (Id)result.get('Order__c'),
                Total_Amount__c = (Decimal)result.get('totalAmount')
            ));
        }
        
        // Handle orders with no items (total = 0)
        Set<Id> ordersWithItems = new Set<Id>();
        for(AggregateResult result : orderTotals) {
            ordersWithItems.add((Id)result.get('Order__c'));
        }
        
        for(Id orderId : orderIds) {
            if(!ordersWithItems.contains(orderId)) {
                ordersToUpdate.add(new Order__c(
                    Id = orderId,
                    Total_Amount__c = 0
                ));
            }
        }
        
        // Update all orders
        if(!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
            System.debug('Updated ' + ordersToUpdate.size() + ' orders');
        }
    }
    
    /**
     * Check if we have enough product in stock
     * @param productId - Which product to check
     * @param requestedQuantity - How much customer wants
     * @return true if we have enough stock
     */
    public static Boolean checkProductAvailability(Id productId, Decimal requestedQuantity) {
        // Query the product
        List<Product__c> products = [
            SELECT Stock_Quantity__c 
            FROM Product__c 
            WHERE Id = :productId 
            LIMIT 1
        ];
        
        if(products.isEmpty()) {
            return false;
        }
        
        return products[0].Stock_Quantity__c >= requestedQuantity;
    }
    
    /**
     * Calculate tax for an order
     * @param orderAmount - Order total
     * @return Tax amount
     */
    public static Decimal calculateTax(Decimal orderAmount) {
        // Simple 8.5% tax rate
        return orderAmount * 0.085;
    }
    
    /**
     * Calculate shipping cost
     * @param orderAmount - Order total
     * @return Shipping cost (free over $50)
     */
    public static Decimal calculateShipping(Decimal orderAmount) {
        if(orderAmount >= 50) {
            return 0.00; // Free shipping
        }
        return 9.99; // Standard shipping
    }
}