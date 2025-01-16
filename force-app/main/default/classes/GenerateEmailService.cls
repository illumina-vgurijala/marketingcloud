/**
*   @author Rishab Wali
*   @date 2021-06-15
*   @description   Test Class - TestApttusProposals
*   Modification Log:
*   ------------------------------------------------------------------------------------
*           Developer                   Date                Description
*           Rishab Wali                 2021-06-15          [DCP-46920] : Sending email to quote owner when document generated 
*   ------------------------------------------------------------------------------------
**/
public with sharing class GenerateEmailService {

    /*Description - [DCP-46920] Method to create Email Body */
    public static String getEmailBody(Boolean isSuccess , Apttus_Proposal__Proposal__c objProposal)
    {
        String anchorBreakLine = '</a> <br>';
        String href = '<a href=" ';
        String emailBody = '<body> ';
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        if(isSuccess)
        { 
            emailBody += 'Your Quotation has been approved and is attached.<br><br>';
        }
        else 
        {
            emailBody += 'Your Quotation has been approved <strong> but could not be generated. </strong>';
            emailBody += 'Please generate the quotation from within the Salesforce Quote ' + href + baseUrl + '/' + objProposal.Id + '">';
            emailBody += objProposal.SAP_Quote__c + ' / ' + objProposal.Name + '</a> <br><br>';
        }

        emailBody += 'Quote Details: <br>';
        emailBody += 'Primary Contact - ' + href+ baseUrl + '/' + objProposal.Apttus_Proposal__Primary_Contact__c + '">';
        emailBody +=  objProposal.Apttus_Proposal__Primary_Contact__r.Name + '</a> / ';
        emailBody +=  href + 'mailto:' + objProposal.Apttus_Proposal__Primary_Contact__r.Email + '">' + objProposal.Apttus_Proposal__Primary_Contact__r.Email + anchorBreakLine;
        emailBody += 'Quotation - ' + href + baseUrl + '/' + objProposal.Id + '">';
        emailBody += objProposal.SAP_Quote__c + ' / ' + objProposal.Name + anchorBreakLine;
        emailBody += 'Opportunity - ' + href + baseUrl + '/' + objProposal.Apttus_Proposal__Opportunity__c + '">';
        emailBody += objProposal.Apttus_Proposal__Opportunity__r.Name + anchorBreakLine;
        emailBody += 'Sold To - ' + href + baseUrl + '/' + objProposal.Apttus_Proposal__Opportunity__r.AccountId + '">';
        emailBody += objProposal.Apttus_Proposal__Opportunity__r.Account.Name + anchorBreakLine;
        if(objProposal.Work_Order__c != Null){
            emailBody += 'Work Order - ' + href + baseUrl + '/' + objProposal.Work_Order__c + '">';
            emailBody += objProposal.Work_Order__r.Name + anchorBreakLine;
            emailBody += 'Work Order Owner - ' + objProposal.Work_Order__r.Owner.Name + anchorBreakLine;
        }
        emailBody += '</body>';
        return emailBody;
    }

    /*Description - [DCP-46920] Method to set subject */
    public static string setEmailSubject(Apttus_Proposal__Proposal__c objProposal)
    {
        return 'Quotation ' + objProposal.SAP_Quote__c + ' Approved for Opportunity ' + objProposal.Apttus_Proposal__Opportunity__r.Name;
    }

}