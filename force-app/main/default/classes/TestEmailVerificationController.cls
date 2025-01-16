/**
 *    @author Kushagra Desai
 *    @date   14-July-2020
 *    @description  Test class for EmailVerificationController
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *    Maruthi                        02-Feb-2022          PM-22: updated testEmailValidationsSuccess method to cover getRecordData 
 *    Maruthi                        04-Feb-2022          PM-75 and PM-97 Created tesForNegativeSenarios method to cover Negative Senario
 *    Ashwin                         11-July-2022         INC0403213 - Add testMethod for Contact objectApiName
 *    Gerardo Garcia                 22-03-2024           CMCM-5889 - Add new test getRecordDataInvalidId
    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestEmailVerificationController {

    @TestSetup
    static void makeData(){
       TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
       TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
    }

    private static Lead getLead() {
        return [SELECT id FROM Lead WHERE FirstName = 'testfirstname'];
    }

    private static Contact getContact() {
        return [SELECT id FROM Contact WHERE FirstName = 'testfirstname'];
    }

    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Email Validation  
    */  
    @isTest
    static void testEmailValidationsSuccess() {
        Lead lead = getLead();
        Test.starttest();
        //Added as part of PM-22
        Test.setMock(HttpCalloutMock.class, new LeadEmailVerificationMockHTTP('S'));
        Test.stoptest();
        Assert.areEqual('Verified Successfully',EmailVerificationController.sendVerificationRequest('test@gmail.com',lead.id, 'Lead', true),'Verified Successfully');
    }

    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Email Validation 
    */ 
    @isTest
    static void testEmailValidationsPartialSuccess() {
        Lead lead = getLead();
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new LeadEmailVerificationMockHTTP('SP'));
        Test.stoptest();
        Assert.areEqual('Verified With Warning',EmailVerificationController.sendVerificationRequest('test@gmail.com',lead.id, 'Lead', true),'Partial Validation failed');
    }

    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Email Validation 
    */ 
    @isTest
    static void testEmailValidationsFailure() {
        List<String> strList = new List<String>();
        strList.add('Verification_Status__c');
        strList.add('Deactivation_Reason__c');
        strList.add('Verification_Status__c');
        strList.add('Deactivation_Reason__c');
        strList.add('Verification_Status__c');
        strList.add('Deactivation_Reason__c');
        String objectApiName = 'Contact';
        Lead lead = getLead();
        Test.starttest();
        EmailVerificationController.EmailVerificationFieldsWrapper wrapWrap = new EmailVerificationController.EmailVerificationFieldsWrapper(strList,objectApiName);         
        wrapWrap.strVerofocationStatus = 'Verified Successfully';
        Test.setMock(HttpCalloutMock.class, new LeadEmailVerificationMockHTTP('F'));        
        Test.stoptest();
        Assert.areEqual('Error-System Failure',EmailVerificationController.sendVerificationRequest('test@gmail.com',lead.id,'Lead', true),'Error-System Failure');
    }

    /*
    *@author: Ashwin
    *@Desc: INC0403213 - Test method to check Email Validation for Contact
    */ 
    @isTest
    static void testEmailValidationForContact() {
        Contact objContact = getContact();
        User objAdminUser = TestDataUser.findUserInProfile('System Administrator');
        System.runAs(objAdminUser) {
            objContact.Deactivation_Reason__c = 'Email Verification Failed';
            objContact.Is_Active__c = false;
            objContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('KOL').getRecordTypeId();
            update objContact;
            Test.starttest();
            Test.setMock(HttpCalloutMock.class, new LeadEmailVerificationMockHTTP('S'));   
            Test.stoptest();
            Assert.areEqual('Verified Successfully', EmailVerificationController.sendVerificationRequest('test@gmail.com', objContact.Id, 'Contact', true), 'Verified Successfully');
            Assert.areEqual('Marketing', ilib_LogEvent.MARKETING);
        }
    }

    @isTest
    private static void sendVerificationRequestInvalidAuraException() {
        Test.setMock(HttpCalloutMock.class, new LeadEmailVerificationMockHTTP('S'));

        Contact objContact = getContact();
        delete objContact;
        
        Boolean gotException = false;
        Test.startTest();
        try{
            EmailVerificationController.sendVerificationRequest('test@gmail.com', objContact.Id, 'Contact', true);
        } catch(AuraHandledException e) {
            System.debug(e);
            gotException = true;
        }
        Test.stopTest();
        Assert.isTrue(gotException, 'It should got an AuraException');
    }

    @isTest
    private static void sendVerificationRequestInvalidEmailVerificationException() {
        Test.setMock(HttpCalloutMock.class, new LeadEmailVerificationMockHTTP('S'));

        Contact objContact = getContact();
        delete objContact;
        
        Boolean gotException = false;
        Test.startTest();
        try{
            EmailVerificationController.sendVerificationRequest('test@gmail.com', objContact.Id, 'Contact', false);
        } catch(EmailVerificationController.EmailVerificationException e) {
            System.debug(e);
            gotException = true;
        }
        Test.stopTest();
        Assert.isTrue(gotException, 'It should got a EmailVerificationException');
    }

    @IsTest
    private static void getRecordDataInvalidIdAuraException() {
        Contact objContact = getContact();
        delete objContact;

        Boolean gotException = false;
        Test.startTest();
        try{
            EmailVerificationController.getRecordData(objContact.id, 'Contact', true); //true, comes from lwc. It should throw Aura Exception
        } catch(AuraHandledException e) {
            System.debug(e);
            gotException = true;
        }
        Test.stopTest();
        Assert.isTrue(gotException, 'It should got an AuraException');
    }

    @IsTest
    private static void getRecordDataInvalidIdEmailVerificationException() {
        Contact objContact = getContact();
        delete objContact;

        Boolean gotException = false;
        Test.startTest();
        try{
            EmailVerificationController.getRecordData(objContact.id, 'Contact', false); //false, comes from Apex. It should throw EmailVerificationController.EmailVerificationException
        } catch(EmailVerificationController.EmailVerificationException e) {
            System.debug(e);
            gotException = true;
        }
        Test.stopTest();
        Assert.isTrue(gotException, 'It should got a LimitException');
    }
}