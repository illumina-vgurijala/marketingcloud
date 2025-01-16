/**
*  @date   2024-06-14
*  @description  Selector class for Reapproval Reference Object
*  Modification Log:
*  ------------------------------------------------------------------------------------
*      Developer          Date          Description
*      Kumar Gaurav       14-Jun-2024   Initial Development 
*      Sai Pasumarthy     11-Sep-2024   DGP-956
* -----------------------------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ReapprovalReferenceSelector extends ilib_SObjectSelector{
   /**
    *  @author  Kumar Gaurav
    *  @description method to get the sObject type
    *  
    **/
    public Schema.SObjectType getSObjectType()
   {
      return Reapproval_Reference__c.sObjectType;
   }
    /**
    *  @author  Kumar Gaurav
    *  @description Retrieve list of fields for Reapproval_Reference__c 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
         Reapproval_Reference__c.Id,
         Reapproval_Reference__c.Name,
         Reapproval_Reference__c.Current_Line_Data__c,
         Reapproval_Reference__c.Level_1_Data_Changed__c,
         Reapproval_Reference__c.Level_1_Line_Data__c,
         Reapproval_Reference__c.Level_2_Data_Changed__c,
         Reapproval_Reference__c.Level_2_Line_Data__c,
         Reapproval_Reference__c.Level_2_Finance_Data_Changed__c,
         Reapproval_Reference__c.Level_2_Finance_Line_Data__c,
         Reapproval_Reference__c.Level_3_Data_Changed__c,
         Reapproval_Reference__c.Level_3_Finance_Data_Changed__c,
         Reapproval_Reference__c.Level_3_Finance_Line_Data__c,
         Reapproval_Reference__c.Level_3_Line_Data__c,
         Reapproval_Reference__c.Level_4_Data_Changed__c,
         Reapproval_Reference__c.Level_4_Finance_Data_Changed__c,
         Reapproval_Reference__c.Level_4_Finance_Line_Data__c,
         Reapproval_Reference__c.Level_4_Line_Data__c,	
         Reapproval_Reference__c.Level_5_Data_Changed__c,
         Reapproval_Reference__c.Level_5_Finance_Data_Changed__c,
         Reapproval_Reference__c.Level_5_Finance_Line_Data__c,
         Reapproval_Reference__c.Level_5_Line_Data__c,
         Reapproval_Reference__c.Level_6_Data_Changed__c,
         Reapproval_Reference__c.Level_6_Line_Data__c,
         Reapproval_Reference__c.Level_7_Data_Changed__c,
         Reapproval_Reference__c.Level_7_Line_Data__c,
         Reapproval_Reference__c.Level_8_Data_Changed__c,
         Reapproval_Reference__c.Level_8_Line_Data__c,
         Reapproval_Reference__c.Quote_Proposal_Id__c
       };	 
       }
   /*
    * @Author: Kumar Gaurav 
    * @Description : method for selecting list of Reapproval Reference
    * @param :Set<Id> setQuoteIds
    * @return: List<Reapproval_Reference__c>
    */
       public List<Reapproval_Reference__c> selectByQuoteId(Set<Id> setQuoteIds) 
       {
         return (List <Reapproval_Reference__c>) Database.query(
            newQueryFactory()
            .setCondition('Quote_Proposal_Id__c IN: setQuoteIds')
            .toSOQL()
        );
       }	

}