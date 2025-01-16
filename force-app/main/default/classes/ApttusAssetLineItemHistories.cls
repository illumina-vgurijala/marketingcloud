/**
 *    @author Gopesh Banker
 *    @date   10-01-2018
 *    @description   Domain class for ApttusAssetLineItemHistoryTrigger
 *    @Test Class for above 90% coverage.
 *    -TestTAPS_ApttusAssetLineHistory
 *    @Test Class for atleast 75% coverage.
      -TestTAPS_ApttusAssetLineHistory
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *      Developer                      Date                 Description
 *      Gopesh Banker                 01-OCT-2018         Initial Version
 *      Aman Tyagi                    30-Mar-2022         CodeScan Fixes
 *      Nishan Shetty                 24-Aug-2022         DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
 *    ------------------------------------------------------------------------------------
 *
 */
 public with sharing class ApttusAssetLineItemHistories extends ilib_SObjectDomain {

	 public static Boolean hasRunTaps = false;

	/*
	* @Author: Gopesh Banker
	* @Description : parameterized constructor of the class ApttusAssetLineItemHistories
	* @param: List<Apttus_Config2__AssetLineItemHistory__c> sObjectList
	* @return: NA
	*/
	public ApttusAssetLineItemHistories(List<Apttus_Config2__AssetLineItemHistory__c> sObjectList)
	{
		super(sObjectList);
	}

	/**
	 * Boilerplate which is required for base class instantiation logic
	 **/
	public class Constructor implements ilib_SObjectDomain.IConstructable
	{

		/*
		* @Author: Gopesh Banker
		* @Description :constructor for base class
		* @param: List<SObject> sObjectList
		*/		
		public ilib_SObjectDomain construct(List<SObject> sObjectList)
		{
			return new ApttusAssetLineItemHistories(sObjectList);
		}
	}

	/**
	 *  @Name           : onBeforeUpdate
	 *  @Author         : Gopesh Banker (Apttus)
	 *  @Description    : before update logic called
	 *  @Since          : 01 OCT 2018
	 *  @Returns        : null
	 *  @Params         : map of id to sobject of existing records
	 **/
	public override void onBeforeUpdate(Map<Id, sObject> existingRecords)
	{
		Set<Id> setAssetLineItems = new Set<Id>();
		List<Apttus_Config2__AssetLineItemHistory__c> lstAssetLineItemHistories = (List<Apttus_Config2__AssetLineItemHistory__c>)records;
		for (Apttus_Config2__AssetLineItemHistory__c thisAssetLineItemHistory : lstAssetLineItemHistories)
		{
			if (thisAssetLineItemHistory.Apttus_Config2__AssetLineItemId__c != null & String.valueOf(thisAssetLineItemHistory.Apttus_Config2__AssetLineItemId__c) != '')
				setAssetLineItems.add(thisAssetLineItemHistory.Apttus_Config2__AssetLineItemId__c);
		}

		List<Apttus_Config2__OrderLineItem__c> lstOrderLineItems = new ApttusOrderLineItemsSelector().getOrderLinesByAssetId(setAssetLineItems);

		for (Apttus_Config2__AssetLineItemHistory__c thisAssetLineItemHistory : lstAssetLineItemHistories)
		{
			for (Apttus_Config2__OrderLineItem__c thisOrderLineItem : lstOrderLineItems)
			{
				System.debug('asset history asset line item id = '+thisAssetLineItemHistory.Apttus_Config2__AssetLineItemId__c);
				System.debug('order line - asset line item id = '+thisOrderLineItem.Apttus_Config2__AssetLineItemId__c);
				System.debug('order line line status = '+thisOrderLineItem.Apttus_Config2__LineStatus__c);
				if (thisAssetLineItemHistory.Apttus_Config2__AssetLineItemId__c == thisOrderLineItem.Apttus_Config2__AssetLineItemId__c
					&& thisOrderLineItem.Apttus_Config2__LineStatus__c == System.Label.LineItemLineStatusRenewed)
				{
					System.debug('in if ');
					thisAssetLineItemHistory.Apttus_Config2__AssetStatus__c = System.Label.LineItemLineStatusRenewed;
				}
			}
		}
	}

	/*
	* @Author: Gopesh Banker
	* @Description : after insert logic is calling out in this method
	* @param: null
	* @return: void
	*/
	 public override void onAfterInsert()
	 {   
		TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
		tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
	 }

	/*
	* @Author: Gopesh Banker
	* @Description : after update logic is calling out in this method
	* @param: Map<Id, sObject> existingRecords
	* @return: void
	*/
	 public override void onAfterUpdate(Map<Id, sObject> existingRecords)
	 {
		 if (!hasRunTaps && !isInsertOperationForObject(getSObjectType()))
		 {
			 List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId' };
			 TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
			 Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);//DCP-44091
			 if (idsThatNeedRecalculation.size() > 0)
			 {
				tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
				hasRunTaps = true;
			 }
		 }
	 }

 }