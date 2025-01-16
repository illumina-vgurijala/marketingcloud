/**
*    @author Joshith k
*    @date   19 Aug 2019
*    @description  Software Download Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*     Aman Tyagi             31st March 2022           CodeScan Fixes
*     Rishab Wali            07-June-2022              [DCP-53883] Adding Query Instrumentation	
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class SoftwareDownloadsSelector extends ilib_SObjectSelector{

    public static final string LOG_TITLE = 'SoftwareDownloadsSelector';
    public static final String MARKETING_QUERY_LOGS = 'MarketingQueryLogs';

    /*
    * @Author: Joshith k
    * @Description : method for returning sObject type
    * @param : null
    * @return :sObjectType
    */
    public Schema.SObjectType getSObjectType()
    {
        return Software_Download__c.sObjectType;
    }
    
    /**
     *  @author  Joshith k
     *  @description Retrieve list of fields for Software_Download__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Software_Download__c.Id,
           Software_Download__c.Name,
		   Software_Download__c.Contact_full_name__c,
		   Software_Download__c.Lead_full_name__c,
           Software_Download__c.Email_Address__c,
           Software_Download__c.Country__c,
           Software_Download__c.First_Name__c,
           Software_Download__c.Last_Name__c
       };
    }
    
    /*
    * @author  Joshith k
    * @date 20-Aug-2019  
    * @description Fetch list of Software Downloads for corresponding Lead Associated
    * @param Set of Lead Ids
    *
    */
    public List<Software_Download__c> selectSoftwareDownloadByLeads(Set<Id> setLeadIds) 
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectSoftwareDownloadByLeads',UtilsCollection.serializeIds(setLeadIds));
        }
        List<Software_Download__c> res = (List<Software_Download__c>) Database.query(
                                          newQueryFactory().setCondition('Lead_Full_Name__c IN : setLeadIds').toSOQL()
        );
        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    } 

    /*
    * @author  Joshith k
    * @date 21-Sep-2019  
    * @description Fetch list of orphan Software Downloads for corresponding Email ids 
    * @param Set of Lead Ids
    *
    */
    public List<Software_Download__c> selectSoftwareDownloadByEmail(Set<String> setEmailIds) 
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectSoftwareDownloadByEmail',UtilsCollection.serializeIds(setEmailIds));
        }

        List<Software_Download__c> res = (List<Software_Download__c>) Database.query(
                                          newQueryFactory().setCondition('Email_Address__c IN : setEmailIds AND Lead_Full_Name__c=NULL AND Contact_Full_Name__c=NULL').toSOQL()
                                        );
        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    } 
    
   
    
 }