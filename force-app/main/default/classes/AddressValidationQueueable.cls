public with sharing class AddressValidationQueueable
        implements Queueable, Database.AllowsCallouts {

    private List<Id> recordIds;

    public AddressValidationQueueable(List<Id> recordIds){
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext ctx){
        if (this.recordIds == null || this.recordIds.isEmpty()) return;

        // Directly call the processing logic to avoid enqueue loop
        ContactAddressValidation.performBulkValidation(this.recordIds);
    }

}