/* @ author      : Dushyant Srivastava
* @ date         : 12 November 2021
* @ Description  : TestApttusEmailCartController for ApttusEmailCartController
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Dushyant Srivastava          2021-11-02          Initial Version
*    ----------------------------------------------------------------------------------------------------------------------------------
*/
global with sharing class ApttusEmailCartController {
    public static final String CONFIGID = 'Id';
    public static final String CONFIGREQUESTID = 'configRequestId';
    public static final String FLOW = 'flow';
    public static final String BUSINESSOBJECTID = 'businessObjectId';
    global String strConfigId;
    global string strConfigRequestId;
    global string strFlow;
    global String strBusinessObjectId;
    public String strHref{set;get;}
    public String strBody{set;get;}
    private static final String EMAIL_TEMPLATE_NAME = 'ApttusEmailCart';
    public static final String EMAIL_SUBJECT = 'Email From Cart of Quote #';
	
	/* @ author      : Dushyant Srivastava
	* @ date         : 12 November 2021
	* @ Description  : Constructor
	*/
    public ApttusEmailCartController() {
        strConfigId = ApexPages.CurrentPage().getParameters().get(CONFIGID) == null ? null : ApexPages.CurrentPage().getParameters().get(CONFIGID).escapeHtml4();
        strConfigRequestId = ApexPages.currentpage().getparameters().get(CONFIGREQUESTID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGREQUESTID).escapeHtml4();
        strFlow = ApexPages.currentpage().getparameters().get(FLOW) == null ? null : ApexPages.currentpage().getparameters().get(FLOW).escapeHtml4();
        strBusinessObjectId = ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID) == null ? null : ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID).escapeHtml4();
    }
	
	/* @ author      : Dushyant Srivastava
	* @ date         : 12 November 2021
	* @ Description  : method to create link to open Outlook
	*/
    public void emailCart() {
        strHref = 'mailto:';
        ApttusProposalsSelector objApttusProposalsSelector = new ApttusProposalsSelector();
        Apttus_Proposal__Proposal__c objProposal = objApttusProposalsSelector.selectByQuoteId(new set<Id>{strBusinessObjectId})[0];
        strHref +=  '?subject=' + setEmailSubject(objProposal);
        strBody = getEmailBody(objProposal);
    }
	/* @ author      : Dushyant Srivastava
	* @ date         : 12 November 2021
	* @ Description  : method to redirect to cart
	*/
    global PageReference redirectToCart()
    {
        return ApttusCheckPriceBaseClass.redirectToCart(strConfigId, strConfigRequestId, strFlow, strBusinessObjectId);
    }
	/* @ author      : Dushyant Srivastava
	* @ date         : 12 November 2021
	* @ Description  : Created Email Body
	*/
    public static String getEmailBody(Apttus_Proposal__Proposal__c objProposal) {
        EmailTemplate objEmailTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{EMAIL_TEMPLATE_NAME}).get(0);
        String emailBody = objEmailTemplate.body;
        emailBody = objProposal.Apttus_Proposal__Primary_Contact__r.Name!= Null ? emailBody.replace('(#Primary_Contact)',objProposal.Apttus_Proposal__Primary_Contact__r.Name) : emailBody.replace('(#Primary_Contact)','');
        emailBody = objProposal.SAP_Quote__c!= Null ? emailBody.replace('(#SAP_Quote)',objProposal.SAP_Quote__c) : emailBody.replace('(#SAP_Quote)','');
        emailBody = objProposal.Name!= Null ? emailBody.replace('(#ProposalName)',objProposal.Name) :  emailBody.replace('(#ProposalName)','');
        emailBody = objProposal.Apttus_Proposal__Opportunity__r.Name != Null ? emailBody.replace('(#OpportunityName)',objProposal.Apttus_Proposal__Opportunity__r.Name) : emailBody.replace('(#OpportunityName)','');
        emailBody = objProposal.Apttus_Proposal__Opportunity__r.Account.Name!= Null ? emailBody.replace('(#Sold_To)',objProposal.Apttus_Proposal__Opportunity__r.Account.Name) : emailBody.replace('(#Sold_To)','');
        return emailBody;
    }
	/* @ author      : Dushyant Srivastava
	* @ date         : 12 November 2021
	* @ Description  : method to Email Subject
	*/
    public static string setEmailSubject(Apttus_Proposal__Proposal__c objProposal) {
        String emailSubject = objProposal.SAP_Quote__c!= Null ? objProposal.SAP_Quote__c :'';
        return EMAIL_SUBJECT + emailSubject;
   }
}