/* @ author      : Adyasha Satapathy
* @ date         : 07-05-2021
* @ Description  : TestOpportunityQuoteAutomation is the test class for all the OpportunityQuoteAutomation classes.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Adyasha Satapathy       07-05-2021                  DCP-38809         Initial version
* Adyasha Satapathy       19-05-2021                  DCP-46318         Added method to check user permission for Quote creation
* Akshay Mohan            24-05-2021                  DCP-39386         Added method to check on opportunity existing
* Akshay Mohan            07-06-2021                  DCP-46835         Exclude from forecast check

*/
@isTest
public with sharing class TestOpportunityQuoteAutomation {

     /**
     *  @author      : Adyasha Satapathy
     *  @description : Setup method
     **/
    @TestSetup
    static void setUpTestData()
    {
        TestDataBillableFlowQueueable.getWorkOrder();
    }

    /**
     *  @author      : Adyasha Satapathy
     *  @description : method to test auto creation of opportunity
     **/
    @isTest
    public static void testItemizedQuote(){
        SVMXC__Service_Order__c objWO = [SELECT id,Initiate_Quoting__c FROM SVMXC__Service_Order__c LIMIT 1 ]; 
        CreateOpportunityAutomation queueable = new CreateOpportunityAutomation();
        queueable.setRecordId(objWO.Id);
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();
        objWO = [SELECT id,Initiate_Quoting__c,OwnerId,Opportunity__c FROM SVMXC__Service_Order__c LIMIT 1 ];
        System.assert(String.isNotBlank(objWO.Opportunity__c),'Opportunity not created as expected');
        //DCP-46835: Start- Check Exclude_from_Forecast__c value
        UpdateOppExcludeForecast.doBusinessLogic(new List<Id>{objWO.Opportunity__c});//Test class not publishing platform event
        Opportunity objOpportunity = [Select id, Work_Order__c, Exclude_from_Forecast__c from Opportunity where Id =: objWO.Opportunity__c];
        System.assert(objOpportunity.Exclude_from_Forecast__c,'Exclude from Forecast not set for Break fix');
        //DCP-46835: End- Check Exclude_from_Forecast__c value
        System.assertEquals(objWO.id, objOpportunity.Work_Order__c, 'Work Order not stamped on Opportunity');
    }

    /**
     *  @author      : Adyasha Satapathy
     *  @description : method to test  blanket purchase order opportunity auto creation
     **/
    @isTest
    public static void testBlanketPurchaseOrderQuote()
    {
        SVMXC__Service_Order__c objWO2 = [SELECT id,Initiate_Quoting__c FROM SVMXC__Service_Order__c LIMIT 1]; 
       
        Test.startTest();
        objWO2.Initiate_Quoting__c = 'Blanket Purchase Order Quote';
        update objWO2;
        Test.stopTest();
        Opportunity objOpportunity = [Select id, Work_Order__c, Product_Interest__c from Opportunity where Work_Order__c =: objWO2.id];
        System.assertEquals('Break Fix',objOpportunity.Product_Interest__c, 'Opportunity auto creation failed');

    }

    /**DCP-39386
     *  @author      : Adyasha Satapathy
     *  @description : method to test user permission for enabling Initiate Quoting
     **/
    @isTest
    static void testIsUserEnabledForQuoteCreation(){
        String errorMessage = '';

        User objFieldServiceUser = TestDataUser.findUserInProfile('Field Service');
        User objAdminUser = TestDataUser.findUserInProfile('System Administrator');
        Territory2 objTerritory = TestTerritoryPlanStrategyController.getTerritory();
        
        System.runAs(objAdminUser)
        {
            UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(objTerritory.Id,objFieldServiceUser.id);
            insert objUTA;
        }
        
        SVMXC__Service_Order__c objWO = [SELECT id,Initiate_Quoting__c, Partner_Work_Order__c FROM SVMXC__Service_Order__c LIMIT 1]; 
       
        System.runAs(objFieldServiceUser){
            Test.startTest();
            objWO.Initiate_Quoting__c = 'Itemized Quote';
            objWO.Partner_Work_Order__c = true;
            try
            {
                update objWO;
            }
            catch(Exception e)
            {
                errorMessage = e.getMessage();
            }
            Test.stopTest();
        }
        System.assert(errorMessage.contains(Label.WorkOrderPreventQuotingValidationErrorMessage), 'Permission to Initiate Quotion Error');
    }

    /**DCP-39386
     *  @author      : Akshay Mohan
     *  @description : method to test when opportunity already exists and process is initiated
     **/
    @isTest
    static void testOppExists(){
        SVMXC__Service_Order__c objWO = [SELECT id,Initiate_Quoting__c FROM SVMXC__Service_Order__c LIMIT 1]; 
        Test.startTest();
        Opportunity opp =TestDataBillableFlowQueueable.createOpportunityFromWorkOrder(objWO.id,null);
        objWO.Opportunity__c=opp.id;
        update objWO;
        CreateOpportunityAutomation queueable = new CreateOpportunityAutomation();
        queueable.setRecordId(objWO.Id);
        queueable.execute(null);
        Test.stopTest();
        objWO = [SELECT id,Opportunity__c FROM SVMXC__Service_Order__c LIMIT 1]; 
        System.assertEquals(opp.id,objWO.Opportunity__c,'Opportunity created');
        System.assertEquals(opp.id,queueable.getRecordId(),'Wrong opp passed to next step');
    }

     /**DCP-39386
     *  @author      : Akshay Mohan
     *  @description : method to test when opportunity creation fails
     **/
    @isTest
    static void testError(){
        try{
        SVMXC__Service_Order__c objWO = [SELECT id,Initiate_Quoting__c,Sold_To_Account__c,Distributor_Account__c FROM SVMXC__Service_Order__c LIMIT 1]; 
        System.debug('objWO: '+objWO);
        Account objAccount = new Account(Id=objWO.Sold_To_Account__c, Account_Group__c=Label.AccountGroupLegacy);
        Test.startTest();
        update objAccount;
        Test.stopTest();
        User objFieldServiceUser = TestDataUser.findUserInProfile('Field Service');
        
        CreateOpportunityAutomation queueable = new CreateOpportunityAutomation();
        queueable.setRecordId(objWO.Id);
        System.runAs(objFieldServiceUser){
            queueable.execute(null);
        }
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails = queueable.getErrorDetails();
        
        System.debug('wrapDetails: '+wrapDetails);
    }catch(Exception ex){
        System.assert(ex.getMessage().contains('Opportunity cannot be created/edited when Sold To\'s account status is Cancelled,Rejected, Suspended, Pending Obsolete or Obsolete'),'Wrong error details');
    }
}

    /**DCP-39386
     *  @author      : Akshay Mohan
     *  @description : method to test notification is working fine
     **/
    @isTest
    static void testNotification(){
        SVMXC__Service_Order__c objWO = [SELECT id,Initiate_Quoting__c,Sold_To_Account__c,Distributor_Account__c FROM SVMXC__Service_Order__c LIMIT 1]; 
        System.debug('objWO: '+objWO);
        User objFieldServiceUser = TestDataUser.findUserInProfile('Field Service');
        objWO.OwnerId=objFieldServiceUser.Id;
        
        update objWO;
        Account objAccount = new Account(Id=objWO.Sold_To_Account__c,Account_Group__c=Label.AccountGroupLegacy);
        update objAccount;
        System.debug('Owner set to: '+objFieldServiceUser.Id);
        System.runAs(objFieldServiceUser){
            Test.startTest();
            OpportunityQuoteAutomationQueueable objQueueable = new OpportunityQuoteAutomationQueueable(objWO.Id);
            System.enqueueJob(objQueueable);
            Test.stopTest();
        }
        
        objWO = [SELECT id,Opportunity__c FROM SVMXC__Service_Order__c LIMIT 1]; 
        System.assertEquals(null,objWO.Opportunity__c,'Opportunity set on work order'); 
    }
    
 /*******************************************************
    *Method Name : coverCatchOppQouteAutQueueable()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest
    public static void coverCatchOppQouteAutQueueable(){
        try{
            OpportunityQuoteAutomationQueueable.catchException = true;
            OpportunityQuoteAutomationQueueable lQ = new OpportunityQuoteAutomationQueueable(null);
            Test.startTest();
            System.enqueueJob(lQ);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null,'e is not empty');
        }
    }

     /**
     *  @author      : Anshaj
     *  @description : method to cover catch block in CreateOpportunityAutomation
     **/
    @isTest
    public static void coverCatchCreateOpportunityAutomation(){
        try{
            Test.startTest();
            CreateOpportunityAutomation.catchException = true;
            SVMXC__Service_Order__c objWO = [SELECT id,Initiate_Quoting__c,Sold_To_Account__c,Distributor_Account__c FROM SVMXC__Service_Order__c LIMIT 1];
            CreateOpportunityAutomation queueable = new CreateOpportunityAutomation();
            queueable.setRecordId(objWO.Id);
            queueable.execute(null);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
	

}