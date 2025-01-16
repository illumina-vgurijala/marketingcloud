/***************************************************************************************************************************************
 * NAME   : TestSMAttributesTemplateSelector 
 * DESCRIPTION  : TestClass for SMAttributesTemplateSelector 
 *           
 * @AUTHOR : Vignesh
 * @DATE   : 10-12-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vignesh                12-Oct-2021            Initial Version
****************************************************************************************************************************************/ 
  
@isTest(SeeAllData = false)
public class TestSMAttributesTemplateSelector {
    /**
     * method: TestSMAttributesTemplateSelector
     * Description: test method for SMAttributesTemplateSelector
     * params: void
     */
    public static testmethod void testAttributesTemplateSelector() {
        SVMXC__SM_Attributes_Template__c objTemplate = new SVMXC__SM_Attributes_Template__c();
        objTemplate.SVMXC__SM_Attr_Type_Template__c = 'TECHNICAL';
        objTemplate.SVMXC__SM_Active__c = TRUE;
        objTemplate.SVMXC__SM_Template_Json__c = '{"Attribute":"test"}';
        objTemplate.SVMXC__SM_Template_Json__c = 'Dummy template';
        insert objTemplate;
        Set<String> setTemplateTitleName = new Set<String>();
        setTemplateTitleName.add('NextSeq - NSQ - Dx Template');
        new SMAttributesTemplateSelector().getTemplates(setTemplateTitleName);
        List<SVMXC__SM_Attributes_Template__c> lstTempalte = new SMAttributesTemplateSelector().getActiveRecords();
        system.assert(lstTempalte.size() > 0 );
    }
}