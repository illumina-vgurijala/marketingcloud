/**************************************************************************************************************
 * NAME   : TestBatchRecyclePastContacts
 * DESCRIPTION  : TestClass for BatchRecyclePastContacts
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
public class TestBatchRecyclePastContacts{

     static testMethod void testBatch(){
		 List<RecordType> obj=[select id,name,developerName from recordType where sobjecttype='Contact' and developerName='Standard_Contact'];
         Id recordTypeId;
         if(obj.size()>0){
            recordTypeId=obj[0].id; 
         }
		Contact objContact=TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
		Contact objContact2=TestDataMarketing.createContact('testfirstname','testlastname','test2@gmail.com');
		Contact objContact3=TestDataMarketing.createContact('testfirstname','testlastname','test3@gmail.com');
		objContact2.Marketing_Score__c=20;
		objContact3.Marketing_Score__c=55;
		objContact.recordTypeId=recordTypeId;
		objContact2.recordTypeId=recordTypeId;
		objContact3.recordTypeId=recordTypeId;

		cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
		cs.Bypass_All_Validations__c = true;
		upsert cs cs_Apex_Settings__c.Id;
		objContact.Marketing_Contact_Status__c='New';
		objContact2.Marketing_Contact_Status__c='Inquiry';
		objContact3.Marketing_Contact_Status__c='Automation Qualified';
		List<Contact> lstContact=new list<Contact>{objContact,objContact2,objContact3};
		update lstContact;
		cs.Bypass_All_Validations__c = false;
		upsert cs cs_Apex_Settings__c.Id;

		Test.starttest();
		String sch = '0 0 23 * * ?';

		BatchRecyclePastContacts objbatch=new BatchRecyclePastContacts();
		system.schedule('Test112'+system.now(),sch,objbatch);         

		database.executebatch(objbatch);
		Test.stopTest();
		List<Contact> lstContactnew=[select id, Marketing_Contact_Status__c,Disposition_Code__c from Contact];
		//system.assertEquals(lstContactnew[0].Marketing_Contact_Status__c,'Recycled');
		//system.assertEquals(lstContactnew[0].Disposition_Code__c,'Auto-Recycle');
     }


}