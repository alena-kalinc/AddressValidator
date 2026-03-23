public class AddressValidationCalloutService implements Database.AllowsCallouts {
	private static final String BASE_INTERNATIONAL_URL = 'https://international-street.api.smarty.com/verify?auth-id=abcdefg&auth-token=token';
    private static final String BASE_US_URL = 'https://us-street.api.smarty.com/street-address?auth-id=abcdefg&auth-token=token&license=us-core-cloud';
    private static final String STATUS_VERIFIED = 'Verified';
    private static final String STATUS_PRECISION_NONE = 'none';
    
    public static Boolean validateAddressUS(String street, String city, String state) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        street = EncodingUtil.urlEncode(street, 'UTF-8');
        city = EncodingUtil.urlEncode(city, 'UTF-8');
        state = EncodingUtil.urlEncode(state, 'UTF-8');
        String requestUrl = BASE_US_URL + '&street=' + street + '&city=' + city + '&state=' + state;
        System.debug('requestUrl: ' + requestUrl);
        request.setEndpoint(requestUrl);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        Boolean isValidAddress = false;
        
        if(response.getStatusCode() == 200) {
            List<Object> objects = (List<Object>) JSON.deserializeUntyped(response.getBody());
            Object obj = null;
            if(objects!=null && objects.size()==1) {
                obj = objects.get(0);
                String jsonResponse = JSON.serialize(obj);
                Map<String, Object> mapResp = (Map<String, Object>)JSON.deserializeUntyped(jsonResponse);
                Object metadataObj = mapResp.get('metadata');
                String metadataPar = JSON.serialize(metadataObj);
                System.debug('metadataPar: ' + metadataPar);
                Map<String, Object> mapAnalysis = (Map<String, Object>)JSON.deserializeUntyped(metadataPar);
                Object precision = mapAnalysis.get('precision');
                System.debug('precision: ' + precision);
                if(precision!=STATUS_PRECISION_NONE) {
                    isValidAddress = true;
                }
            }
        }
        
        return isValidAddress;
    }
    
    public static Boolean validateAddressITL(String address1, String postal_code, String country) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        address1 = EncodingUtil.urlEncode(address1, 'UTF-8');
        postal_code = EncodingUtil.urlEncode(postal_code, 'UTF-8');
        country = EncodingUtil.urlEncode(country, 'UTF-8');

        String requestUrl = BASE_INTERNATIONAL_URL + '&address1=' + address1 + '&postal_code=' + postal_code + '&country=' + country;
        System.debug('requestUrl: ' + requestUrl);
        request.setEndpoint(requestUrl);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        Boolean isValidAddress = false;
        
        if(response.getStatusCode() == 200) {            
            List<Object> objects = (List<Object>) JSON.deserializeUntyped(response.getBody());
            System.debug('body: ' + response.getBody());
            Object obj = null;
            if(objects!=null && objects.size()==1) {
                obj = objects.get(0);
                String jsonResponse = JSON.serialize(obj);
                Map<String, Object> mapResp = (Map<String, Object>)JSON.deserializeUntyped(jsonResponse);
                Object analysisObj = mapResp.get('analysis');
                String analysisPar = JSON.serialize(analysisObj);
                Map<String, Object> mapAnalysis = (Map<String, Object>)JSON.deserializeUntyped(analysisPar);
                Object verificationStatus = mapAnalysis.get('verification_status');
                System.debug('verificationStatus: ' + verificationStatus);
                if(verificationStatus==STATUS_VERIFIED) {
                    isValidAddress = true;
                }                
            }
        }
        
        return isValidAddress;
    }
}