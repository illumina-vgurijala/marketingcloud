/***************************************************************************************************************************************
* NAME   : CaseUnreadEmailsToggleController 
* DESCRIPTION  : Controller class
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class CaseUnreadEmailsToggleController {
       
   /*
    * Constructor
    */
    public CaseUnreadEmailsToggleController(ApexPages.StandardController stdController) {
        
    }
	
	
   /*
    * DESCRIPTION - toggleUnreadEmail method 
	* Return - PageReference
    */
    Public PageReference  toggleUnreadEmail(){
        set<id> setCaseId = new set<id>();
        Id idCase = ApexPages.currentPage().getParameters().get('id').escapeHtml4();
        setCaseId.add(idCase);
        List<Case> lstCase = new CasesSelector().selectCasesFromSetIds(setCaseId);
        lstCase[0].Unread_Emails__c= lstCase[0].Unread_Emails__c?false:true;
        update lstCase;
        PageReference pg = new PageReference('/'+idCase);
        pg.setRedirect(true);
        return pg;
    }

}