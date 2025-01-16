/***************************************************************************************************************************************
* NAME         : ProactiveRunMetricsWrapper
* DESCRIPTION  : Wrapper class to hold the response values for Metrics (Second Response from Proactive) for all categories. 
*                    
* @AUTHOR      : Raviteja Vakkalagadda
* @DATE        : 21-Jun-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class ProactiveRunMetricsWrapper {
    
    public String runId {get;set;}
    public Double clusterDensityRead1 {get;set;}
    public Double clusterDensityPFRead1 {get;set;}
    public Double percentPf {get;set;}
    public Double gtq30Percent {get;set;}
    public Double percentGTQ30Read1 {get;set;}
    public Double percentGTQ30Read2 {get;set;}
    public Double yieldTotalG {get;set;}
    public Double alignedPercent {get;set;}
    public Double errorRate {get;set;}
    public Double loadingConcentration {get;set;}
    public String controlSoftwareVersion {get;set;}
    public String rtaVersion {get;set;}
    public String fpgaVersion {get;set;}
    public String proactiveLink {get;set;}
    public Double occupancyPercent {get;set;}
    public String systemSuiteVersion {get;set;}

    public String analysisProtalType {get;set;}
    public String runManagementType {get;set;}
    public String analysisWorkflowType {get;set;}
    public String side {get;set;}
    public String ucsVersion {get;set;}
   
    public String copyServiceVersion {get;set;}
    public String secondaryAnalysisMode {get;set;}
    public String secondaryAnalysisWorkflow {get;set;}
    public String secondaryAnalysisPlatformVersion {get;set;}
    public String beadChipBarcode {get;set;}
    public String applicationName {get;set;}

    //iSeq wapper extra nodes
    public String firmwareVersion {get;set;}
    public String localRunManagerVersion {get;set;}
    public Integer localRunManagerRunId {get;set;}
    
    /*MiSeq & MiniSeq & Next500 Start*/
    public dataWrapp flowcellRfidTagPartNumber {get;set;}
    public dataWrapp reagentKitRfidTagPartNumber {get;set;}
    public dataWrapp pr2BottleRfidTagPartNumber {get;set;}
    public dataWrapp flowcellEepromTagPartNumber {get;set;}
    public dataWrapp flowcellPartNumber {get;set;}
    public dataWrapp sbsPartNumber {get;set;}
    public dataWrapp bufferPartNumber {get;set;}
    public dataWrapp cartridgePartNumber {get;set;}
    public dataWrapp clusterPartNumber {get;set;}

    /*HiSeq Combined*/
    public String fcPosition {get;set;}
    public Boolean firstBaseConfirmation {get;set;}
    public String rapidRunChemistry {get;set;}

    /*HiSeq HD and HiSeq X*/
    public dataWrapp flowcellType {get;set;} //CMCM-6601
	
    /*NovaSeq X */ //CMCM-6601
    public dataWrapp lyoPartNumber {get;set;}
	public dataWrapp sampleTubePartNumber {get;set;}
    public dataWrapp reagentPartNumber {get;set;}
    /*
    * Inner class to hold the value and expired value for each attribute in the response of Datawrapp type
    */
    public class dataWrapp {
        public String value {get;set;}
        public Boolean expired {get;set;}
    } 
    
}