/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for QuoteValidaton_WOHelper
*/
@IsTest
private class TestQuoteValidaton_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final string SERVICE_PRODUCT_STATUS_AVAILABLE = 'Available';

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
       
    }

     /*
      *  @description -
      **/    
    static testMethod void testQuoteValidaton() {
        Boolean expectedExceptionThrown;

        User serviceEngineer = TestDataFieldService.createUser('Field Service', false);
        User sapUsr = TestDataFieldService.createUser('Integration SAP Service', false);
        sapUsr.LastName = 'Integration';
        sapUsr.UserName = sapUsr.UserName+'1';
        List<User> lstUser = new List<User>{serviceEngineer, sapUsr};
        insert lstUser;

        Contact con = [SELECT id, AccountId FROM Contact LIMIT 1];

        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.BillingCountryCode = 'US';
        objAccount.Territory_Region__c = 'AMR';
        insert objAccount;

        SVMXC__Site__c location = new SVMXC__Site__c();
        location.Name = 'Test Location 1';
        location.SVMXC__Account__c = objAccount.Id;
        location.SVMXC__Stocking_Location__c = true;
        insert location;

        Product2 toolProduct = TestDataMaster.initProduct('IL-SER-TRAVEL-Z1','Tools');//DCP-46834: Changes on product setup
        toolProduct.IsActive = true;
        toolProduct.SVMXC__Tracking__c = 'Serialized';
        toolProduct.SVMXC__Stockable__c = true;
        toolProduct.SVMXC__Enable_Serialized_Tracking__c = true;
        toolProduct.Service_Product_Type__c  = 'Spare';
        toolProduct.Material_Group__c = '41';
        toolProduct.Material_Number__c = '20029031';
        toolProduct.RMA_Required__c = true;
        insert toolProduct;

        SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(toolProduct.Id);
        insert workOrderIP;

        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location.Id;
        serializedProdStock.SVMXC__Product__c = toolProduct.Id;
        serializedProdStock.SVMXC__Status__c = SERVICE_PRODUCT_STATUS_AVAILABLE;
        serializedProdStock.SVMXC__Quantity2__c = 6;
        insert serializedProdStock;

        SVMXC__Service_Order__c workOrder;
        
        Id adminId = UserInfo.getUserId();

        System.runas(sapUsr) {
            Case cs = TestDataCase.initServiceRequestCase(con);
            insert cs;
            workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
            workOrder.Record_Created_from_SFM__c = true;
            insert workOrder;
            Test.startTest();
            workOrder.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Estimates').getRecordTypeId();
            workOrder.OwnerId = adminId;
            workOrder.SVMXC__Scheduled_Date_Time__c = System.now().addDays(2);
            update workOrder;

            List<SVMXC__Service_Order_Line__c> listWDS = new List<SVMXC__Service_Order_Line__c>();
            SVMXC__Service_Order_Line__c objWorkDetail1= TestDataFieldService.createWorkDetail(workOrder.Id,workOrderIP.Id);
            objWorkDetail1.SVMXC__Estimated_Quantity2__c = 3;
            objWorkDetail1.SVMX_PS_VS_Consumed_Product_Stock__c= serializedProdStock.Id;
            objWorkDetail1.SVMXC__Line_Type__c = 'Labor';
            objWorkDetail1.SVMXC__Product__c=toolProduct.id;
            objWorkDetail1.RecordTypeId=SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('Estimate').getRecordTypeId();
            listWDS.add(objWorkDetail1);

            SVMXC__Service_Order_Line__c objWorkDetail2= TestDataFieldService.createWorkDetail(workOrder.Id,workOrderIP.Id);
            objWorkDetail2.SVMXC__Estimated_Quantity2__c = 3;
            objWorkDetail2.SVMX_PS_VS_Consumed_Product_Stock__c= serializedProdStock.Id;
            objWorkDetail2.SVMXC__Line_Type__c = 'Travel';
            objWorkDetail2.SVMXC__Product__c=toolProduct.id;
            objWorkDetail2.RecordTypeId=SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('Estimate').getRecordTypeId();
            listWDS.add(objWorkDetail2);
            insert listWDS;

            workOrder.Initiate_Quoting__c = 'Itemized Quote';

            try {
                update workOrder;
            } Catch(Exception ee) {
                expectedExceptionThrown = ee.getMessage().contains(Label.WorkOrderPreventQuotingValidationErrorMessage);
            }

        }
        Test.stopTest();

        System.assert(expectedExceptionThrown, 'validateUserForAutomatedQuoteCreation failed');
    }

}