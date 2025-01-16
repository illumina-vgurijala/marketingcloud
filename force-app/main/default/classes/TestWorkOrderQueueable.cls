/***************************************************************************************************************************************
 * NAME   : TestWorkOrderQueueable
 * DESCRIPTION  :Test class  Queueable class on  workorder object.
 *           DCP-33872  :Performance story on work orders.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 25-Feb-2020  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             25-Feb-2020           Initial Version
 * Pooja                 23-Sep-2022           CodeScan Fixes
 * Nitin Z/Nidhi         15-May-2014           CMCM-7773 
*****************************************************************************************************************************************/
@isTest
private class TestWorkOrderQueueable {
    static final String BUSINESS_ISSUE = 'Business Issue';
    static final String CASE_STATUS_INITIATED = 'Initiated';
    public static final String WO_ABANDONED_REASON_NO_CUST_RESPONSE = 'No Customer Response';
    
    @TestSetup
    static void initialTestdata(){
        
        Code_Library__c clObj= new Code_Library__c();
        clObj.Code_Type__c = 'Resolution';
        clObj.Case_Type__c = 'Business Issue';
        clObj.Name ='BUS Customer abandoned or unresponsive';
        clObj.Code_Description__c = 'Test Code';
        insert clObj;
        System.assert(clObj.Id!=null);
        
    }
    @isTest
    private static void testLinkFieldActionItemsFromCase(){
        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null, 'Account should not be null');
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact should not be null');

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        // To create a FAN record of record type "Notification"
        Field_Action_Notification__c objFAN =TestDataFieldService.createFAN('Notification');
        insert objFAN;
        // To create a second FAI record with FAN record type "Notification"
        Field_Action_Item__c objFAI1 =TestDataFieldService.createFAI(cs.Id,objFAN.Id);
        insert objFAI1;

        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
		
        
        
        Test.startTest();
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c='Service Activities';
            workOrder.Record_Created_from_SFM__c = true;
            insert workOrder;
        Test.stopTest();
    }

    /**
    * @description:verify work order owner update and link associated code to WO functionality
    *
    **/
    @isTest
    private static void testOwnerAndAbandonedReasonUpdate(){
        initialTestdata();
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
            LastName = 'last',
            Email = 'test@g.com',
            Username = 'test@g.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
       );
       insert u;

        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null, 'Account should not be null');
        
        Account acc2 = TestDataAccount.getAccount('Test Acc2', 'USD');
        acc2.Account_Group__c='Distributor';
        acc2.ERP_Customer_Id__c = 'Test2';
        insert acc2;
        System.assert(acc2.Id != null, 'Account should not be null');

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);

        Contact con2 = TestDataPerson.getNewContact(acc2.Id);
        System.assert(con2.id != null);

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        Case cs2 = TestDataCase.createCase('Business Issue','Initiated',con2.Id);
        cs2.Sub_Type__c = 'Complaint';
        update cs2;

        // To create a FAN record of record type "Notification"
        Field_Action_Notification__c fan =TestDataFieldService.createFAN('Notification');
        insert fan;
        // To create a second FAI record with FAN record type "Notification"
        Field_Action_Item__c fAI1 =TestDataFieldService.createFAI(cs.Id,fan.Id);
        insert fAI1;

        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
		
       
        
        Test.startTest();
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c='Service Activities';
            workOrder.Record_Created_from_SFM__c = true;
            workOrder.Is_Service_Report_Generated__c=true;
            insert workOrder;

            workOrder.OwnerId=u.Id;
            workOrder.Abandoned_Reason__c=WO_ABANDONED_REASON_NO_CUST_RESPONSE;
            workOrder.SVMX_PS_Subject__c='test';
            update workOrder;

            SVMXC__Service_Order__c workOrder2 = TestDataFieldService.createWorkOrder('Field Service', cs2.Id, 'Initiated');
            workOrder2.SVMXC__Order_Type__c='Service Activities';
            workOrder2.Record_Created_from_SFM__c = true;
            workOrder2.Is_Service_Report_Generated__c=true;
            insert workOrder2;

            workOrder2.OwnerId=u.Id;
            workOrder2.Abandoned_Reason__c=WO_ABANDONED_REASON_NO_CUST_RESPONSE;
            workOrder2.SVMX_PS_Subject__c='test 2';
            update workOrder2;
                   

        Test.stopTest();
        //List<Field_Action_Item__c> lstFAI = [Select Id from Field_Action_Item__c where Work_Order__c =: workOrder.Id];
       // System.assert(!lstFAI.isEmpty(), 'List should not be empty'); 
        //List<Associated_Codes__c> lstAssociatedCOde = [Select id,Work_Order__c,Code_Title__c,Code_Type__c FROM Associated_Codes__c where Work_Order__c=:workOrder.id];
        //System.assert(lstAssociatedCOde.isEmpty(), 'List should be empty if WO is associated with a non-Business Issue Case');  
    }

    /**
    * @description: Test Elevation desc functionality
    **/
    @isTest
    public static void testElevationDesc() 
    {
        Account acc = TestDataAccount.getAccount('Test Account', 'USD');
        acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert acc;
        System.assert(acc.id != null);

        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact should not be null');

        Case objCase = TestDataCase.initNewCase(BUSINESS_ISSUE, CASE_STATUS_INITIATED, con.Id);
        objCase.Subject = 'test';
        objCase.Description= 'test';
        objCase.Origin = 'Phone-CP';
        objCase.Date_of_Issue_Awareness__c=System.today() -2;
        objCase.Awareness_Date_Difference_Reason__c = 'Logistical delay';
        insert objCase;
        System.assert(objCase.id != null, 'Case should not be null');

        SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                                SVMXC__Order_Status__c from 
                                                SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
        System.assert(workOrder.id != null, 'Work Order should not be null');

        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];//Fetching list of Users

        Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();// To fetch the recordtype of Technical Elevation
            
        //Create Elevation Record
		Elevations__c techElev = new Elevations__c();
		techElev.Elevation_Owner__c = lstUsers[0].Id;
        techElev.Elevation_Manager__c = lstUsers[0].Id;
        techElev.Plan_of_Action__c = 'test';
		techElev.Work_Order__c = workOrder.Id;
        techElev.RecordTypeId = technicalElevationRecordType;
        techElev.Elevation_Category__c = 'Standard Technical';
        techElev.Elevation_Status__c = 'Open';
        insert techElev;//Insert TechElev
        System.assert(techElev.id != null, 'Technical Elevation should not be null');

        workOrder.Technical_Elevation__c = techElev.Id;
        update workOrder;

        Test.startTest();
        workOrder.SVMXC__Problem_Description__c = 'Test Update';
        update workOrder;
        Test.stopTest();
        
        Elevations__c updatedElevation = [SELECT id, Work_Order_Description__c FROM Elevations__c WHERE id =: techElev.Id];
        System.assertEquals(updatedElevation.Work_Order_Description__c,workOrder.SVMXC__Problem_Description__c,'Description not matching');
    }
}