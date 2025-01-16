/**
 *    @author Prabhsimran Singh
 *    @date   4-March-2020
 *    @description    Class to get the Agreement Clause records based on different conditions 
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Prabhsimran Singh             3/4/2020             Added method as part of DCP-35369
 
 *    --------------------------------------------------------------------------------------------------------------------------
 */ 
public class ApttusAgreementClauseSelectors extends ilib_SObjectSelector{ 
/**
    *  @author Prabhsimran 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Agreement Clause
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Apttus__Agreement_Clause__c.sObjectType;
    }
    /**
     *  @author Prabhsimran
     *  @description Retrieve list of fields for Agreement Clause sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
		
            Apttus__Agreement_Clause__c.id,
            Apttus__Agreement_Clause__c.Apttus__Clause__c,
            Apttus__Agreement_Clause__c.Apttus__Action__c,
            Apttus__Agreement_Clause__c.Apttus__PrevText__c,
            Apttus__Agreement_Clause__c.Apttus__Text__c,
            Apttus__Agreement_Clause__c.Approval_Status__c
        };
    }    
    /**
     *  @author Prabhsimran
     *  @description fetch Agreement Clauses for the Agreement Ids passed in the argument
     *  @param idSet set of agreement ids
     *  @return list of clause records
     **/
    public List<Apttus__Agreement_Clause__c> selectByAgreementId(Set<Id> setAgreementId) 
    {
        return (List<Apttus__Agreement_Clause__c>) Database.query(
                                newQueryFactory()                                
                                .setCondition('Apttus__Agreement__c IN: setAgreementId')
                                .toSOQL()
      );
    }
}