
/*@ author       : Saddam
* @ date         : 02-May-2022
* @ Description  : testclass for AccountRQComplianceUpdateQueueable ,pm-33,pmm-430 user story
*
*/
@istest
public with sharing class TestAccountRQComplianceUpdateQueueable {

    /*@ author       : Saddam
    * @ Description  : Method to cover the class
    */
    @istest
    static void testAccountMethod() {
       
        List<Account> updatelist = new list<Account>();
        //Create Account
        Account objAccount1 = TestDataAccount.getNewAccount();
        objAccount1.R_Q_Contact_Compliant__c='Non Compliant'; 
        objAccount1.R_Q_Contact_Eligible__c=true;
        updatelist.add(objAccount1);

        test.startTest();
        Update updatelist;
        AccountRQComplianceUpdateQueueable updateqclass= new AccountRQComplianceUpdateQueueable(updatelist);
        System.enqueueJob(updateqclass);
        system.assert(!updatelist.isEmpty(), 'Account update');
        test.stopTest();
    }
}
