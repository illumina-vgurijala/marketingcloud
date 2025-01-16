/***************************************************************************************************************************************
* NAME   : TestWOScheduledOutsideSLAWebFlow
* DESCRIPTION  : For Covering the "Work Order: Scheduled Outside SLA Web" Flow
*    
* @AUTHOR : Abhishek
* @DATE   : 5-Oct-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek             5-Oct-2023              Initial Version (CMCM-3823)
* Abhishek             15-Feb-2024             Val test issue fix
****************************************************************************************************************************************/ 
@isTest
public class TestWOScheduledOutsideSLAWebFlow {
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    public static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    public static final String STRING_ACCOUNT = 'Test Acc';
    /**
    *  @author Abhishek
    *  @description - Inserted test data 
    **/
    @testSetup
    private static void insertTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        User manager1 = TestDataFieldService.createUser('Field Service', false);
        manager1.IsActive = true;
        manager1.Email = 'TestWOScheduledOutsideSLA@test.com';
        manager1.UserName = 'doejhon534@test.com';
        insert manager1;
        User manager2 = TestDataFieldService.createUser('Field Service', false);
        manager2.IsActive = true;
        manager2.ManagerId = manager1.id;
        manager1.Email = 'WOScheduledOutsideSLA@test.com';
        manager2.UserName = 'jhondoe879@test.com';
        insert manager2;
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'TestWOScheduledOutsideSLAWebFlow@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = manager2.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }
    
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    private static void testScheduledOutsideSLAWeb() {
        Case cs = [Select Id from Case limit 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        SVMXC__Service_Group_Members__c technician = [SELECT Id FROM SVMXC__Service_Group_Members__c LIMIT 1];
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        insert workOrder;
        test.startTest();
        workOrder.SVMXC__Scheduled_Date_Time__c = System.today();
        workOrder.SVMXC__Group_Member__c = technician.id;
        workOrder.SVMXC__Order_Type__c = STRING_WO_ORDER_TYPE;
        workOrder.Onsite_Response_Due_Date__c = System.today().addDays(-2);
        update workOrder;
        test.stopTest();
        FeedItem item =  [SELECT Id FROM FeedItem LIMIT 1];
        Assert.isTrue(item != null , 'Feed is Empty');
    }
}