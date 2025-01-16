/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54028 Test class for AwaitingPartsValidation_WOHelper
*/
@IsTest
private class TestAwaitingPartsValidation_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
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
        System.assert(con.id != null);
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    /*******************************************************************************************************
    * @description test method checkPartsOrderStatusChange
    */ 
    static testmethod void testCheckPartsOrderStatusChange() {
        Boolean isErrorThrown;

        Test.startTest();

        List<Case> lstCase = [SELECT id FROM Case LIMIT 1];
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, lstCase[0].Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test'; 
        workOrder.PO_Number__c = '12345';    
        insert workOrder;

        workOrder.SVMXC__Order_Status__c = 'Awaiting Parts';
        try {
            update workOrder;
        } catch (Exception e) {
            isErrorThrown = e.getMessage().contains(Label.WONoShipmentPartsOrders);
        }
        Test.stopTest();
        System.Assert(isErrorThrown, 'Validation Error for checkPartsOrderStatusChange not thrown');
    }
}
