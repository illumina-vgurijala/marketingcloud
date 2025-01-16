/**
 * Created by tnewman on 11/20/18.
 */
@isTest
public with sharing class TestDataContract {

    /*public static Customer_Agreement__c getNewAgreement()
    {
        Customer_Agreement__c rec = initAgreement();
        insert rec;
        return rec;
    }
    public static Customer_Agreement__c initAgreement()
    {
        Customer_Agreement__c rec = new Customer_Agreement__c(
                Name = TestData.getRandom(),
                Agreement_Number__c = TestData.getRandomNumeric(),
                Agreement_Type__c = 'Standing Agreement',
                Product_Type__c = 'Instrument',
                Start_Date__c = Date.today() - 2,
                End_Date__c = Date.today() + 20
        );
        return rec;
    }
    public static Customer_Agreement_Account_Link__c getNewAgreementLink(Id accountId, Id agreementId)
    {
        Customer_Agreement_Account_Link__c rec = initAgreementLink(accountId, agreementId);
        insert rec;
        return rec;
    }
    public static Customer_Agreement_Account_Link__c initAgreementLink(Id accountId, Id agreementId)
    {
        Customer_Agreement_Account_Link__c rec = new Customer_Agreement_Account_Link__c(
                Account__c = accountId,
                Customer_Agreement__c = agreementId
        );
        return rec;
    }*/

}