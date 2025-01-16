/***************************************************************************************************************************************
* NAME         : CoveredProductsQueueable
* DESCRIPTION  : Queueable class for CoveredProducts class.
*                    
* @AUTHOR : Prashanth Kumar
* @DATE   : 15-02-2021 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Prashanth Kumar         15-02-2021           Initial Version.
  Nitin                   7 june 2022          CMSI-36 try catch in execute method  
****************************************************************************************************************************************/
public with sharing class CoveredProductsQueueable implements Queueable{
    String strMethodtoExecute;
    Set<Id> setInstalledProductIds = new Set<Id>();
    Public static final String UPDATE_CURRENT_ACTIVE_CONTRACT_ON_IP = 'updateCurrentActiveContractOnIP';
    Public static final String UPDATE_LATEST_EXPIRING_CONTRACT_ON_IP = 'updateLatestExpiringContractOnIP';
    public static Boolean catchException = false;

	/*
	 * Constructor
	 */    
    public CoveredProductsQueueable(String strMethodtoExecute, Set<Id> setInstalledProductIds) {
        this.strMethodtoExecute = strMethodtoExecute;
        this.setInstalledProductIds = setInstalledProductIds;
    }
    /*
    * Method Name: execute method
    * Description: Holds methods that need to be Run in Queuable context from CoveredProducts Class
    */
    public void execute(QueueableContext qc){
        try {
                if(strMethodtoExecute == UPDATE_CURRENT_ACTIVE_CONTRACT_ON_IP){
                    ServiceUtilityCollection.updateCurrentActiveContractOnIP(setInstalledProductIds);
                }
                if(strMethodtoExecute == UPDATE_LATEST_EXPIRING_CONTRACT_ON_IP){
                    ServiceUtilityCollection.updateLatestExpiringContractOnIP(setInstalledProductIds);
                }
                if(catchException == true){
                    throw new AuraHandledException('throwing custom exceptions');
                  }
                
        }
        
        catch(Exception e){
            ApexExceptions.emit('CoveredProductsQueueable',e,ilib_logEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }    
    }

}