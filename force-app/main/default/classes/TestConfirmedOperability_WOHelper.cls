/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for ConfirmedOperability_WOHelper
*/
@IsTest
private class TestConfirmedOperability_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';

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

    /**
     * Method: testPopulateConfirmOperabilityMethod
     * Description: Testmethod to test relocation functionality of Relocation Work Order
     * CreatedDate: 01-09-2021
     * DCP-46273
     * */
    static testMethod void testPopulateConfirmOperabilityMethod() {
        List<Account> accList = new List<Account>();
        Account acc1 = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc1.Account_Group__c='Distributor';
        acc1.ERP_Customer_Id__c = 'Test1';
        accList.add(acc1);
  
        Account acc2 = TestDataAccount.getAccount(STRING_ACCOUNT+'2', 'USD');
        acc2.Account_Group__c='Distributor';
        acc2.ERP_Customer_Id__c = 'Test12';
        accList.add(acc2);
        insert accList;
        System.assert(acc1.Id != null, 'List should not be empty');
        System.assert(acc2.Id != null, 'Account insertion failed');
  
        List<Contact> conLst = new List<Contact>();
        Contact con = TestDataPerson.initContact(acc1.Id);
        conLst.add(con);
        contact con2 = TestDataPerson.initContact(acc2.Id);
        conLst.add(con2);
        insert conLst;
        System.assert(con.id != null, 'Contact insertion failed');
        

        List<Case> caseLst = new List<Case>();
        Case cs = TestDataCase.initServiceRequestCase(con2);
        caseLst.add(cs);

        Case cs1 = TestDataCase.initServiceRequestCase(con2);
        caseLst.add(cs1);
        insert caseLst;

        List<SVMXC__Site__c> locationLst = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation('testlocation1','teststreet','testcountry','53434343','USD');
        locationLst.add(objLocation1);

        SVMXC__Site__c objLocation2 = TestDataFieldService.createLocation('testlocation1','teststreet','testcountry','53434343','USD');
        locationLst.add(objLocation2);
        insert locationLst;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        //objInstalledProduct.SVMXC__Company__c = acc1.Id;
        objInstalledProduct.SVMXC__Company__c = acc2.Id;
        objInstalledProduct.SVMXC__Site__c = objLocation1.Id;
        objInstalledProduct.SVMXC__Contact__c = con2.id;
        insert objInstalledProduct;

        Test.StartTest();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Relocation';
        workOrder.Confirmed_Operability__c ='OQ';
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.SVMXC__Component__c=objInstalledProduct.id;

        SVMXC__Service_Order__c relatedWorkOrder = TestDataFieldService.createWorkOrder('Field Service', cs1.Id, 'Initiated');
        relatedWorkOrder.SVMXC__Order_Type__c='Relocation';
        relatedWorkOrder.Confirmed_Operability__c ='Installation';
        relatedWorkOrder.Record_Created_from_SFM__c=true;
        relatedWorkOrder.SVMXC__Component__c=objInstalledProduct.id;
        insert new list<SVMXC__Service_Order__c> {relatedWorkOrder,workOrder};
        system.assert(relatedWorkOrder.Id!=null, 'Work Order insertion failed');

        List<SVMXC__Service_Order__c> updateRecsList = new List<SVMXC__Service_Order__c>();
        workOrder.Relocated_Account__c=acc2.id;
        workOrder.Relocated_Location__c=objLocation2.id;
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.No_Calibrated_Tools_Used__c=true;
        workOrder.SVMXC__Order_Status__c='Assigned';
        workOrder.Related_WO_to_Confirm_Operability__c=relatedWorkOrder.Id;
        workorder.SVMXC__Contact__c=con2.id;
        updateRecsList.add(workOrder);
        relatedWorkOrder.Confirmed_Operability__c ='PQ';
        updateRecsList.add(relatedWorkOrder);
        WorkOrders.skipWOTrigger = true;
        update updateRecsList;

        Test.StopTest();
          
    }
}