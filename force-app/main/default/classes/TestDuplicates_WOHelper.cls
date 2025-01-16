/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for Duplicates_WOHelper
*/
@IsTest
private class TestDuplicates_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';

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
    *  @description - 
    **/
    static testMethod void checkClosedDuplicate1() {
        Case cs = [SELECT id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        insert wo;
        SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c();
        wd.SVMXC__Service_Order__c = wo.id;
        wd.SVMXC__Activity_Type__c = 'Repair/Troubleshooting';
        wd.Duration_in_hours__c = '1';
        wd.SVMXC__Line_Type__c = WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR;
        insert wd;
        wo.SVMXC__Order_Status__c = 'Closed-Duplicate';
        try{
           update wo; 
           System.assert(wo.Id != null, 'Work Order insertion failed');
           System.assert([Select Id,Work_Order_Status__c from Case where Id = : cs.Id].Work_Order_Status__c != null, 'Work Order Status not updated');
        }catch(exception e){
            system.debug('exception:'+e.getMessage());
            ApexExceptions.emit('exception',e);
        }
    }

     /**
    *  @description - 
    **/
    static testMethod void checkClosedDuplicate2() {
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        insert wo;
        System.assert(wo.Id != null, 'Work Order insertion failed');
        Code_Library__c cl = new Code_Library__c(Name='Test2', Code_type__c = 'Resolution', Service_Product_Type__c = 'Tool');
        insert cl;
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = cl.Id;
        ac.Work_Order__c = wo.Id;
        insert ac;
        wo.SVMXC__Order_Status__c = 'Closed-Duplicate';
        wo.Evaluation__c = 'test';
        try{
           update wo; 
           System.assertEquals('Tool',[Select Id,Service_Product_Type__c from Code_Library__c where Id=: cl.Id].Service_Product_Type__c, 'Service Product Type not updated to Tool');
        }catch(exception e){
            system.debug('exception:'+e.getMessage());
            ApexExceptions.emit('exception',e);
        }
    }

     /**
    *  @description - 
    **/
    static testMethod void checkClosedDuplicate3() {
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c='Test';
        wo.Verification_Result__c='Test'; 
        wo.Notes__c='Test'; 
        wo.Additional_Detail__c='Test'; 
        
        insert wo;
        System.assert(wo.Id != null, 'Work Order Insertion failed');
        wo.SVMXC__Order_Status__c = 'Completed';
        wo.No_Calibrated_Tools_Used__c = true;
        wo.Is_Service_Report_Generated__c = true;
        wo.PO_Number__c='12';
        wo.No_Calibrated_Tools_Used__c = true;
        update wo;
        wo.SVMXC__Order_Status__c = 'Closed-Duplicate';
        try{
           update wo;
           System.assertEquals('Closed-Duplicate', [select Id,SVMXC__Order_Status__c from SVMXC__Service_Order__c where Id=:wo.Id].SVMXC__Order_Status__c
                , 'Order Status not updated to Closed-Duplicate');
        }catch(exception e){
            system.debug('exception:'+e.getMessage());
            ApexExceptions.emit('exception',e);
        }
    }
}