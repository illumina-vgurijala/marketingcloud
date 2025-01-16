/***************************************************************************************************************************************
* NAME   : SVMX_PS_PM_InvokePMProcess 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public class SVMX_PS_PM_InvokePMProcess {

   public List<String> listPMProcessName {get; set;}
   public List<SelectOption> options = new List<SelectOption>();
   private Map<String,String> mapPMProcess = new Map<String,String>();
   public boolean isTestFlag = false;
   

		/*
         * Constructor
         */   
   public SVMX_PS_PM_InvokePMProcess() {
       List<SVMXC__ServiceMax_Processes__c> listPMProcesses = [Select SVMXC__Name__c,Id From SVMXC__ServiceMax_Processes__c 
                                  WHERE RecordType.Name='PM Process' AND SVMXC__Active__c = true];
     
       if(listPMProcesses != null && listPMProcesses.size() > 0){ 
          listPMProcessName = new List<String>();              
         for(SVMXC__ServiceMax_Processes__c pmProcess : listPMProcesses){
             options.add(new SelectOption(pmProcess.SVMXC__Name__c,pmProcess.SVMXC__Name__c));
             mapPMProcess.put(pmProcess.SVMXC__Name__c, pmProcess.id);
         } 
       }   
   }
   
		
		/* 
        * @description: To return list of Options 
        * @return: List of Select Option
        */
				
   
   public List<SelectOption> getOptions() {
            return options;
   }
 
			
   /* 
   * @description: To invoke PM Process
   * @return: void
   */
   public void invokePMProcess(){  
      SVMXC.PREV_Engine_Batch engObj = new SVMXC.PREV_Engine_Batch();
      
      for(String selectedPMProcess : listPMProcessName){
              System.debug(selectedPMProcess);
              engObj.setProcessIds.add(mapPMProcess.get(selectedPMProcess));
      }                               
      
      if(!isTestFlag){      
        database.executebatch(engObj, 1); 
      } 
   }  
}