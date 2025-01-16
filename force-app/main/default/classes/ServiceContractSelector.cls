/**
 *    @author Veerendra
 *    @date   09-June-2018
 *    @description    Class to get the Service Contract records based on different conditions
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Veerendra                   09-Jun-2018            Initial Version
 *    Prashanth                   24-Aug-2021            Added Query Instrumentation
 *    Siddartha Reddy Kalam       28-Nov-2023            CMCM-3980 Added LWC Related Selectors
 *    Dhairya Shah                6-March-2024           CMCM-5309
 *    ---------------------------------------------------------------------------------------
 *                    
 */
public with sharing class ServiceContractSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'ServiceContractSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final Date TODAYS_DATE = System.today(); //G2022-171
    private static final String CONTRACTTYPESOFTWAREZWS = 'Software (ZWS)';
    private static final String CONTRACTTYPEZCQ = 'Quantity Contract (ZCQ)';
    private static final String CONTRACTTYPESOFTWAREZWV = 'Software Contract (ZWV)';
    private static final String STRING_REGISTRATION_CONTACT_EMAIL = 'Registration_Contact_Email__c'; //CMCM-8089
    private static final String STRING_STATUS = 'Status__c'; //CMCM-8089

   /**
    *  @author Veerendra
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Service_Contract__c.sObjectType;
   }
    
   /**
     *  @author  Veerendra 
     *  @description Retrieve List of fields for Service Contract sObject 
     *  @return sObjectFieldList List of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           SVMXC__Service_Contract__c.id,
           SVMXC__Service_Contract__c.Parts_Included__c,
           SVMXC__Service_Contract__c.Labor_Included__c,
           SVMXC__Service_Contract__c.Travel_Included__c,
           SVMXC__Service_Contract__c.Consumables_Included__c,
           SVMXC__Service_Contract__c.Remote_Support_Included__c,
           SVMXC__Service_Contract__c.ERP_Contract_Line_Number__c,
           SVMXC__Service_Contract__c.ERP_Header_Contract_Number__c,
           SVMXC__Service_Contract__c.SVMXC__End_Date__c,
           SVMXC__Service_Contract__c.SVMXC__Start_Date__c, //DCP-47459
           SVMXC__Service_Contract__c.Status__c,  //DCP-52634
           SVMXC__Service_Contract__c.Registration_Contact_Email__c , //DCP-52634
           SVMXC__Service_Contract__c.Domain_ID__c,  //DCP-52634
           SVMXC__Service_Contract__c.Workgroup_Name__c,  //DCP-52634
           SVMXC__Service_Contract__c.ProductCode__c, // DCP-52634
           SVMXC__Service_Contract__c.SVMXC__Service_Plan__c, // DCP-52634
           SVMXC__Service_Contract__c.Status__c,
           SVMXC__Service_Contract__c.SVMXC__Active__c,// DCP-52634
           SVMXC__Service_Contract__c.Zuora_Subscription_ID__c,//DCP-52634
           SVMXC__Service_Contract__c.Domain_URL_Pattern__c,//DCP-52634
           SVMXC__Service_Contract__c.Order_Line_Item__c//CMCM-263
       };
    }

    /**
     *  @author Veerendra
     *  @description Fetch Service Contract associated with Case And Work Orders
     *  @param Service Contract Ids, Status
     *  @return List of Service Contracts that are Active
     **/
    public List<SVMXC__Service_Contract__c> selectServiceContractsByStatus(Set<Id> setServiceContractIds, String strServiceContractStatus) 
    {  
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServiceContractsByStatus', UtilsCollection.serializeIds(setServiceContractIds)+'|'+strServiceContractStatus);
        }   
        List<SVMXC__Service_Contract__c> res = (List<SVMXC__Service_Contract__c>) Database.query(
            newQueryFactory()
            .setCondition('ID IN :setServiceContractIds AND Status__c = :strServiceContractStatus').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }


     /**
     *  @author Digvijay
     *  @description Fetch Service Contract associated with Case And Work Orders
     *  @param Service Contract Ids
     *  @return List of Service Contracts 
     **/
    public List<SVMXC__Service_Contract__c> selectServiceContracts(Set<Id> setServiceContractIds) 
    {     
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServiceContracts', UtilsCollection.serializeIds(setServiceContractIds));
        }
        List<SVMXC__Service_Contract__c> res = (List<SVMXC__Service_Contract__c>) Database.query(
            newQueryFactory()
            .setCondition('ID IN :setServiceContractIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
      
    /**
     *  @author NancyKalach
     *  @description Fetch Active Dedicated Service Contract associated with a set of Account Ids
     *  @param setAccountId Account Ids
     *  @param setDedicatedServicePlans Dedicated Service Contracts Names
     *  @return List of Service Contracts 
     **/
    public List<SVMXC__Service_Contract__c> selectServContractsByAccountId(Set<Id> setAccountId) {     
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServContractsByAccountId', UtilsCollection.serializeIds(setAccountId));
        }
        List<SVMXC__Service_Contract__c> res = (List<SVMXC__Service_Contract__c>) Database.query(
            newQueryFactory().selectField('Id')
            .selectField('SVMXC__Company__c')
            .selectField('SVMXC__Start_Date__c')
            .selectField('SVMXC__End_Date__c')
            .selectField('SVMXC__Service_Plan__r.Name')
            .selectField('SVMXC__Service_Plan__r.SVMXC__Active__c')
            .selectField('SVMXC__Service_Plan__r.Item_Number__c')
            .setCondition('SVMXC__Company__c IN :setAccountId AND SVMXC__Start_Date__c <= :TODAYS_DATE AND SVMXC__End_Date__c >= :TODAYS_DATE')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
     /*******************************************************************************************************
    * @description CMCM-3980 LWC Fetches data using Account Id and Key attribute which holds search data
    *  @author Siddartha Reddy Kalam
    * @param AccountID & key Key attribute which holds search data
    * @return List<SVMXC__Service_Contract__c>
    */
    public List<SVMXC__Service_Contract__c> selectServContractsWithAccountIdandSearch(Id accountId,String key) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServContractsWithAccountIdandSearch');
        } 

        ilib_QueryFactory srvConQuery = newQueryFactory();
        srvConQuery.selectField('Id');
        srvConQuery.selectField('Name');
        srvConQuery.selectField('Product_Name__c');
        srvConQuery.selectField('ProductCode__c');
        srvConQuery.selectField(STRING_REGISTRATION_CONTACT_EMAIL); // added for CMCM 8089 by Dhairya Shah
        srvConQuery.setCondition('SVMXC__Company__c =: accountId AND (ERP_Contract_Type__c =:CONTRACTTYPESOFTWAREZWS OR ERP_Contract_Type__c =:CONTRACTTYPEZCQ OR ERP_Contract_Type__c =:CONTRACTTYPESOFTWAREZWV) AND (Name LIKE :key OR Zuora_Subscription_ID__c LIKE :key OR Registration_Contact_Email__c LIKE :key)');
        srvConQuery.setLimit(50);//CMCM-5309 FR change 14th March 2024 // CMCM-8089 Increase limit from 20 to 50 by Dhairya Shah

        List<SVMXC__Service_Contract__c> res = (List<SVMXC__Service_Contract__c>) Database.query(
            srvConQuery
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /*******************************************************************************************************
    * @description CMCM-10540 LWC Fetches data using Key attribute which holds search data
    *  @author Abhishek Yadav
    * @param key attribute which holds search data
    * @return List<SVMXC__Service_Contract__c>
    */
    public List<SVMXC__Service_Contract__c> selectServContractsWithSearchSOSL(String key) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServContractsWithSearchSOSL');
        } 
        List<List<SObject>> searchResults = [FIND :key 
        IN ALL FIELDS
        RETURNING SVMXC__Service_Contract__c (
            Id, 
            Name,
            SVMXC__Company__c,
            Product_Name__c, 
            ERP_Contract_Type__c,
            ProductCode__c, 
            Registration_Contact_Email__c, 
            Status__c
        ) 
        LIMIT 50];
        List<SVMXC__Service_Contract__c> res = (List<SVMXC__Service_Contract__c>) searchResults[0];
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

     /*******************************************************************************************************
    * @description CMCM-3980 LWC Fetches data using id attribute which holds record data
    *  @author Siddartha Reddy Kalam
    * @param idofsbcrpts attribute which holds associated products data
    * @return List<SVMXC__Service_Contract__c>
    */
    public List<SVMXC__Service_Contract__c> selectServContractsWithid(List<Id> idofsbcrpts) {

        ilib_LogQuery logger = NULL;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServContractsWithid');
        } 

        ilib_QueryFactory srvConQuery = newQueryFactory();
        srvConQuery.selectField('Id');
        srvConQuery.selectField('Name');
        srvConQuery.selectField('Order_Line_Item__r.Apttus_Config2__ProductId__c');
        srvConQuery.setCondition('(id =: idofsbcrpts) AND (ERP_Contract_Type__c =:CONTRACTTYPESOFTWAREZWS OR ERP_Contract_Type__c =:CONTRACTTYPEZCQ OR ERP_Contract_Type__c =:CONTRACTTYPESOFTWAREZWV)');

        List<SVMXC__Service_Contract__c> res = (List<SVMXC__Service_Contract__c>) Database.query(
            srvConQuery
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /**
     *  @author Abhishek yadav
     *  @description Fetch Service Contract associated product - CMCM-263
     *  @param Service Contract Ids
     *  @return List of Service Contracts
     **/
    public List<SVMXC__Service_Contract__c> selectServiceContractByIds(Set<Id> serviceContractIds) {
        ilib_LogQuery logger=null; 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServiceContractByIds', UtilsCollection.serializeIds(serviceContractIds));
        }
        List<SVMXC__Service_Contract__c> res = (List<SVMXC__Service_Contract__c>) Database.query(
            newQueryFactory().selectField('Id')
            .selectField('Order_Line_Item__c')
            .selectField('Order_Line_Item__r.Apttus_Config2__ProductId__c')
            .setCondition('Id IN :serviceContractIds')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    /**
     *  @author Abhishek yadav
     *  @description Fetch Service Contract - CMCM-269
     *  @param Service Contract Ids
     *  @return List of Service Contracts
     **/
    public List<SVMXC__Service_Contract__c> selectServiceContractByExternalId(String serviceContractExternalId) {
        ilib_LogQuery logger=null; 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServiceContractByExternalId', serviceContractExternalId);
        }
        List<SVMXC__Service_Contract__c> res = (List<SVMXC__Service_Contract__c>) Database.query(
            newQueryFactory().selectField('Id')
            .setCondition('SVMX_PS_External_ID__c like :serviceContractExternalId')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
}