/**
*    @author Satya Swain
*    @date   16 Nov 2018  
*    @description Allow user to Revert to Draft on a Quote if user has the specific Permission Set
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Satya Swain                  16 Nov 2018          Initial Version
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
**/
public class QuotationPreventRevertToDraft {
    public static Boolean boolPermissionFound;
    /*
    * @author Satya Swain
    * @date   16-Nov-2018
    * @description  Check if  user has Revert to Draft permission set
    * @return String 
    */
    @AuraEnabled
	public static String checkRevertToDraftPermissionForUser(String strProposalId){
        System.debug('@@@@ Proposal Id: '+ strProposalId);
        Boolean hasRevertToDraftPermission = false;
        Boolean boolIsOpportunityClosed = false;
        boolPermissionFound = false;

        List<Apttus_Proposal__Proposal__c> lstProposal = new ApttusProposalsSelector().selectByQuoteId(new Set<Id>{strProposalId});
       String strStageName = lstProposal.get(0).Apttus_Proposal__Opportunity__r.StageName;
        System.debug('@@@ opportunity stage: '+strStageName);
       
        if(strStageName.contains('Closed')){
            boolIsOpportunityClosed = true;
            hasRevertToDraftPermission=FeatureManagement.checkPermission('SL_Revert_To_Draft');
            boolPermissionFound=hasRevertToDraftPermission;
        }
        System.debug('@@@@ hasRevertToDraftPermission' + hasRevertToDraftPermission);
        System.debug('@@@@ boolIsOpportunityClosed' + boolIsOpportunityClosed);
        return '{"hasRevertToDraftPermission":'+JSON.serialize(hasRevertToDraftPermission)
                + ',"boolIsOpportunityClosed":'+JSON.serialize(boolIsOpportunityClosed)+'}';
    }
}