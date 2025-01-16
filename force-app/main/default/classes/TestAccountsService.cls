/*@ author       : Saddam
* @ date         : 28-03-2022
* @ Description  : testclass for AccountsService and Acr Class , PM-430,PM-33
*
*/
@istest
public with sharing class TestAccountsService {
   
     /**
    * @author Saddam
    * @date    19-Mar-2022
    * @description  To cover 
    */
      @testSetup 
    static void createSampleData() {
       
        //Create Account
        Account objAccount1 = TestDataAccount.getAccount('Test Acc1', 'USD');
        objAccount1.R_Q_Contact_Compliant__c='Non Compliant'; 
        objAccount1.R_Q_Contact_Eligible__c=true;
        Insert objAccount1;

        Account objAccount2 = TestDataAccount.getAccount('Test Acc2', 'USD');
        objAccount2.R_Q_Contact_Compliant__c='Compliant';
        objAccount2.R_Q_Contact_Eligible__c=true;
        Insert objAccount2;

        
        Account objAccount3 = TestDataAccount.getAccount('Test Acc3', 'USD');
        objAccount3.R_Q_Contact_Compliant__c='Not Applicable';
        objAccount3.R_Q_Contact_Eligible__c=false;
        Insert objAccount3;

        Contact con = new Contact(FirstName='First',LastName='Last',AccountId = objAccount1.Id, Phone='1234567890', Email='test@test.com');
        insert con;
        
    } 
    
    /**
    * @author Saddam
    * @date    19-Mar-2022
    * @description  To cover 
    */
     @isTest
    static void testAcrupdate() {

        //creation of accounts
        Account account1 = TestDataAccount.getCustomerAccount();
        Account account2 = TestDataAccount.getCustomerAccount();
        insert new List<Account> {account1, account2};
        System.assert(account1.Id != null,'Account not created.');
        //creation of contacts
        Contact con1 =TestDataPerson.initContact(account1.Id);
        Contact con2 = TestDataPerson.initContact(account2.Id);
        Contact con3 = TestDataPerson.initContact(account2.Id);
        insert new List<Contact> {con1, con2,con3};
        System.assert(con1.Id != null,'Contact not created.');

        Account acclist =[Select id,R_Q_Contact_Compliant__c,R_Q_Contact_Eligible__c,R_Q_Non_Compliance_Date__c From Account where R_Q_Contact_Eligible__c = false Limit 1 ];
        acclist.R_Q_Contact_Compliant__c= 'Not Applicable';
        acclist.R_Q_Non_Compliance_Date__c=Null;

        AccountContactRelation  acr = [Select Id from AccountContactRelation where contactId =: con2.Id];
        acr.Roles = 'BioInformatics';
        update acr; 
        
        List<AggregateResult> accconrelrecords = [SELECT AccountId, COUNT(Id) NumberOfRecord,Contact.Is_Active__c contactIsActive FROM AccountContactRelation WHERE Contact.Is_Active__c =true GROUP BY AccountId,Contact.Is_Active__c having COUNT(Id)>=2];   
        set<id> acids = new Set<Id>();
        for(AggregateResult agrres :accconrelrecords) {
        acids.add((id)agrres.get('AccountId'));
        }
        Test.startTest();
        AccountsService.updateRqAccount(acids);
        update acclist;
        system.assertNotEquals(Null,acids.size(),'Not Contains ACR Records');
        system.assertEquals(Null,acclist.R_Q_Non_Compliance_Date__c,'Account is not updated');
        Test.stopTest(); 
    }
}
 
 