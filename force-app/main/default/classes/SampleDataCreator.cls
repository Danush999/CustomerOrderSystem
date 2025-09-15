/**
 * SampleDataCreator - Creates test data for our Order Management System
 * This class helps you create realistic sample data to test your system
 */
public class SampleDataCreator {
    
    /**
     * Create complete sample data set
     * @return Summary of created records
     */
    @AuraEnabled
    public static String createAllSampleData() {
        
        try {
            System.debug('🏗️ Creating complete sample data set...');
            
            // Check if data already exists
            Integer existingProducts = [SELECT COUNT() FROM Product__c];
            Integer existingContacts = [SELECT COUNT() FROM Contact];
            Integer existingOrders = [SELECT COUNT() FROM Order__c];
            
            if (existingProducts > 0 || existingContacts > 0 || existingOrders > 0) {
                return 'Sample data already exists. Products: ' + existingProducts + 
                       ', Customers: ' + existingContacts + ', Orders: ' + existingOrders;
            }
            
            // Create sample data
            List<Contact> customers = createSampleCustomers();
            List<Product__c> products = createSampleProducts();
            List<Order__c> orders = createSampleOrders(customers, products);
            
            String summary = 'Successfully created sample data:\n' +
                           '✅ ' + customers.size() + ' customers\n' +
                           '✅ ' + products.size() + ' products\n' +
                           '✅ ' + orders.size() + ' orders\n' +
                           '\nYour system is ready for testing!';
            
            System.debug('✅ Sample data creation completed');
            return summary;
            
        } catch (Exception e) {
            System.debug('❌ Error creating sample data: ' + e.getMessage());
            return 'Error creating sample data: ' + e.getMessage();
        }
    }
    
    /**
     * Create sample customers
     * @return List of created customers
     */
    public static List<Contact> createSampleCustomers() {
        
        System.debug('👥 Creating sample customers...');
        
        List<Contact> customers = new List<Contact>{
            new Contact(
                FirstName = 'John',
                LastName = 'Smith',
                Email = 'john.smith@email.com',
                Phone = '(555) 123-4567',
                MailingStreet = '123 Main Street',
                MailingCity = 'San Francisco',
                MailingState = 'CA',
                MailingPostalCode = '94105',
                MailingCountry = 'USA'
            ),
            new Contact(
                FirstName = 'Sarah',
                LastName = 'Johnson',
                Email = 'sarah.johnson@email.com',
                Phone = '(555) 234-5678',
                MailingStreet = '456 Oak Avenue',
                MailingCity = 'New York',
                MailingState = 'NY',
                MailingPostalCode = '10001',
                MailingCountry = 'USA'
            ),
            new Contact(
                FirstName = 'Mike',
                LastName = 'Davis',
                Email = 'mike.davis@email.com',
                Phone = '(555) 345-6789',
                MailingStreet = '789 Pine Road',
                MailingCity = 'Austin',
                MailingState = 'TX',
                MailingPostalCode = '73301',
                MailingCountry = 'USA'
            ),
            new Contact(
                FirstName = 'Emma',
                LastName = 'Wilson',
                Email = 'emma.wilson@email.com',
                Phone = '(555) 456-7890',
                MailingStreet = '321 Cedar Lane',
                MailingCity = 'Seattle',
                MailingState = 'WA',
                MailingPostalCode = '98101',
                MailingCountry = 'USA'
            ),
            new Contact(
                FirstName = 'David',
                LastName = 'Brown',
                Email = 'david.brown@email.com',
                Phone = '(555) 567-8901',
                MailingStreet = '654 Elm Street',
                MailingCity = 'Miami',
                MailingState = 'FL',
                MailingPostalCode = '33101',
                MailingCountry = 'USA'
            )
        };
        
        insert customers;
        System.debug('✅ Created ' + customers.size() + ' customers');
        return customers;
    }
    
