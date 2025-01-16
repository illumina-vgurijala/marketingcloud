/**
*    @author vishnu Kurra
*    @date   2020-03-09
*    @description    Class to get the Custom Metadata records for Agreement Line Items Required based on different conditions 
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    vishnu Kurra                020-03-09          Initial Version
*    Aman Tyagi                  31 Mar 2022        CodeScan Fixes
*    ------------------------------------------------------------------------------------                  
*/

public with sharing class AgreementLineItemRequiredSelector extends ilib_SObjectSelector 
{

      /*
      * @Author: vishnu Kurra
      * @Description : methhod for returning sObject type
      * @param : null
      * @return :sObjectType
      */
 		public Schema.SObjectType getSObjectType()
 		{
    		return Agreement_Line_Items_Required__mdt.sObjectType;
 		}
      /**
   *  @author  vishnu Kurra
   *  @description Retrieve list of fields for Agreement Line Items Required Metadata type 
   *  @return sObjectFieldList list of Schema.SObjectField
   **/
  public List<Schema.SObjectField> getSObjectFieldList()
  {
     return new List<Schema.SObjectField> {
    	Agreement_Line_Items_Required__mdt.Agreement_Record_Type__c,
		Agreement_Line_Items_Required__mdt.Agreement_Sub_Type__c,
		Agreement_Line_Items_Required__mdt.Is_Agreement_Line_Items_Required__c,
        Agreement_Line_Items_Required__mdt.DeveloperName,
		Agreement_Line_Items_Required__mdt.MasterLabel
     };
  }
      /**
   *  @author vishnu kurra
   *  @description Fetch Agreement Line Items Required 
   *  @param 
   *  @return list of Agreement Line Items Required 
   **/
  public List<Agreement_Line_Items_Required__mdt> selectAgreementLineItem(Set<String> setSubtype,Set<String> setRecordTypeName) 
  {
      
     return (List<Agreement_Line_Items_Required__mdt>) Database.query(
      newQueryFactory().setCondition('Agreement_Sub_Type__c  IN :setSubtype AND Agreement_Record_Type__c IN :setRecordTypeName').toSOQL()
      ); 
      
  }

}