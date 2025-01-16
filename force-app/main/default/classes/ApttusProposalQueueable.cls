/***************************************************************************************************************************************
* NAME         : ApttusProposalQueueable
* DESCRIPTION  :  ApttusProposalQueueable.
*                    
* @AUTHOR : Tapas Chakraborty
* @DATE   : 18-Aug-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Tapas Chakraborty           18-Aug-2020           Initial Version. 
* Aman Tyagi                  31-Mar-2022           CodeScan Fixes
* Nitin                       7 june 2022           CMSI-36 try catch in execute method 
****************************************************************************************************************************************/

public class ApttusProposalQueueable implements Queueable {
    
	public static final String STRING_UPDATEPRIMARYCONTACTONOPPORTUNITYCONTACTROLE = 'updatePrimaryContactOnOpportunityContactRole';
    public static Boolean catchException = false;

    String strMethodtoExecute;
    List<Apttus_Proposal__Proposal__c> lstProposal=new List<Apttus_Proposal__Proposal__c>();
    Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal = new Map<Id, Apttus_Proposal__Proposal__c>(); 
    /*
    * @Author: Tapas Chakraborty 
    * @Description : parameterized constructor of class ApttusProposalQueueable to Initialize Class parameters  
    * @param : Objective__c obj,Account_Plan__c accPlan
    */
    public ApttusProposalQueueable(String strMethodtoExecute , List<Apttus_Proposal__Proposal__c> lstProposal, Map<Id, Apttus_Proposal__Proposal__c> idToOldProposal){
        this.strMethodtoExecute=strMethodtoExecute;
        this.lstProposal=lstProposal;
        this.idToOldProposal =idToOldProposal ;
        
        
    }
    
    /**
*  @author Tapas Chakraborty
*  @description -Holds methods that need to be Run in Queuable context from ApttusProposals Class
*                 
**/
    public void execute(QueueableContext qc) { 
        try{
            if(strMethodtoExecute == STRING_UPDATEPRIMARYCONTACTONOPPORTUNITYCONTACTROLE && !lstProposal.IsEmpty() && !idToOldProposal.IsEmpty()){
                ApttusProposals.updatePrimaryContactOnOpportunityContactRole(lstProposal, idToOldProposal);
            }
            if(catchException == true){
                throw new AuraHandledException('throwing custom exceptions');
            }
        
        //add other methods here
        }
        catch(Exception e){
            ApexExceptions.emit('ApttusProposalQueueable',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
}
    
}