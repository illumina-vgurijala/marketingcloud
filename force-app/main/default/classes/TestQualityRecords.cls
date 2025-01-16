/***************************************************************************************************************************************
 * NAME   : TestQualityRecords
 * DESCRIPTION  : Test Class for QualityRecordTrigger
 *				      
 * @AUTHOR : Gladis Evangaly
 * @DATE   : 06-Apr-2022  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Gladis             	06-Apr-2022            Initial Version. 
 * Abhinav             	14-Apr-2022            Added Test method for QRJ deletion. 
  ****************************************************************************************************************************************/ 
@isTest
public with sharing class TestQualityRecords {

    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';


    /**
    *  @Author - Gladis
    *  @Description - test data
    **/
    @testSetup
    public static void initializeTestData() {

        List<Quality_Record__c> lstQR = new List<Quality_Record__c>();

        Quality_Record__c qr1 = new Quality_Record__c();
        qr1.EtQ_Number__c = '01';
        qr1.EtQ_Integration_Status__c = 'QI Creation Initiated'; 
        lstQR.add(qr1);

        Quality_Record__c qr2 = new Quality_Record__c();
        qr2.EtQ_Number__c = '02';
        qr2.EtQ_Integration_Status__c = 'QI Creation Successful';
        lstQR.add(qr2);
        
        insert lstQR;
        System.assertNotEquals(null, qr1.Id);
    }

    /**
    *  @Author - Gladis
    *  @Description - Test method for asyncProcessesOnAfterQRInsert method
    **/    
    @isTest
    static void testAsyncProcessesOnAfterQRInsert() {

        Quality_Record__c qr = new Quality_Record__c();
        qr.EtQ_Number__c = '001';
        qr.EtQ_Integration_Status__c = 'QI Creation Initiated'; 
        insert qr;
        
        Test.startTest();
        List<Quality_Record__c> lstQR = [Select Id from Quality_Record__c where Id=:qr.Id];
        System.assertEquals(qr.Id, lstQR[0].Id, 'Mismatched Id');
        Test.stopTest();
    }

    /**
    *  @Author - Gladis
    *  @Description - Test method for asyncProcessesOnAfterQRUpdate method
    **/    
    @isTest
    static void testAsyncProcessesOnAfterQRUpdate() {

        Quality_Record__c qr = new Quality_Record__c();
        qr.EtQ_Number__c = '002';
        qr.EtQ_Integration_Status__c = 'Manual Created'; 
        insert qr;

        qr.EtQ_Integration_Status__c = 'QI Creation Initiated';
        update qr;

        
        Test.startTest();
        List<Quality_Record__c> lstQR = [Select Id, EtQ_Integration_Status__c from Quality_Record__c where Id=:qr.Id];
        System.assertEquals('QI Creation Initiated', lstQR[0].EtQ_Integration_Status__c, 'Update Failed');
        Test.stopTest();
    }

        /**
    *  @Author - Abhinav
    *  @Description - Test method for deleteQualityJuncRecOnVoid method
    **/    
    @isTest
    static void testDeleteQualityJuncRecOnVoid() {

        Quality_Record__c qr = new Quality_Record__c();
        qr.EtQ_Number__c = '002';
        qr.EtQ_Integration_Status__c = 'QI Creation Initiated'; 
        insert qr;

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        insert objCase;

        Quality_Record_Junction__c qrj1 = new Quality_Record_Junction__c(Quality_Record__c=qr.Id,Case__c=objCase.Id);
        insert qrj1;

        qr.Current_Phase__c = 'Void';
        update qr;
        
        Test.startTest();
        List<Quality_Record_Junction__c> qrList = [Select Id from Quality_Record_Junction__c where Quality_Record__c =:qr.Id];
        System.assertEquals(0,qrList.size(), 'Delete Failed');
        Test.stopTest();
    }
}
