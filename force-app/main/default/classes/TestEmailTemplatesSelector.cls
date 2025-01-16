/***************************************************************************************************************************************
 * NAME   : TestEmailTemplatesSelector
 * DESCRIPTION  : TestClass for EmailTemplatesSelector
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 24-June-2019 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             24-June-2019             Initial Version
  ****************************************************************************************************************************************/ 

@isTest
public class TestEmailTemplatesSelector {
    /**
    * method Name:emailTemplatesSelectorTest
    * Description: This method is to test selectById,selectByNameOrDeveloperName methods in emailTemplatesSelector class.
    * params: NA
    * return: void
    * author: prashanth
    **/
	static testMethod void emailTemplatesSelectorTest() {
	    //insert email templats from TestDataEmailTemplate
	    List<Id> lstEmailTemplateIds = TestDataEmailTemplate.getEmailTemplates();
	    System.assertEquals(5,lstEmailTemplateIds.size(),'Incorrect Templates initialized');

        Test.startTest();
        EmailTemplatesSelector selectorClass = new EmailTemplatesSelector();
        //test selectById method
        List<EmailTemplate> lstEmailTemplates = selectorClass.selectById(new Set<Id>(lstEmailTemplateIds));
        System.assertEquals(5,lstEmailTemplates.size(),'Select by ID returning incorrect count');
        //test selectByNameOrDeveloperName method
        List<EmailTemplate> emailTemplates = selectorClass.selectByNameOrDeveloperName(new List<String> {lstEmailTemplates[0].DeveloperName});
        System.assertEquals(lstEmailTemplates[0].DeveloperName,emailTemplates[0].DeveloperName,'Select by name returning incorrect template');
        
        Test.stopTest();
	}
	

}