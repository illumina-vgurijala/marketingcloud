/**
 *    @author Rahul Sharma
 *    @date   14-Jan-2020
 *    Modification Log:
 *   Test class for 90% coverage: TestApttusAgreements,
 *   Test class for 75% coverage: TestOpenOfferagreements (for Open Offer )
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Rahul Sharma                  14-Jan-2020          Created
 *    B Kamini                      08-Feb-2020          Modified as part of DCP-33776
 *    Kushagra Desai             1-Mar-2020              Added field
 *    Rahul Bishnoi                 15-June-2020         Modified as part of TASK0486150
 *    Rishab Wali                   23-Nov-2020          DCP-43224 Adding Agreement Account in the query.
 *    Khushbu Vasani                 7-January-2022      INC0350167 - sort by customer name in pricing output paramters
 *    Bharath Varma                 30-Mar-2022          TASK0718153 - Added a new method selectByAccountId
 *    Aman Tyagi                    31-March-2022        CodeScan Fixes
 *     Saddam                       02-sep-2022            DCP-54536  Added Feields to fieldlist.
 *    --------------------------------------------------------------------------------------------------------------------------
 */ 
public class AgreementAccountRelationshipSelectors extends ilib_SObjectSelector{
    private static final string  LOG_TITLE = 'AgreementAccountRelationshipSelectors';
    private static final  string SALES_QUERY_LOGS = 'SalesQueryLogs';

    string strOrderByClause;

     /**
    *  @author Rahul Sharma 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Line Items
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Agreement_Account_Relationship__c.sObjectType;
    }
    /**
     *  @author Kushagra Desai
     *  @description Retrieve list of fields for Line Item sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Agreement_Account_Relationship__c.id,
            Agreement_Account_Relationship__c.Name,
            Agreement_Account_Relationship__c.Account__c,
            Agreement_Account_Relationship__c.Agreement__c,
            Agreement_Account_Relationship__c.Agreement_Output_Visibility__c,
            Agreement_Account_Relationship__c.Customer_ERP_Number__c,
            Agreement_Account_Relationship__c.Agreement_Status__c,
            //Added fields as part of DCP-54439 
            Agreement_Account_Relationship__c.Include_In_Annual_Consumable_Spend__c,
            Agreement_Account_Relationship__c.Opt_In_Receiving_Open_Offer_Discount__c,
            Agreement_Account_Relationship__c.Consider_for_GF_Discount_Calculation__c
            //End of DCP-54439 
        };
    }
    /**
     *  @author Rahul Sharma 
     *  @description fetch Line Items for the ids passed in the argument
     *  @param idSet set of line item ids
     *  @return list of line item records
     **/
    public List<Agreement_Account_Relationship__c> selectByAgreementId(Set<Id> setAgreementId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SALES_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByAgreementId', UtilsCollection.serializeIds(setAgreementId));


        List<Agreement_Account_Relationship__c> res = (List<Agreement_Account_Relationship__c>) Database.query(
                                newQueryFactory()
                                .selectField('Account__r.ERP_Customer_Id__c')
                                .selectField('Account__r.Name')
                                .selectField('Customer_ERP_Number__c')
                                .selectField('Agreement__r.Account_ERP_Number__c')
                                .selectField('Account__c')//DCP-33776
                                .selectfield('Agreement__c')//DCP-33776
								.selectfield('Agreement__r.Apttus__Account__c')//DCP-43224
                                .setCondition('Agreement__c IN :setAgreementId')
                                .toSOQL()
                                  );
                                  
        if(Feature.isOn(SALES_QUERY_LOGS))
        logger.stop(res.size());

        return res;
    }
      /**
     *  @author Aman Tyagi
     *  @description fetch the records for the ids passed in the argument account relationship
     *  @param idSet set of agreement ids
     *  @return list of agreement account relationship item records
     **/
    public List<Agreement_Account_Relationship__c> selectByAgreementIdAndOpenOffer(Set<Id> setAgreementId) 
    {
        String strCondition = 'Agreement__c IN :setAgreementId AND Opt_In_Receiving_Open_Offer_Discount__c= True';

        ilib_LogQuery logger=null;
        if(Feature.isOn(SALES_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByAgreementId', UtilsCollection.serializeIds(setAgreementId));

        List<Agreement_Account_Relationship__c> res = (List<Agreement_Account_Relationship__c>) Database.query(
                                newQueryFactory()
                                .selectField('Account__r.Name')
                                .selectField('Account__r.ERP_Customer_Id__c')
                                .selectField('Include_In_Annual_Consumable_Spend__c')
                                .selectField('Agreement__r.RecordType.DeveloperName')
                                .selectField('Consider_for_GF_Discount_Calculation__c')
                                .selectField('Opt_In_Receiving_Open_Offer_Discount__c')
                                .setCondition(strCondition)
                                .toSOQL()
                                  );
                                  
        if(Feature.isOn(SALES_QUERY_LOGS))
        logger.stop(res.size());

        return res;
    }

    //INC0350167 - sort by customer name in pricing output paramters
    /*
    * @Description : method for returning order
    * @param : null
    * @return : String
    */
    public override String getOrderBy()
    {   
        if(String.isNotBlank(strOrderByClause))
            return strOrderByClause;  
        else 
            return super.getOrderBy(); 
    }

    /**
     *  @author Khushbu 
     *  @description fetch Line Items for the ids passed in the argumentsorted by account name
     *  @param idSet set of line item ids
     *  @return list of line item records
     **/
    public List<Agreement_Account_Relationship__c> selectByAgreementIdSortedByAccountName(Set<Id> setAgreementId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SALES_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByAgreementIdSortedByAccountName', UtilsCollection.serializeIds(setAgreementId));

        strOrderByClause = 'Account__r.Name';
        List<Agreement_Account_Relationship__c> res = (List<Agreement_Account_Relationship__c>) Database.query(
                                newQueryFactory()
                                .selectField('Account__r.ERP_Customer_Id__c')
                                .selectField('Account__r.Name')
                                .selectField('Customer_ERP_Number__c')
                                .selectField('Agreement__r.Account_ERP_Number__c')
                                .selectField('Account__c')//DCP-33776
                                .selectfield('Agreement__c')//DCP-33776
								.selectfield('Agreement__r.Apttus__Account__c')//DCP-43224
                                .setCondition('Agreement__c IN :setAgreementId')
                                .toSOQL()
         );

      
      if(Feature.isOn(SALES_QUERY_LOGS))
        logger.stop(res.size());

      return res;

    }

    /**
     *  @author Bharath Varma 
     *  @description fetch records where the Account Id is in setAccountId
     *  @param idSet set of line item ids
     *  @return list of Agreement Account Relationship records
     **/
    public List<Agreement_Account_Relationship__c> selectByAccountId(Set<Id> setAccountId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SALES_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByAccountId', UtilsCollection.serializeIds(setAccountId));

        List<Agreement_Account_Relationship__c> res = (List<Agreement_Account_Relationship__c>) Database.query(
                                newQueryFactory()
                                .setCondition('Account__c IN :setAccountId')
                                .toSOQL()
         );

      
      if(Feature.isOn(SALES_QUERY_LOGS))
        logger.stop(res.size());

      return res;

    }
}