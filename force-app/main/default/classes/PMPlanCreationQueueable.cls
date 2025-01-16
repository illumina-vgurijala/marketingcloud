/***************************************************************************************************************************************
* NAME         : PMPlanCreationQueueable
* DESCRIPTION  :  PMPlanCreationQueueable.
*                    
* @AUTHOR : Prashanth Kumar
* @DATE   : 04-12-2020 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Prashanth              04-12-2020           Initial Version. 
****************************************************************************************************************************************/

public with sharing class PMPlanCreationQueueable implements Queueable {

    Set<Id> setSCwithCoveredProduct = new Set <Id>();
    List<SVMXC__Service_Contract__c> lstContracts = new List<SVMXC__Service_Contract__c>();
    public static Boolean catchException = false;
	
	    /*
         * Constructor
         */
    public PMPlanCreationQueueable (List<SVMXC__Service_Contract__c> lstContracts, Set<Id> setSCwithCoveredProduct){
		system.debug('in constructor--:');
		this.lstContracts = lstContracts;
        this.setSCwithCoveredProduct = setSCwithCoveredProduct;
    }
    
    /**
    *  @author Prashanth
    *  @description -Holds methods that need to be Run in Queuable context for PM plan creation
    *                 
    **/
	public void execute(QueueableContext qc) { 
      try{
        system.debug('in Execute==>');
        if(!lstContracts.isEmpty() && !setSCwithCoveredProduct.isEmpty()){
          ServiceUtilityCollection.PMPlanCreation(lstContracts,setSCwithCoveredProduct);
        }
         //code coverage for catch block
         if(catchException == true){
          throw new AuraHandledException('throwing custom exceptions');
      }
      }catch(Exception e){
        //catch the exception 
        ApexExceptions.emit('PMPlanCreationQueueable', e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
      }
              
    } 
}
