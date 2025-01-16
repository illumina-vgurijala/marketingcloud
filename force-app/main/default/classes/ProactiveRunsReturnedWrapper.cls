/***************************************************************************************************************************************
* NAME         : ProactiveRunsReturnedWrapper
* DESCRIPTION  : Wrapper class to hold the response values for MiSeq,MiniSeq,iSeq,Nextseq 500/550,Nextseq 1000,Genotyping,NovaSeq 
				categories 
*                    
* @AUTHOR      : Raviteja Vakkalagadda
* @DATE        : 21-Jun-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class ProactiveRunsReturnedWrapper {

    
	@AuraEnabled public String id {get;set;} 
	@AuraEnabled public String name {get;set;} 
	@AuraEnabled public double proNumber {get;set;} // In response it is coming as 'NUMBER'(Which is a datatype in salesforce)
	@AuraEnabled public String status {get;set;} 
	@AuraEnabled public String side {get;set;} 
	@AuraEnabled public String instrumentStartedDate {get;set;} 
	@AuraEnabled public String instrumentCompletedDate {get;set;} 
	@AuraEnabled public double totalSize {get;set;} 
	@AuraEnabled public String workflow {get;set;} 
	@AuraEnabled public String instrumentSerialNumber {get;set;} 
	@AuraEnabled public String apiUrl {get;set;} 
	@AuraEnabled public String environment {get;set;} 
	@AuraEnabled public String runId {get;set;} 
	@AuraEnabled public String readLength {get;set;} 
	
    
    // Formating the Date values so that only Date value is displayed in the lightning data table for Start Date and End Date
	@AuraEnabled public String instrumentStartDtFormated {get{
        
		if(STRING.isnotBlank(instrumentStartedDate)){
            system.debug('Entered startdate format'+instrumentStartedDate.split('T')[0]);
			instrumentStartDtFormated = instrumentStartedDate.split('T')[0];
		}
		return instrumentStartDtFormated;
	}set;} 
	@AuraEnabled public String instrumentEndDtFormated {
		get{
			if(STRING.isnotBlank(instrumentCompletedDate)){
                system.debug('Entered startdate format'+instrumentCompletedDate.split('T')[0]);
				instrumentEndDtFormated = instrumentCompletedDate.split('T')[0];
			}
			return instrumentEndDtFormated;
		}set;} 

	 /*
	 *  Constructor 
	 */
    public ProactiveRunsReturnedWrapper(String id,String name,double proNumber,String status,String side,
                                        double totalSize,String workflow,String instrumentSerialNumber,String apiUrl,String environment,String runId,String readLength){
                                            this.id = id;
                                            this.name = name;
                                            this.proNumber =  proNumber;  
                                            this.status =  status;
                                            this.side =  side;
                                            this.totalSize =  totalSize;
                                            this.workflow =  workflow;
                                            this.instrumentSerialNumber =  instrumentSerialNumber;
                                            this.apiUrl =  apiUrl;
                                            this.environment =  environment;
                                            this.runId =  runId;
                                            this.readLength = readLength;
                                            system.debug('Inside constructor');
                                        }

     /*
	 *  Method used to parse the response and show on UI
	 */

    public static List<ProactiveRunsReturnedWrapper> parseRunsResponse(String json) {
        system.debug('json'+json);
    return (List<ProactiveRunsReturnedWrapper>) System.JSON.deserialize(json, List<ProactiveRunsReturnedWrapper>.class);
    }
       
  }