    /**
     * Create sample products
     * @return List of created products
     */
    public static List<Product__c> createSampleProducts() {
        
        System.debug('📦 Creating sample products...');
        
        List<Product__c> products = new List<Product__c>{
            new Product__c(
                Name = 'iPhone 15 Pro',
                Price__c = 999.99,
                Stock_Quantity__c = 25,
                Description__c = 'Latest iPhone with advanced camera system, A17 Pro chip, and titanium design. Perfect for professionals and photography enthusiasts.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'MacBook Pro 14"',
                Price__c = 1999.99,
                Stock_Quantity__c = 15,
                Description__c = 'Powerful laptop with M3 Pro chip, 18GB RAM, and stunning Liquid Retina XDR display. Ideal for creative professionals.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'AirPods Pro (2nd Gen)',
                Price__c = 249.99,
                Stock_Quantity__c = 50,
                Description__c = 'Premium wireless earbuds with active noise cancellation, spatial audio, and up to 6 hours of listening time.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'iPad Air 11"',
                Price__c = 599.99,
                Stock_Quantity__c = 30,
                Description__c = 'Versatile tablet with M2 chip, perfect for work, creativity, and entertainment. Supports Apple Pencil and Magic Keyboard.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'Apple Watch Series 9',
                Price__c = 399.99,
                Stock_Quantity__c = 40,
                Description__c = 'Advanced smartwatch with health monitoring, fitness tracking, and seamless iPhone integration.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'Magic Mouse',
                Price__c = 79.99,
                Stock_Quantity__c = 35,
                Description__c = 'Wireless mouse with multi-touch surface and rechargeable battery. Works great with Mac computers.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'Magic Keyboard',
                Price__c = 99.99,
                Stock_Quantity__c = 20,
                Description__c = 'Wireless keyboard with scissor mechanism and numeric keypad. Pairs automatically with your Mac.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'AirTag 4-Pack',
                Price__c = 99.99,
                Stock_Quantity__c = 45,
                Description__c = 'Precision finding devices to help locate your belongings using the Find My network.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'iPhone 15 Case',
                Price__c = 49.99,
                Stock_Quantity__c = 60,
                Description__c = 'Premium silicone case designed specifically for iPhone 15. Available in multiple colors.',
                Is_Active__c = true
            ),
            new Product__c(
                Name = 'USB-C Cable (2m)',
                Price__c = 29.99,
                Stock_Quantity__c = 0, // Out of stock for testing
                Description__c = 'High-quality USB-C to USB-C cable for charging and data transfer.',
                Is_Active__c = true
            )
        };
        
        insert products;
        System.debug('✅ Created ' + products.size() + ' products');
        return products;
    }
    
    /**
     * Create sample orders with realistic scenarios
     * @param customers - List of customers to create orders for
     * @param products - List of products to use in orders
     * @return List of created orders
     */
    public static List<Order__c> createSampleOrders(List<Contact> customers, List<Product__c> products) {
        
        System.debug('📋 Creating sample orders...');
        
        List<Order__c> orders = new List<Order__c>();
        List<Order_Item__c> allOrderItems = new List<Order_Item__c>();
        
        // Order 1: John's large order (multiple items)
        Order__c order1 = new Order__c(
            Customer__c = customers[0].Id, // John Smith
            Order_Date__c = Date.today().addDays(-5),
            Status__c = 'Confirmed'
        );
        orders.add(order1);
        
        // Order 2: Sarah's simple order
        Order__c order2 = new Order__c(
            Customer__c = customers[1].Id, // Sarah Johnson
            Order_Date__c = Date.today().addDays(-3),
            Status__c = 'Shipped'
        );
        orders.add(order2);
        
        // Order 3: Mike's draft order (not yet confirmed)
        Order__c order3 = new Order__c(
            Customer__c = customers[2].Id, // Mike Davis
            Order_Date__c = Date.today().addDays(-1),
            Status__c = 'Draft'
        );
        orders.add(order3);
        
        // Order 4: Emma's delivered order
        Order__c order4 = new Order__c(
            Customer__c = customers[3].Id, // Emma Wilson
            Order_Date__c = Date.today().addDays(-10),
            Status__c = 'Delivered'
        );
        orders.add(order4);
        
        // Order 5: David's recent order
        Order__c order5 = new Order__c(
            Customer__c = customers[4].Id, // David Brown
            Order_Date__c = Date.today(),
            Status__c = 'Confirmed'
        );
        orders.add(order5);
        
        // Insert orders first
        insert orders;
        
        // Create order items for each order
        
        // Order 1 Items: John's big purchase
        allOrderItems.addAll(new List<Order_Item__c>{
            new Order_Item__c(
                Order__c = orders[0].Id,
                Product__c = products[0].Id, // iPhone 15 Pro
                Quantity__c = 1,
                Unit_Price__c = products[0].Price__c
            ),
            new Order_Item__c(
                Order__c = orders[0].Id,
                Product__c = products[2].Id, // AirPods Pro
                Quantity__c = 1,
                Unit_Price__c = products[2].Price__c
            ),
            new Order_Item__c(
                Order__c = orders[0].Id,
                Product__c = products[8].Id, // iPhone Case
                Quantity__c = 1,
                Unit_Price__c = products[8].Price__c
            )
        });
        
        // Order 2 Items: Sarah's MacBook
        allOrderItems.add(new Order_Item__c(
            Order__c = orders[1].Id,
            Product__c = products[1].Id, // MacBook Pro
            Quantity__c = 1,
            Unit_Price__c = products[1].Price__c
        ));
        
        // Order 3 Items: Mike's accessories
        allOrderItems.addAll(new List<Order_Item__c>{
            new Order_Item__c(
                Order__c = orders[2].Id,
                Product__c = products[5].Id, // Magic Mouse
                Quantity__c = 1,
                Unit_Price__c = products[5].Price__c
            ),
            new Order_Item__c(
                Order__c = orders[2].Id,
                Product__c = products[6].Id, // Magic Keyboard
                Quantity__c = 1,
                Unit_Price__c = products[6].Price__c
            )
        });
        
        // Order 4 Items: Emma's iPad setup
        allOrderItems.addAll(new List<Order_Item__c>{
            new Order_Item__c(
                Order__c = orders[3].Id,
                Product__c = products[3].Id, // iPad Air
                Quantity__c = 1,
                Unit_Price__c = products[3].Price__c
            ),
            new Order_Item__c(
                Order__c = orders[3].Id,
                Product__c = products[7].Id, // AirTag 4-Pack
                Quantity__c = 1,
                Unit_Price__c = products[7].Price__c
            )
        });
        
        // Order 5 Items: David's watch
        allOrderItems.add(new Order_Item__c(
            Order__c = orders[4].Id,
            Product__c = products[4].Id, // Apple Watch
            Quantity__c = 1,
            Unit_Price__c = products[4].Price__c
        ));
        
        // Insert all order items (triggers will calculate totals automatically!)
        insert allOrderItems;
        
        System.debug('✅ Created ' + orders.size() + ' orders with ' + allOrderItems.size() + ' items');
        System.debug('🔄 Order totals will be calculated automatically by triggers');
        
        return orders;
    }
    
