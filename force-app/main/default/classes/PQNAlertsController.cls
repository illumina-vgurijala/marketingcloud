/**
*    @author  Pankaj Singla
*    @date    01-August-2018
*    @description  This class is custom controller for all the components developed for PQN Alert functionality from SFDC to PQN

*        Modification Log:
*       
------------------------------------------------------------------------------------
*       Developer                       Date                Description
*       
------------------------------------------------------------------------------------
*       Pankaj Singla                   01/08/2018            Original  Version
        Pankaj Singla                   28/08/2019            Incorporated Review Comments
*/


public with sharing class PQNAlertsController {
        
    /*
    * @author Pankaj Singla
    * @description: This method returns the Campaign records matching the search keyword
    * @param: String : keyword for search
              String: object name to look
    *@return: list<sobject>- List of records matching the search string
    
    */
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String strSearchKeyWord, String strObjectName) {
        system.debug('ObjectName-->' + strObjectName);
        String searchKey = strSearchKeyWord;       
        String strEsc = String.escapeSingleQuotes(searchKey);
        strObjectName=String.escapeSingleQuotes(strObjectName);
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
        String strsQuery =  'select id, Name from ' +strObjectName + ' where Name LIKE \'%'+strEsc + '%\' order by createdDate DESC limit 50';
        List < sObject > lstOfRecords = Database.query(strsQuery);
        
        return lstOfRecords;
    }

    /*
    * @author Pankaj Singla
    * @description: This method processes the file uploaded by user and generates the required map if data
    * @param: String : file contents read by parser           
    * @return: map<string,map<String,string>>- returns map of map of processed data
    
    */  
    
    @AuraEnabled
    public static map<string,map<string,string>> processFileContents(String strfilecontents){
        system.debug('original file--'+strfilecontents);
        map<string,string> emailToContactId=new map<string,string>(); // key- Contact email id, value- Contact id
        map<string,string> emailToLeadId=new map<string,string>(); //key- Lead Email Id, value- Lead id
        map<string,string> finalmatchedmap=new map<string,string>();
        /*this map is used to get the latest updated Lead/Contact record if both exists*/
        map<string,Contact> contactEmailToObjContact=new map<string,Contact>();//key Contact EmailId, Value-Contact
        map<string,string> emailToEmail=new map<string,string>();// map of all email ids. Same key value as we need to incorporate in the return map
        /*Final map that is returned and contains Processed File Contents*/
        map<string,map<string,string>> processedFileContents=new map<string,map<string,string>>();
        map<string,string> statisticsMap =new map<string,string>();// stores the count of data uploaded
        Integer intCountExistingRecords=0;
        String strFileData = EncodingUtil.urlDecode(strfilecontents, 'UTF-8');
        system.debug('myfile123--'+strFileData);
        system.debug('strFileData--'+strFileData.length());
        /*Split the data in rows*/
        //list<string> lstEmails=strFileData.split('\\r?\\n');
        
        String[] lstEmailsData = safeSplit(strFileData, '\r\n');
        system.debug('lstEmailsData size is ---'+lstEmailsData.size());
        Integer intEmptyIndex=lstEmailsData.indexOf('');
        /*Remove any empty email Ids in the list*/
        if(intEmptyIndex>=0){
            lstEmailsData.remove(intEmptyIndex);
        }
        if(lstEmailsData.size()>0){
            for(String ss:lstEmailsData){
                emailToEmail.put(ss,ss);
            }
                
        } 
        //getMapOfStringToString(emailToContactId, 'Email', 'Id');
        // Add total uploaded records
        statisticsMap.put('TotalInput',string.valueOf(lstEmailsData.size()));
        for(Contact c:[select id,name,Email,LastModifiedDate from Contact where Email!=null and Email in:lstEmailsData]){
            intCountExistingRecords=intCountExistingRecords+1;
            emailToContactId.put(c.Email,c.id);
            contactEmailToObjContact.put(c.Email,c);
        }
        for(Lead l:[select id,name,Email,LastModifiedDate from Lead where Email!=null and Email in:lstEmailsData]){
            if(emailToContactId.containsKey(l.email) && contactEmailToObjContact.containsKey(l.Email)){
                // use the recently modified record and remove the old record
                if(contactEmailToObjContact.get(l.Email).LastModifiedDate<l.LastModifiedDate){
                    emailToContactId.remove(l.Email);
                    emailToLeadId.put(l.Email,l.id);
                }
            }
            else{
                intCountExistingRecords=intCountExistingRecords+1;
                emailToLeadId.put(l.Email,l.id);
            }
            
                
            
        }
        finalmatchedmap.putAll(emailToContactId);
        finalmatchedmap.putAll(emailToLeadId);
        Integer mapsize=finalmatchedmap.size();
        statisticsMap.put('MatchedRecordCount',string.valueOf(mapsize));
        processedFileContents.put('Contacts',emailToContactId);
        processedFileContents.put('Leads',emailToLeadId);
        processedFileContents.put('statistics',statisticsMap);
        processedFileContents.put('UploadedEmailIds',emailToEmail);
        system.debug('ProcessedFileContents is --'+processedFileContents);
        return processedFileContents;
    }
    
   /*
    * @author Pankaj Singla
    * @description: This method creates a JSON string and post data to PQN using REST API call
    * @param: String : PQN Number
              String :PQN Url
              String PQN Date
              map<string,string> map of Uploaded Email Ids            
    * @return: response status code from PQN
    
    */  
    @AuraEnabled
    public static Boolean postDatatoPQN(String strPQNNumber,String strPQNUrl,String strPQNDate,String strNotificationName,map<string,string> strTostrAllUploadedEmails){
        system.debug('I am here'+strNotificationName);
        String strRestError = null;
        final string  INTERFACE_NAME='PQN_ALERTS';
        List<String> lstEmails=new list<string>(strTostrAllUploadedEmails.keySet());
        system.debug('keys-'+lstEmails);
        if(lstEmails.size()>0){
            Integer intLstSize=lstEmails.size();
            if(lstEmails[intLstSize-1]==''){
                lstEmails.remove(intLstSize-1);
            }
            
        }
        Map<String, String> config = getIntegrationEndpoint(INTERFACE_NAME);
        if(!Test.IsRunningTest()){
                       
            ProductNotificationCalloutBatch obj=new ProductNotificationCalloutBatch(lstEmails,strPQNNumber,strPQNUrl,strNotificationName);
            database.executebatch(obj,2000);
           
        }
        
        
        return true;
     
        
    }
    
    /*
    * @author Pankaj Singla
    * @description: This method creates a campaign membership for the selected campaign id 
    * @param: Campaign: The campaign record selected by user
              map<string,string> map of contact email id and id
              map<string,string> map of lead email id and id    
    * @return: Null
    
    */  
    
    @AuraEnabled
    public static void createCampaignMembershipSaleforce(Campaign sobjCampaignRecord,map<string,string> emailToContactId,map<string,string> emailToLeadId){
       list<string> lstObjIds=new list<string>(emailToContactId.values());
        lstObjIds.addAll(emailToLeadId.values());
        BatchToCreateCampaignMembersPQN bb=new BatchToCreateCampaignMembersPQN(lstObjIds,sobjCampaignRecord.id);
        Id idBatchProcessedid=database.executeBatch(bb);
    }
    
    /*
    * @author Pankaj Singla
    * @description: This method is used to process indivial email Ids uploaded. The split function is not able to handle large data 
    * @param:inStr- The input to parse
    * @param:delim - The delimeter used to separate the file data     
    * @return: List<String> the parse list of strings
    
    */
    
    public static List<String> safeSplit(String inStr, String delim)    
    {
    Integer regexFindLimit = 100;
    Integer regexFindCount = 0;
    
    List<String> output = new List<String>();
    
    Matcher m = Pattern.compile(delim).matcher(inStr);
    
    Integer lastEnd = 0;

    while(!m.hitEnd())
    {
        while(regexFindCount < regexFindLimit && !m.hitEnd())
        {
            if(m.find())
            {
                output.add(inStr.substring(lastEnd, m.start()));  
                lastEnd = m.end();
            }
            else
            {
                output.add(inStr.substring(lastEnd));
                lastEnd = inStr.length();
            }
            
            regexFindCount++;
        }

        // Note: Using region() to advance instead of substring() saves 
        // drastically on heap size. Nonetheless, we still must reset the 
        // (unmodified) input sequence to avoid a 'Regex too complicated' 
        // error.
        m.reset(inStr);        
        m.region(lastEnd, m.regionEnd());
        
        regexFindCount = 0;
    }
    
    return output;
}
     /**
    *  @author Pankaj Singla
    *  @description This method gets the integration end point data
    *  @param strIntegrationName- Interface name
    *  @return Map<String,String> Map of Interface Parameter Data
    **/
    public static Map<String, String> getIntegrationEndpoint(String strIntegrationName)
    {
        Interface_Parameters__mdt connectionParameters = getConnectionParameters(strIntegrationName);
        return new Map<String, String> { 'Endpoint' => connectionParameters.Endpoint__c, 'ApiKey' => connectionParameters.ApiKey__c, 'Authorization' => 'Bearer '+connectionParameters.BearerToken__c,'NamedCredentials' =>connectionParameters.Named_Credential__c,
        'Endpoint' =>connectionParameters.Endpoint__c};
    }
    
    /**
    *  @author Pankaj Singla
    *  @description This method queries the Interface Parameter based on Org Type
    *  @param strIntegrationName- Interface name
    *  @return Interface_Parameters__mdt- The Interface Parameter Record
    **/
    public static Interface_Parameters__mdt getConnectionParameters(String strIntegrationName)
    {
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1][0].IsSandbox;
        String sandboxPostfix = isSandbox ? '_SANDBOX' : '';
        String developerName = strIntegrationName + sandboxPostfix;

        List<Interface_Parameters__mdt> listParameters =
            [SELECT Id, DeveloperName, ApiKey__c, Endpoint__c, Named_Credential__c, BearerToken__c
             FROM Interface_Parameters__mdt
             WHERE DeveloperName = :developerName];

        return listParameters.get(0);
    }
    /*
    *  Description: Class JSONForPQNWrapper created 
    */
    public class JSONForPQNWrapper {
        public String userLogonId;
        public Integer notificationTypeId;
        public String externalNotificationId;
        public String ctaLink;
        public String metadata;
        }
    /*
    *  Description: Class JSONInner created 
    */  
    public class JSONInner{
        public String notificationNumber;
        public String notificationName;
        public String notificationType;
    }
    /*
    *  Description: Class PQNJSONResult created 
    */
    public class PQNJSONResult{
        
        public List<JSONResponseInner> data;
        
    }   
     /*
    *  Description: Class JSONResponseInner created 
    */   
        public class JSONResponseInner{
            public String userLogonId;
            public String notificationTypeId;
            public String externalNotificationId;
            public String message;
         
        }

    
    
    

}