/***************************************************************************************************************************************
* NAME         : LocationQueueable
* DESCRIPTION  :  LocationQueueable.
*                    
* @AUTHOR : Prakhar Kumar
* @DATE   : 08-07-2020 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Prakhar               08-07-2020           Initial Version. 
* Pooja			20-6-2022		DCP-53976:Added try catch in the execute method
****************************************************************************************************************************************/

public class LocationQueueable implements Queueable {

    String strMethodtoExecute;   
    List<Id> listLocationIds = new List <Id>();
    public static Boolean catchException = false;
    
		/*
         * Constructor
         */	
    public LocationQueueable (String strMethodtoExecute ,List<Id> listLocationIds){
    system.debug('in constructor');
    this.strMethodtoExecute = strMethodtoExecute;
    this.listLocationIds = listLocationIds;
    }
    
    /**
*  @author Prakhar
*  @description -Holds methods that need to be Run in Queuable context from Location Class 
*                 
**/
   public void execute(QueueableContext qc) { 
    try  {
        //Call to populateAccountOnLocation method on Locations class to make update on Location
        if(strMethodtoExecute=='populateAccountOnLocation' 
            && !listLocationIds.IsEmpty() )
        {
            Locations.populateAccountOnLocation(listLocationIds);
        }

        //code coverage for catch block
        if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }
    }
    catch(Exception e){
        //catch the exception 
        ApexExceptions.emit('LocationQueueable', e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
    }  
  } 
}
