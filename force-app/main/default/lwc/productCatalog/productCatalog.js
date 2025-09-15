// Import LWC framework components
import { LightningElement, track, wire } from 'lwc';

// Import Apex methods (our server-side functions)
import getProducts from '@salesforce/apex/ProductController.getProducts';

// Import Lightning platform utilities
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * Product Catalog Lightning Web Component
 * Shows products in a grid with search, filtering, and add to cart functionality
 */
export default class ProductCatalog extends LightningElement {
    
    // Reactive properties - when these change, UI updates automatically
    @track products = [];              // Array of product records
    @track searchTerm = '';            // Current search term
    @track showInStockOnly = true;     // Filter for in-stock products only
    @track isLoading = false;          // Show/hide loading spinner
    @track error = null;               // Error message if something goes wrong
    @track cartItems = [];             // Items added to cart
    @track quantities = {};            // Track quantity for each product
    
    /**
     * Wire service - automatically calls Apex method when parameters change
     * This creates a live connection between UI and server
     */
    @wire(getProducts, { 
        searchTerm: '$searchTerm', 
        inStockOnly: '$showInStockOnly' 
    })
    wiredProducts({ error, data }) {
        this.isLoading = false;
        
        if (data) {
            console.log('📦 Received products:', data);
            
            // Process the product data
            this.products = data.map(product => ({
                ...product,  // Keep all existing product properties
                hasStock: product.Stock_Quantity__c > 0,
                isOutOfStock: product.Stock_Quantity__c <= 0
            }));
            
            this.error = null;
            console.log('✅ Processed products:', this.products);
            
        } else if (error) {
            this.error = error.body ? error.body.message : 'Unknown error occurred';
            this.products = [];
            console.error('❌ Error loading products:', error);
        }
    }
    
    /**
     * Computed Properties - calculated values based on other properties
     */
    
    // Check if we have products to display
    get hasProducts() {
        return this.products && this.products.length > 0;
    }
    
    // Check if we should show "no products" message
    get showNoProducts() {
        return !this.isLoading && !this.error && !this.hasProducts;
    }
    
    // Check if cart has items
    get hasCartItems() {
        return this.cartItems && this.cartItems.length > 0;
    }
    
    // Count total items in cart
    get cartItemCount() {
        return this.cartItems.reduce((total, item) => total + item.quantity, 0);
    }
    
    // Calculate total cart value
    get cartTotal() {
        return this.cartItems.reduce((total, item) => total + (item.quantity * item.unitPrice), 0);
    }
    
    /**
     * Event Handlers - respond to user interactions
     */
    
    /**
     * Handle search input changes with debouncing
     * Waits 300ms after user stops typing before searching
     */
    handleSearch(event) {
        console.log('🔍 Search term changed:', event.target.value);
        
        // Clear previous timeout
        clearTimeout(this.searchTimeout);
        
        // Set new timeout to avoid too many server calls
        this.searchTimeout = setTimeout(() => {
            this.searchTerm = event.target.value;
            this.isLoading = true;
            console.log('🔍 Searching for:', this.searchTerm);
        }, 300); // Wait 300ms after user stops typing
    }
    
    /**
     * Handle stock filter checkbox change
     */
    handleStockFilter(event) {
        this.showInStockOnly = event.target.checked;
        this.isLoading = true;
        console.log('📦 Stock filter changed:', this.showInStockOnly);
    }
    
    /**
     * Handle refresh button click
     */
    handleRefresh() {
        console.log('🔄 Refreshing products...');
        this.isLoading = true;
        this.error = null;
        
        // Reset search and filters
        this.searchTerm = '';
        this.showInStockOnly = true;
        
        // Clear search input
        const searchInput = this.template.querySelector('lightning-input[type="search"]');
        if (searchInput) {
            searchInput.value = '';
        }
    }
    
    /**
     * Handle quantity input changes
     */
    handleQuantityChange(event) {
        const productId = event.target.dataset.productId;
        const quantity = parseInt(event.target.value, 10);
        
        console.log('🔢 Quantity changed for product', productId, ':', quantity);
        
        // Store quantity for this product
        this.quantities = {
            ...this.quantities,
            [productId]: quantity
        };
    }
    
