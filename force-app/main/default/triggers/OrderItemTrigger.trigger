/**
 * OrderItemTrigger - Automatically runs when Order Items change
 * This trigger watches for changes and calls our handler to do the work
 */
trigger OrderItemTrigger on Order_Item__c (before insert, before update, after insert, after update, after delete) {
    
    System.debug('🚀 OrderItemTrigger FIRED!');
    System.debug('Context: Insert=' + Trigger.isInsert + 
                 ', Update=' + Trigger.isUpdate + 
                 ', Delete=' + Trigger.isDelete +
                 ', Before=' + Trigger.isBefore +
                 ', After=' + Trigger.isAfter);
    
    // BEFORE events - for validation (before data is saved)
    if(Trigger.isBefore) {
        
        if(Trigger.isInsert) {
            System.debug('📋 BEFORE INSERT: Validating ' + Trigger.new.size() + ' new items');
            OrderTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        
        if(Trigger.isUpdate) {
            System.debug('📋 BEFORE UPDATE: Validating ' + Trigger.new.size() + ' updated items');
            OrderTriggerHandler.handleBeforeUpdate(Trigger.new);
        }
    }
    
    // AFTER events - for calculations (after data is saved)
    if(Trigger.isAfter) {
        
        if(Trigger.isInsert) {
            System.debug('✨ AFTER INSERT: Processing ' + Trigger.new.size() + ' new items');
            OrderTriggerHandler.handleAfterInsert(Trigger.new);
        }
        
        if(Trigger.isUpdate) {
            System.debug('✨ AFTER UPDATE: Processing ' + Trigger.new.size() + ' updated items');
            OrderTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.old);
        }
        
        if(Trigger.isDelete) {
            System.debug('✨ AFTER DELETE: Processing ' + Trigger.old.size() + ' deleted items');
            OrderTriggerHandler.handleAfterDelete(Trigger.old);
        }
    }
    
    System.debug('✅ OrderItemTrigger COMPLETED!');
}