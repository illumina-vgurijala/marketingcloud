/***************************************************************************************************************************************
* @Author:  Prem Ranjan
* @Date:   10-March-2022
* @Description: Test Class to cover AccVerificaionEmailNotifyFlow and EmailNotificationOnAccUpgrade class
*
* Modification Log:
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* Prem Ranjan              10-March-2022        Initial Version
* Adyasha Satapathy        28-Nov-2022          POL-54: Update region references to AMEA and EUR
******************************************************************************************************************************************/
@isTest(SeeAllData = false)
public class TestEmailNotificationOnAccUpgrade {
    public static final String UNVERIFIED = 'Unverified';
    public static final String REGION_AMR = 'AMR';
    public static final String REGION_AMEA = 'AMEA'; //POL-54
    public static final String REGION_EUR = 'EUR'; //POL-54
    public static final String REGION_GC = 'China';
    public static final String USD = 'USD';
    public static final String ACTIVE_PROSPECT = 'Active Prospect';
    public static final String ULTIMATE_CONSIGNEE = 'Ultimate Consignee';
    public static final String SOLD_TO = 'Sold To';
    public static final String DISTRIBUTOR = 'Distributor';

/* METHOD NAME   : testAccUnverifiedToActiveProspect
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-51955 Account: Ability for system to auto send email notification to Sales user on account verification and/or upgrade
* DESCRIPTION    : TestMethod for To cover AccUnverifiedToActiveProspect step in flow
*/    
    static testMethod void testAccUnverifiedToActiveProspect(){
        List<Account> accLst = new List<Account>();
        Account accAMR = TestDataAccount.getAccount('Test Acc1', USD);
        accAMR.Account_Status__c = UNVERIFIED;
        accAMR.Territory_Region__c = REGION_AMR;  
        accLst.add(accAMR);
        Account accAMEA = TestDataAccount.getAccount('Test Acc2', USD); //POL-54
        accAMEA.Account_Status__c = UNVERIFIED;//POL-54
        accAMEA.Territory_Region__c = REGION_AMEA;//POL-54
        accLst.add(accAMEA);//POL-54
        Account accEUR = TestDataAccount.getAccount('Test Acc3', USD);//POL-54
        accEUR.Account_Status__c = UNVERIFIED;//POL-54
        accEUR.Territory_Region__c = REGION_EUR;//POL-54
        accLst.add(accEUR);//POL-54
        Account accGC = TestDataAccount.getAccount('Test Acc4', USD);
        accGC.Account_Status__c = UNVERIFIED;
        accGC.Territory_Region__c = REGION_GC;
        accLst.add(accGC);
        Insert accLst;
        
        accAMR.Account_Status__c = ACTIVE_PROSPECT;
        accAMEA.Account_Status__c = ACTIVE_PROSPECT;//POL-54
        accEUR.Account_Status__c = ACTIVE_PROSPECT;//POL-54
        accGC.Account_Status__c = ACTIVE_PROSPECT;

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
        update accAMR;
        update accAMEA;//POL-54
        update accEUR;//POL-54
        update accGC;
        System.assertEquals(4, Limits.getEmailInvocations(), 'Emails should be sent');
        Test.stopTest();

    }

/* METHOD NAME   : testProspectToUC
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-51955 Account: Ability for system to auto send email notification to Sales user on account verification and/or upgrade
* DESCRIPTION    : TestMethod for To cover ProspectToUC step in flow
*/    
    static testMethod void testProspectToUC(){
        List<Account> accLst = new List<Account>();
        Account accAMR = TestDataAccount.getAccount('Test Acc1', USD);
        //accAMR.Account_Status__c = UNVERIFIED;
        accAMR.Territory_Region__c = REGION_AMR;  
        accLst.add(accAMR);
        Account accAMEA = TestDataAccount.getAccount('Test Acc2', USD);//POL-54
        //accAMEA.Account_Status__c = UNVERIFIED;
        accAMEA.Territory_Region__c = REGION_AMEA;//POL-54
        accLst.add(accAMEA);//POL-54
        Account accEUR = TestDataAccount.getAccount('Test Acc3', USD);//POL-54
        //accEUR.Account_Status__c = UNVERIFIED;
        accEUR.Territory_Region__c = REGION_EUR;//POL-54
        accLst.add(accEUR);//POL-54
        Account accGC = TestDataAccount.getAccount('Test Acc4', USD);
        //accGC.Account_Status__c = UNVERIFIED;
        accGC.Territory_Region__c = REGION_GC;
        accLst.add(accGC);
        Insert accLst;
        
        accAMR.Account_Group__c = ULTIMATE_CONSIGNEE;
        accAMEA.Account_Group__c = ULTIMATE_CONSIGNEE;//POL-54
        accEUR.Account_Group__c = ULTIMATE_CONSIGNEE;//POL-54
        accGC.Account_Group__c = ULTIMATE_CONSIGNEE;

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
        update accAMR;
        update accAMEA;//POL-54
        update accEUR;//POL-54
        update accGC;
        System.assertEquals(4, Limits.getEmailInvocations(), 'Emails should be sent');
        Test.stopTest();

    }

/* METHOD NAME   : testUCToSoldTo
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-51955 Account: Ability for system to auto send email notification to Sales user on account verification and/or upgrade
* DESCRIPTION    : TestMethod for To cover ProspectToUC step in flow
*/    
    static testMethod void testUCToSoldTo(){
        List<Account> accLst = new List<Account>();
        Account accAMR = TestDataAccount.getAccount('Test Acc1', USD);
        accAMR.Account_Group__c = ULTIMATE_CONSIGNEE;
        accAMR.Territory_Region__c = REGION_AMR;  
        accLst.add(accAMR);
        Account accAMEA = TestDataAccount.getAccount('Test Acc2', USD);//POL-54
        accAMEA.Account_Group__c = ULTIMATE_CONSIGNEE;//POL-54
        accAMEA.Territory_Region__c = REGION_AMEA;//POL-54
        accLst.add(accAMEA);//POL-54
        Account accEUR = TestDataAccount.getAccount('Test Acc3', USD);//POL-54
        accEUR.Account_Group__c = ULTIMATE_CONSIGNEE;//POL-54
        accEUR.Territory_Region__c = REGION_EUR;//POL-54
        accLst.add(accEUR);//POL-54
        Account accGC = TestDataAccount.getAccount('Test Acc4', USD);
        accGC.Account_Group__c = ULTIMATE_CONSIGNEE;
        accGC.Territory_Region__c = REGION_GC;
        accLst.add(accGC);
        Insert accLst;
        
        accAMR.Account_Group__c = SOLD_TO;
        accAMEA.Account_Group__c = SOLD_TO;//POL-54
        accEUR.Account_Group__c = SOLD_TO;//POL-54
        accGC.Account_Group__c = SOLD_TO;

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
        update accAMR;
        update accAMEA;//POL-54
        update accEUR;//POL-54
        update accGC;
        System.assertEquals(4, Limits.getEmailInvocations(), 'Emails should be sent');
        Test.stopTest();

    }

/* METHOD NAME   : testProspectToDistributor
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-51955 Account: Ability for system to auto send email notification to Sales user on account verification and/or upgrade
* DESCRIPTION    : TestMethod for To cover ProspectToUC step in flow
*/    
    static testMethod void testProspectToDistributor(){
        List<Account> accLst = new List<Account>();
        Account accAMR = TestDataAccount.getAccount('Test Acc1', USD);
        //accAMR.Account_Status__c = UNVERIFIED;
        accAMR.Territory_Region__c = REGION_AMR;  
        accLst.add(accAMR);
        Account accAMEA = TestDataAccount.getAccount('Test Acc2', USD);//POL-54
        //accAMEA.Account_Status__c = UNVERIFIED;
        accAMEA.Territory_Region__c = REGION_AMEA;//POL-54
        accLst.add(accAMEA);//POL-54
        Account accEUR = TestDataAccount.getAccount('Test Acc3', USD);//POL-54
        //accEUR.Account_Status__c = UNVERIFIED;
        accEUR.Territory_Region__c = REGION_EUR;//POL-54
        accLst.add(accEUR);//POL-54
        Account accGC = TestDataAccount.getAccount('Test Acc4', USD);
        //accGC.Account_Status__c = UNVERIFIED;
        accGC.Territory_Region__c = REGION_GC;
        accLst.add(accGC);
        Insert accLst;
        
        accAMR.Account_Group__c = DISTRIBUTOR;
        accAMEA.Account_Group__c = DISTRIBUTOR;//POL-54
        accEUR.Account_Group__c = DISTRIBUTOR;//POL-54
        accGC.Account_Group__c = DISTRIBUTOR;

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
        update accAMR;
        update accAMEA;//POL-54
        update accEUR;//POL-54
        update accGC;
        System.assertEquals(4, Limits.getEmailInvocations(), 'Emails should be sent');
        Test.stopTest();
    }

/* METHOD NAME   : testUCToDistributor
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-51955 Account: Ability for system to auto send email notification to Sales user on account verification and/or upgrade
* DESCRIPTION    : TestMethod for To cover ProspectToUC step in flow
*/    
    static testMethod void testUCToDistributor(){
        List<Account> accLst = new List<Account>();
        Account accAMR = TestDataAccount.getAccount('Test Acc1', USD);
        accAMR.Account_Group__c = ULTIMATE_CONSIGNEE;
        accAMR.Territory_Region__c = REGION_AMR;  
        accLst.add(accAMR);
        Account accAMEA = TestDataAccount.getAccount('Test Acc2', USD);//POL-54
        accAMEA.Account_Group__c = ULTIMATE_CONSIGNEE;//POL-54
        accAMEA.Territory_Region__c = REGION_AMEA;//POL-54
        accLst.add(accAMEA);//POL-54
        Account accEUR = TestDataAccount.getAccount('Test Acc3', USD);//POL-54
        accEUR.Account_Group__c = ULTIMATE_CONSIGNEE;//POL-54
        accEUR.Territory_Region__c = REGION_EUR;//POL-54
        accLst.add(accEUR);//POL-54
        Account accGC = TestDataAccount.getAccount('Test Acc4', USD);
        accGC.Account_Group__c = ULTIMATE_CONSIGNEE;
        accGC.Territory_Region__c = REGION_GC;
        accLst.add(accGC);
        Insert accLst;
        
        accAMR.Account_Group__c = DISTRIBUTOR;
        accAMEA.Account_Group__c = DISTRIBUTOR;//POL-54
        accEUR.Account_Group__c = DISTRIBUTOR;//POL-54
        accGC.Account_Group__c = DISTRIBUTOR;

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
        update accAMR;
        update accAMEA;//POL-54
        update accEUR;//POL-54
        update accGC;
        System.assertEquals(4, Limits.getEmailInvocations(), 'Emails should be sent');
        Test.stopTest();

    }
}