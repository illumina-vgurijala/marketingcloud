/**
*    @author Roopal Verma
*    @date   2018-08-1
*    @description    DCP-4498: Consortium Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Roopal Verma                  1 Aug 2018         Consortium Selector class
*             Himanshu                      30 Mar 2022        Code Scan Fixes 
*             Aman Tyagi                    12 Dec 2022        CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class Consortiumselector extends ilib_SObjectSelector{
    /*
    *   @author Roopal Verma      
    *   @date   1 Aug 2018   
    *   @description  Describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return Consortium__c.sObjectType;
    }
    
    /**
    *  @author  Roopal Verma
    *  @description Retrieve list of fields for Consortium Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Consortium__c.id,
            Consortium__c.Open_Closed_Consortium__c
        }; 
    }
    
    /**
    *  @author Roopal Verma
    *  @description Fetch the Consortium
    *  @param Set of consortium Ids
    *  @return List of Accounts  
    **/
    public List<Consortium__c> selectConsortium(Set<Id> consortiumId) 
    {
        return (List<Consortium__c>) Database.query(
                                    newQueryFactory().setCondition('id IN :consortiumId').toSOQL()
        );
    }   
    
}