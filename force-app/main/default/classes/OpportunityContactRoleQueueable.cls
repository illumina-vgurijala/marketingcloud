/***************************************************************************************************************************************
* NAME         : OpportunityContactRoleQueueable
* DESCRIPTION  :  OpportunityContactRoleQueueable.
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
****************************************************************************************************************************************/

public class OpportunityContactRoleQueueable implements Queueable {
    
	public static final String STRING_UPDATEPRIMARYCONTACTONOPPORTUNITYCONTACTROLE = 'updatePrimaryContactOnOpportunityContactRole';

    String strMethodtoExecute;
    Boolean isUpdateFromQuote;
    List<OpportunityContactRole> lstOCR=new List<OpportunityContactRole>();   
    public static Boolean catchException = false;
    /*
    * @Author: Tapas Chakraborty 
    * @Description : parameterized constructor of class OpportunityContactRoleQueueable to Initialize Class parameters  
    * @param : String strMethodtoExecute , List<OpportunityContactRole> lstOCR, Boolean isUpdateFromQuote
    */
    public OpportunityContactRoleQueueable(String strMethodtoExecute , List<OpportunityContactRole> lstOCR, Boolean isUpdateFromQuote){
        this.strMethodtoExecute = strMethodtoExecute;
        this.lstOCR = lstOCR;
        this.isUpdateFromQuote = isUpdateFromQuote;
    }
    
    /**  
*  @author Tapas Chakraborty
*  @description -Holds methods that need to be Run in Queuable context from OpportunityContactRoles Class
*                 
**/
    public void execute(QueueableContext qc) { 
        
       try{
        if(strMethodtoExecute == 'updateopportunityPrimaryContact' && !lstOCR.IsEmpty()){
            OpportunityContactRoles.updateopportunityPrimaryContact(lstOCR, isUpdateFromQuote);
        }
         //code coverage for catch block
         if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }
       }catch(Exception e){
        //catch the exception 
        ApexExceptions.emit('OpportunityContactRoleQueueable', e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
       }
    }
    
}