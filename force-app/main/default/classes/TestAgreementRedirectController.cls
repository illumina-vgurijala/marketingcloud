/*@ author       : 
* @ date         : 
* @ Description  : TestAgreementRedirectController Test class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Parthasarathy D      10-Oct-2022                                 Codescan Fix- Added header comments.
* 
*/
@isTest(seeAllData = false)
public with sharing class TestAgreementRedirectController {

    static testMethod void testRedirect() {
        Test.startTest();

        Test.setCurrentPageReference(new PageReference('Page.AgreementTemplateProcessRedirect'));
        System.currentPageReference().getParameters().put('masterId', 'param1');
        System.currentPageReference().getParameters().put('templateID', 'param2');

        AgreementRedirectController ctrlr = new AgreementRedirectController();
        PageReference redir = ctrlr.redirectToAdobeVF();
        System.assertEquals(2, redir.getParameters().size());

        Test.stopTest();
    }
}