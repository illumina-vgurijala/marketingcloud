/*
* DESCRIPTION  : TestClass for casePDFMetadataValues
Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Saptarshi Das               15-Sep-2022            QACM-175 - Printable Case View for Audit & Non-SFDC Users
*
*    ------------------------------------------------------------------------------------                  
*/


@isTest(SeeAllData = false) 
public with sharing class TestcasePDFMetadataValues {

    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';

    static testmethod void pDFmetadataValuesTest() {

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        insert objCase;

        Pagereference pdfPage = page.casePDF;
        Test.setCurrentPage(pdfPage);
        Apexpages.currentPage().getparameters().put('recId',objCase.Id);
        
        Test.startTest();
        CasePDFController caseMeta = new CasePDFController();
        caseMeta.getLayouts();
        Test.stopTest();
        System.assertNotEquals(null, objCase.Id);
    }
}