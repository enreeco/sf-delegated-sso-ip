@RestResource(urlMapping='/delegatedAuth')
global without sharing class RESTDelegatedAuthenticator {
    
    @HttpPost
    global static void getOpenCases() {
        RestResponse response = RestContext.response;
        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/xml');
        Boolean authResult = false;
        try{
            Dom.Document doc = new DOM.Document(); 
            doc.load(RestContext.request.requestBody.toString());  
            DOM.XMLNode root = doc.getRootElement();
            Map<String,String> requestValues = walkThrough(root);
            
            
            authResult = checkCredentials(requestValues.get('username'), 
                                          requestValues.get('password'),
                                          requestValues.get('sourceIp'));
        }catcH(Exception e){
            //authResult = true;
            insert new Log__c(Description__c = e.getStackTraceString()+'\n'+e.getMessage(), 
                       Request__c = RestContext.request.requestBody.toString());
        }finally{
            //authResult = true;
            insert new Log__c(Description__c = 'Result:'+authResult, 
                       Request__c = RestContext.request.requestBody.toString());
        }
        String soapResp = '<?xml version="1.0" encoding="UTF-8"?>'
            +'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
            +'<soapenv:Body>'
            +'<AuthenticateResult xmlns="urn:authentication.soap.sforce.com">'
            +'<Authenticated>'+authResult+'</Authenticated>'
            +'</AuthenticateResult>'
            +'</soapenv:Body>'
            +'</soapenv:Envelope>';
        response.responseBody = Blob.valueOf(soapResp);
    }
    
    /*
* Checks current username / token / IP and garbages all old token (created < NOW-3 mins)
*/
    private static Boolean checkCredentials(String username, String token, String ip){
        delete [Select Id From DelegatedToken__c Where CreatedDate < :System.now().addMinutes(-3)];
        List<DelegatedToken__c> dTList =  [Select Id From DelegatedToken__c Where Username__c = :username
                                           and RequestIP__c = :ip and Token__c = :token];
        if(dTList.size()>0){
            //delete the found token
            delete dTList;
            return true;
        }
        return false;
    }
    
    /*
    * Gets all text elements of the DOM
    */
    private static map<String,String> walkThrough(DOM.XMLNode node) {
        map<String,String> tempMap = new map<String,String>();
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            if (node.getText().trim() != '') {
                tempMap.put(node.getName(), node.getText());
            }
            for (Dom.XMLNode child: node.getChildElements()) {
                tempMap.putAll(walkThrough(child));
            }
        }
        return tempMap; 
    }
    
}