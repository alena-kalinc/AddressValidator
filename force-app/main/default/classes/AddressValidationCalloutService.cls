public inherited sharing class AddressValidationCalloutService {
    private static final String NAMED_CRED_INTERNATIONAL = 'callout:Smarty_International';
    private static final String NAMED_CRED_US = 'callout:Smarty_US';

    private static final String STATUS_VERIFIED = 'Verified';
    private static final String STATUS_PARTIAL = 'Partial';
    private static final String STATUS_PRECISION_UNKNOWN = 'Unknown';
    private static final Integer SMARTY_MAX_BATCH_SIZE = 100;

    /**
     * @description Bulk US validation with official Smarty batch POST + input_id mapping.
     * @param contacts List of Contacts (Mailing fields + Id required)
     * @return Map<Id, Boolean> validation result per Contact Id
     */
    public static Map<Id, Boolean> validateAddressUSBulk(List<Contact> contacts) {

        Map<Id, Boolean> results = new Map<Id, Boolean>();
        if (contacts == null || contacts.isEmpty()) return results;

        for (Contact c : contacts) {
            results.put(c.Id, false);
        }

        // Chunking logic to respect Smarty API limits (100 per request)
        List<USInput> currentChunk = new List<USInput>();
        for (Integer i = 0; i < contacts.size(); i++) {
            Contact c = contacts[i];
            currentChunk.add(new USInput(c.Id, c.MailingStreet, c.MailingCity, c.MailingState));

            if (currentChunk.size() == SMARTY_MAX_BATCH_SIZE || i == contacts.size() - 1) {
                processUSChunk(currentChunk, results);
                currentChunk.clear();
            }
        }

        return results;
    }

    private static void processUSChunk(List<USInput> inputs, Map<Id, Boolean> results) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CRED_US);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json; charset=utf-8');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(inputs));

        try {
            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200) {
                List<USCandidate> candidates = (List<USCandidate>) JSON.deserialize(
                        res.getBody(),
                        List<USCandidate>.class
                );

                for (USCandidate cand : candidates) {
                    if (String.isNotBlank(cand.input_id) && cand.metadata != null) {
                        Boolean isValid = (cand.metadata.precision != null && cand.metadata.precision != STATUS_PRECISION_UNKNOWN);
                        results.put((Id)cand.input_id, isValid);
                    }
                }
            } else {
                logError('US Smarty HTTP Error', 'Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
            }
        } catch (Exception e) {
            logError('US Smarty Callout Exception', e.getMessage());
        }
    }

    public static Boolean validateAddressITL(String address1, String postalCode, String country) {
        if (String.isBlank(address1) || String.isBlank(country)) {
            return false;
        }

        String encodedAddr = EncodingUtil.urlEncode(address1, 'UTF-8');
        String encodedPostal = EncodingUtil.urlEncode(postalCode, 'UTF-8');
        String encodedCountry = EncodingUtil.urlEncode(country, 'UTF-8');

        String endpoint = NAMED_CRED_INTERNATIONAL
                + '?address1=' + encodedAddr
                + '&postal_code=' + encodedPostal
                + '&country=' + encodedCountry;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setTimeout(120000);

        try {
            HttpResponse response = new Http().send(request);

            if (response.getStatusCode() != 200) {
                logError('International HTTP error: ', 'Status: ' + response.getStatusCode() + ' Body: ' + response.getBody());
                return false;
            }

            List<InternationalCandidate> candidates = (List<InternationalCandidate>) JSON.deserialize(
                    response.getBody(), List<InternationalCandidate>.class
            );

            if (candidates == null || candidates.isEmpty()) return false;
            String actualStatus = candidates[0]?.analysis?.verification_status;

            return actualStatus == STATUS_VERIFIED || actualStatus == STATUS_PARTIAL;

        } catch (Exception e) {
            logError('International callout exception:', e.getMessage() + '\n' + e.getStackTraceString());
            return false;
        }

    }

    private static void logError(String summary, String detail) {
        // TODO: Refactor to use Integration_Log__c and EventBus.publish(IntegrationErrorEvent__e) for production-grade error tracking
        System.debug(LoggingLevel.ERROR, summary + ' | ' + detail);
    }

    private class USInput {
        public String input_id; // Mapping key
        public String street;
        public String city;
        public String state;
        public Integer candidates = 1;

        public USInput(Id contactId, String street, String city, String state) {
            this.input_id = (String) contactId;
            this.street = street;
            this.city = city;
            this.state = state;
        }
    }

    private class USCandidate {
        public String input_id;
        public USMetadata metadata;
    }

    private class USMetadata {
        public String precision;
    }

    private class InternationalCandidate {
        public InternationalAnalysis analysis;
    }

    private class InternationalAnalysis {
        public String verification_status;
    }

}