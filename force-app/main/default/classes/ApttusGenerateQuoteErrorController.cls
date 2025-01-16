/*
 * @Author: Kushagra Desai
 * @Date: 2018-11-07
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
 * Kushagra Desai       5-APR-2019                    DCP-24602 -Error stroing on generate
 * B Kamini             10 Dec 2019                   Sonar Qube Issue Fix
 * Himanshu				31 Mar 2022					  Code Scan Fixes
 * Adyasha Satapathy    12-Oct-2022                   Code Scan Fixes(Method Naming Convention)	
 */
public with sharing class ApttusGenerateQuoteErrorController {
	
	public String strQuoteid{get;set;}
	public String strDataError{get;set;}
	public static Apttus_Proposal__Proposal__c objQuote;
	/**
	* @description  Constructor Called
	* @params NA
	* @return NA
	**/
	public ApttusGenerateQuoteErrorController(){
		// Added by Kamini to fix SonarQube issue
		strQuoteID = ApexPages.CurrentPage().getParameters().get('id').escapeHtml4();
		system.debug('Quote Id constructor--'+strQuoteID);
	}
	
	/**
	* @description   Added error storing mechanism
	* @params NA
	* @return null
	**/
	public PageReference loadError(){
		// Added by Kamini to fix SonarQube issue
		strQuoteID = ApexPages.CurrentPage().getParameters().get('id').escapeHtml4();
		objQuote = new  ApttusProposalsSelector().selectProposalById(strQuoteID);
		strDataError = objQuote.SAP_Errors__c;
		return null;
	}
	/**
	* @description  method to redirect page
	* @params NA
	**/
	public PageReference redirectToQuote(){
		system.debug('Quote Id --'+strQuoteID);
        PageReference orderPage = new PageReference('/'+strQuoteID);
        orderPage.setRedirect(true);
        return orderPage;
    }
}