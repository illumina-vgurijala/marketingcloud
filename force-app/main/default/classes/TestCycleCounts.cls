/***************************************************************************************************************************************
* NAME   : TestCycleCounts
* DESCRIPTION  : TestClass for Cycle Count Trigger
*          
*    
* @AUTHOR : Soumya Ranjan Sahu
* @DATE   : 08-Apr-2019  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Soumya Sahu	           08-Apr-2019            Initial Version
****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  

public with sharing class TestCycleCounts {
	
	static SVMXC__Site__c location1 = new SVMXC__Site__c();
	static SVMXC__Site__c location2 = new SVMXC__Site__c();
	static SVMXC__Service_Group_Members__c fieldSupport = new SVMXC__Service_Group_Members__c();
	static User serviceEngineer = new User();
	//static User PreferedTechnician = new User();
	/*@testSetup*/
    public static void initializeTestData() {
    	serviceEngineer = TestDataFieldService.createUser('Field Service Logistics',true);
    	
    	//PreferedTechnician = TestDataFieldService.createUser('Field Service Logistics',true);
    	SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam('TestTeam','US');
    	insert serviceTeam;
    	fieldSupport = TestDataFieldService.getNewFieldSupport(serviceEngineer.Id,'PreferedTechnician',serviceTeam.Id);

    	//To insert a location having Service Engineer as Inventory authority
    	location1 = TestDataFieldService.createLocation('TestLocation1','Test','Test','123456','USD');
    	location1.SVMXC__Service_Engineer__c = serviceEngineer.Id;
    	insert location1;

    	//To insert a location having Prefered technician as Inventory authority
    	location2 = TestDataFieldService.createLocation('TestLocation2','Test','Test','123456','USD');
    	location2.SVMX_PS_Preferred_Technician__c=fieldSupport.Id;
    	insert location2;


    }

    /**
    *  @author Soumya
    *  @description - test the work order status when Cycle Count status is updated
    **/
    static testMethod void validateWorkOrderStatusWithCycleCountStatus(){
        initializeTestData();
        SVMXC__Service_Order__c workorder = TestDataFieldService.createWorkOrderWithLocation('Field Stock Management',location1.id,'Initiated','Cycle Count');
		workOrder.SVMXC__Billing_Type__c = 'Billable';
		workOrder.PO_Number__c='12';
        insert workorder;
        
		Test.startTest();
        Cycle_Count__c objCycleCount1 = TestDataFieldService.createCycleCountFromWO(workorder.id,'Initiated');
        insert objCycleCount1;
        Cycle_Count__c objCycleCount2 = TestDataFieldService.createCycleCountFromWO(workorder.id,'Initiated');
        insert objCycleCount2;
        objCycleCount2.Status__c= 'In Progress';
        update objCycleCount2;

        List<SVMXC__Service_Order__c> insertedWO = [Select id,SVMXC__Order_Status__c from SVMXC__Service_Order__c where id = :workorder.id  limit 1];
        system.assertEquals('In Progress',insertedWO[0].SVMXC__Order_Status__c);

        objCycleCount1.Status__c= 'Completed';
        update objCycleCount1;
        objCycleCount2.Status__c= 'In Progress';
        update objCycleCount2;
        List<SVMXC__Service_Order__c> insertedWO1 = [Select id,SVMXC__Order_Status__c from SVMXC__Service_Order__c where id = :workorder.id  limit 1];
        system.assertNotEquals('Completed',insertedWO1[0].SVMXC__Order_Status__c);
        Cycle_Count__c objCycleCount3 = TestDataFieldService.createCycleCountFromWO(workorder.id,'Initiated');
        insert objCycleCount3;
        List<SVMXC__Service_Order__c> insertedWO2 = [Select id,SVMXC__Order_Status__c from SVMXC__Service_Order__c where id = :workorder.id  limit 1];
        system.assertEquals('In Progress',insertedWO2[0].SVMXC__Order_Status__c);
        delete objCycleCount3;
        List<SVMXC__Service_Order__c> insertedWO3 = [Select id,SVMXC__Order_Status__c from SVMXC__Service_Order__c where id = :workorder.id  limit 1];
        system.assertEquals('In Progress',insertedWO3[0].SVMXC__Order_Status__c, 'Status should be in Progress');
		Test.stopTest();
    }
    /**
    *  @author Soumya
    *  @description - test the work order field support and owner when a new Cycle Count work order is inserted     
    **/
    static testMethod void validateFSandOwnerAsInventoryAuthority (){
        initializeTestData();
        SVMXC__Service_Order__c workorder = TestDataFieldService.createWorkOrderWithLocation('Field Stock Management',location1.id,'Initiated','Cycle Count');
        insert workorder;
        List<SVMXC__Service_Order__c> insertedWO = [Select id,OwnerId,SVMXC__Group_Member__c from SVMXC__Service_Order__c where id = :workorder.id  limit 1];
        system.assertEquals(insertedWO[0].OwnerId,serviceEngineer.id);
	
		SVMXC__Service_Order__c workorder1 = TestDataFieldService.createWorkOrderWithLocation('Field Stock Management',location2.id,'Initiated','Cycle Count');
		insert workorder1;
       
        system.assertEquals(insertedWO[0].OwnerId,serviceEngineer.id);

        Cycle_Count__c objCycleCount = TestDataFieldService.createCycleCountFromWO(workorder.id,'Initiated');
        insert objCycleCount;

        List<Cycle_Count__c> insertedCycleCount = [Select id,OwnerId,Field_Support__c from Cycle_Count__c where id = :objCycleCount.id  limit 1];
        system.assertEquals(insertedCycleCount[0].OwnerId,insertedWO[0].OwnerId);
        system.assertEquals(insertedCycleCount[0].Field_Support__c,insertedWO[0].SVMXC__Group_Member__c);
    }
}