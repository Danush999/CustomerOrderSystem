/**
 * ShippingService - Integration with External Shipping Provider
 * 
 * This class demonstrates how to integrate Salesforce with external APIs
 * In this example, we're connecting to a fictional shipping provider
 * to calculate rates and create shipping labels
 */
public class ShippingService {
    
    // API Configuration - In production, store these in Custom Settings or Named Credentials
    private static final String API_BASE_URL = 'https://api.shippingprovider.com/v1';
    private static final String API_KEY = 'demo_key_12345'; // In real app, use secure storage
    
    /**
     * Calculate shipping rates for an order (Asynchronous)
     * @param orderId - ID of the order to calculate shipping for
     * 
     * @future(callout=true) allows this method to make HTTP calls to external systems
     * and run asynchronously so it doesn't slow down the user interface
     */
    @future(callout=true)
    public static void calculateShippingRatesAsync(Id orderId) {
        
        System.debug('📦 Calculating shipping rates for order: ' + orderId);
        
        try {
            // Get order details including customer address
            Order__c order = getOrderWithCustomerDetails(orderId);
            
            // Calculate package weight and dimensions
            PackageInfo packageInfo = calculatePackageInfo(orderId);
            
            // Call external shipping API
            List<ShippingRate> rates = getShippingRatesFromAPI(order, packageInfo);
            
            // Update order with the best rate
            updateOrderWithShippingInfo(orderId, rates);
            
            System.debug('✅ Successfully calculated shipping for order: ' + orderId);
            
        } catch (Exception e) {
            System.debug('❌ Error calculating shipping: ' + e.getMessage());
            
            // Create a case for manual review
            createShippingErrorCase(orderId, e.getMessage());
        }
    }
    
    /**
     * Get shipping rates synchronously (for immediate display)
     * @param customerAddress - Shipping destination
     * @param weight - Package weight in pounds
     * @param value - Package value for insurance
     * @return List of available shipping options
     */
    public static List<ShippingRate> getShippingRates(String customerAddress, Decimal weight, Decimal value) {
        
        System.debug('📦 Getting shipping rates for: ' + customerAddress);
        
        try {
            // Prepare API request
            Map<String, Object> requestBody = new Map<String, Object>{
                'destination' => customerAddress,
                'weight' => weight,
                'value' => value,
                'service_types' => new List<String>{'standard', 'express', 'overnight'}
            };
            
            // Make API call
            HttpResponse response = makeShippingAPICall('POST', '/rates', requestBody);
            
            // Parse response
            if (response.getStatusCode() == 200) {
                return parseShippingRatesResponse(response.getBody());
            } else {
                System.debug('❌ API Error: ' + response.getStatusCode() + ' - ' + response.getBody());
                return getDefaultShippingRates(); // Fallback to default rates
            }
            
        } catch (Exception e) {
            System.debug('❌ Error getting shipping rates: ' + e.getMessage());
            return getDefaultShippingRates(); // Always return something
        }
    }
    
    /**
     * Create a shipping label and tracking number
     * @param orderId - Order to ship
     * @param shippingOption - Selected shipping service (standard, express, overnight)
     * @return Shipment details including tracking number and label URL
     */
    public static ShipmentResult createShipment(Id orderId, String shippingOption) {
        
        System.debug('📦 Creating shipment for order: ' + orderId);
        
        try {
            // Get order and customer details
            Order__c order = getOrderWithCustomerDetails(orderId);
            
            // Calculate package details
            PackageInfo packageInfo = calculatePackageInfo(orderId);
            
            // Prepare shipment request
            Map<String, Object> shipmentRequest = new Map<String, Object>{
                'service_type' => shippingOption,
                'destination' => formatCustomerAddress(order),
                'package' => new Map<String, Object>{
                    'weight' => packageInfo.weight,
                    'length' => packageInfo.length,
                    'width' => packageInfo.width,
                    'height' => packageInfo.height,
                    'value' => order.Total_Amount__c,
                    'description' => 'Customer Order #' + order.Name
                }
            };
            
            // Create shipment via API
            HttpResponse response = makeShippingAPICall('POST', '/shipments', shipmentRequest);
            
            if (response.getStatusCode() == 201) {
                ShipmentResult result = parseShipmentResponse(response.getBody());
                
                // Update order with tracking information
                update new Order__c(
                    Id = orderId,
                    Status__c = 'Shipped',
                    Tracking_Number__c = result.trackingNumber,
                    Shipping_Cost__c = result.cost,
                    Shipping_Label_URL__c = result.labelUrl
                );
                
                System.debug('✅ Shipment created successfully: ' + result.trackingNumber);
                return result;
                
            } else {
                throw new CalloutException('Shipment creation failed: ' + response.getBody());
            }
            
        } catch (Exception e) {
            System.debug('❌ Error creating shipment: ' + e.getMessage());
            throw new AuraHandledException('Unable to create shipment: ' + e.getMessage());
        }
    }
    
