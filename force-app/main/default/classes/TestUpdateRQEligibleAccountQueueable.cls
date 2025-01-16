
/*@ author       : Saddam
* @ date         : 28-03-2022
* @ Description  : testclass for UpdateRQEligibleAccountQueueable ,pm-33,pmm-430 user story
*
*/
@istest
public with sharing class TestUpdateRQEligibleAccountQueueable {
    
    @istest
    static void method() {
       
        List<Account> updatelist = new list<Account>();
		List<Account> updatelist1 = new list<Account>();
        //Create Account
        Account objAccount1 = TestDataAccount.getNewAccount();
        objAccount1.R_Q_Contact_Compliant__c='Non Compliant'; 
        objAccount1.R_Q_Contact_Eligible__c=true;
        updatelist.add(objAccount1);
		objAccount1.Name = null;
		updatelist1.add(objAccount1);

        test.startTest();        
        UpdateRQEligibleAccountQueueable updateqclass= new UpdateRQEligibleAccountQueueable(updatelist);
		UpdateRQEligibleAccountQueueable updateqclass1= new UpdateRQEligibleAccountQueueable(updatelist1);
        System.enqueueJob(updateqclass);
		System.enqueueJob(updateqclass1);
        System.assert(!updatelist.isEmpty(), 'Account update');
        test.stopTest();
    }
}
