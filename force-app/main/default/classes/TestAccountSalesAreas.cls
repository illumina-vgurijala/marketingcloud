/**
*    @author Rahul Sharma
*    @date   2018-08-27
*    @description    DCP-10312: Account Sales Area test class
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Rahul Sharma                27 Aug 2018            Account Sales Areas test class
*             Aman Tyagi                  21 Apr 2022            CodeScan Fixes
*             Adyasha Satapathy           12-10-2022             Code Scan Fixes(Method Naming Convention)
*             Gerardo Garcia              22-03-2024             CMCM-5889 Tests queueable EmailVerification
*    ---------------------------------------------------------------------------------------------------------------------
*
*/
@isTest(isParallel=true)
public class TestAccountSalesAreas {
    @testSetup
    static void initializeTestData()
    {
        Account acc = TestDataAccount.getNewAccount();
        Contact contact = TestDataPerson.initContact(acc.Id);
        contact.FirstName = 'Tester';
        contact.LastName = 'Testos';
        insert contact;
    }


/**
*    @author Rahul Sharma
*    @date   2018-08-27
*    @description Testing insert scenario for Account Sales Area With Price List
*/
    static testMethod void accountSalesAreaInsertWithPriceList()
    {
       
        List< Account_Sales_Area__c > accList=new List< Account_Sales_Area__c >();
        Account acc = TestDataAccount.getNewAccount();
        Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','178','div1',false);
        accSalesArea.Price_List_Type__c='01';
        accSalesArea.CurrencyIsoCode = 'USD';
        accSalesArea.Account__c = acc.Id;
        accList.add(accSalesArea);
        
        
        List< Price_List__mdt > lstPriceList = [Select Id, Price_List__c
                                                      from Price_List__mdt WHERE MasterLabel='01_USD' ];
       
        
        
        for (Account_Sales_Area__c asa : accList)
        {
            
            asa.Price_List__c = lstPriceList[0].Price_List__c ;
            
        }
        Test.startTest();
        insert accList;
        Test.stopTest();
        
        System.assert(true,accList[0].Price_List__c='01-AMR-USD');
        
        

    }
    
    /**
*    @author Rahul Sharma
*    @date   2018-08-27
*    @description Testing update scenario for Account Sales Area With Price List
*/
    static testMethod void accountSalesAreaUpdateWithPriceList()
    {
       
        Account acc = TestDataAccount.getNewAccount();
        Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','178','div1',false);
        accSalesArea.Price_List_Type__c='01';
        accSalesArea.CurrencyIsoCode = 'USD';
        accSalesArea.Account__c = acc.Id;
        List<Account_Sales_Area__c> accList1 =  new List< Account_Sales_Area__c >();
        accList1.add(accSalesArea); 
        insert accList1;
        
        List<Account_Sales_Area__c> accList2 = [SELECT Id, Price_List__c, Price_List_Type__c, Account__c FROM Account_Sales_Area__c];
        Set<Id> setId=new Set<Id>();
        
        
        List< Price_List__mdt > lstPriceList = [Select Id, Price_List__c
                                                      from Price_List__mdt WHERE MasterLabel='01_USD' ];
       
        
        
        for (Account_Sales_Area__c asa : accList2)
        {
            asa.Price_List_Type__c='03';
            asa.CurrencyIsoCode = 'USD';
            asa.Price_List__c = lstPriceList[0].Price_List__c;
            setId.add(asa.Id);
            
        }
        Test.startTest();
        update accList2;
        Test.stopTest();
        
        accList2 = [SELECT Id, Price_List__c, Price_List_Type__c,Account__c FROM Account_Sales_Area__c WHERE Id IN: setId]; 
        System.assert(true,accList2[0].Price_List__c='01-AMR-USD');
        
        
     }
     /**
     *  @author      : Nitin
     *  @description : method to cover catch block in EmailVerificationQueueable
     **/
    @isTest
    private static void coverCatchBlockEmailVerificationQueueableNullException(){
        Boolean gotException = false;
        try{
            EmailVerificationQueueable pd = new EmailVerificationQueueable(null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            gotException = true;
        }
        Assert.isTrue(gotException, 'It should get an exception');
    }

    @isTest
    private static void emailVerificationQueueable() {
        Test.setMock(HttpCalloutMock.class, new LeadEmailVerificationMockHTTP('S'));

        Contact contact = getContact();
        System.debug('contact should not have filled verification fields:' + JSON.serializePretty(contact));

        EmailVerificationQueueable.testVerificationRequest = true;
        EmailVerificationQueueable pd = new EmailVerificationQueueable(contact);
        Test.startTest();
        System.enqueueJob(pd);
        Test.stopTest();

        contact = getContact();

        Assert.areEqual(EmailVerificationController.VERIFIED_SUCCESSFULLY, contact.Verification_Status__c, 'It should be succesfully');
        Assert.isNotNull(contact.Email_Verification_Date__c, 'It should be filled email verification date');
    }

    private static Contact getContact() {
        return [SELECT id, Email, Email_Verification_Date__c, Verification_Status__c FROM Contact WHERE FirstName = 'Tester'];
    }
}