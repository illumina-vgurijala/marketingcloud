/**
 *    @author Kushagra Desai
 *    @date   11-Dec-2019
 *    @description    Class to get the Agreement Error records based on different conditions 
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *       
 *    --------------------------------------------------------------------------------------------------------------------------
 */ 
public with sharing class AgreementErrorSelector extends ilib_SObjectSelector{
    /**
    *  @author Kushagra Desai 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Line Items
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Agreement_Error__c.sObjectType;
    }
    /**
     *  @author Kushagra Desai
     *  @description Retrieve list of fields for Line Item sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Agreement_Error__c.id,
            Agreement_Error__c.Agreement_Line_Item__c,
            Agreement_Error__c.Message__c,
            Agreement_Error__c.Message_Number__c,
            Agreement_Error__c.MsgId__c,
            Agreement_Error__c.Status__c,
            Agreement_Error__c.Agreement_Line_Item__c,
            Agreement_Error__c.Message_Type__c,
            Agreement_Error__c.Generate_Error__c

        };
    }
    /*
    * @author Kushagra Desai
    * @date   20-Dec-2019
    * @description Fetch Agreement Record
    * @param Set of agreeement id
    *
    */
    public List<Agreement_Error__c> selectAgreementErrorActiveTrue(String agreementIds , boolean isGenerateError ){
         
        return (List<Agreement_Error__c>) Database.query(
        newQueryFactory().
        setCondition('Agreement__c =:agreementIds AND Status__c = \'Active\' AND Generate_Error__c = :isGenerateError ').toSOQL());
    }
}