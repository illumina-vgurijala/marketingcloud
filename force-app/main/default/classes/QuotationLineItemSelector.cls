/**
*    @author Kushagra Desai
*    @date    2018-10-25
*    @description  
*    Modification Log:
*    ----------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Kushagra Desai                2018-10-25           Initial Build	
*            Aman Tyagi                   31 March 2022        Codescan Fixes
*            Aman Tyagi                   12 dec 2022          codeScan Fixes		  
*    ------------------------------------------------------------------------------------------- 
*/
public with sharing class QuotationLineItemSelector extends ilib_SObjectSelector{
	
    /*
    * @Author: Kushagra Desai 
    * @Description : method to get the sObject type
    * @param :null
    */
	public Schema.SObjectType getSObjectType()
    {
        return Apttus_Proposal__Proposal_Line_Item__c.sObjectType;
    }

	/**
     *  @author  Kushagra Desai 
     *  @description Retrieve list of fields for Quotation sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Apttus_Proposal__Proposal_Line_Item__c.id
           //add product fields as required 
       };
    }

    /*
    * @Author: Kushagra Desai 
    * @Description : method to get the fetch line item based on ErpId
    * @param :Set<String> erpId
    * @return : List<Apttus_Proposal__Proposal_Line_Item__c>
    */
    public List<Apttus_Proposal__Proposal_Line_Item__c> fetchLineItemId(Set<String> erpId){

        return (List<Apttus_Proposal__Proposal_Line_Item__c>) Database.query(
        newQueryFactory().selectField('ERP_Line_Number__c')
                         .setCondition('ERP_Line_Number__c IN :erpId').toSOQL());
    }
}