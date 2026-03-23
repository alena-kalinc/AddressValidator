@IsTest
public class TestContactAddressValidation {
	@IsTest
    public static void testValidAddressUS() {
        Contact contact = new Contact(LastName='Doe', FirstName='Joe', MailingStreet='1428 Post Aly', MailingCity='Seattle', MailingPostalCode='98101', MailingCountry='US', MailingState='WA');
        insert contact;
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockValidAddressUS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        contact = ContactAddressValidation.validateAddress(contact.Id);
        Test.stopTest();
        
        Assert.areEqual(true, contact.AddressValid__c);
    }
    
    @IsTest
    public static void testValidAddressITL() {
        Contact contact = new Contact(LastName='Doe', FirstName='John', MailingStreet='De Bleek 7', MailingCity='Woerden', MailingPostalCode='3447 GV', MailingCountry='NL');
        insert contact;
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockValidAddressITL');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        contact = ContactAddressValidation.validateAddress(contact.Id);
        Test.stopTest();
        
        Assert.areEqual(true, contact.AddressValid__c);
    }
    
    @IsTest
    public static void testInvalidAddressUS() {
        Contact contact = new Contact(LastName='Doe', FirstName='Joe', MailingStreet='Teststraat 1', MailingCity='Teststad', MailingPostalCode='1234 QA', MailingCountry='US', MailingState='WA');
        insert contact;
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockInvalidAddressUS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        contact = ContactAddressValidation.validateAddress(contact.Id);
        Test.stopTest();
        
        Assert.areEqual(false, contact.AddressValid__c);
    }
    
    @IsTest
    public static void testInvalidAddressITL() {
        Contact contact = new Contact(LastName='Doe', FirstName='Joe', MailingStreet='Teststraat 1', MailingCity='Teststad', MailingPostalCode='1234 QA', MailingCountry='NL');
        insert contact;
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockInvalidAddressITL');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        contact = ContactAddressValidation.validateAddress(contact.Id);
        Test.stopTest();
        
        Assert.areEqual(false, contact.AddressValid__c);
    }
}