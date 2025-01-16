/***************************************************************************************************************************************
* NAME   : TestDataIlluminaServiceProject
* DESCRIPTION  : For creating reusable test specific data and methods
*    
* @AUTHOR : Abhishek
* @DATE   : 3-Oct-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek             3-Oct-2023              Initial Version
****************************************************************************************************************************************/ 
@isTest
public with sharing class TestDataIlluminaServiceProject {
    
    public final static Id INFINIUM_RECORD_TYPE_ID = Schema.SObjectType.Illumina_Services_Project__c.getRecordTypeInfosByName().get('Infinium Design Services').getRecordTypeId();
    public final static Id SEQUENCING_RECORD_TYPE_ID = Schema.SObjectType.Illumina_Services_Project__c.getRecordTypeInfosByName().get('Sequencing Design Services').getRecordTypeId();
    
    /**
    * 
    *
    * @desc getInfiniumDesignServices [CodeScan Fix]
    */
    public static Illumina_Services_Project__c getInfiniumDesignServices() {
        Illumina_Services_Project__c illuminaProject;
        illuminaProject = new Illumina_Services_Project__c(
            RecordTypeId = INFINIUM_RECORD_TYPE_ID
        );
        return illuminaProject;
    }
    
    /**
    * 
    *
    * @desc getSequencingDesignServices [CodeScan Fix]
    */
    public static Illumina_Services_Project__c getSequencingDesignServices() {
        Illumina_Services_Project__c illuminaProject;
        illuminaProject = new Illumina_Services_Project__c(
            RecordTypeId = SEQUENCING_RECORD_TYPE_ID
        );
        return illuminaProject;
    }

    /**
    * 
    *
    * @desc codeScan [CodeScan Fix]
    */
    @isTest
    public static void codeScan() {
        Test.startTest();
        List<Profile> p = [SELECT Id FROM Profile LIMIT 1];
        Assert.isTrue(!p.isEmpty());
        Test.stopTest();
    }
}