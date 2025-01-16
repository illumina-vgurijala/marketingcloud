/**
 *    @author Roopal Verma
 *    @date   08-24-2018
 *    @description    Class to get the Custom Approvaal Matrix Product records based on different conditions
 *    Modification Log:
 *    --------------------------------------------------------------------------------------------------------------- 
 *    Developer                   Date                Description
 *      Roopal                   24-Aug-2020          Initial Version
 *    --------------------------------------------------------------------------------------------------------------- 
 *                    
 */
public with sharing class CustomApprovalMatrixProductSelector extends ilib_SObjectSelector {

    /**
    *  @author Roopal Verma
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Custom Approval Matrix Product
    **/
    public Schema.SObjectType getSObjectType() {
        return Custom_Approval_Matrix_Products__c.sObjectType;
    }

    /**
     *  @author  Roopal Verma 
     *  @description Retrieve list of fields for Custom Appproval Matrix Product sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
        Custom_Approval_Matrix_Products__c.Product__c,
        Custom_Approval_Matrix_Products__c.Custom_Approval_Matrix__c,
        Custom_Approval_Matrix_Products__c.Name
       };
    }

    /**
     *  @author  Roopal Verma
     *  @description Select Custom approval matrox product records by custom approval matrix Id 
     *  @return List<Custom_Approval_Matrix_Products__c> List of Custom Approval Matrix Product
     **/
    public List<Custom_Approval_Matrix_Products__c> selectbyCustomApprMatrixId(Set<Id> setCamId)
    {
        return (List<Custom_Approval_Matrix_Products__c>) Database.query(
            newQueryFactory()
            .selectField('Product__r.Material_Number__c')
            .setCondition('Custom_Approval_Matrix__c IN :setCamId')
            .toSOQL());
    }

}