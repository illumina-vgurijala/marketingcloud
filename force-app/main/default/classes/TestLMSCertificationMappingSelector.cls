/***************************************************************************************************************************************
 * NAME   : TestLMSCertificationMappingSelector
 * DESCRIPTION  : TestClass for LMSCertificationMappingSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 29-Aug-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             29-Aug-2021             Initial Version
  ***************************************************************************************************************************************
*/
@isTest(seeAllData = false)
public with sharing class TestLMSCertificationMappingSelector {
    static LMS_Certification_Mapping__c lmsCertificationMappingObj = new LMS_Certification_Mapping__c();
    static final String STRING_PRODUCT_FAMILY_AUTOLOADER_2 = 'Autoloader - 2';
    /**
      *  @author Prashanth
      *  @description - initialize test data
    **/
    @TestSetup
    public static void initializeTestData(){
        //create LMS Certification Mapping Record.
        lmsCertificationMappingObj = new LMS_Certification_Mapping__c();
        lmsCertificationMappingObj.Active__c = true;
        lmsCertificationMappingObj.Certification_Name__c = 'CS: FSE iScan Certification';
        lmsCertificationMappingObj.Product_Family__c = STRING_PRODUCT_FAMILY_AUTOLOADER_2;
        lmsCertificationMappingObj.Certification_ID__c = '00010040';
        insert lmsCertificationMappingObj;
    }
    /**
      *  @author Prashanth
      *  @description - test the LMSCertificationMappingSelector class.
    **/
    @IsTest
    static void lmsCertificationMappingSelectorTest(){
        LMSCertificationMappingSelector selector = new LMSCertificationMappingSelector();
        Test.startTest();
        System.assertEquals(1, selector.selectProductFamilyByCertificationId('00010040').size(), 'Assertion Failed.');
        System.assertEquals(1, selector.selectLMSMappingRecords().size(), 'Assertion Failed.');
        Test.stopTest();
        
    }
}