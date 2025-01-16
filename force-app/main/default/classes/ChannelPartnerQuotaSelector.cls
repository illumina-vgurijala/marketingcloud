/**
 *    @author Kushagra Desai
 *    @date   11-Sept-2020
 *    @description : Selector class for Channel_Partner_Quota__c
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Nishan Shetty                16-Nov-2021          DCP-50448 Added New Fields to getSObjectFieldList method.
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ChannelPartnerQuotaSelector extends ilib_SObjectSelector{
    private String strOrderByClause;
    /*
    * @author KD
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {  
        return new List<Schema.SObjectField> {
            Channel_Partner_Quota__c.id,
            Channel_Partner_Quota__c.Account_Name__c,
            Channel_Partner_Quota__c.FY_Quota__c,
            Channel_Partner_Quota__c.Year__c,
            //START DCP-50448
            Channel_Partner_Quota__c.CurrencyIsoCode,
            Channel_Partner_Quota__c.Name,
            Channel_Partner_Quota__c.Quarter_1__c,
            Channel_Partner_Quota__c.Quarter_2__c,
            Channel_Partner_Quota__c.Quarter_3__c,
            Channel_Partner_Quota__c.Quarter_4__c
            //END DCP-50448
        };
    }
    /*
    * @author KD
    * @date   
    * @description  Order By override
    *
    */
    public override String getOrderBy()
    {   
        if(String.isNotBlank(strOrderByClause))
            return strOrderByClause;  
        else 
            return super.getOrderBy(); 
    }
    /*
    * @author KD
    * @date   
    * @description  Describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    { 
        return Channel_Partner_Quota__c.sObjectType;
    }
    private ilib_QueryFactory getRelatedFieldsQuery(){
        return newQueryFactory()
            .selectField('Account_Name__c.Territory_Code__c');
    }
    /**
     * @author : KD
     * @description return Quota Records
     * Returns List<Channel_Partner_Quota__c> sObject Record 
     **/
    public List<Channel_Partner_Quota__c> getQuotaByAccountWithFYQuota(Set<Id> setAccountIds)
    {
        strOrderByClause = 'LastModifiedDate DESC';
        return (List<Channel_Partner_Quota__c>)Database.query(
            getRelatedFieldsQuery()
            .setCondition('Account_Name__c IN :setAccountIds AND FY_Quota__c > 0')
            .toSOQL());
    }
    /**
     * @author : KD
     * @description return Quota Records
     * Returns List<Channel_Partner_Quota__c> sObject Record 
     **/
    public List<Channel_Partner_Quota__c> getQuotaByAccount(List<Id> setAccountIds)
    {
        strOrderByClause = 'LastModifiedDate DESC';
        return (List<Channel_Partner_Quota__c>)Database.query(
            getRelatedFieldsQuery()
            .setCondition('Account_Name__c IN :setAccountIds')
            .toSOQL());
    }
}