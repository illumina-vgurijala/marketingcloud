/**************************************************************************************************************
 * NAME   : TestBatchContactStatusUpdate
 * DESCRIPTION  : TestClass for BatchContactStatusUpdate
 *                  
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 19-Jan-2019 
 *
 * MODIFICATION LOG:  
 * -----------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pankaj                   19-Jan-2019        initial Development
 * Rishab                   17-Jan-2022        CodeScan Fixes  
 * Deep Diwakar             Dec-05-2024        CMCM-12570: Added test method for this story
 * ------------------------------------------------------------------------------------------------------------
  *************************************************************************************************************/ 
@isTest(SeeAllData = false  isParallel=false)
public class TestBatchContactStatusUpdate{

     static testMethod void testBatch(){
         
      Contact con1=TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
      Contact con2=TestDataMarketing.createContact('testfirstname','testlastname','test2@gmail.com');
      Contact con3=TestDataMarketing.createContact('testfirstname','testlastname','test3@gmail.com');
      
      con1.Marketing_Score__c=20;
      con2.Marketing_Score__c=50;
      con1.Date_Of_Last_Score_Change__c=Datetime.now();
      con2.Date_Of_Last_Score_Change__c=Datetime.now();   
      con3.Contact_Me_Requested_Date__c=system.today(); 
      con3.Contact_Me__c=true;
      List<Contact> lstCon=new List<Contact>{Con1,Con2,Con3};
      update lstCon;
      Test.starttest();
         BatchContactStatusUpdate b = new BatchContactStatusUpdate(); 
          database.executebatch(b);
           String sch = '0 0 23 * * ?';
         
          system.schedule('Test1121'+system.now(),sch,b); 
          Test.stopTest(); 
     
     
     for(Contact objCon:[select id,Marketing_Contact_Status__c from contact]){
         if(objCon.id==con1.id){
              system.assertEquals('Inquiry',objCon.Marketing_Contact_Status__c);
         }
         
         if(objCon.id==con2.id){
              system.assertEquals('Automation Qualified',objCon.Marketing_Contact_Status__c);
         }
         
        
     }
     }


     @isTest
     static void testContactHandRaiseStatus() {
         Contact objContact=TestDataMarketing.createContact('FirstHand','LastRaise','handraise@testing.com');
         objContact.Contact_Me__c = true;
 
         update objContact;
 
         Test.startTest();
         BatchContactStatusUpdate testBatch = new BatchContactStatusUpdate();
         Database.executeBatch(testBatch);
         Test.stopTest();
 
         Contact resultContact = [Select Id, Marketing_Contact_Status__c From Contact Where Id =: objContact.Id];
 
         Assert.areEqual('Hand Raise', resultContact.Marketing_Contact_Status__c, 'Batch did not correctly set Hand Raise Contact status');
 
     }
}