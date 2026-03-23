public with sharing class ContactAddressValidation {
    /**
     * @description Legacy single record validation (used by LWC)
     * Now internally uses bulk logic for consistency.
     */
    @AuraEnabled
    public static Contact validateAddress(Id recordId) {
        List<Contact> result = validateAddressesBulk(new List<Id>{
                recordId
        });
        return result.isEmpty() ? null : result[0];
    }

    @AuraEnabled
    public static List<Contact> validateAddressesBulk(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) return new List<Contact>();

        // Check if already in Async context to prevent System.AsyncException
        Boolean isAsync = System.isQueueable() || System.isBatch() || System.isFuture();
        if (recordIds.size() > 100 && !isAsync) {
            System.enqueueJob(new AddressValidationQueueable(recordIds));
            return [SELECT Id, AddressValid__c FROM Contact WHERE Id IN :recordIds WITH SECURITY_ENFORCED];
        }

        return performBulkValidation(recordIds);
    }

    public static List<Contact> performBulkValidation(List<Id> recordIds) {
        Map<Id, Contact> contactMap = new Map<Id, Contact>([
                SELECT Id, MailingStreet, MailingPostalCode, MailingCity,
                        MailingCountry, MailingState, AddressValid__c
                FROM Contact
                WHERE Id IN :recordIds
                WITH SECURITY_ENFORCED
        ]);

        List<Contact> usContacts = new List<Contact>();
        List<Contact> intlContacts = new List<Contact>();
        List<Contact> toUpdate = new List<Contact>();

        for (Contact c : contactMap.values()) {
            String country = String.isBlank(c.MailingCountry) ? '' : c.MailingCountry.toUpperCase().trim();
            if (country == 'US' || country == 'USA') {
                usContacts.add(c);
            } else {
                intlContacts.add(c);
            }
        }

        // Process US (Bulk)
        if (!usContacts.isEmpty()) {
            Map<Id, Boolean> usResults = AddressValidationCalloutService.validateAddressUSBulk(usContacts);
            for (Contact c : usContacts) {
                Boolean isValid = usResults.get(c.Id) == true;
                if (c.AddressValid__c != isValid) {
                    c.AddressValid__c = isValid;
                    toUpdate.add(c);
                }
            }
        }

        // Process International (Single Loop)
        for (Contact c : intlContacts) {
            if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
                System.debug(LoggingLevel.WARN, 'Max callouts reached. Skipping remaining international addresses.');
                break;
            }

            Boolean isValid = AddressValidationCalloutService.validateAddressITL(
                    c.MailingStreet, c.MailingPostalCode, c.MailingCountry
            );
            if (c.AddressValid__c != isValid) {
                c.AddressValid__c = isValid;
                toUpdate.add(c);
            }
        }

        if (!toUpdate.isEmpty()) {
            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, toUpdate);
            Database.update(securityDecision.getRecords(), false);
        }

        return contactMap.values();
    }

}