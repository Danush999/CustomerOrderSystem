/**
 * ProductController - Apex Controller for Product Catalog LWC
 * Provides server-side methods that Lightning Web Components can call
 */
public with sharing class ProductController {
    
    /**
     * Get products based on search criteria
     * This method is called by the Lightning Web Component
     * 
     * @param searchTerm - Text to search in product name
     * @param inStockOnly - Whether to show only products with stock
     * @return List of Product records
     */
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getProducts(String searchTerm, Boolean inStockOnly) {
        
        System.debug('🔍 ProductController.getProducts called');
        System.debug('Search term: ' + searchTerm);
        System.debug('In stock only: ' + inStockOnly);
        
        // Build dynamic SOQL query
        String query = 'SELECT Id, Name, Price__c, Stock_Quantity__c, Description__c, Is_Active__c FROM Product__c';
        
        // List to hold WHERE conditions
        List<String> conditions = new List<String>();
        
        // Always show only active products
        conditions.add('Is_Active__c = true');
        
        // Add stock filter if requested
        if (inStockOnly == true) {
            conditions.add('Stock_Quantity__c > 0');
        }
        
        // Add search term filter if provided
        if (String.isNotBlank(searchTerm)) {
            // Escape single quotes to prevent SOQL injection
            String escapedSearchTerm = String.escapeSingleQuotes(searchTerm);
            conditions.add('Name LIKE \'%' + escapedSearchTerm + '%\'');
        }
        
        // Add WHERE clause
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        // Add ORDER BY and LIMIT
        query += ' ORDER BY Name ASC LIMIT 50';
        
        System.debug('🔍 Final query: ' + query);
        
        // Execute query and return results
        List<Product__c> products = Database.query(query);
        
        System.debug('📦 Found ' + products.size() + ' products');
        
        return products;
    }
    
    /**
     * Get a single product by ID
     * @param productId - ID of the product to retrieve
     * @return Product record
     */
    @AuraEnabled(cacheable=true)
    public static Product__c getProduct(Id productId) {
        
        System.debug('🔍 Getting product: ' + productId);
        
        try {
            return [
                SELECT Id, Name, Price__c, Stock_Quantity__c, Description__c, Is_Active__c 
                FROM Product__c 
                WHERE Id = :productId 
                AND Is_Active__c = true
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('❌ Error getting product: ' + e.getMessage());
            throw new AuraHandledException('Product not found: ' + e.getMessage());
        }
    }
    
    /**
     * Create sample products for testing
     * This method helps create test data
     * @return Number of products created
     */
    @AuraEnabled
    public static Integer createSampleProducts() {
        
        System.debug('🏗️ Creating sample products...');
        
        // Check if products already exist
        Integer existingCount = [SELECT COUNT() FROM Product__c WHERE Is_Active__c = true];
        if (existingCount > 0) {
            throw new AuraHandledException('Sample products already exist. Found ' + existingCount + ' products.');
        }
        
        // Create sample products
        List<Product__c> sampleProducts = new List<Product__c>{
            new Product__c(
                Name = 'iPhone 15 Pro',
                Price__c = 999.99,
                Stock_Quantity__c = 25,
                Description__c = 'Latest iPhone with advanced camera system and A17 Pro chip.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'MacBook Pro 14"',
                Price__c = 1999.99,
                Stock_Quantity__c = 10,
                Description__c = 'Powerful laptop with M3 chip, perfect for professionals.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'AirPods Pro',
                Price__c = 249.99,
                Stock_Quantity__c = 50,
                Description__c = 'Wireless earbuds with active noise cancellation.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'iPad Air',
                Price__c = 599.99,
                Stock_Quantity__c = 30,
                Description__c = 'Versatile tablet for work and creativity.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'Apple Watch Series 9',
                Price__c = 399.99,
                Stock_Quantity__c = 20,
                Description__c = 'Advanced smartwatch with health monitoring.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'Magic Mouse',
                Price__c = 79.99,
                Stock_Quantity__c = 0, // Out of stock for testing
                Description__c = 'Wireless mouse with multi-touch surface.',
                Is_Active__c = true
            )
        };
        
        try {
            insert sampleProducts;
            System.debug('✅ Created ' + sampleProducts.size() + ' sample products');
            return sampleProducts.size();
            
        } catch (Exception e) {
            System.debug('❌ Error creating sample products: ' + e.getMessage());
            throw new AuraHandledException('Error creating sample products: ' + e.getMessage());
        }
    }
}