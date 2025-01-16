/***************************************************************************************************************************************
* NAME         : ProductQueueable
* DESCRIPTION  :  ProductQueueable.
*                    
* @AUTHOR : Vaibhav
* @DATE   : 11 Apr 2021 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Vaibhav               11-Apr-2021        Initial Version. 
****************************************************************************************************************************************/

public class ProductQueueable implements Queueable {

    String strMethodtoExecute;   
    set<Id> setProductIds = new set <Id>();
    public static Boolean catchException = false;
    /*
	* Constructor method for Queuable
	*/
    public ProductQueueable (String strMethodtoExecute ,set<Id> setProductIds){
    this.strMethodtoExecute = strMethodtoExecute;
    this.setProductIds = setProductIds;
    }
    
    /**
*  @description -Holds methods that need to be Run in Queuable context from Product Class
*                 
**/
   public void execute(QueueableContext qc) { 
      try{
          //Call to createProductServicedForDCPProducts method on Product class
      if(strMethodtoExecute=='createProductServicedForDCPProducts' && !setProductIds.IsEmpty() ){
        Products.createProductServicedForDCPProducts(setProductIds);
      }
       //code coverage for catch block
       if(catchException == true){
        throw new AuraHandledException('throwing custom exceptions');
      }
      }catch(Exception e){
           //catch the exception 
        ApexExceptions.emit('ProductQueueable', e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
      }
  } 
}
