/**
*    @author Pankaj Singla
*    @date   2018-10-15
*    @description    MasterDataRequestSelector- Selector class for Master Data Request
*    Modification Log:
*    ----------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                10 Apr 2019           Initial Build   
*             Himanshu					   30 Mar 2022           Code Scan Fixes	         
*    ------------------------------------------------------------------------------------------- 
*                    
*/

public with sharing class MasterDataRequestSelector extends ilib_SObjectSelector{
	
	/**
	*  @author Pankaj Singla
	*  @description  
	*  @return SObjectType The Schema.SObjectType of the Master_Data_Request__c
	**/
	public Schema.SObjectType getSObjectType()
    {
        return Master_Data_Request__c.sObjectType;
    }
	/*
    *   @author  Pankaj Singla
    *   @description  Set Select fields
	*   @params NA
	*   @return  List<Schema.SObjectField>
    */
	public List<Schema.SObjectField> getSObjectFieldList()
		{
			return new List<Schema.SObjectField> {
			Master_Data_Request__c.id,
			Master_Data_Request__c.Account_Name__c,
			Master_Data_Request__c.Channel_Partner_Type__c,
			Master_Data_Request__c.Comments__c,
			Master_Data_Request__c.Contact_Email__c,
			Master_Data_Request__c.Contact_Name__c,
			Master_Data_Request__c.Contact_Phone__c,
			Master_Data_Request__c.Customer_ERP_Id__c,
			Master_Data_Request__c.Distributor__c,
			Master_Data_Request__c.Distributor_Distribution_Channel__c,
			Master_Data_Request__c.Distributor_ERP_ID__c,
			Master_Data_Request__c.New_Address__c,
			Master_Data_Request__c.New_City__c,
			Master_Data_Request__c.New_Clinical_Type__c,
			Master_Data_Request__c.New_Country__c,
			Master_Data_Request__c.New_Customer_Sub_Type__c,
			Master_Data_Request__c.New_Customer_Type__c,
			Master_Data_Request__c.New_Market_Segment__c,
			Master_Data_Request__c.New_Market_Segment_Allocation__c,
			Master_Data_Request__c.New_State_Province__c,
			Master_Data_Request__c.New_Tier__c,
			Master_Data_Request__c.New_Zip_Postal_Code__c,
			Master_Data_Request__c.Payer_Name__c,
			Master_Data_Request__c.Primary_Sold_To_Account__c,
			Master_Data_Request__c.Primary_Distributor__c,
			Master_Data_Request__c.Ship_To__c,
			Master_Data_Request__c.Ship_To_Distribution_Channel__c,
			Master_Data_Request__c.Sold_To_Account_ERP_ID__c,
			Master_Data_Request__c.New_Sales_Org__c,
			Master_Data_Request__c.New_Distribution_Channel__c,
			Master_Data_Request__c.Trigger_Email__c,
			Master_Data_Request__c.Type__c,
			Master_Data_Request__c.Ultimate_Consignee__c,
			Master_Data_Request__c.Ultimate_Consignee_ERP_ID__c,
			Master_Data_Request__c.Ultimate_Consignee_Sales_Org__c,
			Master_Data_Request__c.Was_NCIF_Sent__c,
			Master_Data_Request__c.LastModifiedById,
			Master_Data_Request__c.RecordTypeId,
			Master_Data_Request__c.Name,
			Master_Data_Request__c.CreatedById
			
			};
		}
        /**
        *  @author Pankaj Singla
        *  @description Select MasterDataRequest Records by Id 
        *  @param strMDRId- Master Data Request Record Id
        *  @return List of Master_Data_Request__c
        **/
		public List<Master_Data_Request__c> selectByMDRId(String strMDRId) 
		{
			return (List<Master_Data_Request__c>) Database.query(
				newQueryFactory().setCondition('Id =:strMDRId').toSOQL()
			);
		}
		/**
        *  @author Pankaj Singla
        *  @description Select MasterDataRequest Records by List of Master Data Record Ids 
        *  @param strMDRId- Master Data Request Record Id
        *  @return List of Master_Data_Request__c
        **/
		public List<Master_Data_Request__c> selectByListMDR(List<Id> lstMDRID) 
		{
			return (List<Master_Data_Request__c>) Database.query(
				newQueryFactory().selectField('Account_Name__r.Name')
				.selectField('Account_Name__r.Territory_Region__c')
				.selectField('recordType.developerName')
				.selectField('recordType.Name')
				.selectField('LastModifiedBy.FirstName')
				.selectField('LastmodifiedBy.LastName')
				.selectField('LastModifiedBy.Email')
				.selectField('createdby.FirstName')
				.selectField('Createdby.LastName')
				.selectField('Ultimate_Consignee__r.name')
				.selectField('Distributor__r.name')
				.selectField('Ship_To__r.name')
				.selectField('Primary_Distributor__r.name')
				.selectField('Primary_Sold_To_Account__r.name')
				.setCondition('Id IN :lstMDRID').toSOQL()
			);
		}

}