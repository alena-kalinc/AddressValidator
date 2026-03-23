@IsTest
public class TestContactAddressValidation {
    @IsTest
    public static void testValidAddressUS() {
        Contact contact = new Contact(LastName = 'Doe', FirstName = 'Joe', MailingStreet = '1428 Post Aly', MailingCity = 'Seattle', MailingPostalCode = '98101', MailingCountry = 'US', MailingState = 'WA');
        insert contact;

        Test.setMock(HttpCalloutMock.class, new DynamicSmartyMock('MockValidAddressUS', contact.Id));

        Test.startTest();
        contact = ContactAddressValidation.validateAddress(contact.Id);
        Test.stopTest();

        Assert.isTrue(contact.AddressValid__c, 'Valid US Address should be true');
    }

    @IsTest
    public static void testValidAddressITL() {
        Contact contact = new Contact(LastName = 'Doe', FirstName = 'John', MailingStreet = 'De Bleek 7', MailingCity = 'Woerden', MailingPostalCode = '3447 GV', MailingCountry = 'NL');
        insert contact;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockValidAddressITL');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        contact = ContactAddressValidation.validateAddress(contact.Id);
        Test.stopTest();

        Assert.isTrue(contact.AddressValid__c, 'Valid ITL Address should be marked as true');
    }

    @IsTest
    public static void testInvalidAddressUS() {
        Contact contact = new Contact(LastName = 'Doe', FirstName = 'Joe', MailingStreet = 'Teststraat 1', MailingCity = 'Teststad', MailingPostalCode = '1234 QA', MailingCountry = 'US', MailingState = 'WA');
        insert contact;

        Test.setMock(HttpCalloutMock.class, new DynamicSmartyMock('MockInvalidAddressUS', contact.Id));

        Test.startTest();
        contact = ContactAddressValidation.validateAddress(contact.Id);
        Test.stopTest();

        Assert.isFalse(contact.AddressValid__c, 'Invalid US Address should be false');
    }

    @IsTest
    public static void testInvalidAddressITL() {
        Contact contact = new Contact(LastName = 'Doe', FirstName = 'Joe', MailingStreet = 'Teststraat 1', MailingCity = 'Teststad', MailingPostalCode = '1234 QA', MailingCountry = 'NL');
        insert contact;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockInvalidAddressITL');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        contact = ContactAddressValidation.validateAddress(contact.Id);
        Test.stopTest();

        Assert.isFalse(contact.AddressValid__c, 'Invalid ITL Address should be marked as false');
    }

    @IsTest
    public static void testValidBulkAddressUS() {
        List<Id> contactIds = generateTestContacts(60, 'US');
        Test.setMock(HttpCalloutMock.class, new SmartyBulkMock(true));

        Test.startTest();
        List<Contact> results = ContactAddressValidation.validateAddressesBulk(contactIds);
        Test.stopTest();

        for (Contact c : results) {
            Assert.isTrue(c.AddressValid__c, 'All bulk records should be marked VALID');
        }
    }

    @IsTest
    public static void testInvalidBulkAddressUS() {
        List<Id> contactIds = generateTestContacts(60, 'US');

        Test.setMock(HttpCalloutMock.class, new SmartyBulkMock(false));

        Test.startTest();
        List<Contact> results = ContactAddressValidation.validateAddressesBulk(contactIds);
        Test.stopTest();

        Assert.areEqual(60, results.size(), 'Should process exactly 60 records');

        for (Contact c : results) {
            Assert.isFalse(c.AddressValid__c, 'All bulk records should be marked INVALID');
        }
    }

    @IsTest
    public static void testBulkAddressQueueableExecution() {
        List<Id> contactIds = generateTestContacts(105, 'US');
        Test.setMock(HttpCalloutMock.class, new SmartyBulkMock(true));

        Test.startTest();
        List<Contact> initialResults = ContactAddressValidation.validateAddressesBulk(contactIds);
        Assert.areEqual(105, initialResults.size(), 'Controller should return records immediately for UI state');
        Test.stopTest();

        List<Contact> processedContacts = [SELECT Id, AddressValid__c FROM Contact WHERE Id IN :contactIds];

        Assert.areEqual(105, processedContacts.size(), 'Should find all 105 records in DB');
        for (Contact c : processedContacts) {
            Assert.isTrue(c.AddressValid__c, 'Queueable job should have updated all records to valid in the background');
        }
    }

    private static List<Id> generateTestContacts(Integer numberOfRecords, String country) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            contacts.add(new Contact(
                    LastName = 'TestUser ' + i,
                    MailingStreet = i + ' Main St',
                    MailingCity = 'Seattle',
                    MailingPostalCode = '98101',
                    MailingCountry = country,
                    MailingState = 'WA'
            ));
        }
        insert contacts;

        List<Id> contactIds = new List<Id>();
        for (Contact c : contacts) {
            contactIds.add(c.Id);
        }
        return contactIds;
    }

    public class DynamicSmartyMock implements HttpCalloutMock {
        private String resourceName;
        private Id recordId;

        public DynamicSmartyMock(String resourceName, Id recordId) {
            this.resourceName = resourceName;
            this.recordId = recordId;
        }

        public HttpResponse respond(HttpRequest req) {
            StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = :resourceName LIMIT 1];
            String jsonBody = sr.Body.toString();

            if (this.recordId != null) {
                jsonBody = jsonBody.replace('%%INPUT_ID%%', String.valueOf(this.recordId));
            }

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            res.setBody(jsonBody);

            return res;
        }
    }

    public class SmartyBulkMock implements HttpCalloutMock {
        private Boolean isMockValid;

        public SmartyBulkMock(Boolean isMockValid) {
            this.isMockValid = isMockValid;
        }

        public HttpResponse respond(HttpRequest req) {
            List<Object> inputs = (List<Object>) JSON.deserializeUntyped(req.getBody());
            List<Map<String, Object>> responses = new List<Map<String, Object>>();
            String precisionToReturn = this.isMockValid ? 'Rooftop' : 'Unknown';

            for (Object obj : inputs) {
                Map<String, Object> input = (Map<String, Object>) obj;
                responses.add(new Map<String, Object>{
                        'input_id' => input.get('input_id'),
                        'metadata' => new Map<String, Object>{
                                'precision' => precisionToReturn
                        }
                });
            }

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(responses));
            return res;
        }
    }
}