    /**
     * Track a shipment using tracking number
     * @param trackingNumber - Tracking number to look up
     * @return Current shipment status and location
     */
    public static TrackingInfo trackShipment(String trackingNumber) {
        
        System.debug('🔍 Tracking shipment: ' + trackingNumber);
        
        try {
            // Make API call to tracking endpoint
            HttpResponse response = makeShippingAPICall('GET', '/track/' + trackingNumber, null);
            
            if (response.getStatusCode() == 200) {
                return parseTrackingResponse(response.getBody());
            } else {
                System.debug('❌ Tracking API error: ' + response.getStatusCode());
                return new TrackingInfo('Unknown', 'Unable to retrieve tracking information');
            }
            
        } catch (Exception e) {
            System.debug('❌ Error tracking shipment: ' + e.getMessage());
            return new TrackingInfo('Error', 'Tracking service temporarily unavailable');
        }
    }
    
    /**
     * Helper Methods for API Integration
     */
    
    /**
     * Make HTTP request to shipping API
     * @param method - HTTP method (GET, POST, PUT, DELETE)
     * @param endpoint - API endpoint path
     * @param requestBody - Request body for POST/PUT requests
     * @return HTTP response from the API
     */
    private static HttpResponse makeShippingAPICall(String method, String endpoint, Map<String, Object> requestBody) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Set request properties
        request.setEndpoint(API_BASE_URL + endpoint);
        request.setMethod(method);
        request.setHeader('Authorization', 'Bearer ' + API_KEY);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setTimeout(10000); // 10 second timeout
        
        // Add request body for POST/PUT requests
        if (requestBody != null && (method == 'POST' || method == 'PUT')) {
            request.setBody(JSON.serialize(requestBody));
            System.debug('📤 API Request: ' + method + ' ' + endpoint);
            System.debug('📤 Request Body: ' + JSON.serialize(requestBody));
        }
        
        // Make the callout
        HttpResponse response = http.send(request);
        
        System.debug('📥 API Response: ' + response.getStatusCode());
        System.debug('📥 Response Body: ' + response.getBody());
        
