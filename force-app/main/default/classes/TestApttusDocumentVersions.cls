/**
* Author: Illumina
* @date   
* @description: Test class. 
* Modification Log:
* ------------------------------------------------------------------------------------
*   Parthasarathy D        10-Oct-2022            Codescan Fixes
*   Adyasha Satapathy      28-Nov-2022            POL-54: POL-54: Update region references to AMEA and EUR
*------------------------------------------------------------------------------------
*/
@isTest
private class TestApttusDocumentVersions {

    @isTest static void recordTypeValue()
    {
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BillingCountryCode='HK';
        insert acc;

        Customer_Master_Data__c objCMD1 = TestDataAccount.initCustomerMasterData('123456', 'Hong Kong', 'HK');
        insert new List<Customer_Master_Data__c> { objCMD1 };

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.initAccountSalesArea(acc.Id, '123456', 'HK01', '01', '00', '01-AMEA-USD', '06');//POL-54
        insert new List<Account_Sales_Area__c> { acc1SalesArea };

        // this is needed because the user running the tests might not have permission to insert agreements
        cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(UserInfo.getProfileId());
        cs.Bypass_All_Validations__c = true;
        upsert cs cs_Apex_Settings__c.Id;

        Id rtId;
        String rtName;
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = ApttusAgreements.getRecordTypeMap();
        for (Id i : idToRecordTypeInfo.keySet())
        {
            if (idToRecordTypeInfo.get(i).isActive())
            {
                rtId = i;
                rtName = idToRecordTypeInfo.get(i).getDeveloperName();
                break;
            }
        }

        Apttus__APTS_Agreement__c agreement = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.Id);
        agreement.Sales_Org__c = 'HK01'; //adding reference sale org
        agreement.RecordTypeId = rtId;
        insert agreement;

        // add record
        Apttus__DocumentVersion__c rec1 = new Apttus__DocumentVersion__c(
            Apttus__AgreementId__c = agreement.Id,
            Apttus__LatestVersion__c = 'hi',
            Apttus__Title__c = 'hi'
        );
        insert rec1;

        Apttus__DocumentVersion__c savedRec = [SELECT Id, Agreement_Record_Type__c FROM Apttus__DocumentVersion__c].get(0);
        System.assertEquals(rtName, savedRec.Agreement_Record_Type__c);
    }

}