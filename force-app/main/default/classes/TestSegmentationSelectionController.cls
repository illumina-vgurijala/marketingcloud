/**
 * @author Akshay Mohan 
 * @date   12-Oct-2018
 * @description  Test class for SegmentationSelectionController & related components
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Akshay Mohan             12-Oct-2018         Original
*   Kushagra Desai			 27-Aug-2019		 DCP-28584 : Updating Account plan
*	Satya Swain				 23-May-2022	     DCP-53342 : updated saveRecords()
*   Adyasha                  02-Jun-2022         DCP-53375 : Added new methods for Market Segments Allocation Validation
*  -----------------------------------------------------------------------------------          
*/
@isTest(isParallel=false)
public with sharing class TestSegmentationSelectionController {
	private static final Set<String> SET_SUB_SEGMENTS = new Set<String> {'Metabolic Disease Testing','Neurological Testing','Autoimmune Testing'};
	private static final String STRING_MARKET_SEGMENT_VARIABLE = 'strMarketSegment';
	private static final String STRING_ALLOCATION_VARIABLE = 'decAllocation';
	private static final String STRING_SUB_SEGMENT_VARIABLE = 'lstSubSegments';
	private static final String STRING_RECORDID_VARIABLE = 'strRecordId';
	private static final String STRING_LIST_MARKET_SEGMENT_VARIABLE = 'lstMarketSegments';
	private static final String MS_GENETIC_DISEASE_TESTING = 'Genetic Disease Testing';
	private static final String STRING_INCORRECT_RECORDS = 'Incorrect records returned';
	private static final String STRING_INCORRECT_ALLOCATION = 'Allocation not set';
	
	/*
	*  @author       : Akshay Mohan
	*  @description  : setup data method
	*  @param        : none
	*  @return       : void
	*/
	@testSetup
    public static void setupData() {
		Account objAccount = TestDataAccount.getAccount('Defenders');
		objAccount.Market_Segment__c = null;
        insert objAccount;

		Market_Segment__c objLuke= new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=objAccount.Id,
															Market_Sub_Segment__c='Agriculture Research;Plant Testing',Percent_Allocation__c = 30);
		Market_Segment__c objDanny= new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=objAccount.Id,
															Market_Sub_Segment__c='Agriculture Research;Plant Testing',Percent_Allocation__c = 40);
		Market_Segment__c objMathew= new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=objAccount.Id,
															Market_Sub_Segment__c='Agriculture Research;Plant Testing',Percent_Allocation__c = 30);
		
		insert new List<Market_Segment__c>{objLuke,objDanny,objMathew};
		
		TestDataAccountPlan.getNewAccountPlan(objAccount);		
	}

	/*
	*  @author       : Akshay Mohan
	*  @description  : test method for loadPage method
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void loadPage() {
		Account objAccount = [SELECT Id,Name FROM Account WHERE Name ='Defenders'];
		
		Test.startTest();
		UserRecordAccessSelector objUserRecordAccessSelector = new UserRecordAccessSelector();
		objUserRecordAccessSelector.getSObjectType();
		objUserRecordAccessSelector.getSObjectFieldList();
		String strJSON = SegmentationSelectionController.loadPage(objAccount.Id);
		Test.stopTest();
		List<SegmentationSelectionController.MarketSegmentWrapper> lstSegments = (List<SegmentationSelectionController.MarketSegmentWrapper>)
			JSON.deserialize(UtilsObject.getJSONPart(strJSON, '{"lstMarketSegments" : ', ',"lstMarketSegmentPicklistValues" : '), List<SegmentationSelectionController.MarketSegmentWrapper>.class);
		System.assertEquals(3,lstSegments.size(),'Incorrect segmentation records fetched');
	}

	/*
	*  @author       : Akshay Mohan
	*  @description  : test method for saving market segment records
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void testInsertUpdateMarketSegments() {
		Account objAccount = [SELECT Id,Name FROM Account LIMIT 1];
		
		Test.startTest();
		String strJSON = SegmentationSelectionController.reloadRecords(objAccount.Id);
		Map<String,Object> mapSegmentationObject = (Map<String, Object>)JSON.deserializeUntyped(strJSON);

		List<Map<String, Object>> lstSegments = new List<Map<String, Object>>();
		List<Object> lstMarketSegmentsDeserialized = (List<Object>) mapSegmentationObject.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
	
		for (Object instance : lstMarketSegmentsDeserialized) {
			Map<String, Object> segment = (Map<String, Object>) instance;
			segment.put(STRING_MARKET_SEGMENT_VARIABLE,MS_GENETIC_DISEASE_TESTING);
			segment.put(STRING_ALLOCATION_VARIABLE,20);
			segment.put(STRING_SUB_SEGMENT_VARIABLE,new List<String>(SET_SUB_SEGMENTS));
			lstSegments.add(segment); 
		}		

		Map<String, Object> segment = new Map<String, Object>();
		segment.put(STRING_MARKET_SEGMENT_VARIABLE,MS_GENETIC_DISEASE_TESTING);
		segment.put(STRING_ALLOCATION_VARIABLE,20);
		segment.put(STRING_SUB_SEGMENT_VARIABLE,new List<String>(SET_SUB_SEGMENTS));
		lstSegments.add(segment); 
		
		strJSON = SegmentationSelectionController.saveMarketSegments(objAccount.Id, JSON.serialize(lstSegments));
		Test.getEventBus().deliver();
		Test.stopTest();
		Map<String,Object> mapSegmentationObjectNew = (Map<String, Object>)JSON.deserializeUntyped(strJSON);
		List<Object> lstSegmentsNew = (List<Object>) mapSegmentationObjectNew.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
		
		System.assertEquals(4,lstSegmentsNew.size(),STRING_INCORRECT_RECORDS);		

		for (Object instance : lstSegmentsNew) {
			Map<String, Object> data = (Map<String, Object>) instance;
			List<Object> lstSubSegments = (List<Object>) data.get(STRING_SUB_SEGMENT_VARIABLE);			
			System.assert(String.isNotBlank(String.valueOf(data.get(STRING_RECORDID_VARIABLE))),'Record found without Id');
			System.assertEquals(MS_GENETIC_DISEASE_TESTING,data.get(STRING_MARKET_SEGMENT_VARIABLE),'Market Segment not set');
			System.assertEquals(20,(Decimal)data.get(STRING_ALLOCATION_VARIABLE),STRING_INCORRECT_ALLOCATION);
			System.assertEquals(3,lstSubSegments.size(),'Subsegment size incorrect');
		}
	}

	/*
	*  @author       : Adyasha Satapathy
	*  @description  : test method for testing simple insert scenario for market segment records
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void testInsertMarketSegments() {
		Account objAccount = [SELECT Id,Name FROM Account LIMIT 1];
		List<Market_Segment__c> lstExistingMarketSegment = [Select Id fROM Market_Segment__c WHERE Account__c = :objAccount.Id];
		delete lstExistingMarketSegment;		
		User objSalesUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP);
		update new Account(Id = objAccount.Id, OwnerId = objSalesUser.Id);
		System.runAs(objSalesUser) {
			Test.startTest();			
			List<Map<String, Object>> lstSegments = new List<Map<String, Object>>();
			Map<String, Object> segment = new Map<String, Object>();
			segment.put(STRING_MARKET_SEGMENT_VARIABLE,MS_GENETIC_DISEASE_TESTING);
			segment.put(STRING_ALLOCATION_VARIABLE,100);			
			segment.put(STRING_SUB_SEGMENT_VARIABLE,new List<String>(SET_SUB_SEGMENTS));
			lstSegments.add(segment); 
			String strJSON = SegmentationSelectionController.saveMarketSegments(objAccount.Id, JSON.serialize(lstSegments));
			Test.getEventBus().deliver();
			
			Test.stopTest();
			
			Map<String,Object> mapSegmentationObjectNew = (Map<String, Object>)JSON.deserializeUntyped(strJSON);
			List<Object> lstSegmentsNew = (List<Object>) mapSegmentationObjectNew.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
			System.assertEquals(1,lstSegmentsNew.size(),STRING_INCORRECT_RECORDS);
		}
	}

	/*
	*  @author       : Adyasha Satapathy
	*  @description  : test method for testing simple update scenario for market segment records
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void testUpdateMarketSegments() {
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Test.startTest();		
		String strJSON = SegmentationSelectionController.reloadRecords(objAccount.Id);
		Map<String,Object> mapSegmentationObject = (Map<String, Object>)JSON.deserializeUntyped(strJSON);

		List<Map<String, Object>> lstSegments = new List<Map<String, Object>>();
		List<Object> lstMarketSegmentsDeserialized = (List<Object>) mapSegmentationObject.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
				
		for (Object instance : lstMarketSegmentsDeserialized) {
			Map<String, Object> segment = (Map<String, Object>) instance;
			segment.put(STRING_MARKET_SEGMENT_VARIABLE,MS_GENETIC_DISEASE_TESTING);						
			lstSegments.add(segment); 
		}	
		String strJSONReturned = SegmentationSelectionController.saveMarketSegments(objAccount.Id, JSON.serialize(lstSegments));

		Test.getEventBus().deliver();
		
		Test.stopTest();
		Map<String,Object> mapSegmentationObjectNew = (Map<String, Object>)JSON.deserializeUntyped(strJSONReturned);
		List<Object> lstSegmentsNew = (List<Object>) mapSegmentationObjectNew.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
		System.assertEquals(3,lstSegmentsNew.size(),STRING_INCORRECT_RECORDS);		
	}

	/*
	*  @author       : Adyasha Satapathy
	*  @description  : test method for testing simultaneous delete and insert scenario for market segment records
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void testDeleteInsertMarketSegments() {
		Account objAccount = [SELECT Id,Name,OwnerId FROM Account LIMIT 1];		
				
		Test.startTest();		
		String strJSON = SegmentationSelectionController.reloadRecords(objAccount.Id);
		Map<String,Object> mapSegmentationObject = (Map<String, Object>)JSON.deserializeUntyped(strJSON);

		List<Map<String, Object>> lstSegments = new List<Map<String, Object>>();
		List<Object> lstMarketSegmentsDeserialized = (List<Object>) mapSegmentationObject.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
				
		for (Object instance : lstMarketSegmentsDeserialized) {
			Map<String, Object> segment = (Map<String, Object>) instance;			
			segment.put('booDelete',true);
			segment.put(STRING_RECORDID_VARIABLE,segment.get(STRING_RECORDID_VARIABLE));			
			lstSegments.add(segment); 
		}
		
		Map<String, Object> segment = new Map<String, Object>();
		segment.put(STRING_MARKET_SEGMENT_VARIABLE,MS_GENETIC_DISEASE_TESTING);
		segment.put(STRING_ALLOCATION_VARIABLE,100);			
		segment.put(STRING_SUB_SEGMENT_VARIABLE,new List<String>(SET_SUB_SEGMENTS));
		lstSegments.add(segment); 

		String strJSONReturned = SegmentationSelectionController.saveMarketSegments(objAccount.Id, JSON.serialize(lstSegments));

		Test.getEventBus().deliver();
		
		Test.stopTest();
		Map<String,Object> mapSegmentationObjectNew = (Map<String, Object>)JSON.deserializeUntyped(strJSONReturned);
		List<Object> lstSegmentsNew = (List<Object>) mapSegmentationObjectNew.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
		System.assertEquals(1,lstSegmentsNew.size(),STRING_INCORRECT_RECORDS);		
	}

	/*
	*  @author       : Adyasha Satapathy
	*  @description  : test method for testing simultaneous delete and update scenario for market segment records
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void testDeleteUpdateMarketSegments() {
		Account objAccount = [SELECT Id,Name,OwnerId FROM Account LIMIT 1];				
		Test.startTest();		
		String strJSON = SegmentationSelectionController.reloadRecords(objAccount.Id);
		Map<String,Object> mapSegmentationObject = (Map<String, Object>)JSON.deserializeUntyped(strJSON);

		List<Map<String, Object>> lstSegments = new List<Map<String, Object>>();
		List<Object> lstMarketSegmentsDeserialized = (List<Object>) mapSegmentationObject.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
		
		for(Integer i = 0; i < lstMarketSegmentsDeserialized.size();i++) {
			Map<String, Object> segment = (Map<String, Object>) lstMarketSegmentsDeserialized.get(i);
			if(i==0) {
				segment.put('booDelete',true); 				
			}
			segment.put(STRING_RECORDID_VARIABLE,segment.get(STRING_RECORDID_VARIABLE));
			segment.put(STRING_ALLOCATION_VARIABLE,33.33);
			lstSegments.add(segment); 
		}		

		String strJSONReturned = SegmentationSelectionController.saveMarketSegments(objAccount.Id, JSON.serialize(lstSegments));

		Test.getEventBus().deliver();
		
		Test.stopTest();
		Map<String,Object> mapSegmentationObjectNew = (Map<String, Object>)JSON.deserializeUntyped(strJSONReturned);
		List<Object> lstSegmentsNew = (List<Object>) mapSegmentationObjectNew.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
		System.assertEquals(2,lstSegmentsNew.size(),STRING_INCORRECT_RECORDS);	
	}

	/*
	*  @author       : Adyasha Satapathy
	*  @description  : test method for testing simultaneous delete, insert and update scenario for market segment records
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void testDeleteInsertUpdateMarketSegments() {
		Account objAccount = [SELECT Id,Name FROM Account LIMIT 1];
		
		Test.startTest();
		String strJSON = SegmentationSelectionController.reloadRecords(objAccount.Id);
		Map<String,Object> mapSegmentationObject = (Map<String, Object>)JSON.deserializeUntyped(strJSON);

		List<Map<String, Object>> lstSegments = new List<Map<String, Object>>();
		List<Object> lstMarketSegmentsDeserialized = (List<Object>) mapSegmentationObject.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);
		
		for(Integer i = 0; i < lstMarketSegmentsDeserialized.size();i++) {
			Map<String, Object> segment = (Map<String, Object>) lstMarketSegmentsDeserialized.get(i);
			if(i==0) {
				segment.put('booDelete',true); 				
			}
			segment.put(STRING_RECORDID_VARIABLE,segment.get(STRING_RECORDID_VARIABLE));
			segment.put(STRING_ALLOCATION_VARIABLE,33.33);
			lstSegments.add(segment);
		}
				

		Map<String, Object> segment = new Map<String, Object>();
		segment.put(STRING_MARKET_SEGMENT_VARIABLE,MS_GENETIC_DISEASE_TESTING);
		segment.put(STRING_ALLOCATION_VARIABLE,33.33);
		segment.put(STRING_SUB_SEGMENT_VARIABLE,new List<String>(SET_SUB_SEGMENTS));
		lstSegments.add(segment); 
		
		strJSON = SegmentationSelectionController.saveMarketSegments(objAccount.Id, JSON.serialize(lstSegments));
		Test.getEventBus().deliver();
		Test.stopTest();
		
		Map<String,Object> mapSegmentationObjectNew = (Map<String, Object>)JSON.deserializeUntyped(strJSON);
		
		List<Object> lstSegmentsNew = (List<Object>) mapSegmentationObjectNew.get(STRING_LIST_MARKET_SEGMENT_VARIABLE);		
		
		System.assertEquals(3,lstSegmentsNew.size(),STRING_INCORRECT_RECORDS);		
	}
	
	/*
	*  @author       : Satya Swain
	*  @description  : test method for checking edit access on segmentation selection component for running user
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	static void testCheckEditAccessForRunningUser() {
		Account objAccount = [SELECT Id,Name FROM Account LIMIT 1];
		User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE);
		System.runAs(objUser) {
			Test.startTest();
			String strJSON = SegmentationSelectionController.loadPage(objAccount.Id);			
			Boolean boolHasRecordEditAccess =  Boolean.valueOf(UtilsObject.getJSONPart(strJSON,  '"boolHasRecordEditAccess": ', ',"boolComparisonCustomerFieldsFLS":'));
			Test.stopTest();
			System.assert(!boolHasRecordEditAccess,'User should not have record edit access on Account');
		}
	}
	
	/*
	*  @author       : Satya Swain
	*  @description  : test method for checking ISR user accessbility for SegmentationSelection Component
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	static void testISRAccessibilityForSegmentation() {
		Account objAccount = [SELECT Id,Name, OwnerId FROM Account LIMIT 1];		
		Id activeTerritoryModelId = [SELECT Id FROM Territory2Model WHERE State = 'Active']?.Id;
        if (activeTerritoryModelId == null) { return; }
			
		User objSalesUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP);
		User objAnotherAdminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id>{UserInfo.getUserId()});
		
		objAccount.OwnerId = objSalesUser.Id;
		update objAccount;

		System.runAs(objAnotherAdminUser) {
			Territory2 objTerritory = TestDataTerritory.getNewTerritory(activeTerritoryModelId, 'R1', TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_REGION));	
			insert TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,objAccount.Id);		
			UserTerritory2Association associatedUser = TestDataTerritory.initUserTerritoryLinkRole(objSalesUser.Id, objTerritory.Id, 'Inside Sales Representative - Commercial');
			insert associatedUser;
		}

		System.runAs(objSalesUser) {
			Test.startTest();
			String strJSON = SegmentationSelectionController.loadPage(objAccount.Id);
			Boolean boolComparisonCustomerFieldsFLS =  Boolean.valueOf(UtilsObject.getJSONPart(strJSON, '"boolComparisonCustomerFieldsFLS": ', ',"conditionalReadOnlyAccessForOO":'));
			Test.stopTest();
			System.assert(boolComparisonCustomerFieldsFLS,'Edit Access should not be present for the component');
		}
	}
}