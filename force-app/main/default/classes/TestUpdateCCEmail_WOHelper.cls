/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for UpdateCCEmail_WOHelper
*/
@IsTest
private class TestUpdateCCEmail_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final String STRING_EMAIL = 'a@b.com';
    private static final String STRING_WO_ORDER_TYPE = 'Service Activities';

    /**
    *  @description - initialize test data
    **/
    @testSetup
    public static void initializeTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact Insertion failed!');
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    /**
     * DCP-575
    *  @author : Sandeep Ram Ch.
    *  @description - test the work order cc Email field on when a work order is Updated/inserted
    **/
    static testMethod void workOrderUpdateCCEmail() {
        Case cs = [SELECT id FROM Case LIMIT 1];

        List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                LIMIT 1];
        List<SVMXC__Service_Order__c> lstWo = new List<SVMXC__Service_Order__c>();
        List<SVMXC__Service_Group_Members__c> lstFieldSupport = new List<SVMXC__Service_Group_Members__c>();
        List<Account_to_Field_Support__c> lstAccToFieldSupport = new List<Account_to_Field_Support__c>();
        
        Account acc = [SELECT id FROM Account WHERE Account_Group__c = 'Distributor' LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        System.assert(serviceTeam.Id != NULL, 'serviceTeam Insertion failed');
            
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
        technician.SVMXC__Email__c=STRING_EMAIL;
        lstFieldSupport.add(technician);
    
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c='b@b.com';
        lstFieldSupport.add(technicianFAS);
        insert lstFieldSupport;
        System.assert(technicianFAS.Id != NULL, 'Field Support Insertion failed');
            
        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Service Engineer',lstFieldSupport[0].id);
        
        lstAccToFieldSupport.add(accToFieldSupport);
    
        Account_to_Field_Support__c accToFieldSupportFSM =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Application Scientist',lstFieldSupport[1].id);
        
        lstAccToFieldSupport.add(accToFieldSupportFSM);
        Test.startTest();
        insert lstAccToFieldSupport;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
        workOrder.SVMXC__Company__c = acc.id ;
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrder.Record_Created_from_SFM__c=true;
        lstWo.add(workOrder);
        SVMXC__Service_Order__c workOrderTwo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
        workOrderTwo.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrderTwo.Record_Created_from_SFM__c=true;
        workOrderTwo.SVMXC__Company__c = acc.id ;
        lstWo.add(workOrderTwo );
        insert lstWo;
        
        Test.stopTest();
        
        List<SVMXC__Service_Order__c> updatedWO = [SELECT id, CC_Email__c FROM SVMXC__Service_Order__c LIMIT 1];
        System.assert(updatedWO[0].CC_Email__c != NULL, 'CC Email Field not populated successfully');
    }
}