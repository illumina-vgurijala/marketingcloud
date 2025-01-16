/**
*    @author Indra Ganesan
*    @date   2018-05-25
*    @description    DCP-1010,598: Opportunity Selector class
*	 @Test Class Coverage: 90% --> TestOpportunitySelector, 75% --> TestOpportunitySelector
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
*     Indra Ganesan              25 May 2018            Opportunity Selector Class
*     Govind Dubey               28 June 2018           Added Are_Products_Added_by_Channel_Partner__c field for query
*     Indra Ganesan              10 July 2018           Added Are_Products_Added__c
*     Rahul Sharma               06 Aug  2018           Added Price_List__c for query
*     Roopal Verma               11 Aug  2018           Added selectConsortiumOpp for getting Consrtiums on Opportunity
*     Akash Kumar                29 Sep 2018            Added selectUtimateConsigneeOpp
*     Akash Kumar                29 Sep 2018            Added selectDistributorOpp
*     Satya Swain                04 Sep 2019            Added cache for selectOpportunities method as part of INC0225110
*     Saurav Bhandari            10 Nov 2019            Added Is_Customer_Readiness_Form_Required__c field in the query
*     Saurav Bhandari            6 March 2020           Added Partner_Request__c,Product_Interest__c and Partner_Request__r.RecordType.DeveloperName field in selectOpportunities method query
*     Tapas                      11 Sep 2020            New method selectOpportunitiesByAgreementIdsAccIdsClosedates
*     Rishab Wali                8 March 2021           DCP-45453 Quote Improvements
*     Rishab Wali                15 March 2021          DCP-43259 Quote Improvements
*     Bharath Varma              16 March 2021          DCP-43259 Quote Imporvements
*     Rishab                     27 Mar 2021            DCP-45454 Added Field on selectOpportunity method
*     Todd                       13 Apr 2021            DCP-45737: Add quote instrumentation (with feature flag)
*     Adyasha Satapathy          10 May 2021            DCP-38809/DCP-46472 : Added fields to selectOpportunities method
*     KD                         31 May 2021            DCP-38933 : Added fields to selectOpportunities method and deleted SelectById method
*     Akshay Mohan               07 June 2021           DCP-46835: Add Exclude_from_Forecast__c
*     Anand Palla                15 Jun 2021            DCP-46168 : Added fields to selectOpportunities method
*     KD                         29-June-2021           DCP-46226 : Add field Product intrest, Account Billing Country
*     Adyasha                    03-Dec-2021            DCP-50392: Added new method selectOpportunitiesByAccountRecordIds
*     Maruthi                    07-Sep-2022            DCP-54459: Updated selectOpportunitiesByAccountRecordIds to add new fields
*     Atit Kar                   21-Mar-2023            TASK0876760 - Added fields Business Unit, Subregion
*     Arquimidez Mora            10-Aug-2024            CMCM-9644 Added new methods fetchOpportunityRelatedToWorkOrders and selectOpportunityWithFields
*    ----------------------------------------------------------------------------------------------------------------------
*/
public with sharing class OpportunitySelector extends ilib_SObjectSelector {

    private final String LOG_TITLE = 'OpportunitySelector';
    private static final string QUERY_LOGS_SALES = 'SalesQueryLogs';

    // Added by Satya for INC0225110
    private static Map<String, List<Opportunity>> cacheForSelectOpportunities = new Map<String, List<Opportunity>>();

    private static Map<String, List<Opportunity>> cacheForSelectRelatedOpportunities = new Map<String, List<Opportunity>>();

    /*Method - getSObjectType */
    public Schema.SObjectType getSObjectType()
    {
        return Opportunity.sObjectType;
    }

    /**
     *  @author  Indra Ganesan
     *  @description Retrieve list of fields for Opportunity sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Opportunity.Id,
           Opportunity.OwnerId,
           Opportunity.Product_Type__c,
           Opportunity.Are_Products_Added_by_Channel_Partner__c,
           Opportunity.Are_Products_Added__c,
           Opportunity.StageName,
           Opportunity.Consortium__c,
           Opportunity.First_Proposal_Id__c,
           Opportunity.Type,
           Opportunity.Price_List__c,
           Opportunity.Consortium__c,
           Opportunity.AccountId,
           Opportunity.Ultimate_Consignee__c,
           Opportunity.Sales_Area_Sold_To__c,
           Opportunity.Sales_Area_Ultimate_Consignee__c,
           Opportunity.RecordTypeId,
           Opportunity.Distributor__c,
           Opportunity.Sales_Area_Distributor__c,
           Opportunity.Direct_Sale_to_Ultimate_Consignee__c,
           Opportunity.Is_Updated_By_System__c,
           Opportunity.ICE_Opportunity_Product_Lines__c,
           Opportunity.Account_Change__c,
           Opportunity.Sold_To_Account_Region__c,
           Opportunity.Ultimate_Consignee_Region__c,
           Opportunity.Ship_To_Sales_Org__c,
           Opportunity.Product_Interest__c // DCP-46226
       };
    }

    // Deleted SelectById method, Please use selectOpportunities method

    /**
     *  @author Indra Ganesan
     *  @description Fetch Related Opportunities for the Opportunity
     *  @param opportunityIds Set of Opportunity Ids
     *  @return OpportunityContactRoleList List of OpportunityContactRole
     **/

    /**
     *  @author Satya Swain
     *  @description removed cached results for selectOpportunities() method
     **/
    public static void clearOpportunityCache()
    {
        cacheForSelectOpportunities = new Map<String, List<Opportunity>>();
    }

    /*Method - selectOpportunities , Param - Set<Id> */
    public List<Opportunity> selectOpportunities(Set<Id> opportunityIds)
    {
        String serialized = UtilsCollection.serializeIds(opportunityIds);

        if (cacheForSelectOpportunities.containsKey(serialized)){
            System.debug('@@@@ Inside if, cache contains key, value is: '+cacheForSelectOpportunities.get(serialized));
            return cacheForSelectOpportunities.get(serialized);
        }

        System.debug('@@@@ outside if, querying the records again');
        ilib_LogQuery logger;
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectOpportunities',
            serialized
        );

        List<Opportunity> res = (List<Opportunity>) Database.query(
            newQueryFactory()
            .selectField('RecordType.DeveloperName')
            .selectField('Account.ERP_Customer_Id__c')
            .selectField('Account.Owner.Id')
            .selectField('Ultimate_Consignee__r.Owner.Id')
            .selectField('Ultimate_Consignee__r.CurrencyIsoCode')
            .selectField('Sales_Area_Distributor__c')
            .selectField('Ultimate_Consignee__r.ERP_Customer_Id__c')
            .selectField('ByPass_Change_Record_Type_To_Standard__c')
            .selectField('Ultimate_Consignee__r.BillingCountry')
            .selectField('Distributor__r.BillingCountry')
            .selectField('Distributor__r.ERP_Customer_Id__c')
            .selectField('RecordTypeName__c')
            .selectField('Account_Change__c')
            .selectField('Is_Customer_Readiness_Form_Required__c')
            .selectField('Partner_Request__c')
            .selectField('Product_Interest__c')
            .selectField('Primary_Contact__c')
            .selectField('Is_Power_Sponsor_Identified__c')
            .selectField('Is_Contact_Role_Identified__c')
            .selectField('Partner_Request__r.RecordType.DeveloperName')
            .selectField('CurrencyIsoCode')
            .selectField('Territory_Region__c') //DCP-45453
            .selectField('Account.Preferred_Language__c') //DCP-45453
            .selectField('Account.Apttus_Config2__PaymentTermId__c') //DCP-45453
            .selectField('Company_Code_Address__c') //DCP-45453
            .selectField('Contract_Number__c') //DCP-45453
            .selectField('Consortium__r.Project_Manager__c') //DCP-45453
            .selectField('Sold_to_Distribution_Channel__c') //DCP-45453
            .selectField('Sold_to_Division__c') //DCP-45453
            .selectField('Sold_to_Sales_Organization__c') //DCP-45453
            .selectField('Primary_Contact__r.Email') //DCP-45453
            .selectField('Is_Quote_Stage_In_Review__c')//DCP-43259
            .selectField('ByPass_LockSentProposalDate__c')//DCP-43259
            .selectField('Proposal_Sent_On__c')//DCP-43259
            .selectField('Account.CurrencyIsoCode')//DCP-45454
            .selectField('Work_Order__c')//DCP-38809
            .selectField('Work_Order__r.Name')//DCP-38809
            .selectField('Work_Order__r.Initiate_Quoting__c')//DCP-38809
            .selectField('Primary_Contact__r.Email')//DCP-38809
            .selectField('Work_Order__r.SVMXC__Site__r.ERP_Customer_ID__c')//DCP-38809
            // DCP-46472
            .selectField('Work_Order__r.Owner.Email')
            .selectField('Work_Order__r.Owner.type')
            .selectField('Work_Order__r.Account_Region__c')
            .selectField('Work_Order__r.OwnerId')
            // DCP-46472 Ends
            // DCP-38933
            .selectField('Primary_Field_Service_Engineer__c')
            .selectField('Primary_Field_Application_Scientist__c')
            .selectField('Primary_Contact__r.Phone')
            // DCP-38933 ends
            //DCP-46835: Start
            .selectField('Exclude_from_Forecast__c')
            //DCP-46835: End
			.selectField('Account.CurrencyIsoCode')//DCP-45454
            //DCP-46168: Start
            .selectField('Related_Agreement__r.Owner.Email')
            .selectField('Related_Agreement__r.Apttus__Account__r.Territory_Region__c')
            .selectField('Related_Agreement__r.OwnerId')
            //DCP-46168: End
            .selectField('Account.BillingCountry') //DCP-46226
            .selectField('Transborder_Flag__c')//DCP-56658
            .selectField('Distributor__r.Owner.ID')
            .selectField('Price_List_Type__c')
            //TASK0876760 : Start
            .selectField('Account.Business_Unit__c')
            .selectField('Account.Subregion__c')
            .selectField('Ultimate_Consignee__r.Business_Unit__c')
            .selectField('Ultimate_Consignee__r.Subregion__c')
            .selectField('Distributor__r.Business_Unit__c')
            .selectField('Distributor__r.Subregion__c')
            .selectField('Is_Updated_From_Contact_Role__c')
            //TASK0876760 : End
            .setCondition('Id IN :opportunityIds')
            .toSOQL()
        );

        cacheForSelectOpportunities.put(serialized,res);
        System.debug('@@@@ value of opty query result: '+res);

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

    /*Method - selectConsortiumOpp , Param - Set<Id>*/
    public List<Opportunity> selectConsortiumOpp(Set<Id> setConsortiumId)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectConsortiumOpp',
            UtilsCollection.serializeIds(setConsortiumId)
        );

        List<Opportunity> res = (List<Opportunity>) Database.query(
            newQueryFactory()
            .setCondition('Consortium__c IN :setConsortiumId')
            .toSOQL()
        );

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

    /*Method - selectByAccountIds , Param - Set<Id> */
    public List<Opportunity> selectByAccountIds(Set<Id> accountIds)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectByAccountIds',
            UtilsCollection.serializeIds(accountIds)
        );

        List<Opportunity> res = (List<Opportunity>) Database.query(
            newQueryFactory()
            .setCondition('AccountId IN :accountIds')
            .toSOQL()
        );

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

    /*Method - SelectByAccountOrUCIds , Param - Set<Id> */
    public List<Opportunity> selectByAccountOrUCIds(Set<Id> accountIds)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectByAccountOrUCIds',
            UtilsCollection.serializeIds(accountIds)
        );

        List<Opportunity> res = (List<Opportunity>) Database.query(
            newQueryFactory()
            .setCondition('AccountId IN :accountIds OR Ultimate_Consignee__c IN :accountIds')
            .toSOQL()
        );

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

    /*Method - selectRelatedOpenOpportunities , Param - Set<Id>*/
    public List<Opportunity> selectRelatedOpenOpportunities(Set<Id> setRelatedAccountIds)
    {
        return selectRelatedOpportunities(setRelatedAccountIds, 'open');
    }

    /**
     *  @param setRelatedAccountIds account IDs for sold to or UC
     *  @description returns open opps related to those accounts
     **/
    public List<Opportunity> selectRelatedClosedOpportunities(Set<Id> setRelatedAccountIds)
    {
        return selectRelatedOpportunities(setRelatedAccountIds, 'closed');
    }

    private List<Opportunity> selectRelatedOpportunities(Set<Id> setRelatedAccountIds, String stageKind)
    {
        String serialized = stageKind + '~' + UtilsCollection.serializeIds(setRelatedAccountIds);

        if (cacheForSelectRelatedOpportunities.containsKey(serialized)){
            return cacheForSelectRelatedOpportunities.get(serialized);}

        // need local variables for query parsing
        Set<String> directRecordTypeNames = Opportunities.DIRECT_RECORD_TYPES;
        Set<String> indirectRecordTypeNames = Opportunities.INDIRECT_RECORD_TYPES;

        Set<String> openStatuses = Opportunities.OPEN_STATUSES;
        Set<String> closedStatuses = Opportunities.CLOSED_STATUSES;

        String stageClause = '';
        if ('open'.equals(stageKind)) stageClause = ' AND StageName IN :openStatuses';
        if ('closed'.equals(stageKind)) stageClause = ' AND StageName IN :closedStatuses';

        ilib_LogQuery logger;
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectRelatedOpportunities',
            serialized
        );

        List<Opportunity> res = (List<Opportunity>) Database.query(
            newQueryFactory(false)
            .selectField('Id')
            .setCondition('((Ultimate_Consignee__c IN :setRelatedAccountIds AND RecordType.DeveloperName IN :directRecordTypeNames) '
                + 'OR (Distributor__c IN :setRelatedAccountIds AND RecordType.DeveloperName IN :indirectRecordTypeNames))'
                + stageClause)
            .toSOQL()
        );

        cacheForSelectRelatedOpportunities.put(serialized, res);
        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

    /*Method -  selectOpportunitiesByAgreementIdsAccIdsClosedates , Param - Set<Id>,Set<Id>,Set<Date>,Set<Id> */
    public List<Opportunity> selectOpportunitiesByAgreementIdsAccIdsClosedates(Set<Id> agreementIds, Set<Id> accountIds, Set<Date> setLastDateOfQuarters, Set<Id> setStandingQuoteOppIds)
    {
        Set<String> closedLostStatuses = new Set<String> {Opportunities.STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED};
        String stageClause = ' AND StageName NOT IN :closedLostStatuses';

        String serialized = UtilsCollection.serializeIds(agreementIds) + '~' + UtilsCollection.serializeIds(accountIds) + '~' + setLastDateOfQuarters + '~' + UtilsCollection.serializeIds(setStandingQuoteOppIds);
        ilib_LogQuery logger;
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectOpportunitiesByAgreementIdsAccIdsClosedates',
            serialized
        );

        List<Opportunity> res = (List<Opportunity>) Database.query(
            newQueryFactory()
            .selectField('Related_Agreement__c')
            .selectField('CloseDate')
            .selectField('Last_Date_Of_Quarter__c')
            .setCondition('Id NOT IN :setStandingQuoteOppIds AND AccountId IN :accountIds AND Related_Agreement__c IN :agreementIds AND Last_Date_of_Quarter__c = :setLastDateOfQuarters' + stageClause)
            .toSOQL()
        );

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

     /**
     * @author Adyasha
     * @date   03-December-2021
     * @description  DCP-50392 get Opportunity records on the basis of Account or UC or Distributor relationship supplied by set of RecordIds
     * @param set of Account Ids
     */
    public List<Opportunity> selectOpportunitiesByAccountRecordIds(Set<Id> accountIds)
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn(QUERY_LOGS_SALES)) { logger = new ilib_LogQuery(LOG_TITLE + '.selectOpportunitiesByAccountRecordIds', UtilsCollection.serializeIds(accountIds)); }

        List<Opportunity> res = [
            SELECT Id,Name,StageName,CloseDate,RecordType.Name,CurrencyIsoCode,Probability,Amount,Market_Segment__c,Product_Type__c,OwnerId,Owner.Name, Account.Name, Account.ERP_Customer_Id__c, Account.Ultimate_Parent__c //DCP-54459
            FROM Opportunity 
            WHERE AccountId IN :accountIds 
            OR Ultimate_Consignee__c IN :accountIds 
            OR Distributor__c IN :accountIds
        ];

        if (Feature.isOn(QUERY_LOGS_SALES)) { logger.stop(res.size()); }
        return res;
    }

    /*
     * @Author : Arquimidez Mora
     * @Decription : Fetch Opportunities related to Work Orders
     * @return  Opportunity List
     */
    public List<Opportunity> fetchOpportunityRelatedToWorkOrders(Set<Id> setWorkOrderIds)
    {
        List<Opportunity> res = (List<Opportunity>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .setCondition('Work_Order__c IN :setWorkOrderIds')
            .toSOQL()
        );

        return res;
    }

    /*
     * @Author : Arquimidez Mora
     * @Decription : Fetch Opportunities with fields from parameter list
     * @return  Opportunity List
     */
    public List<Opportunity> selectOpportunityWithFields(Set<Id> setOpportunityIds, List<String> lstFields)
    {
        ilib_QueryFactory objQueryFactor = newQueryFactory();

        for(String strField : lstFields){
            objQueryFactor.selectField(strField);
        }

        List<Opportunity> res = (List<Opportunity>) Database.query(
            objQueryFactor
            .setCondition('Id IN :setOpportunityIds')
            .toSOQL()
        );

        return res;
    }
}
