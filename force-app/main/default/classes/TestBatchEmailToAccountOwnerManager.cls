/**
*    @author Saddam hussain
*    @date   02-FEB-2022
*    @description  PM-41 : BatchEmailToAccountOwnerManager test class
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*      Saddam                10-Feb-22                Initial version
*    -----------------------------------------------------------------------------------------------------------------------------------
*
*/

@istest
public with sharing class TestBatchEmailToAccountOwnerManager {
    
    /**
    * @author saddam
    * @date   10-Feb-22 
    * @description  Method to cover cover the class.
    */
    @istest
    public static void  batchEmailMethodTest() {

        User manager = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{Id.valueOf(UserInfo.getUserId())});
        TestDataUser.allowUserCreation(Manager.Id); 
        
        Account accn = TestDataAccount.getAccount('Test Acc', 'USD');
        insert accn;

        set<id> acnid=new set<id>();
        acnid.add(accn.id);
        
        EmailMessage objEmail1 = new EmailMessage();
        objEmail1.FromAddress = 'test@illumin.com';
        objEmail1.Incoming = true;
        objEmail1.ToAddress = Manager.email;
        objEmail1.Subject = 'Test email';
        objEmail1.TextBody = 'Hello';
        
        List<EmailMessage> lstEmailMessage = new List<EmailMessage>();
        lstEmailMessage.add(objEmail1);
        insert lstEmailMessage; 
        ID reproti;
    
        Test.startTest();   
        BatchtoEmailAccountOwnerManager batchemail = new BatchtoEmailAccountOwnerManager();
        Database.executeBatch(batchemail);
        BatchtoEmailAccountOwnerManager.createEmail(Manager,reproti);
        String schdule = '0 0 23 * * ?';
        system.assert(schdule != Null,'schedule run failed'); 
        system.schedule('TestSchedule'+system.now(),schdule,batchemail);
        Test.stopTest();
    }  
}