    /**
     * Clean up all sample data (for testing purposes)
     * @return Summary of deleted records
     */
    @AuraEnabled
    public static String deleteAllSampleData() {
        
        try {
            System.debug('🗑️ Cleaning up sample data...');
            
            // Delete in reverse order due to relationships
            Integer deletedOrderItems = 0;
            Integer deletedOrders = 0;
            Integer deletedProducts = 0;
            Integer deletedContacts = 0;
            
            // Delete order items first
            List<Order_Item__c> orderItems = [SELECT Id FROM Order_Item__c];
            if (!orderItems.isEmpty()) {
                delete orderItems;
                deletedOrderItems = orderItems.size();
            }
            
            // Delete orders
            List<Order__c> orders = [SELECT Id FROM Order__c];
            if (!orders.isEmpty()) {
                delete orders;
                deletedOrders = orders.size();
            }
            
            // Delete products
            List<Product__c> products = [SELECT Id FROM Product__c];
            if (!products.isEmpty()) {
                delete products;
                deletedProducts = products.size();
            }
            
            // Delete contacts
            List<Contact> contacts = [SELECT Id FROM Contact];
            if (!contacts.isEmpty()) {
                delete contacts;
                deletedContacts = contacts.size();
            }
            
            String summary = 'Successfully deleted sample data:\n' +
                           '🗑️ ' + deletedOrderItems + ' order items\n' +
                           '🗑️ ' + deletedOrders + ' orders\n' +
                           '🗑️ ' + deletedProducts + ' products\n' +
                           '🗑️ ' + deletedContacts + ' contacts\n';
            
            System.debug('✅ Sample data cleanup completed');
            return summary;
            
        } catch (Exception e) {
            System.debug('❌ Error deleting sample data: ' + e.getMessage());
            return 'Error deleting sample data: ' + e.getMessage();
        }
    }
    
    /**
     * Get system status and data counts
     * @return Current data summary
     */
    @AuraEnabled
    public static String getSystemStatus() {
        
        Integer productCount = [SELECT COUNT() FROM Product__c];
        Integer customerCount = [SELECT COUNT() FROM Contact];
        Integer orderCount = [SELECT COUNT() FROM Order__c];
        Integer orderItemCount = [SELECT COUNT() FROM Order_Item__c];
        
        // Get order status breakdown
        List<AggregateResult> statusCounts = [
            SELECT Status__c, COUNT(Id) orderCount
            FROM Order__c 
            GROUP BY Status__c
        ];
        
        String statusBreakdown = '';
        for (AggregateResult result : statusCounts) {
            statusBreakdown += '\n   • ' + result.get('Status__c') + ': ' + result.get('orderCount');
        }
        
        return 'System Status:\n' +
               '📦 Products: ' + productCount + '\n' +
               '👥 Customers: ' + customerCount + '\n' +
               '📋 Orders: ' + orderCount + statusBreakdown + '\n' +
               '📄 Order Items: ' + orderItemCount + '\n' +
               '\nSystem is ready for use!';
    }
}