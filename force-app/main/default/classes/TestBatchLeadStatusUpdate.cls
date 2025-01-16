/**************************************************************************************************************
 * NAME   : TestBatchLeadStatusUpdate
 * DESCRIPTION  : TestClass for BatchLeadStatusUpdate
 *                  
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 19-Jan-2019 
 *
 * MODIFICATION LOG:  
 * -----------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pankaj                   19-Jan-2019        initial Development
 * Deep Diwakar             Dec-05-2024        CMCM-12570: Added test method for this story
 * ------------------------------------------------------------------------------------------------------------
  *************************************************************************************************************/ 
@isTest(SeeAllData = false  isParallel=false)
public class TestBatchLeadStatusUpdate{


    static testMethod void testBatch(){

        Lead objLead=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
        Lead objLead2=TestDataMarketing.createLead('testfirstname2','testlastname2','test2@gmail.com','USA','testCompany');
        Lead objLead3=TestDataMarketing.createLead('testfirstname3','testlastname3','test3@gmail.com','USA','testCompany'); 
        objLead.Marketing_Score__c=20;
		objLead.Date_Of_Last_Score_Change__c=datetime.now();
        objLead2.Marketing_Score__c=55;
		objLead2.Date_Of_Last_Score_Change__c=datetime.now();
        objLead3.Contact_Me_Requested_Date__c=system.today();
        objLead3.Contact_Me__c=true;
        objLead3.status='New';
         objLead.status='New';
          objLead2.status='New';
        List<Lead> lstLead=new list<Lead>{objLead,objLead2,objLead3};
        update lstLead;
        system.debug('values are '+objLead.Marketing_Score__c+'@@'+objLead2.Marketing_Score__c);
        Test.starttest();
          String sch = '0 0 23 * * ?';
         BatchLeadStatusUpdate b = new BatchLeadStatusUpdate();
          system.schedule('Test1123'+system.now(),sch,b); 
          database.executebatch(b);
          Test.stopTest();
          for(Lead objLd:[select id,status from lead LIMIT 10]){
              system.debug('I am '+objLd.status);
              if(objLd.id==objLead.id){
                  system.assertEquals('Inquiry',objLd.status);
              }
              else if(objLd.id==objLead2.id){
                  system.assertEquals('Automation Qualified',objLd.status);
              }
              
              
          
          } 
    }

    @isTest
    static void testLeadHandRaiseStatus() {
        Lead objLead=TestDataMarketing.createLead('FirstHand','LastRaise','handraise@testing.com','USA','Test Hand Raise Inc');
        objLead.Contact_Me__c = true;

        update objLead;

        Test.startTest();
        BatchLeadStatusUpdate testBatch = new BatchLeadStatusUpdate();
        Database.executeBatch(testBatch);
        Test.stopTest();

        Lead resultLead = [Select Id, Status From Lead Where Id =: objLead.Id];

        Assert.areEqual('Hand Raise', resultLead.Status, 'Batch did not correctly set Hand Raise Lead status');

    }

}