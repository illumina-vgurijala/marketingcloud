/**
*    @author      :Himanshu Malik
*    @date        :2022-08-05
*    @description :Test class for AgreementSendEMailForOpenOfferAgrrement
*    Modification Log:
*     ---------------------------------------------------------------------------------------------------------------------------
*         Developer                       Date                    Description         
*         Himanshu                      2022-06-02                Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
*
***/

@isTest(isParallel=false)
public with sharing class TestAgreementEmailForOpenOfferAgreement {
    
    @isTest
    static void sendEmail(){
        Test.startTest();
            AgreementSendEmailForOpenOfferAgreement.DataInputsForEmail objVariable = new AgreementSendEmailForOpenOfferAgreement.DataInputsForEmail();
            List<AgreementSendEmailForOpenOfferAgreement.DataInputsForEmail>lstVaribale = new List<AgreementSendEmailForOpenOfferAgreement.DataInputsForEmail>();
            List<String>ccAddress = new List<String>{'test@test.com'};
            objVariable.emailBody = 'test';
            objVariable.emailSubject = 'test coverage';
            objVariable.toEmailAddress = ccAddress;
            objVariable.ccEmailAddress = ccAddress;
            lstVaribale.add(objVariable);
            AgreementSendEmailForOpenOfferAgreement.sendEmail(lstVaribale);
        Test.stopTest();
        System.assertEquals(1, lstVaribale.size(),'Incorrect List Size');

    }
}