/**************************************************************************************************************
 * NAME   : TestBatchRecyclePastLeads
 * DESCRIPTION  : TestClass for BatchRecyclePastLeads
 *                  
 *    
 * @AUTHOR : Pankaj Singla
 * @DATE   : 04-March-2020 
 *
 * MODIFICATION LOG:  
 * -----------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pankaj                   04-March-2020         initial Development
 * ------------------------------------------------------------------------------------------------------------
  *************************************************************************************************************/ 
@isTest(SeeAllData = false  isParallel=false)
public class TestBatchRecyclePastLeads{

     static testMethod void testBatch(){
         Lead objLead=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
         Lead objLead2=TestDataMarketing.createLead('testfirstname2','testlastname2','test2@gmail.com','USA','testCompany');
         Lead objLead3=TestDataMarketing.createLead('testfirstname3','testlastname3','test3@gmail.com','USA','testCompany'); 
          objLead2.Marketing_Score__c=20;
          objLead3.Marketing_Score__c=55;
          objLead2.Date_Of_Last_Score_Change__c=datetime.now();
         objLead3.Date_Of_Last_Score_Change__c=datetime.now();
          
          cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
          cs.Bypass_All_Validations__c = true;
          upsert cs cs_Apex_Settings__c.Id;
          objLead.status='New';
          objLead2.status='Inquiry';
          objLead3.status='Automation Qualified';
          List<Lead> lstLead=new list<Lead>{objLead,objLead2,objLead3};
          update lstLead;
          cs.Bypass_All_Validations__c = false;
          upsert cs cs_Apex_Settings__c.Id;
          
          Test.starttest();
          String sch = '0 0 23 * * ?';
          
          BatchRecyclePastLeads objbatch=new BatchRecyclePastLeads();
          system.schedule('Test112'+system.now(),sch,objbatch);         
          
          database.executebatch(objbatch);
          Test.stopTest();
          List<Lead> lstLeadnew=[select id, status,Disposition_Code__c from lead];
          //system.assertEquals(lstLeadnew[0].status,'Recycled');
          //system.assertEquals(lstLeadnew[0].Disposition_Code__c,'Auto-Recycle');
     }


}