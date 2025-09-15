/**
 * OrderAPI - REST API for External Systems
 * 
 * This class creates REST endpoints that external systems can call
 * to interact with your Salesforce order data
 * 
 * Base URL: https://yourinstance.salesforce.com/services/apexrest/orders/
 */
@RestResource(urlMapping='/orders/*')
global with sharing class OrderAPI {
    
    /**
     * GET /services/apexrest/orders/
     * Get list of orders with optional filtering
     * 
     * Example URLs:
     * - GET /orders/ (all orders)
     * - GET /orders/?status=Confirmed (orders with specific status)
     * - GET /orders/?limit=10 (limit results)
     */
    @HttpGet
    global static OrderResponse getOrders() {
        
        try {
            System.debug('🔍 OrderAPI: GET request received');
            
            // Get URL parameters
            RestRequest request = RestContext.request;
            String status = request.params.get('status');
            String limitParam = request.params.get('limit');
            String customerEmail = request.params.get('customer');
            
            System.debug('Parameters - Status: ' + status + ', Limit: ' + limitParam + ', Customer: ' + customerEmail);
            
            // Build dynamic query
            String query = 'SELECT Id, Name, Customer__r.Name, Customer__r.Email, ' +
                          'Order_Date__c, Status__c, Total_Amount__c, Shipping_Cost__c, ' +
                          'Tracking_Number__c, CreatedDate ' +
                          'FROM Order__c';
            
            List<String> conditions = new List<String>();
            
            // Add status filter
            if (String.isNotBlank(status)) {
                conditions.add('Status__c = \'' + String.escapeSingleQuotes(status) + '\'');
            }
            
            // Add customer filter
            if (String.isNotBlank(customerEmail)) {
                conditions.add('Customer__r.Email = \'' + String.escapeSingleQuotes(customerEmail) + '\'');
            }
            
            // Add WHERE clause if we have conditions
            if (!conditions.isEmpty()) {
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }
            
            // Add ORDER BY and LIMIT
            query += ' ORDER BY CreatedDate DESC';
            
            Integer limitValue = 50; // Default limit
            if (String.isNotBlank(limitParam)) {
                try {
                    limitValue = Integer.valueOf(limitParam);
                    limitValue = Math.min(limitValue, 200); // Max 200 records
                } catch (Exception e) {
                    limitValue = 50;
                }
            }
            
            query += ' LIMIT ' + limitValue;
            
            System.debug('🔍 Final query: ' + query);
            
            // Execute query
            List<Order__c> orders = Database.query(query);
            
            System.debug('📦 Found ' + orders.size() + ' orders');
            
            // Convert to API response format
            List<OrderData> orderList = new List<OrderData>();
            for (Order__c order : orders) {
                orderList.add(new OrderData(order));
            }
            
            return new OrderResponse(true, 'Success', orderList, orders.size());
            
        } catch (Exception e) {
            System.debug('❌ Error in getOrders: ' + e.getMessage());
            return new OrderResponse(false, 'Error: ' + e.getMessage(), null, 0);
        }
    }
    
    /**
     * GET /services/apexrest/orders/{orderId}
     * Get specific order with items
     */
    @HttpGet
    global static OrderDetailResponse getOrderById() {
        
        try {
            // Extract order ID from URL
            String requestURI = RestContext.request.requestURI;
            String orderId = requestURI.substring(requestURI.lastIndexOf('/') + 1);
            
            System.debug('🔍 Getting order details for: ' + orderId);
            
            // Query order with items
            Order__c order = [
                SELECT Id, Name, Customer__r.Name, Customer__r.Email,
                       Order_Date__c, Status__c, Total_Amount__c, Shipping_Cost__c,
                       Tracking_Number__c, CreatedDate,
                       (SELECT Id, Product__r.Name, Product__r.Price__c,
                               Quantity__c, Unit_Price__c, Line_Total__c
                        FROM Order_Items__r)
                FROM Order__c 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // Convert order items
            List<OrderItemData> items = new List<OrderItemData>();
            for (Order_Item__c item : order.Order_Items__r) {
                items.add(new OrderItemData(item));
            }
            
            OrderDetailData orderDetail = new OrderDetailData(order, items);
            
            return new OrderDetailResponse(true, 'Success', orderDetail);
            
        } catch (QueryException e) {
            System.debug('❌ Order not found');
            return new OrderDetailResponse(false, 'Order not found', null);
            
        } catch (Exception e) {
            System.debug('❌ Error getting order: ' + e.getMessage());
            return new OrderDetailResponse(false, 'Error: ' + e.getMessage(), null);
        }
    }
    
    /**
     * POST /services/apexrest/orders/
     * Create new order
     * 
     * Request Body Example:
     * {
     *   "customerEmail": "john@example.com",
     *   "items": [
     *     {
     *       "productId": "a03xx000000001",
     *       "quantity": 2,
     *       "unitPrice": 99.99
     *     }
     *   ]
     * }
     */
    @HttpPost
    global static OrderCreateResponse createOrder() {
        
        try {
            System.debug('📝 OrderAPI: POST request received');
            
            // Parse request body
            String requestBody = RestContext.request.requestBody.toString();
            System.debug('📝 Request body: ' + requestBody);
            
            CreateOrderRequest orderRequest = (CreateOrderRequest) JSON.deserialize(requestBody, CreateOrderRequest.class);
            
            // Validate request
            if (String.isBlank(orderRequest.customerEmail)) {
                return new OrderCreateResponse(false, 'Customer email is required', null);
            }
            
            if (orderRequest.items == null || orderRequest.items.isEmpty()) {
                return new OrderCreateResponse(false, 'At least one order item is required', null);
            }
            
            // Find customer
            List<Contact> customers = [
                SELECT Id, Name, Email 
                FROM Contact 
                WHERE Email = :orderRequest.customerEmail 
                LIMIT 1
            ];
            
            if (customers.isEmpty()) {
                return new OrderCreateResponse(false, 'Customer not found with email: ' + orderRequest.customerEmail, null);
            }
            
            Contact customer = customers[0];
            
            // Create order
            Order__c newOrder = new Order__c(
                Customer__c = customer.Id,
                Order_Date__c = Date.today(),
                Status__c = 'Draft'
            );
            insert newOrder;
            
            System.debug('✅ Created order: ' + newOrder.Id);
            
            // Create order items
            List<Order_Item__c> orderItems = new List<Order_Item__c>();
            
            for (CreateOrderItemRequest itemRequest : orderRequest.items) {
                // Validate product exists and is active
                List<Product__c> products = [
                    SELECT Id, Name, Price__c, Stock_Quantity__c, Is_Active__c
                    FROM Product__c 
                    WHERE Id = :itemRequest.productId 
                    AND Is_Active__c = true
                    LIMIT 1
                ];
                
                if (products.isEmpty()) {
                    delete newOrder; // Rollback
                    return new OrderCreateResponse(false, 'Product not found or inactive: ' + itemRequest.productId, null);
                }
                
                Product__c product = products[0];
                
                // Check stock
                if (itemRequest.quantity > product.Stock_Quantity__c) {
                    delete newOrder; // Rollback
                    return new OrderCreateResponse(false, 'Insufficient stock for product: ' + product.Name + 
                                                  '. Available: ' + product.Stock_Quantity__c + 
                                                  ', Requested: ' + itemRequest.quantity, null);
                }
                
                // Create order item
                orderItems.add(new Order_Item__c(
                    Order__c = newOrder.Id,
                    Product__c = itemRequest.productId,
                    Quantity__c = itemRequest.quantity,
                    Unit_Price__c = itemRequest.unitPrice != null ? itemRequest.unitPrice : product.Price__c
                ));
            }
            
            // Insert order items (triggers will calculate totals)
            insert orderItems;
            
            // Get updated order with calculated total
            Order__c updatedOrder = [
                SELECT Id, Name, Total_Amount__c, Status__c
                FROM Order__c 
                WHERE Id = :newOrder.Id
            ];
            
            System.debug('✅ Created order with ' + orderItems.size() + ' items. Total: $' + updatedOrder.Total_Amount__c);
            
            return new OrderCreateResponse(true, 'Order created successfully', updatedOrder.Id);
            
        } catch (Exception e) {
            System.debug('❌ Error creating order: ' + e.getMessage());
            return new OrderCreateResponse(false, 'Error creating order: ' + e.getMessage(), null);
        }
    }
    
    /**
     * PUT /services/apexrest/orders/{orderId}
     * Update order status
     */
    @HttpPut
    global static OrderUpdateResponse updateOrder() {
        
        try {
            // Extract order ID from URL
            String requestURI = RestContext.request.requestURI;
            String orderId = requestURI.substring(requestURI.lastIndexOf('/') + 1);
            
            System.debug('📝 Updating order: ' + orderId);
            
            // Parse request body
            String requestBody = RestContext.request.requestBody.toString();
            UpdateOrderRequest updateRequest = (UpdateOrderRequest) JSON.deserialize(requestBody, UpdateOrderRequest.class);
            
            // Update order
            Order__c orderToUpdate = new Order__c(Id = orderId);
            
            if (String.isNotBlank(updateRequest.status)) {
                orderToUpdate.Status__c = updateRequest.status;
            }
            
            if (String.isNotBlank(updateRequest.trackingNumber)) {
                orderToUpdate.Tracking_Number__c = updateRequest.trackingNumber;
            }
            
            update orderToUpdate;
            
            System.debug('✅ Updated order: ' + orderId);
            
            return new OrderUpdateResponse(true, 'Order updated successfully');
            
        } catch (Exception e) {
            System.debug('❌ Error updating order: ' + e.getMessage());
            return new OrderUpdateResponse(false, 'Error updating order: ' + e.getMessage());
        }
    }
    
    /**
     * Data Transfer Objects (DTOs) for API Responses
     */
    
    // Main order list response
    global class OrderResponse {
        global Boolean success { get; set; }
        global String message { get; set; }
        global List<OrderData> orders { get; set; }
        global Integer totalCount { get; set; }
        
        global OrderResponse(Boolean success, String message, List<OrderData> orders, Integer totalCount) {
            this.success = success;
            this.message = message;
            this.orders = orders;
            this.totalCount = totalCount;
        }
    }
    
    // Individual order data
    global class OrderData {
        global String orderId { get; set; }
        global String orderNumber { get; set; }
        global String customerName { get; set; }
        global String customerEmail { get; set; }
        global Date orderDate { get; set; }
        global String status { get; set; }
        global Decimal totalAmount { get; set; }
        global Decimal shippingCost { get; set; }
        global String trackingNumber { get; set; }
        global DateTime createdDate { get; set; }
        
        global OrderData(Order__c order) {
            this.orderId = order.Id;
            this.orderNumber = order.Name;
            this.customerName = order.Customer__r.Name;
            this.customerEmail = order.Customer__r.Email;
            this.orderDate = order.Order_Date__c;
            this.status = order.Status__c;
            this.totalAmount = order.Total_Amount__c;
            this.shippingCost = order.Shipping_Cost__c;
            this.trackingNumber = order.Tracking_Number__c;
            this.createdDate = order.CreatedDate;
        }
    }
    
    // Order detail response with items
    global class OrderDetailResponse {
        global Boolean success { get; set; }
        global String message { get; set; }
        global OrderDetailData order { get; set; }
        
        global OrderDetailResponse(Boolean success, String message, OrderDetailData order) {
            this.success = success;
            this.message = message;
            this.order = order;
        }
    }
    
    // Detailed order data with items
    global class OrderDetailData {
        global String orderId { get; set; }
        global String orderNumber { get; set; }
        global String customerName { get; set; }
        global String customerEmail { get; set; }
        global Date orderDate { get; set; }
        global String status { get; set; }
        global Decimal totalAmount { get; set; }
        global Decimal shippingCost { get; set; }
        global String trackingNumber { get; set; }
        global List<OrderItemData> items { get; set; }
        
        global OrderDetailData(Order__c order, List<OrderItemData> items) {
            this.orderId = order.Id;
            this.orderNumber = order.Name;
            this.customerName = order.Customer__r.Name;
            this.customerEmail = order.Customer__r.Email;
            this.orderDate = order.Order_Date__c;
            this.status = order.Status__c;
            this.totalAmount = order.Total_Amount__c;
            this.shippingCost = order.Shipping_Cost__c;
            this.trackingNumber = order.Tracking_Number__c;
            this.items = items;
        }
    }
    
    // Order item data
    global class OrderItemData {
        global String itemId { get; set; }
        global String productName { get; set; }
        global Decimal productPrice { get; set; }
        global Decimal quantity { get; set; }
        global Decimal unitPrice { get; set; }
        global Decimal lineTotal { get; set; }
        
        global OrderItemData(Order_Item__c item) {
            this.itemId = item.Id;
            this.productName = item.Product__r.Name;
            this.productPrice = item.Product__r.Price__c;
            this.quantity = item.Quantity__c;
            this.unitPrice = item.Unit_Price__c;
            this.lineTotal = item.Line_Total__c;
        }
    }
    
    // Create order request
    global class CreateOrderRequest {
        global String customerEmail { get; set; }
        global List<CreateOrderItemRequest> items { get; set; }
    }
    
    // Create order item request
    global class CreateOrderItemRequest {
        global String productId { get; set; }
        global Decimal quantity { get; set; }
        global Decimal unitPrice { get; set; }
    }
    
    // Create order response
    global class OrderCreateResponse {
        global Boolean success { get; set; }
        global String message { get; set; }
        global String orderId { get; set; }
        
        global OrderCreateResponse(Boolean success, String message, String orderId) {
            this.success = success;
            this.message = message;
            this.orderId = orderId;
        }
    }
    
    // Update order request
    global class UpdateOrderRequest {
        global String status { get; set; }
        global String trackingNumber { get; set; }
    }
    
    // Update order response
    global class OrderUpdateResponse {
        global Boolean success { get; set; }
        global String message { get; set; }
        
        global OrderUpdateResponse(Boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }
}