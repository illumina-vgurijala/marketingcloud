/***************************************************************************************************************************************
 * NAME   : TestQualityRecordJunctions
 * DESCRIPTION  : Test Class for QualityRecordJunctionsTrigger
 *				      
 * @AUTHOR : Gladis Evangaly
 * @DATE   : 06-Apr-2022  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Gladis             	06-Apr-2022            Initial Version. 
  ****************************************************************************************************************************************/ 
@isTest 
public with sharing class TestQualityRecordJunctions {
    /**
    *  @Author - Gladis
    *  @Description - test data
    **/
    @testSetup
    public static void initializeTestData() {

        List<Quality_Record_Junction__c> lstQRJ = new List<Quality_Record_Junction__c>();

        Quality_Record__c qr = new Quality_Record__c();
        qr.EtQ_Number__c = '01';
        qr.EtQ_Integration_Status__c = 'QI Creation Initiated';
        insert qr;

        Quality_Record_Junction__c qrj1 = new Quality_Record_Junction__c();
        qrj1.Quality_Record__c = qr.id;
        qrj1.EtQ_Integration_Status__c = 'Link Initiated'; 
        lstQRJ.add(qrj1);

        Quality_Record_Junction__c qrj2 = new Quality_Record_Junction__c();
        qrj2.Quality_Record__c = qr.id;
        qrj2.EtQ_Integration_Status__c = 'Delink Initiated';
        lstQRJ.add(qrj2);
        
        insert lstQRJ;

        
        System.assertNotEquals(null, qrj1.Id);
    }

    /**
    *  @Author - Gladis
    *  @Description - Test method for asyncProcessesOnAfterQRJInsert method
    **/    
    @isTest
    static void testasyncProcessesOnAfterQRJInsert() {
        
        initializeTestData();
        Quality_Record__c qr = new Quality_Record__c();
        qr.EtQ_Number__c = '01';
        qr.EtQ_Integration_Status__c = 'QI Creation Initiated';
        insert qr;

        Quality_Record_Junction__c qrj = new Quality_Record_Junction__c();
        qrj.Quality_Record__c = qr.id;
        qrj.EtQ_Integration_Status__c = 'Link Initiated'; 
        insert qrj;
        
        Test.startTest();
        List<Quality_Record_Junction__c> lstQRJ = [Select Id from Quality_Record_Junction__c where Id=:qrj.Id];
        System.assertEquals(qrj.Id, lstQRJ[0].Id, 'Mismatched Id');
        Test.stopTest();
    }

    /**
    *  @Author - Gladis
    *  @Description - Test method for asyncProcessesOnAfterQRJUpdate method
    **/    
    @isTest
    static void testAsyncProcessesOnAfterQRJUpdate() {

        Quality_Record__c qr = new Quality_Record__c();
        qr.EtQ_Number__c = '01';
        qr.EtQ_Integration_Status__c = 'QI Creation Initiated';
        insert qr;

        Quality_Record_Junction__c qrj = new Quality_Record_Junction__c();
        qrj.Quality_Record__c = qr.id;
        qrj.EtQ_Integration_Status__c = 'Manual Link'; 
        insert qrj;

        qr.EtQ_Integration_Status__c = 'Link Initiated';
        update qr;

        
        Test.startTest();
        List<Quality_Record__c> lstQR = [Select Id,EtQ_Integration_Status__c from Quality_Record__c where Id=:qr.Id];
        System.assertEquals('Link Initiated', lstQR[0].EtQ_Integration_Status__c, 'Update Failed');
        Test.stopTest();
    }
}
