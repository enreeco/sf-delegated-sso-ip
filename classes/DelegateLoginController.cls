public class DelegateLoginController { 
    /*
     * Helper class to handle different delegated users
     */
    public class DelegatedUser{
        
        public DelegatedUser(DelegatedUser__c usr){
            this.usr = usr;
        }
        
        public DelegatedUser__c usr{get;set;}
        
        public PageReference delegateAuthentication(){
            String password = generateGUID();
            insert new DelegatedToken__c(Token__c = password, 
                                      Username__c = this.usr.DelegatedUsername__c,
                                      RequestIP__c = getCurrentIP());
            String url = 'https://login.salesforce.com/login.jsp?'
                        +'un='+EncodingUtil.urlEncode(this.usr.DelegatedUsername__c, 'utf8')
                        +'&orgId='+this.usr.Delegated_ORG_ID__c 
                        +'&pw='+EncodingUtil.urlEncode(password, 'utf8')
                		+'&rememberUn=0&jse=0';
            //you can also setup a startURL, logoutURL and ssoStartPage parameters to enhance usre experience
            PageReference page = new PageReference(url);
            page.setRedirect(false);
            return page;
        }
    }
    
    /*
     * List of all delegated users
     */
    public List<DelegatedUser> users{get;set;}
    
    /*
     * Constructor
	 */
    public DelegateLoginController(){
        this.users = new List<DelegatedUser>();
        for(DelegatedUser__c du : [Select Id, DelegatedUsername__c, Delegated_ORG_ID__c
                                  	From DelegatedUser__c Where LocalUser__c = :UserInfo.getUserId()
                                   Order by DelegatedUsername__c]){
        	this.users.add(new DelegatedUser(du));                               
		}
    }
    
    /*
     * GUID generator
     */
    public static String generateGUID(){
        Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertTohex(b);
		return h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' 
            	+ h.SubString(12,16) + '-' + h.SubString(16,20) 
            	+ '-' + h.substring(20);
    }
    
    /*
     * Gets current user's IP
     */
    public static String getCurrentIP(){
        Map<String, String> mapHeaders = ApexPages.currentPage().getHeaders();   
        String ipAddress;
        if(mapHeaders != null) {
            ipAddress = mapHeaders.get('True-Client-IP');
            if(ipAddress == null){
                ipAddress = mapHeaders.get('X-Salesforce-SIP');
            }
        }
        return ipAddress;
    }
}