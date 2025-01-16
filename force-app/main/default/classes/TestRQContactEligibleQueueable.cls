/*@ author       : Maruthi B
* @ date         : 17-02-2022
* @ Description  : PM-122: Test class for RQContactEligibleQueueable
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Maruthi               17-02-2022                 Initial version
* Gopi               	05-06-2023                 CMCM-698
* Bala               	23-06-2023                 CMCM-933,CMCM-1563
* Enrique Reyes         14-08-2023                 CMCM-2229
*/
@isTest
public with sharing class TestRQContactEligibleQueueable {
    public static final String ROLE1 = 'Regulatory/Quality';
    public static final String ROLE2 = 'Hard Copy RQ Sales';
    public static final String ROLE3 = 'Hard Copy RQ Service';

    /*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: This Method to RQContactEligibleQueueable  
    */ 
    @isTest 
    static void checkQueueable() {
        Account acc = TestDataAccount.initAmrAccount();       
        insert acc;        
        Apttus_Config2__Order__c ord = TestDataOrder.getNewOrder(acc.id);
        
        Test.startTest();          
            ord.Apttus_Config2__Type__c = 'Standard Order';
        	update ord;
        	Account accc = [Select id, R_Q_Contact_Eligible__c from Account where id =: ord.Apttus_Config2__SoldToAccountId__c];        	        	
            System.assert(!accc.R_Q_Contact_Eligible__c, 'accc.R_Q_Contact_Eligible__c is false'); 
        Test.stopTest();
        
    }    
    
	/*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: This Method to RQContactEligibleQueueable  
    */ 
    @isTest 
    static void checkQueueable1() {
        Account acc = TestDataAccount.initAmrAccount();       
        insert acc;
        acc.Account_Group__c = 'Distributor';
        update acc;        
        Apttus_Config2__Order__c ord = TestDataOrder.getNewOrder(acc.id);
        
        Test.startTest();          
            ord.Apttus_Config2__Type__c = 'Standard Order';
        	update ord;
        	Account accc = [Select id, R_Q_Contact_Eligible__c from Account where id =: ord.Apttus_Config2__SoldToAccountId__c];        	        	
            System.assert(!accc.R_Q_Contact_Eligible__c, 'accc.R_Q_Contact_Eligible__c is false'); 
        Test.stopTest();
        
    }

    /*
    *  @AUTHOR:  Gopi
    *  @DESCRIPTION: This Method is for RQContactEligibleQueueable  
    */ 
    @isTest 
    static void checkQueueableRQEligible() {
        Account ultimateConsigneeAccount = TestDataAccount.getCustomerAccount();       
        ultimateConsigneeAccount.Account_Group__c = 'Ultimate Consignee';
        insert ultimateConsigneeAccount;

        Account acc = TestDataAccount.initAmrAccount();       
        insert acc;
        acc.Account_Group__c = 'Sold To';
        update acc;        
        Apttus_Config2__Order__c ord = TestDataOrder.getNewOrder(acc.id);
        
        Test.startTest();          
            ord.Apttus_Config2__Type__c = 'Standard Order';
        	update ord;
        	Account acc2 = TestDataAccount.getCustomerAccount();       
        	insert acc2;
            acc2.Account_Group__c = 'Distributor';
            update acc2;        
            Apttus_Config2__Order__c ord2 = TestDataOrder.getNewOrder(acc2.id);
        	ord2.Apttus_Config2__Type__c = 'Standard Order';
        	update ord2;

            Account acc3 = TestDataAccount.getCustomerAccount();
            acc3.Account_Group__c = 'Distributor';
        	acc3.BillingCountryCode = 'US';
            insert acc3;        
            Apttus_Config2__Order__c ord3 = TestDataOrder.getNewOrder(acc3.id);
        	ord3.Apttus_Config2__Type__c = 'Standard Order';
        	update ord3;
        
        	Account usaSoldToAccount = [Select id, R_Q_Contact_Eligible__c from Account where id =: ord3.Apttus_Config2__SoldToAccountId__c];        	        	
            System.assert(!usaSoldToAccount.R_Q_Contact_Eligible__c, 'Given accc.R_Q_Contact_Eligible__c is false, it should be true for Account Group \'Distributor\' and USA.');
        
        	Account acc4 = TestDataAccount.getCustomerAccount();       
            acc4.Account_Group__c = 'Distributor';
        	acc4.BillingCountryCode = 'JP';
            insert acc4;
            Apttus_Config2__Order__c ord4 = TestDataOrder.getNewOrder(acc4.id);
        	ord4.Apttus_Config2__Type__c = 'Standard Order';
            ord4.Ultimate_Consignee__c = ultimateConsigneeAccount.Id;
        	update ord4;
        
        	Account japanUltimateConsigneeAccount = [Select id, R_Q_Contact_Eligible__c from Account where id =: ord4.Ultimate_Consignee__c];        	        	
            System.assert(!japanUltimateConsigneeAccount.R_Q_Contact_Eligible__c, 'Given accc.R_Q_Contact_Eligible__c is false, it should be true for Account Group \'Distributor\' and Japan.');

            Account acc5 = TestDataAccount.getCustomerAccount();
            acc5.Account_Group__c = 'Distributor';
        	acc5.BillingCountryCode = 'KE';
            insert acc5;        
            Apttus_Config2__Order__c ord5 = TestDataOrder.getNewOrder(acc5.id);
        	ord5.Apttus_Config2__Type__c = 'Standard Order';
            ord5.Ultimate_Consignee__c = ultimateConsigneeAccount.Id;
        	update ord5;
        
        	Account koreaSoldToAccount = [Select id, R_Q_Contact_Eligible__c from Account where id =: ord5.Apttus_Config2__SoldToAccountId__c];
            Account koreaUltimateconsigneeAccount = [Select id, R_Q_Contact_Eligible__c from Account where id =: ord5.Ultimate_Consignee__c];
            System.assert(!koreaSoldToAccount.R_Q_Contact_Eligible__c, 'Given accc.R_Q_Contact_Eligible__c is false, it should be true for Account Group \'Distributor\' and Korea.'); 	        	
            System.assert(!koreaUltimateconsigneeAccount.R_Q_Contact_Eligible__c, 'Given accc.R_Q_Contact_Eligible__c is false, it should be true for Account Group \'Distributor\' and Korea.');

            Account acc6 = TestDataAccount.getCustomerAccount();
            acc6.Account_Group__c = 'Distributor';
        	acc6.BillingCountryCode = 'HK';
            insert acc6;        
            Apttus_Config2__Order__c ord6 = TestDataOrder.getNewOrder(acc6.id);
        	ord6.Apttus_Config2__Type__c = 'Standard Order';
            ord6.Ultimate_Consignee__c = ultimateConsigneeAccount.Id;
        	update ord6;
        
        	Account hongkongSoldToAccount = [Select id, R_Q_Contact_Eligible__c from Account where id =: ord6.Apttus_Config2__SoldToAccountId__c];
            Account hongkongUltimateconsigneeAccount = [Select id, R_Q_Contact_Eligible__c from Account where id =: ord6.Ultimate_Consignee__c];
            System.assert(!hongkongSoldToAccount.R_Q_Contact_Eligible__c, 'Given accc.R_Q_Contact_Eligible__c is false, it should be true for Account Group \'Distributor\' and Hong Kong.'); 	        	
            System.assert(!hongkongUltimateconsigneeAccount.R_Q_Contact_Eligible__c, 'Given accc.R_Q_Contact_Eligible__c is false, it should be true for Account Group \'Distributor\' and Hong Kong.');
        Test.stopTest();
    }
    
    /*
    *  @AUTHOR:  Enrique Reyes
    *  @DESCRIPTION: This Method is for UpdateHardBouncedConQueueable  
    */ 
    @isTest 
    static void testGetAccConReltionship() {
        Account testAccount = TestDataAccount.getNewAccount();
        Account testAccount2 = TestDataAccount.getNewAccount();
        Contact testContact = TestDataContact.initContact(testAccount);
        testContact.Email = 'test@test.com';
        insert testContact;
        List<String> listOfRoles = new List<String>();
        String[] roles = new String []{ ROLE1, ROLE2, ROLE3 };
        AccountContactRelation testAccountContactRelation = new AccountContactRelation();
        testAccountContactRelation.AccountId = testAccount2.Id;
        testAccountContactRelation.ContactId = testContact.Id;
        testAccountContactRelation.Roles = String.join(roles, ';');
        testAccountContactRelation.Product_Notifications_Categories__c = 'Default (All)';
        insert testAccountContactRelation;
        
        Set<Id> setContactIds = new Set<Id>();
        setContactIds.add(testContact.Id);
        List<AccountContactRelation> lstAccContRelationRecs = new List<AccountContactRelation>();    
        Test.startTest();
        lstAccContRelationRecs = RQContactEligibleHelper.getAccConReltionship(setContactIds); 
        System.assert(!lstAccContRelationRecs.isEmpty(), 'List should not be empty');
        Test.stopTest();
    }
}