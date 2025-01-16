/***************************************************************************************************************************************
 * NAME   : TestCodeLibrarySelector
 * DESCRIPTION  : TestClass for CodeLibrarySelector
 * @AUTHOR : Prashanth
 * @DATE   :   22-Aug-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth              22-Aug-2021          Initial Version
 * Preetha                09-Mar-2022          QACM-51 Added selectCodeLibrByCodeTypeAndSubType 
 ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  
public with sharing class TestCodeLibrarySelector {

    /**
      *  @author Prashanth
      *  @description - To Test CodeLibrarySelector class
    **/
    static testmethod void testMethod1() {  
	Set<String> setOfTypes= new Set<String>{'Subject'};
    Code_Library__c codeLibrary = new Code_Library__c(
	Name = 'INQ CS Inquiry Subject code',
	CurrencyIsoCode = 'USD',
	Code_ID__c = 'SUB-012306',
	Code_Type__c = 'Subject',
	Case_Type__c = 'Inquiry',
	Inactive__c = false); 
    insert codeLibrary;
    Code_Library__c codeLibraryBI = new Code_Library__c(
	Name = 'BI CS Business Issue code',
	CurrencyIsoCode = 'USD',
	Code_ID__c = 'SUB-012307',
	Code_Type__c = 'Subject',
	Case_Type__c = 'Business Issue',
    Case_Sub_Type__c='Complaint', 
	Inactive__c = false); 
    insert codeLibraryBI; 

    Code_Library__c codeLibraryBI1 = new Code_Library__c(
	Name = 'BI CS Business Issue code',
	CurrencyIsoCode = 'USD',
	Code_ID__c = 'SUB-012308',
	Code_Type__c = 'Hazard',
	Case_Type__c = 'Business Issue',
    Case_Sub_Type__c='Complaint', 
	Inactive__c = false); 
    insert codeLibraryBI1;
        
    Code_Library__c codeLibraryBI2 = new Code_Library__c(
	Name = 'BI CS Business Issue code',
	CurrencyIsoCode = 'USD',
	Code_ID__c = 'SUB-012309',
	Code_Type__c = 'Logistics',
	Case_Type__c = 'Business Issue',
    Case_Sub_Type__c='Complaint', 
	Inactive__c = false); 
    insert codeLibraryBI2; 
        
    Set<Id> setNull = new Set<Id>();
    setNull.add(null);
            
    CodeLibrarySelector cls = new CodeLibrarySelector();
    cls.selectCodeLibraryByType(setOfTypes);
    cls.selectCodeLibraryByTitle(setOfTypes);
    cls.selectCodeLibraryBySimilarTitle(codeLibrary.Name,new Set<Id>{codeLibrary.id},'Code_ID__c','asc');
    cls.selectCodeLibrBySimilarTitleAndType(codeLibrary.Name,codeLibrary.Code_Type__c,new Set<Id>{codeLibrary.id},'Code_ID__c','asc');
    cls.selectCodeLibrByTitleCodeTypeCaseType(codeLibrary.Name,codeLibrary.Code_Type__c,codeLibrary.Case_Type__c,new Set<Id>{codeLibrary.id},'Code_ID__c','asc');
    //QACM-51
    cls.selectCodeLibrByCodeTypeAndSubType(codeLibrary.Name,codeLibrary.Code_Type__c,codeLibrary.Case_Type__c,codeLibrary.Case_Sub_Type__c,new Set<Id>{codeLibrary.id},'Code_ID__c','asc');
    cls.selectCodeLibrByHazard(codeLibraryBI1.Name,codeLibraryBI1.Code_Type__c,codeLibraryBI1.Case_Type__c,new Set<Id>{codeLibraryBI1.id},'Code_ID__c','asc');
    cls.selectCodeLibrByLogisticsReviewCode(codeLibraryBI2.Name,codeLibraryBI2.Code_Type__c,codeLibraryBI2.Case_Type__c,new Set<Id>{codeLibraryBI2.id},'Code_ID__c','asc');
    cls.selectCodeLibraryByIds(new Set<Id>{codeLibrary.id});
    cls.selectCodeByCodeId(codeLibrary.id);
    system.assertEquals(true,setOfTypes.contains('Subject'));
    cls.selectDisassocaiatedCodeLibrary();
    }

    /**
     * @description: Test method for getCodeLibraryByCaseType()
     */
    static testmethod void testGetCodeLibraryByCaseType() { 
    
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool');
        insert dcl; 

        test.startTest();  
        List<Code_Library__c> res = new CodeLibrarySelector().getCodeLibraryByCaseType('Inquiry'); 
        System.assertEquals(1, res.size(),'testGetCodeLibraryByCaseType');  
        test.stopTest();
    }

}