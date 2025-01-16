/**
 * @author          Sarath Pullanikkatt
 * @date            2020-09-08
 * @description     This class is the controller for AgreementTemplateProcessRedirect Visualforce page.
 *                  It redirects the ServiceMax SFM Custom Action to echosign_dev1__AgreementTemplateProcess.
 *                  Helps to avoid CSRF error which gets thrown while directly calling the EchoSign VF page.
**/
public without sharing class AgreementRedirectController {

    private static final String MASTER_ID = 'masterId';
    private static final String TEMPLATE_ID = 'templateID';

    private String strMasterId;
    private String strTemplateId;

    /**
     * @author      Sarath Pullanikkatt
     * @description Constructor - Captures the parameters passed from SFM Custom Action
    **/
    public AgreementRedirectController() {
        strMasterId = ApexPages.currentPage().getParameters().get(MASTER_ID);
        strTemplateId = ApexPages.currentPage().getParameters().get(TEMPLATE_ID);
    }

    /**
     * @author      Sarath Pullanikkatt
     * @description Visualforce action to redirect to echosign_dev1__AgreementTemplateProcess VF page.
     * @param       None
     * @return      PageReference
    **/
    public PageReference redirectToAdobeVF() {
        PageReference retURL = new PageReference('/apex/echosign_dev1__AgreementTemplateProcess');
        retURL.getParameters().put(MASTER_ID, strMasterId);
        retURL.getParameters().put(TEMPLATE_ID, strTemplateId);
        retURL.setRedirect(true);
        return retURL;
    }
}