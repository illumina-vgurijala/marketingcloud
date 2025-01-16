/***************************************************************************************************************************************
 * NAME   : TestQualtricsSurveyResponses
 * DESCRIPTION  : TestClass for QualtricsSurveyResponses  Trigger hanlder 
 *           
 *    
 * @AUTHOR : Digvijay
 * @DATE   : 30-May-2019  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Digvijay         18-02-2020           Initial Version
 
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)
public with sharing class TestQualtricsSurveyResponses {
  
    static Case cs;
    static Related_Contacts__c rc;
    
    @testSetup
	/* Test Data*/
    public static void initializeTestData()
    {
        Contact con = TestDataPerson.getNewContact(null);
        cs = TestDataCase.initServiceRequestCase(con);
        rc=new Related_Contacts__c(Contact__c=con.id);
        
    }
    
    
     
    static testMethod void insertQSR(){
        initializeTestData();
        
         User uManager = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name =: System.label.Field_Service].Id,
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
        insert uManager ;
        
        
         User u= new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name =: System.label.Field_Service].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             ManagerId=uManager.id,
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u ;
        SVMXC__Service_Order__c workOrder ;
        
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
            
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(u.id,'Primary Field Application Scientists',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        insert technician;
        
        System.RunAs(u){
        insert cs;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.SVMXC__Group_Member__c=technician.id;
        insert workOrder;
        
        insert rc;
        }
        
        
        List<Qualtrics_Survey_Response__c> lstqsr=new List<Qualtrics_Survey_Response__c>();
        Qualtrics_Survey_Response__c  qsrObj1= new Qualtrics_Survey_Response__c(Case__c=cs.id, NPS_Score__c=1,OSAT_Score__c=2,Originating_Record_Owner__c=u.id);
        Qualtrics_Survey_Response__c  qsrObj2= new Qualtrics_Survey_Response__c(Work_Order__c=workOrder.id, NPS_Score__c=1,OSAT_Score__c=2);
         Qualtrics_Survey_Response__c  qsrObj3= new Qualtrics_Survey_Response__c(RelatedContacts__c=rc.id, NPS_Score__c=1,OSAT_Score__c=2);
        lstqsr.add(qsrObj1);
        lstqsr.add(qsrObj2);
         lstqsr.add(qsrObj3);
        
        Test.startTest();
        
        insert lstqsr;
        system.assertequals(uManager.id,[select id,ownerid from Qualtrics_Survey_Response__c where id=:lstqsr[0].id].ownerid,'owner is not manager');
        lstqsr[0].status__c=Label.QSRStatusInProgress;
        lstqsr[1].status__c=Label.QSRStatusReviewNotRequired;
		lstqsr[1].Review_Comments__c = Label.QSRStatusReviewNotRequired;
        Update lstqsr;
        
        Test.StopTest();
       
    }
	
	 static testMethod void insertQSRwithoutOwnerManager(){
        initializeTestData();
        
         User uManager = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name =: System.label.Field_Service].Id,
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
        insert uManager ;
        
        
         User u= new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name =: System.label.Field_Service].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             //ManagerId=uManager.id,
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u ;
        SVMXC__Service_Order__c workOrder ;
        
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
            
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(u.id,'Primary Field Application Scientists',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        insert technician;
        
        System.RunAs(u){
        insert cs;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.SVMXC__Group_Member__c=technician.id;
        insert workOrder;
        
        insert rc;
        }
        
        
        List<Qualtrics_Survey_Response__c> lstqsr=new List<Qualtrics_Survey_Response__c>();
        Qualtrics_Survey_Response__c  qsrObj1= new Qualtrics_Survey_Response__c(Case__c=cs.id, NPS_Score__c=8,OSAT_Score__c=8,Review_Comments__c='Test',Non_Low_Score_Follow_Up_Justification__c = 'test');
        Qualtrics_Survey_Response__c  qsrObj2= new Qualtrics_Survey_Response__c(Work_Order__c=workOrder.id, NPS_Score__c=8,OSAT_Score__c=8,Review_Comments__c='Test',Non_Low_Score_Follow_Up_Justification__c = 'test');
         Qualtrics_Survey_Response__c  qsrObj3= new Qualtrics_Survey_Response__c(RelatedContacts__c=rc.id, NPS_Score__c=8,OSAT_Score__c=8,Review_Comments__c='Test',Non_Low_Score_Follow_Up_Justification__c = 'test');
        lstqsr.add(qsrObj1);
        lstqsr.add(qsrObj2);
         lstqsr.add(qsrObj3);
        
        Test.startTest();
        
        insert lstqsr;
        lstqsr[0].status__c=Label.QSRStatusInProgress;
		 lstqsr[0].Reason_for_Reopen__c = 'Reopen';
        lstqsr[1].status__c=Label.QSRStatusReviewNotRequired;
        Update lstqsr;
        
        Test.StopTest();
       system.assert(!lstqsr.isEmpty(), 'lstqsr is empty');
    }
    
  }