    /**
     * Handle Add to Cart button click
     */
    handleAddToCart(event) {
        const productId = event.target.dataset.productId;
        
        console.log('🛒 Add to cart clicked for product:', productId);
        
        // Find the product
        const product = this.products.find(p => p.Id === productId);
        if (!product) {
            this.showToast('Error', 'Product not found', 'error');
            return;
        }
        
        // Get quantity (default to 1 if not set)
        const quantity = this.quantities[productId] || 1;
        
        // Validate quantity
        if (quantity <= 0) {
            this.showToast('Invalid Quantity', 'Quantity must be greater than 0', 'warning');
            return;
        }
        
        // Check stock availability
        if (quantity > product.Stock_Quantity__c) {
            this.showToast(
                'Insufficient Stock', 
                `Only ${product.Stock_Quantity__c} items available`, 
                'warning'
            );
            return;
        }
        
        // Add to cart
        this.addToCart(product, quantity);
        
        // Show success message
        this.showToast(
            'Added to Cart! 🎉', 
            `${quantity} x ${product.Name} added to cart`, 
            'success'
        );
        
        // Reset quantity input to 1
        const quantityInput = this.template.querySelector(`lightning-input[data-product-id="${productId}"]`);
        if (quantityInput) {
            quantityInput.value = 1;
            this.quantities[productId] = 1;
        }
        
        console.log('🛒 Cart updated:', this.cartItems);
    }
    
    /**
     * Handle View Cart button click
     */
    handleViewCart() {
        console.log('👀 View cart clicked');
        
        // Create custom event to notify parent components
        this.dispatchEvent(new CustomEvent('viewcart', {
            detail: {
                cartItems: this.cartItems,
                totalItems: this.cartItemCount,
                totalValue: this.cartTotal
            }
        }));
        
        // For now, show cart items in console
        console.log('🛒 Current cart:', this.cartItems);
        
        this.showToast(
            'Cart Contents', 
            `${this.cartItemCount} items worth $${this.cartTotal.toFixed(2)}`, 
            'info'
        );
    }
    
    /**
     * Handle Checkout button click
     */
    handleCheckout() {
        console.log('💳 Checkout clicked');
        
        if (this.cartItems.length === 0) {
            this.showToast('Empty Cart', 'Add some products to your cart first!', 'warning');
            return;
        }
        
        // Dispatch checkout event
        this.dispatchEvent(new CustomEvent('checkout', {
            detail: {
                cartItems: this.cartItems,
                totalItems: this.cartItemCount,
                totalValue: this.cartTotal
            }
        }));
        
        this.showToast(
            'Checkout Started! 🚀', 
            'Proceeding to checkout...', 
            'success'
        );
    }
    
    /**
     * Helper Methods
     */
    
    /**
     * Add item to cart or update existing item
     */
    addToCart(product, quantity) {
        // Check if product already in cart
        const existingItemIndex = this.cartItems.findIndex(item => item.productId === product.Id);
        
        if (existingItemIndex >= 0) {
            // Update existing item
            const updatedCartItems = [...this.cartItems];
            updatedCartItems[existingItemIndex].quantity += quantity;
            updatedCartItems[existingItemIndex].lineTotal = 
                updatedCartItems[existingItemIndex].quantity * updatedCartItems[existingItemIndex].unitPrice;
            this.cartItems = updatedCartItems;
            
        } else {
            // Add new item
            this.cartItems = [...this.cartItems, {
                productId: product.Id,
                productName: product.Name,
                quantity: quantity,
                unitPrice: product.Price__c,
                lineTotal: quantity * product.Price__c
            }];
        }
    }
    
    /**
     * Show toast notification to user
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, // success, error, warning, info
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
    
    /**
     * Component Lifecycle Hooks
     */
    
    /**
     * Called when component is inserted into DOM
     */
    connectedCallback() {
        console.log('🚀 Product Catalog component loaded');
        this.isLoading = true;
    }
    
    /**
     * Called when component is removed from DOM
     */
    disconnectedCallback() {
        console.log('👋 Product Catalog component unloaded');
        
        // Clean up any timers
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }
    }
}