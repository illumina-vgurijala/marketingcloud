/**
 *    @author Kushagra Desai
 *    @date   29-Aug-2019
 *    @description  Selector class for Competitive_Complementary_Technology__c
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Jitesh Lakhwani                6-July-2022         Code Scan fixes of Comments
 *    Saddam                         08-Dec-2022         Codescan Fix , Varaible naming convention. 
 *    Prem Ranjan                    20th Feb 2022       Codesan fixes (APEX) Variable Naming Conventions
 *    Gerardo Garcia                 01-Mar-2024         Add new methods for identifyng recordTypes CMCM-5856.
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class CompetitiveTechnologySelector extends ilib_SObjectSelector{
    public final static String ACCOUNT_RECORD_TYPE = 'Account Competitive and Complementary Technology';
    public final static String OPPORTUNITY_RECORD_TYPE = 'Opportunity Competitive and Complementary Technology';
    
    /**
     *  @description Retrieve list of fields for Competitive Complementary Technology
     *  @param : None
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Competitive_Complementary_Technology__c.id,
            Competitive_Complementary_Technology__c.name,
            Competitive_Complementary_Technology__c.CompetitorName__c,
            Competitive_Complementary_Technology__c.Account__c,
            Competitive_Complementary_Technology__c.ProductName__c,
            Competitive_Complementary_Technology__c.Product_Name_Other__c,
            Competitive_Complementary_Technology__c.Number_Of_Units__c,
            Competitive_Complementary_Technology__c.Company_Other__c,
            Competitive_Complementary_Technology__c.Is_In_Use__c,
            Competitive_Complementary_Technology__c.Company_Other__c,
            Competitive_Complementary_Technology__c.Product_Name_Other__c

        };
    }

    /**
    * @description: Method to retrieve the SObjectType of Competitive Complementary Technology
    * @param : None
    * @return: Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType()
    {
        return Competitive_Complementary_Technology__c.sObjectType;
    }
    /*
    * @author Kushagra Desai
    * @date   29-Aug-2019
    * @description Aggregate roll up of all data
    * @param accountIds Set of Account Ids
    *
    */
    public List<AggregateResult> getAggregateResult(String strGroupByField,Set<Id> accountIds) 
    {
        String query = 'Select '+strGroupByField+' ,count(id) NumberOfRecord from Competitive_Complementary_Technology__c where account__c IN: accountIds group by '+strGroupByField;
        System.debug('---query--- '+query);
        return Database.query(query);
    }
    /*
    * @author Kushagra Desai
    * @date   29-Aug-2019
    * @description Get all competitive data for account
    * @param accountIds Set of Account Ids
    *
    */
    public List<Competitive_Complementary_Technology__c> getAllRecords(Set<Id> accountIds,Integer offset,String strCompanyName) 
    {
        return (List<Competitive_Complementary_Technology__c>)Database.query(
            newQueryFactory()
            .selectfield('Account__r.Name')
            .selectfield('CreatedBy.Name')
            .setCondition('Account__c =: accountIds AND CompetitorName__c =: strCompanyName')
            .setLimit(20)
            .setOffSet(offset)
            .toSOQL());
    }

    /**
     * description: Get Single CCT by Id
     * @param: Id of the CCT
     */
    public Competitive_Complementary_Technology__c getRecodById(Id recordId){
        return (Competitive_Complementary_Technology__c)Database.query(
            newQueryFactory()
            .selectfield('RecordType.Name')
            .setCondition('Id = :recordId')
            .setLimit(1)
            .toSOQL());
    }

    /**
     * description: Determines if is record type account
     * @param: cct record
     */
    public static Boolean isAccountType(Competitive_Complementary_Technology__c cct) {
        return cct.RecordType.Name == ACCOUNT_RECORD_TYPE;
    }

    /**
     * description: Determines if is record type account
     * @param: cct record
     */
    public static Boolean isOpportunityType(Competitive_Complementary_Technology__c cct) {
        return cct.RecordType.Name == OPPORTUNITY_RECORD_TYPE;
    }

    /**
     * @author Gerardo Garcia
     * @description retrieves record type Id of CCT for Account
     * @return Id
     */
    public static Id getAccountTypeId() {
        return Schema.SObjectType.Competitive_Complementary_Technology__c.getRecordTypeInfosByName().get(CompetitiveTechnologySelector.ACCOUNT_RECORD_TYPE).getRecordTypeId();
    }

    /**
     * @author Gerardo Garcia
     * @description retrieves record type of CCT for Opportunity
     * @return Id
     */
    public static Id getOpportunityTypeId() {
        return Schema.SObjectType.Competitive_Complementary_Technology__c.getRecordTypeInfosByName().get(CompetitiveTechnologySelector.OPPORTUNITY_RECORD_TYPE).getRecordTypeId();
    }
}