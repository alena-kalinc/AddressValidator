public class ContactAddressValidation {
    @AuraEnabled
    public static Contact validateAddress(Id recordId) {
        Contact contact = getContact(recordId);
        Boolean isValid = false;
        String country = contact.MailingCountry;
        if(country=='US') {
            isValid = AddressValidationCalloutService.validateAddressUS(contact.MailingStreet, contact.MailingCity, contact.MailingState);
        } else {
            isValid = AddressValidationCalloutService.validateAddressITL(contact.MailingStreet, contact.MailingPostalCode, contact.MailingCountry);
        }
        if(contact.AddressValid__c != isValid) {
            contact.AddressValid__c = isValid;
            update contact;
        }        
        return contact;
    }
    
    private static Contact getContact(Id recordId) {        
        return [SELECT Id, Name, MailingStreet, MailingPostalCode, MailingCity, MailingCountry, MailingState, AddressValid__c FROM Contact WHERE Id = :recordId];
    }
}