        return response;
    }
    
    /**
     * Get order with customer address details
     */
    private static Order__c getOrderWithCustomerDetails(Id orderId) {
        return [
            SELECT Id, Name, Total_Amount__c, Status__c,
                   Customer__r.Name, 
                   Customer__r.MailingStreet, 
                   Customer__r.MailingCity, 
                   Customer__r.MailingState, 
                   Customer__r.MailingPostalCode, 
                   Customer__r.MailingCountry
            FROM Order__c 
            WHERE Id = :orderId
        ];
    }
    
    /**
     * Calculate package information based on order items
     */
    private static PackageInfo calculatePackageInfo(Id orderId) {
        
        // Get order items
        List<Order_Item__c> items = [
            SELECT Quantity__c, Product__r.Name
            FROM Order_Item__c 
            WHERE Order__c = :orderId
        ];
        
        // Simple calculation - in real app, products would have weight/dimension fields
        Decimal totalWeight = 0;
        Decimal itemCount = 0;
        
        for (Order_Item__c item : items) {
            itemCount += item.Quantity__c;
            totalWeight += item.Quantity__c * 2.5; // Assume 2.5 lbs per item
        }
        
        // Calculate box dimensions based on item count
        Decimal length = Math.max(12, itemCount * 2);    // Minimum 12 inches
        Decimal width = Math.max(8, itemCount * 1.5);    // Minimum 8 inches  
        Decimal height = Math.max(4, itemCount * 1);     // Minimum 4 inches
        
        return new PackageInfo(totalWeight, length, width, height);
    }
    
    /**
     * Format customer address for API
     */
    private static Map<String, String> formatCustomerAddress(Order__c order) {
        return new Map<String, String>{
            'name' => order.Customer__r.Name,
            'street' => order.Customer__r.MailingStreet,
            'city' => order.Customer__r.MailingCity,
            'state' => order.Customer__r.MailingState,
            'zip' => order.Customer__r.MailingPostalCode,
            'country' => order.Customer__r.MailingCountry
        };
    }
    
    /**
     * Parse shipping rates from API response
     */
    private static List<ShippingRate> parseShippingRatesResponse(String responseBody) {
        List<ShippingRate> rates = new List<ShippingRate>();
        
        try {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> rateList = (List<Object>) response.get('rates');
            
            for (Object rateObj : rateList) {
                Map<String, Object> rate = (Map<String, Object>) rateObj;
                rates.add(new ShippingRate(
                    (String) rate.get('service_type'),
                    (String) rate.get('service_name'),
                    (Decimal) rate.get('cost'),
                    (Integer) rate.get('delivery_days')
                ));
            }
        } catch (Exception e) {
            System.debug('❌ Error parsing shipping rates: ' + e.getMessage());
        }
        
        return rates;
    }
    
    /**
     * Parse shipment creation response
     */
    private static ShipmentResult parseShipmentResponse(String responseBody) {
        try {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            return new ShipmentResult(
                (String) response.get('tracking_number'),
                (Decimal) response.get('cost'),
                (String) response.get('label_url'),
                (String) response.get('estimated_delivery')
            );
        } catch (Exception e) {
            System.debug('❌ Error parsing shipment response: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Parse tracking response
     */
    private static TrackingInfo parseTrackingResponse(String responseBody) {
        try {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            return new TrackingInfo(
                (String) response.get('status'),
                (String) response.get('description'),
                (String) response.get('last_update'),
                (String) response.get('location')
            );
        } catch (Exception e) {
            System.debug('❌ Error parsing tracking response: ' + e.getMessage());
            return new TrackingInfo('Error', 'Unable to parse tracking information');
        }
    }
    
    /**
     * Get default shipping rates when API is unavailable
     */
    private static List<ShippingRate> getDefaultShippingRates() {
        return new List<ShippingRate>{
            new ShippingRate('standard', 'Standard Shipping (5-7 days)', 9.99, 6),
            new ShippingRate('express', 'Express Shipping (2-3 days)', 19.99, 2),
            new ShippingRate('overnight', 'Overnight Shipping', 39.99, 1)
        };
    }
    
    /**
     * Update order with shipping information
     */
    private static void updateOrderWithShippingInfo(Id orderId, List<ShippingRate> rates) {
        if (rates != null && !rates.isEmpty()) {
            // Use the cheapest rate by default
            ShippingRate cheapestRate = rates[0];
            for (ShippingRate rate : rates) {
                if (rate.cost < cheapestRate.cost) {
                    cheapestRate = rate;
                }
            }
            
            update new Order__c(
                Id = orderId,
                Shipping_Cost__c = cheapestRate.cost,
                Estimated_Delivery_Days__c = cheapestRate.deliveryDays
            );
        }
    }
    
    /**
     * Create error case for shipping issues
     */
    private static void createShippingErrorCase(Id orderId, String errorMessage) {
        try {
            insert new Case(
                Subject = 'Shipping Calculation Error - Order ' + orderId,
                Description = 'Automatic shipping calculation failed: ' + errorMessage,
                Priority = 'Medium',
                Status = 'New',
                Origin = 'System'
            );
        } catch (Exception e) {
            System.debug('❌ Unable to create error case: ' + e.getMessage());
        }
    }
    
    /**
     * Wrapper Classes for API Data
     */
    
    // Shipping rate information
    public class ShippingRate {
        @AuraEnabled public String serviceType { get; set; }
        @AuraEnabled public String serviceName { get; set; }
        @AuraEnabled public Decimal cost { get; set; }
        @AuraEnabled public Integer deliveryDays { get; set; }
        
        public ShippingRate(String serviceType, String serviceName, Decimal cost, Integer deliveryDays) {
            this.serviceType = serviceType;
            this.serviceName = serviceName;
            this.cost = cost;
            this.deliveryDays = deliveryDays;
        }
    }
    
    // Shipment creation result
    public class ShipmentResult {
        @AuraEnabled public String trackingNumber { get; set; }
        @AuraEnabled public Decimal cost { get; set; }
        @AuraEnabled public String labelUrl { get; set; }
        @AuraEnabled public String estimatedDelivery { get; set; }
        
        public ShipmentResult(String trackingNumber, Decimal cost, String labelUrl, String estimatedDelivery) {
            this.trackingNumber = trackingNumber;
            this.cost = cost;
            this.labelUrl = labelUrl;
            this.estimatedDelivery = estimatedDelivery;
        }
    }
    
    // Package dimensions and weight
    public class PackageInfo {
        public Decimal weight { get; set; }
        public Decimal length { get; set; }
        public Decimal width { get; set; }
        public Decimal height { get; set; }
        
        public PackageInfo(Decimal weight, Decimal length, Decimal width, Decimal height) {
            this.weight = weight;
            this.length = length;
            this.width = width;
            this.height = height;
        }
    }
    
    // Tracking information
    public class TrackingInfo {
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String lastUpdate { get; set; }
        @AuraEnabled public String location { get; set; }
        
        public TrackingInfo(String status, String description) {
            this.status = status;
            this.description = description;
        }
        
        public TrackingInfo(String status, String description, String lastUpdate, String location) {
            this.status = status;
            this.description = description;
            this.lastUpdate = lastUpdate;
            this.location = location;
        }
    }
}