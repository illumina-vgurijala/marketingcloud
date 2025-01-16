/**
*    @author Roopal Verma
*    @date   2018-07-31
*    @description    DCP-4498: ConsortiumAccount Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Roopal Verma                  31 July 2018         ConsortiumAccount Selector class
*             Himanshu                      2022-03-30           Code Scan Fixes  
*             Prem Ranjan                   20-Feb-2023          CodeScan Fixes (APEX) Variable Naming Conventions  
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ConsortiumAccountSelector extends ilib_SObjectSelector{
    /*
    *   @author Roopal Verma      
    *   @date   31 July 2018
    *   @description  Describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return Consortium_Account__c.sObjectType;
    }
    
    /**
    *  @author  Roopal Verma
    *  @description Retrieve list of fields for Consortium Account sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Consortium_Account__c.id,
            Consortium_Account__c.Consortia__c,
            Consortium_Account__c.Account__c,
            Consortium_Account__c.Is_InActive__c
        }; 
    }
    
    /**
    *  @author Roopal Verma
    *  @description Fetch the Consortium Accounts
    *  @param Set of consortium Ids
    *  @return List of Accounts  
    **/
    public List<Consortium_Account__c> selectConsortiumAccount(Set<Id> consortiumId) 
    {
        return (List<Consortium_Account__c>) Database.query(
                                    newQueryFactory().setCondition('Is_InActive__c = false AND Consortia__r.id IN :consortiumId').toSOQL()
        );
    }   
    
}