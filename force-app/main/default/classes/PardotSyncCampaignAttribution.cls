/**
*    @author: Pankaj Singla
*    @date:   17-Jun-2019
*    @description:  Class to invoke Pardot Form Handler to update Campaign Attribution field in Pardot
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj            17-Jun-2019      Initial Build  
*    ------------------------------------------------------------------------------------ 
*                    
*/



public with sharing class PardotSyncCampaignAttribution{
   
    /**
  *  @author Pankaj Singla
  *  @description This method is called from Process Builder-Campaign Member : Set Attribution Field
  *  @param lstCampaignMemberIds- List of Campaign Member Ids
  *  @return Null
  **/
      @InvocableMethod
     public static void getMemberEmailIds(list<id> lstCampaignMemberIds){
         /* set<String> setEmailIds=new Set<String>();
         system.debug('The id is--'+lstCampaignMemberIds);
         List<CampaignMember> lstCampaignMembers=[select id, email from CampaignMember where id in:lstCampaignMemberIds];
         for(CampaignMember objCampaignMember:lstCampaignMembers){
             setEmailIds.add(objCampaignMember.email);
         }
         
         apexcallout(setEmailIds); */
     }
    
    /**
  *  @author Pankaj Singla
  *  @description This method is invokes dummy form handler using REST API to update the Campaign Attribution field
  *  @param setEmailIds- Set of Lead/Contact Email Ids
  *  @return Null
  **/
     
     public static void apexcallout(set<string> setEmailIds){
        string interfacename='Pardot_Campaign_Attribution';
        Map<String, String> strTostrconfig;  
        strTostrconfig=getIntegrationEndpoint(interfacename);
        String strRequestURL = strTostrconfig.get('Endpoint');
        //String strNamedCred=strTostrconfig.get('NamedCredentials');
        List<String> lstEmails=new list<String>();
        lstEmails.addAll(setEmailIds);
        String strEndpoint =strRequestURL;
         if(!Test.isRunningTest()){
              PardotQueableForCampaignAttribution objPardotQueableForCampaignAttribution=new PardotQueableForCampaignAttribution(lstEmails,strEndpoint); 
              System.enqueueJob(objPardotQueableForCampaignAttribution);  
         }
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
        return new Map<String, String> { 'Endpoint' => connectionParameters.Endpoint__c, 'ApiKey' => connectionParameters.ApiKey__c, 'Authorization' => 'Bearer '+connectionParameters.BearerToken__c,'NamedCredentials' =>connectionParameters.Named_Credential__c  };
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
}