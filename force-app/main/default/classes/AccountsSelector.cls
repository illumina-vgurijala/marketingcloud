/**
*    Description - Class to get the Account records 
*    Test Class Coverage For 75% coverage: TestAccountsSelector
*    Test Class Coverage For 90% coverage: TestAccountsSelector, TestApttusAssetLineItems
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Rishab Wali                    22nd Feb 2021               DCP-37232 Default Preferred Language
*    Saddam                         22nd Feb 2022               pm-33,Added 2 new fields to sobjectlist method pm-33 
*    Saddam                         21-Mar-2022                 pm-430,Created getRqComplianceAccounts(), accountWithRelatedContacts() methods 
*    Satya Swain                    17-May-2022                 DCP-53342, Added fields in selectLoggedInAccountForUser()
*    Adyasha                        27-Jun-2022                 DCP-53375: Added new method selectAccountsWithMarketSegments
*    Himanshu                       24-Aug-2022                 DCP-56003  Added new field in getSObjectFieldList()
*    Satya Swain                    02-Sept-2022                DCP-54439 : Added new method selectAccountsForNationalGroupNumbers
*    Avina                          10-Oct-2022                 QACM-78, Created selectAccountforLookupController() method
*    Gerardo Garcia                 07-Aug-2024                 CMCM-9578 Add select field Owner.ManagerId and getChildrenAccounts
*    Venkatesh Prabhu               10-Dec-2024                 CMCM-12168 : Too Many SOQL : 101
*   -----------------------------------------------------------------------------------------------
*/
public with sharing class AccountsSelector extends ilib_SObjectSelector {

    private static final String LOG_TITLE = 'AccountsSelector';

    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs'; //CMCM-12168

    private static final String NAME = 'Name'; //CODESCAN FIX ,5-MAY
    
    private static final String TERRITORY_REGION = 'Territory_Region__c';
    private static final String NATIONAL_GROUP_NUMBER = 'National_Group_Number__c';

    private static final String  R_Q_CONTACT_ELIGIBLE = 'R_Q_Contact_Eligible__c';

    /*Constructor */
    public AccountsSelector()
    {
        super(false, false, false, false);
        //m_orderBy = '';  
    }

     /*
    * @author Todd Newman
    * @date   07-12-2018   
    * @description  set select fields
    *Log: Added Care_Of and Care_Of_Local fields
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Account.Id,
            Account.Name,
            Account.OwnerId,
            Account.ERP_Customer_Id__c,
            Account.Account_Group__c,
            Account.BillingStreet,
            Account.BillingPostalCode,
            Account.BillingCity,
            Account.BillingCountryCode,
            Account.BillingCountry,
            Account.BillingState,
            Account.BillingStateCode,
            Account.Phone,
            Account.CurrencyIsoCode,
            Account.NameLocal,
            Account.Street_2_Local__c,
            Account.Street_Local__c,
            Account.City_Local__c,
            Account.Country_Local__c,
            Account.State_Province_Local__c,
            Account.Customer_Type__c,
            Account.Customer_Sub_Type__c,
            Account.Clinical_Type__c,
            Account.Market_Segment__c,
            Account.AccountId_18_Char_Id__c,
            Account.Channel_Partner_Type__c,
            //CMCM-9918
            Account.Partner_Request__c,
            Account.Email_Channel_Partner__c,
            //END: CMCM-9918
            Account.Website,
            Account.Zip_Postal_Code_Local__c,
            Account.Tier__c,
            Account.Address_Status__c,
            Account.Account_Status__c,
            Account.LastModifiedById,
            Account.Care_Of__c,
            Account.Care_Of_Local__c,
            Account.Territory_Region__c,
            Account.National_Group_Number__c,
            Account.District__c,
            Account.Territory_Code__c,
            Account.Ultimate_Parent_Id__c,
            Account.IsCustomerPortal,
            Account.IsPartner,
            Account.R_Q_Contact_Compliant__c, //pm-33
            Account.R_Q_Contact_Eligible__c, //pm-33
            Account.R_Q_Non_Compliance_Date__c, //PM-47
            Account.Signed_Open_Offer__c, // DGP-908
            Account.Open_Offer_Comparison_Customer__c, //DGP-908
            // Added for DCP-56003
          Account.Eligible_To_Estimate_Consumable_Spend__c,
          //Added for CMCM-9577
          Account.Population_Genomics__c,
        // End of DCP-56003
            Account.RecordTypeId //CMCM-12168
        };
    }

    /*
    * @author Todd Newman
    * @date   07-12-2018
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return Account.sObjectType;
    }
    
    /*
    * @author Akshay Mohan
    * @date   07-17-2018
    * @description Fetch Related Accounts for the Account
    * @param accountIds Set of Account Ids
    *
    */
    public List<Account> selectAccounts(Set<Id> accountIdset) 
    {
        return (List<Account>) Database.query(
        newQueryFactory().selectField('LastModifiedBy.Email').selectField('Parent.ERP_Customer_Id__c')
        .selectField('Owner.Name')
        .selectField('Owner.ManagerId')
		.selectField('Preferred_Language__c') //DCP-37232 Default Preferred Language
		.selectField(R_Q_CONTACT_ELIGIBLE) //PM-122 Mark Account.R_Q_Contact_Eligible__c
        .selectField(NAME)//DCP-54039
        .selectField('NameLocal') //DCP-54039
        .selectField('Field_Comments__c') //DCP-54039
        .selectField('Territory_Name__c') //CMCM-721
        .selectField('Channel_Partner_Type__c') //CMCM-12243
        .setCondition('Id IN :accountIdset').toSOQL());
    }   

    /*
    * @author Nitin Sood
    * @date   08-10-2018
    * @description Fetch Accounts on basis of ERP_Customer_Id
    * @param setErpCustomerIds Set 
    */
    public List<Account> selectAccountsForERPCustomerIds(Set<String> setErpCustomerIds) 
    {
        return (List<Account>) Database.query(
        newQueryFactory().setCondition('ERP_Customer_Id__c IN :setErpCustomerIds').toSOQL());
    }

    /**
     * @author Venkatesh Prabhu
     * @date 10-12-2024
     * @description Fetch Accounts on basis of ERP_Customer_Id or Fetch logeed in Community User's Id
     * @param setErpCustomerIds 
     * @param idAccounts 
     * @return  `List<Account>`
     */
    public List<Account> selectLoggedInOrERPCustomerIdsofAccount(Set<String> setErpCustomerIds, List<Id> idAccounts) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLoggedInOrERPCustomerIdsofAccount', UtilsCollection.serializeIds(setErpCustomerIds));
        }
        
        List<Account> lstAccounts = (List<Account>) Database.query(
            newQueryFactory()
            .selectField('id')
            .selectField(NAME)
            .selectField(TERRITORY_REGION)
            .selectField('Channel_Partner_Type__c')
            .setCondition('id IN :idAccounts or ERP_Customer_Id__c IN :setErpCustomerIds')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(lstAccounts.size());
        }
        return lstAccounts;
    }

   /*
    * @author Prakhar Kumar
    * @date   03-10-2018
    * @description Fetch logeed in Community User's Id
    * @param Pass the Logged In user's Id 
    */
    public List<Account> selectLoggedInAccountForUser(String str) {
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLoggedInAccountForUser() ',str);
        }
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('id=:str');

        String strQuery = query.selectField('id')
        .selectField(NAME)
        .selectField('RecordTypeId')            
        .selectField(TERRITORY_REGION)
        .selectField('Channel_Partner_Type__c')
        .selectField('Owner.Name')
        // Added for DCP-53342
        .selectField('RecordType.DeveloperName') 
        .selectField('For_Profit_Company__c')
        .selectField('Purchases_Products_Shipping_to_U_S__c')
        .selectField('Clinical_Oncology_Screening_Dx_Testing__c')
        .selectField('Oncology_Lab_Manufacturer_Comparison__c')
        .selectField('Signed_Open_Offer__c')
        .selectField('Open_Offer_Comparison_Customer__c')
        .selectField('Is_Updated_By_System__c')
        // End of DCP-53342
        
        .toSOQL();
        System.debug('AccountsSelector====='+strQuery);
        List<Account> lstAccount = Database.query(strQuery);
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(lstAccount.size());
        }
        return lstAccount;
    } 

  /*
    * @author Shaik Moulali
    * @date   12-11-2018
    * @description Fetch logeed in Community User's Id
    * @param Pass the Logged In user's Id 
    */
    public List<Account> selectLoggedInAccountList(List<Id> idAccounts) 
    {
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('id IN :idAccounts');

        String strQuery = query.selectField('id')
            .selectField(NAME)
            .selectField('RecordTypeId')
            .selectField(TERRITORY_REGION)
            .selectField('Channel_Partner_Type__c')
            .toSOQL();
        System.debug('AccountsSelector====='+strQuery);
        return Database.query(strQuery);
    }

    /*
    * @author Vishnu Priya Duggineni
    * @date   01-11-2018
    * @description fetch account details for SAP ERP customer Id
    * @param String ERP Customer Id
    */
    public List<Account> getAccountsforCustomerId(String strCustomerErpId)
    {
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('ERP_Customer_Id__c=:strCustomerErpId');

        String strQuery = query.selectField('id')
            .selectField(NAME)
            .selectField('ERP_Customer_Id__c')
            .toSOQL();
        return Database.query(strQuery);
    } 
	
    
     /*
    * @author Naomi Thammadi
    * @date   04-29-2019
    * @description Fetch account territories 
    * @param Pass list of account ids
    */
    public List<Account> getAccountsTerritories(Set<Id> accountIds)
    {
        return (List<Account>) Database.query(
        newQueryFactory().selectField('Id').selectField(TERRITORY_REGION).selectField('Territory_Name__c').selectField('District__c').setCondition('Id IN :accountIds').toSOQL());
    } 
	
	
    
    /*
    * @author :Vignesh S
    * @date   :09-20-2019
    * @description :Query to Fetch Account with related to Account to Field Support.
    * @param :AccIds - Id of Account to query; lstRolesToQuery - Account to field support Roles to Query.
    */
    public List<Account> accountWithFieldSupport(list<string> accIds , list<string> lstRolesToQuery){
        ilib_QueryFactory accountQuery = newQueryFactory();
        AccountQuery.selectField('Id');
        ilib_QueryFactory objAccountToFieldSupportSelector = new AccountToFieldSupportSelector().addQueryFactorySubselect(AccountQuery,'Account_Field_Support_Roles__r');
        objAccountToFieldSupportSelector.selectField('Id');
        objAccountToFieldSupportSelector.selectField('User__r.SVMXC__Salesforce_User__c');
        objAccountToFieldSupportSelector.selectField('User_Role__c');
        objAccountToFieldSupportSelector.setCondition('User_Role__c IN :lstRolesToQuery');
        return (List<Account>) Database.query(accountQuery.setCondition('Id IN :accIds').toSOQL());
    
    }
    /*
    * @author Kushagraesai
    * @date   04-29-2019
    * @description Fetch account territories 
    * @param Pass list of account ids
    */
    public List<Account> getAccountsHierarchy(String ultimateParentId, String ultimateParentName)
    {
        return (List<Account>) Database.query(
        newQueryFactory().selectField('Id').setCondition('Ultimate_Parent_Id__c =: ultimateParentId and Ultimate_Parent__c =: ultimateParentName').toSOQL());

    }
    /*
    * @author Kushagra Desai
    * @date   2-Sep-2020
    * @description DCP-39735 :  Fetch Channel partner account based on territory Code
    * @param String Territory Code
    *
    */
    public List<Account> selectDistributorAccountsByTerritoryCode(Set<String> setTerritoryCode) 
    {
        String strDistributorLabel = Label.AccountGroupDistributor;
        return (List<Account>) Database.query(
        newQueryFactory()
        .setCondition('Territory_Code__c IN :setTerritoryCode AND Account_Group__c =:strDistributorLabel').toSOQL());
    }   
	
      /*
    * @author Sandeep
    * @date   13-08-2020
    * @description Fetch account parent and account group 
    * @param List<object> lstAccountId
    */
     public List<Account> getParentAccount(set<Id> setAccountId)
    {
        return (List<Account>) Database.query(
        newQueryFactory().selectField('Id')
        .selectField('ParentId')
        .selectField('BillingCountryCode')//DCP-54438
        .selectField('Account_Status__c') //DCP-54438
        .selectField(NATIONAL_GROUP_NUMBER) //DCP-54438
        .selectField('Signed_Open_Offer__c') //DCP-54438
        .setCondition('Id IN :setAccountId').toSOQL());

    }
	
	/*
    * @author Maruthi
    * @date   19-05-2022
    * @description Fetch Related Accounts for the Account
    * @param accountIds Set of Account Ids
    *
    */
    public List<Account> selectRQAccounts(Set<Id> accountIds) {
        String serialized = UtilsCollection.serializeIds(accountIds);
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectAccounts',
            serialized
        );
        List<Account> res = (List<Account>) Database.query(
            newQueryFactory()            
            .selectField('Id')
            .selectField(R_Q_CONTACT_ELIGIBLE) //PM-122 Mark Account.R_Q_Contact_Eligible__c
            .setCondition('Id IN :accountIds and ' + R_Q_CONTACT_ELIGIBLE +  '= false')
            .toSOQL()
        );
        logger.stop(res.size());
        return res;
    }

    /*
    * @author Saddam 
    * @date   09-Mar-2022
    * @description Fetch Account for Rq details pm-33,pm-430
    * @param Pass list of account ids
    */
    public List<Account> getRqComplianceAccounts(Set<Id> accountIdset) {
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) 
        logger = new ilib_LogQuery(LOG_TITLE + '.getRqComplianceAccounts',UtilsCollection.serializeIds(accountIdset));

        List<Account> accquery = (List<Account>) Database.query(
        newQueryFactory(false).selectField('Id').selectField(R_Q_CONTACT_ELIGIBLE).selectField('R_Q_Contact_Compliant__c').selectField('R_Q_Non_Compliance_Date__c').setCondition('Id IN :accountIdset').toSOQL());

        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS))
            logger.stop(accquery.size());

        return accquery;
    } 

    /*
    * @author Saddam 
    * @date   09-Mar-2022
    * @description Fetch Account with related contacts,pm-33,pm-430
    * @param Pass set of account ids
    *return list of account queried 
    */
    public List<Account> accountWithRelatedContacts(set<id> accIds) {
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) 
        logger = new ilib_LogQuery(LOG_TITLE + '.accountWithRelatedContacts',UtilsCollection.serializeIds(accIds));

        ilib_QueryFactory accountQuery = newQueryFactory(false);
        accountQuery.selectField('Id');
        accountQuery.selectField(NAME);
        ilib_QueryFactory objAccountToContactSelector = new ContactsSelector().addQueryFactorySubselect(AccountQuery,'Contacts');
        objAccountToContactSelector.selectField('Id');
        objAccountToContactSelector.selectField('Lastname');
        List<Account> accquery = (List<Account>) Database.query(accountQuery.setCondition('Id IN :AccIds').toSOQL());
        
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS))
            logger.stop(accquery.size());

        return accquery;
    }

    /**
     *  @author Adyasha Satapathy
     *  @date   24-June-2022
     *  @description Fetch the list of Accounts with their child Market Segements 
     *  @param Set<Id> setAccountIds
     *  @return List<Account>
     * 
    **/
    public List<Account> selectAccountsWithMarketSegments(Set<Id> setAccountIds) {
        ilib_LogQuery logger = null;
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) { logger = new ilib_LogQuery(LOG_TITLE + '. selectAccountsWithMarketSegments',UtilsCollection.serializeIds(setAccountIds)); }
        ilib_QueryFactory query = newQueryFactory(false)
        .selectField('Id')
        .selectField('Market_Segment__c')
        .setCondition('Id IN :setAccountIds');

        query.subselectQuery('Market_Segments__r').selectFields(new MarketSegmentSelector().getSObjectFieldList());
        List<Account> res = (List<Account>) Database.query(query.toSOQL());

        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) logger.stop(res.size());
        return res;
    }
    /*
    * @author Rucha Dalvi
    * @date   07-11-2022
    * @description Fetch Related Accounts for the Parent Account
    * @param accountIds Set of Account Ids
    *
    */
    public List<Account> selectRelatedAccounts(Set<String> setNGN, Set<String> setStatusValue) {
        String serialized = UtilsCollection.serializeIds(setNGN);
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.selectRelatedAccounts',
            serialized
        );
        List<Account> res = (List<Account>) Database.query(
            newQueryFactory(false)            
            .selectField('Id')
            .selectField('ParentId')
            .selectField('BillingCountryCode')
            .selectField('Account_Status__c')
            .selectField(NATIONAL_GROUP_NUMBER)
            .selectField('Signed_Open_Offer__c')
            .setCondition(NATIONAL_GROUP_NUMBER + ' IN :setNGN AND Signed_Open_Offer__c != true AND Account_Status__c IN: setStatusValue')
            .toSOQL()
        );
        logger.stop(res.size());
        ilib_LogEvent.message('res : '+res.size());
        return res;
    }
     /**
     *  @author Avina
     *  @date   10-Oct-2022
     *  @description QACM-78 Fetch the list of Accounts with fieldName and display text for AccountLookupcontroller class
     *  @param Set<Id> fieldNameSet,value,dynamicCondition
     *  @return List<Account>
     * 
    **/
    public List<Account> selectAccountforLookupController(Set<String> fieldNameSet,String dynamicCondition,Integer queryLimit) {
        ilib_LogQuery logger = null;
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) { 
            logger = new ilib_LogQuery(LOG_TITLE + '. selectAccountforLookupController',UtilsCollection.serializeIds(fieldNameSet)); 
        }
        ilib_QueryFactory query = newQueryFactory();
        for(String fieldName : fieldNameSet) {
            query.selectField(fieldName);
        }
        query.setCondition(dynamicCondition);
        query.setLimit(queryLimit);
        List<Account> res = (List<Account>) Database.query(query.toSOQL());

        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
             logger.stop(res.size());
        }
        return res;
    }

    /**
     *  @author Satya Swain
     *  @date   01 September 2022
     *  @description Fetch the list of Accounts based on supplied National Group Number
     *  @param Set<String> setNationalGroupNumbers
     *  @return List<Account>
     * 
    **/
    public List<Account> selectAccountsForNationalGroupNumbers(Set<String> setNationalGroupNumbers) {
        ilib_LogQuery logger = null;
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) { logger = new ilib_LogQuery(LOG_TITLE + '. selectAccountsForNationalGroupNumbers',UtilsCollection.serializeIds(setNationalGroupNumbers)); }
        
        ilib_QueryFactory query = newQueryFactory(false)
        .selectField('Id')
        .selectField(NATIONAL_GROUP_NUMBER)
        .selectField('ERP_Customer_Id__c')
        .selectField('Name')
        .setCondition(NATIONAL_GROUP_NUMBER + ' IN :setNationalGroupNumbers');

        List<Account> res = (List<Account>) Database.query(query.toSOQL());

        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) { logger.stop(res.size()); }
        return res;
    }
    
    /**
     * DGP-103 : Method to fetch Account and related Account Sales Area records for given set of ERP Customer ID and Sales Org.
     **/
    public List<Account> fetchAccountAndRelatedSalesAreaRecords(Set<String> erpCustomerIdSet, Set<String> salesOrgSet) {
        
        ilib_LogQuery logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchAccountAndRelatedSalesAreaRecords',
            (UtilsCollection.serializeIds(erpCustomerIdSet) + ' --- ' + UtilsCollection.serializeIds(salesOrgSet))
        );
        
        ilib_QueryFactory query = newQueryFactory(false)
            .selectField('Id')
            .selectField('BillingCountry')
            .selectField('BillingCountryCode')
            .selectField('ERP_Customer_Id__c')
            .selectField(NATIONAL_GROUP_NUMBER)
            .selectField(TERRITORY_REGION)
            .setCondition('ERP_Customer_Id__c IN :erpCustomerIdSet');
        
        query.subselectQuery('Account_Sales_Areas__r')
            .selectField('Price_List_Type__c')
            .selectField('Sales_Organization__c')
            .selectField('Distribution_Channel__c')
            .setCondition('Sales_Organization__c IN :salesOrgSet');
        
        List<Account> res = (List<Account>) Database.query(query.toSOQL());
        
        logger.stop(res.size());
        ilib_LogEvent.message('res : '+res.size());
        
        return res;
    }
    
    /**
     * DGP-52 : Method to fetch Accounts and associated Account Sales Area records for given set of Account IDs.
     **/
    public List<Account> selectAccountsAndRelatedSalesArea(Set<Id> accountIdSet) {
        
        ilib_LogQuery logger;
        
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(
                LOG_TITLE + '.selectAccountsAndRelatedSalesArea',
                UtilsCollection.serializeIds(accountIdSet)
            );
        }
        
        ilib_QueryFactory query = newQueryFactory()
            .selectField('LastModifiedBy.Email')
            .selectField('Parent.ERP_Customer_Id__c')
            .selectField('Owner.Name')
            .selectField('Preferred_Language__c')
            .selectField(R_Q_CONTACT_ELIGIBLE)
            .selectField(NAME)
            .selectField('NameLocal')
            .selectField('Field_Comments__c')
            .selectField('Territory_Name__c')
            .setCondition('Id IN :accountIdSet');
        
        query.subselectQuery('Account_Sales_Areas__r')
            .selectField('Price_List_Type__c')
            .selectField('Sales_Organization__c')
            .selectField('Distribution_Channel__c');
            
        List<Account> accountList = (List<Account>) Database.query(query.toSOQL());
        
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(accountList.size());
        }
        
        return accountList;
    }
    
    /**
     * DGP-52 : Method to fetch Accounts and associated Account Sales Area records for given set of ERP Customer Numbers.
     **/
    public List<Account> selectAccountsAndRelatedSalesAreaForERPCustomerIds(Set<String> setErpCustomerIds) {
        
        ilib_LogQuery logger;
        
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(
                LOG_TITLE + '.selectAccountsAndRelatedSalesAreaForERPCustomerIds',
                UtilsCollection.serializeIds(setErpCustomerIds)
            );
        }
        
        ilib_QueryFactory query = newQueryFactory()
            .setCondition('ERP_Customer_Id__c IN :setErpCustomerIds');
        
        query.subselectQuery('Account_Sales_Areas__r')
            .selectField('Price_List_Type__c')
            .selectField('Sales_Organization__c')
            .selectField('Distribution_Channel__c');
        
        List<Account> accountList = (List<Account>) Database.query(query.toSOQL());
        
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(accountList.size());
        }
        
        return accountList;
    }

    /**
     *  @author Gerardo Garcia
     *  @description Fetch the list of Accounts with parentId.
     *  @param Set<Id> parentIds
     *  @return List<Account> children accounts.
     * 
    **/
    public List<Account> getChildrenAccounts(Set<Id> parentIds) {
        ilib_LogQuery logger = null;
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) { logger = new ilib_LogQuery(LOG_TITLE + '. getChildrenAccounts', UtilsCollection.serializeIds(parentIds)); }

        ilib_QueryFactory query = newQueryFactory()
        .selectField('parentId')
        .selectField('RecordTypeId')
        .setCondition('parentId IN :parentIds');

        List<Account> res = (List<Account>) Database.query(query.toSOQL());

        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) { logger.stop(res.size()); }
        return res;
    }
    /**
     *  @author Kumar Gaurav
     *  @description Fetch the list of Accounts with parentId. 
     *  @param Set<Id> parentIds
     *  @return List<Account> accounts.
     * 
    **/
    public List<Account> getAccountwithIds(Set<Id> accIds) {
        ilib_LogQuery logger = null;
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) { logger = new ilib_LogQuery(LOG_TITLE + '. getAccountwithId', UtilsCollection.serializeIds(accIds)); }
     
        ilib_QueryFactory query = newQueryFactory()
        .selectField('Id')
        .selectField('Territory_Region__c')
        .setCondition('id IN :accIds');

        List<Account> res = (List<Account>) Database.query(query.toSOQL());
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) { logger.stop(res.size()); }
        return res;
    }
}