/**
 *    @author Rohan Chandarana
 *    @date   10-01-2018
 *    @description    Class to get the Approval Hierarchy records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                 Date                Description
 *    Rohan                 01-Oct-2018        Initial Version 
 *    ------------------------------------------------------------------------------------ 
 *                    
 */

public class ApprovalHierarchiesSelector extends ilib_SObjectSelector {
  /**
    *  @author Rohan Chandarana 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Approval Hierarchy
    **/
    public Schema.SObjectType getSObjectType() {
        return Approval_Hierarchy__c.sObjectType;
   }
   
   /**
     *  @author  Rohan Chandarana 
     *  @description Retrieve list of fields for Approval Hierarchy sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
   public List<Schema.SObjectField> getSObjectFieldList() {
       return new List<Schema.SObjectField> {
           Approval_Hierarchy__c.id,
           Approval_Hierarchy__c.Approver_Level_1__c,
           Approval_Hierarchy__c.Approver_Level_2__c, 
           Approval_Hierarchy__c.Approver_Level_3__c, 
           Approval_Hierarchy__c.Approver_Level_4__c, 
           Approval_Hierarchy__c.Approver_Level_5__c, 
           Approval_Hierarchy__c.Approver_Level_6__c,
           Approval_Hierarchy__c.Approver_Level_7__c,
           Approval_Hierarchy__c.Approver_Level_8__c,
           Approval_Hierarchy__c.Approval_Hierarchy_Type__c
       };
    }

    /**
     *  @author  Rohan Chandarana 
     *  @description Fetch Account Owners Approval Hierarchy
     *  @return List<Approval_Hierarchy__c> 
     **/
    public List<Approval_Hierarchy__c> selectByAccountOwner(String strType, Set<Id> setAccountOwners) {
      String strCondition = 'Approval_Hierarchy_Type__c = :strType AND Approver_Level_1__c IN :setAccountOwners';
        return (List<Approval_Hierarchy__c>) Database.query(
            newQueryFactory().
            setCondition(strCondition).
            toSOQL()
        );
    }

    /**
     *  @author  Govind Dubey 
     *  @description Fetch all Approval Hierarchy
     *  @return List<Approval_Hierarchy__c> 
     **/
    public List<Approval_Hierarchy__c> selectAllRecords() {
        return (List<Approval_Hierarchy__c>) Database.query(
            newQueryFactory().
            toSOQL()
        );
    }
	
}