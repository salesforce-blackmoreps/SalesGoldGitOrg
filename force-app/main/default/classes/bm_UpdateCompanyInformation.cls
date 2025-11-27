public class bm_UpdateCompanyInformation {
    public static String updateOrgName() {
        String orgId = UserInfo.getOrganizationId();
        String endpoint = Url.getOrgDomainUrl().toExternalForm() 
                        + '/services/data/v60.0/sobjects/Organization/' + orgId;
        
        system.debug('orgId- '+orgId);
        system.debug('endpoint- '+endpoint);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');
        
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
		system.debug('key- ' + UserInfo.getSessionId());
        
        Map<String, Object> jsonBody = new Map<String, Object>();
        jsonBody.put('Name', 'Test From Apex');
        
        //jsonBody.put('Phone', '123456789');
        // jsonBody.put('Street', '123 New Street');
        // jsonBody.put('City', 'New York');
        
        req.setBody(JSON.serialize(jsonBody));

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            system.debug('resopose status code- '+res.getStatusCode());
            if (res.getStatusCode() == 204) {
                return 'SUCCESS: Company Name updated';
            } else {
                return 'ERROR: Status ' + res.getStatusCode() + ' - ' + res.getBody();
            }
        } catch (Exception e) {
            return 'EXCEPTION: ' + e.getMessage();
        }
    }
}