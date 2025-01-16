/***************************************************************************************************************************************
* NAME   : TestPopulateFieldSupportFlow
* DESCRIPTION  : For covering the Case : Populate Field Support field
*    
* @AUTHOR : Saikiran Surapaneni
* @DATE   : 6-Oct-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Saikiran Surapaneni      9-Oct-2023          Initial Version
* Abhishek Yadav           22-Dec-2023         Added the Asserts
****************************************************************************************************************************************/
@IsTest
public class TestPopulateFieldSupportFlow {
	
    /**
     * method to invoke and test the WorkOrder Populate Field Support Flow 
     **/
    @IsTest
    public static void populateFieldSupport() {
        Map<String, Object> inputs = new Map<String, Object>();
        //creating workorder
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase('Service Support','Initiated','Installation');
        //creating user
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        //assigning user to workorder
        objWorkOrder.OwnerId = u.Id;
        update objWorkOrder;
        
        //creating service team
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        
        //creating field support record
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail1@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        SVMXC__Service_Group_Members__c fieldSupport = [SELECT Id, Name FROM SVMXC__Service_Group_Members__c WHERE Name = 'Test Name' AND SVMXC__Email__c = 'testmail1@testing.com'];
        
        //assigning inputs
        inputs.put('IDWorkOrder',objWorkOrder.Id);
        inputs.put('objFieldSupport',fieldSupport);
        inputs.put('objUser',u);
        inputs.put('ObjWorkOrder',objWorkOrder);
        inputs.put('OwnerFirstName','Test');
        inputs.put('OwnerLastName','Owner');
        Flow.Interview exceptionflw = new Flow.Interview.WorkOrder_Populate_FieldSupport_field(inputs);
        Test.startTest();
        exceptionflw.start();
        Test.stopTest();
        Assert.isTrue(fieldSupport != null);
        Assert.isTrue(u != null);
        Assert.isTrue(objWorkOrder != null);
        
        SVMXC__Service_Order__c workOrder = [SELECT Id , SVMXC__Group_Member__c FROM SVMXC__Service_Order__c LIMIT 1];
        Assert.isTrue(workOrder.SVMXC__Group_Member__c != null);
    }
}