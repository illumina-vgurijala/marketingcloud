/**
* @author Shivani Jain
* @date 28 Feb 2022
*
* @description DCP-49675 Test class for PlanOfAction_ElevationHelper
*/ 
@IsTest(SeeAllData=false)
private class TestPlanOfAction_ElevationHelper {

    static final String BUSINESS_ISSUE = 'Business Issue';
    static final String CASE_STATUS_INITIATED = 'Initiated';

    /*******************************************************************************************************
    * @description test validateIfLoanergreementIsGenerated method throwing error
    */
    static testmethod void testSendNotifications() {
        Account acc = TestDataAccount.getAccount('Test Account', 'USD');
        acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert acc;
        System.assert(acc.id != null, 'Account not inserted successfully');

        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact not inserted successfully');

        Case objCase = TestDataCase.initNewCase(BUSINESS_ISSUE, CASE_STATUS_INITIATED, con.Id);
        objCase.Subject = 'test';
        objCase.Description= 'test';
        objCase.Origin = 'Phone-CP';
        objCase.Date_of_Issue_Awareness__c=System.today() -2;
        objCase.Awareness_Date_Difference_Reason__c = 'Logistical delay';
        insert objCase;
        System.assert(objCase.id != null, 'Case not inserted successfully');

        SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                             SVMXC__Order_Status__c from 
                                             SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
        System.assert(workOrder.id != null, 'Automatic Work Order creation from Case trigger failed');

        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];

        Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
          
        Elevations__c techElev = new Elevations__c();
        techElev.RecordTypeId = technicalElevationRecordType;
        techElev.Elevation_Category__c = 'Standard Technical';
        techElev.Elevation_Status__c = 'Open';
        techElev.Elevation_Owner__c = lstUsers[0].Id;
        techElev.Elevation_Manager__c = lstUsers[0].Id;
        techElev.Plan_of_Action__c = 'test';
        techElev.Work_Order__c = workOrder.Id;
        insert techElev;
        System.assert(techElev.id != null, 'Technical Elevation not inserted successfully');

        workOrder.Technical_Elevation__c = techElev.Id;
        update workOrder;

        Test.startTest();
        PlanOfAction_ElevationHelper.sendNotifications(new List<Elevations__c>{techElev});
        
        List<Comment__c> commentLst = [SELECT id FROM Comment__c WHERE Work_Order__c =: workOrder.Id];
        System.assert(commentLst != NULL && commentLst.size() == 1, 'Comment Insertion failed');
        Test.stopTest();
    }
}