/***************************************************************************************************************************************
* NAME         : ProactiveMetricHandlingController
* DESCRIPTION  : This is a utility class which helps in Run Metrics SAVE for each category of installed product
*                    
* @AUTHOR      : Raviteja Vakkalagadda
* @DATE        : 21-Jun-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
*Abhishek Yadav           27 Oct            Added handleProactiveAssociatedProductDML, addToPartNumSetIfNotNull,associatedProductUtility Method
                                            Modified productUtility,proactiveRecUtility,handleGenotyping method (CMCM-303) 
*Dhairya Shah             17 April 2024     CMCM-6760 - Removed the method 'additionalProductUtility()'
****************************************************************************************************************************************/
public with sharing class ProactiveMetricHandlingController {
    
    public final static String SUCCESS_STRING = 'Success';
    public final static String CASE_STRING = 'Case';
    public final static String WORK_ORDER_STRING = 'SVMXC__Service_Order__c';
    //public static List<SVMXC__Case_Line__c> clList = new List<SVMXC__Case_Line__c>(); // CMCM-6760 - Removed method reference 'additionalProductUtility'
    public static SVMXC__Case_Line__c cs = new SVMXC__Case_Line__c();
    public static proactive_run_detail__c proactiveRec = new proactive_run_detail__c();
    public static string runId{get;set;}
    public static Map<String,Product2> prodMap = new Map<String,Product2>();
    public static List<ProactiveComponentController.additionalProdWrapper> apSelectedWrap = new List<ProactiveComponentController.additionalProdWrapper>();
    public static Associated_Product__c associatedProdObj = new Associated_Product__c();
    public static List<Associated_Product__c> apList = new List<Associated_Product__c>();
    public static Set<string> partNumSet = new Set<string>();
/***************************************************************************************
* Author: Raviteja
* Description: Method to handle the SAVE funtionality for Proactive
* Params : 
*****************************************************************************************/

public static string handleProactiveCaseLineDML(ProactiveRunMetricsWrapper sWrap,
                ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper) {
        string prCategory = '';
        system.debug(saveRunWrapper.category);
        prCategory = handleCategory(saveRunWrapper.category);            
        if(!saveRunWrapper.isProactiveUpdate) { 
            apSelectedWrap = (List<ProactiveComponentController.additionalProdWrapper>) System.JSON.deserialize(saveRunWrapper.selectedRecords,List<ProactiveComponentController.additionalProdWrapper>.class);
        }
        //INC0379506 [commented try catch]
        //try{
            proactiveRecUtility(sWrap,saveRunWrapper);
            relatedFieldsOnProactiveRecord(prCategory,sWrap);
            UPSERT proactiveRec Id; // Checks if the Proactive record exists and upserts

            system.debug(proactiveRec);
            productUtility(sWrap);
            // CMCM-6760 - Removed method reference 'additionalProductUtility' commented both if condition
            /*if(!saveRunWrapper.isProactiveUpdate) {
                clList = additionalProductUtility(apSelectedWrap,proactiveRec);
                system.debug(clList.size());
            }
            
            if(!clList.isEmpty()) {
                INSERT clList;
            }*/
            return SUCCESS_STRING;

}

/***************************************************************************************
* Author: Abhishek Yadav
* Description: Method to handle the SAVE funtionality for Proactive
* Params : ProactiveRunMetricsWrapper sWrap, ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper
*****************************************************************************************/
public static string handleProactiveAssociatedProductDML(ProactiveRunMetricsWrapper sWrap, ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper) {
    string prCategory = '';
    system.debug(saveRunWrapper.category);
    prCategory = handleCategory(saveRunWrapper.category);            
    if(!saveRunWrapper.isProactiveUpdate) { 
        apSelectedWrap = (List<ProactiveComponentController.additionalProdWrapper>) System.JSON.deserialize(saveRunWrapper.selectedRecords,List<ProactiveComponentController.additionalProdWrapper>.class);
    }
    proactiveRecUtility(sWrap,saveRunWrapper);
    relatedFieldsOnProactiveRecord(prCategory,sWrap);
    UPSERT proactiveRec Id; // Checks if the Proactive record exists and upserts
    
    system.debug(proactiveRec);
    productUtility(sWrap);
    if(!saveRunWrapper.isProactiveUpdate) {
        apList = associatedProductUtility(apSelectedWrap,proactiveRec);
        system.debug(apList.size());
    }
    
    if(!apList.isEmpty()) {
        INSERT apList;
    }
    return SUCCESS_STRING;
}

/***************************************************************************************
* Author: Raviteja
* Description: Method to map the releavant fields for the respective categories
* Params : Category , ProactiveRunMetricsWrapper
*****************************************************************************************/

public static string relatedFieldsOnProactiveRecord(String category,ProactiveRunMetricsWrapper sWrap) {
    
    switch on category{
        when 'iSeq'{
            proactiveRec.Occupancy_Percent__c = (sWrap.occupancyPercent==NULL)?0:sWrap.occupancyPercent;  
            proactiveRec.Percent_Passing_Filter__c = (sWrap.percentPf==NULL)?0:sWrap.percentPf;
            proactiveRec.LRM_Run_ID__c = (sWrap.localRunManagerRunId==NULL)?0:sWrap.localRunManagerRunId;
            proactiveRec.RTA_Version__c = stringEmptyCheck(sWrap.rtaVersion);
            proactiveRec.System_Suite_Version__c = stringEmptyCheck(sWrap.systemSuiteVersion);
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.Firmware_Version__c = stringEmptyCheck(sWrap.firmwareVersion);
            proactiveRec.LRM_Version__c =  stringEmptyCheck(sWrap.localRunManagerVersion);
            
        }
        when 'MiSeq'{
            proactiveRec.Cluster_Density__c = (sWrap.clusterDensityRead1==NULL)?0:sWrap.clusterDensityRead1;
            proactiveRec.Cluster_Density_Passing_Filter__c = (sWrap.clusterDensityPFRead1==NULL)?0:sWrap.clusterDensityPFRead1;
            proactiveRec.Percent_Passing_Filter__c = (sWrap.percentPf==NULL)?0:sWrap.percentPf;
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.RTA_Version__c = stringEmptyCheck(sWrap.rtaVersion);
            proactiveRec.FPGA_Version__c = stringEmptyCheck(sWrap.fpgaVersion);
        }
        when 'HiSeq'{
            proactiveRec.Side__c = stringEmptyCheck(sWrap.fcPosition);
            proactiveRec.First_Base_Confirmation__c = (sWrap.firstBaseConfirmation==NULL)?FALSE:sWrap.firstBaseConfirmation;
            proactiveRec.Rapid_Run__c = stringEmptyCheck(sWrap.rapidRunChemistry);
            proactiveRec.Cluster_Density__c = (sWrap.clusterDensityRead1==NULL)?0:sWrap.clusterDensityRead1;
            proactiveRec.Cluster_Density_Passing_Filter__c = (sWrap.clusterDensityPFRead1==NULL)?0:sWrap.clusterDensityPFRead1;
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.RTA_Version__c = stringEmptyCheck(sWrap.rtaVersion);
            proactiveRec.FPGA_Version__c = stringEmptyCheck(sWrap.fpgaVersion);
        }
        when 'MiniSeq'{
            proactiveRec.RTA_Version__c = stringEmptyCheck(sWrap.rtaVersion);
            proactiveRec.System_Suite_Version__c = stringEmptyCheck(sWrap.systemSuiteVersion);
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.Cluster_Density__c = (sWrap.clusterDensityRead1==NULL)?0:sWrap.clusterDensityRead1;
            proactiveRec.Cluster_Density_Passing_Filter__c = (sWrap.clusterDensityPFRead1==NULL)?0:sWrap.clusterDensityPFRead1;
            proactiveRec.LRM_Version__c =  stringEmptyCheck(sWrap.localRunManagerVersion);
            proactiveRec.Analysis_Type__c =  stringEmptyCheck(sWrap.analysisProtalType);
            
        }
        when 'NextSeq500' {
            proactiveRec.Cluster_Density__c = (sWrap.clusterDensityRead1==NULL)?0:sWrap.clusterDensityRead1;
            proactiveRec.Cluster_Density_Passing_Filter__c = (sWrap.clusterDensityPFRead1==NULL)?0:sWrap.clusterDensityPFRead1;
            proactiveRec.System_Suite_Version__c = stringEmptyCheck(sWrap.systemSuiteVersion);
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.RTA_Version__c = stringEmptyCheck(sWrap.rtaVersion);
            proactiveRec.Run_Management_Type__c = stringEmptyCheck(sWrap.runManagementType);
            proactiveRec.Analysis_Workflow_Type__c = stringEmptyCheck(sWrap.analysisWorkflowType);
        }
        when 'NextSeq1000'{
            proactiveRec.Loading_Concentration__c = (sWrap.loadingConcentration==NULL)?0:sWrap.loadingConcentration;
            proactiveRec.Occupancy_Percent__c = (sWrap.occupancyPercent==NULL)?0:sWrap.occupancyPercent;  
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.UCS_Version__c = stringEmptyCheck(sWrap.copyServiceVersion);
            proactiveRec.RTA_Version__c = stringEmptyCheck(sWrap.rtaVersion);
            proactiveRec.Secondary_Analysis_Mode__c = stringEmptyCheck(sWrap.secondaryAnalysisMode);
            proactiveRec.Secondary_Analysis_Workflow__c = stringEmptyCheck(sWrap.secondaryAnalysisWorkflow);
            proactiveRec.Secondary_Analysis_Version__c = stringEmptyCheck(sWrap.secondaryAnalysisPlatformVersion);
            
        }
        when 'NovaSeq'{
            proactiveRec.Side__c = stringEmptyCheck(sWrap.side);
            proactiveRec.Occupancy_Percent__c = (sWrap.occupancyPercent==NULL)?0:sWrap.occupancyPercent;
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.UCS_Version__c = stringEmptyCheck(sWrap.ucsVersion);
            proactiveRec.RTA_Version__c = stringEmptyCheck(sWrap.rtaVersion);
        }
        when 'HiSeq HD','HiSeq X'{
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.RTA_Version__c = stringEmptyCheck(sWrap.rtaVersion);
            proactiveRec.Side__c = stringEmptyCheck(sWrap.fcPosition);
            proactiveRec.FPGA_Version__c = stringEmptyCheck(sWrap.fpgaVersion);
            proactiveRec.Flow_Cell_Type__c = stringEmptyCheck(sWrap.flowcellType.value); //CMCM-6601
        }
        when 'NovaSeq X'{
            proactiveRec.Side__c = stringEmptyCheck(sWrap.side);
            proactiveRec.Occupancy_Percent__c = (sWrap.occupancyPercent==NULL)?0:sWrap.occupancyPercent;
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.UCS_Version__c = stringEmptyCheck(sWrap.ucsVersion);
            proactiveRec.RTA_Version__c = stringEmptyCheck(sWrap.rtaVersion);
        }
           
    }
    return null;
}

/***************************************************************************************
* Author: Raviteja
* Description: Method to handle the SAVE funtionality of Genotyping
* Params : ProactiveRunMetricsWrapper,IP Category
*****************************************************************************************/
    
    public static string handleGenotyping(ProactiveRunMetricsWrapper sWrap,ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper) {
        system.debug(saveRunWrapper.category);
        //INC0379506 [commented try catch]
        //try{
            runId = saveRunWrapper.runName;
            List<proactive_run_detail__c> prDetail = new List<proactive_run_detail__c>();
            prDetail = new ProactiveRunDetailSelector().selectPRDRecFromRunId(runId);
            if(!prDetail.isEmpty()) {
                proactiveRec.Id = prDetail[0].Id;                
            }
        // CMCM-303 - START
        Id recId = (Id) saveRunWrapper.recordId;
        String objectAPIName = recId.getSObjectType().getDescribe().getName();
        if(objectAPIName == CASE_STRING) {
            List<Case> csList = [SELECT Id, Work_Order__c  FROM Case WHERE Id =: recId];
            proactiveRec.Case__c = csList[0].Id;
            proactiveRec.Work_Order__c = csList[0].Work_Order__c != null ? csList[0].Work_Order__c : null;
        }
        if(objectAPIName == WORK_ORDER_STRING) {
            List<SVMXC__Service_Order__c> soList = [SELECT Id,SVMXC__Case__c FROM SVMXC__Service_Order__c WHERE Id =:recId];
            proactiveRec.Work_Order__c = soList[0].Id;
            proactiveRec.Case__c = soList[0].SVMXC__Case__c != null ? soList[0].SVMXC__Case__c : null;
        }
        // CMCM-303 - END
			proactiveRec.BS_Run_ID__c = sWrap.runId;
            proactiveRec.Run_ID__c = saveRunWrapper.runName;
            proactiveRec.Bead_Chip_Serial_Number__c = stringEmptyCheck(sWrap.beadChipBarcode);
            proactiveRec.Application_Name__c = stringEmptyCheck(sWrap.applicationName);
            proactiveRec.Control_Software_Version__c = stringEmptyCheck(sWrap.controlSoftwareVersion);
            proactiveRec.FPGA_Version__c = stringEmptyCheck(sWrap.fpgaVersion);
            proactiveRec.Proactive_Link__c = stringEmptyCheck(sWrap.proactiveLink);
            if(!saveRunWrapper.isProactiveUpdate) {
                proactiveRec.Product_Category__c = saveRunWrapper.category;
                proactiveRec.Installed_Product__c = saveRunWrapper.ipId;
                proactiveRec.Notes__c = saveRunWrapper.runNotes;
                proactiveRec.Serial_Number__c = saveRunWrapper.serialNumber;
                proactiveRec.Proactive_Id__c = saveRunWrapper.id;
                proactiveRec.Environment__c = saveRunWrapper.env;
                proactiveRec.Read_Length__c = saveRunWrapper.readLength;
                proactiveRec.Run_Start_Date__c = saveRunWrapper.runStartDate;
                proactiveRec.Run_End_Date__c = saveRunWrapper.runEndDate;
                proactiveRec.Run_Status__c = saveRunWrapper.runStatus;
            }
            UPSERT proactiveRec Id;// Checks if the Proactive record exists and upserts
            system.debug('proactiveRec***'+proactiveRec);
            
            return SUCCESS_STRING;
        //}
        /*catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }*/
    }
    
    
/***************************************************************************************
* Author: Raviteja
* Description: Method to handle the Proactive Run Detail record common fields 
* Params : ProactiveRunMetricsWrapper , ProactiveComponentController.SaveMetricRunWrapper
*****************************************************************************************/
    
    public static void proactiveRecUtility(ProactiveRunMetricsWrapper sWrap,ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper) {
        
        
        ilib_LogEvent.message('runName***'+saveRunWrapper.runName);
        runId = saveRunWrapper.runName;
        List<proactive_run_detail__c> prDetail = new List<proactive_run_detail__c>();
        prDetail = new ProactiveRunDetailSelector().selectPRDRecFromRunId(runId);
        if(!prDetail.isEmpty()) {
            proactiveRec.Id = prDetail[0].Id;                
        }
        // CMCM-303 - START
        Id recId = (Id) saveRunWrapper.recordId;
        String objectAPIName = recId.getSObjectType().getDescribe().getName();
        if(objectAPIName == CASE_STRING) {
            List<Case> csList = [SELECT Id, Work_Order__c  FROM Case WHERE Id =: recId];
            proactiveRec.Case__c = csList[0].Id;
            proactiveRec.Work_Order__c = csList[0].Work_Order__c != null ? csList[0].Work_Order__c : null;
        }
        if(objectAPIName == WORK_ORDER_STRING) {
            List<SVMXC__Service_Order__c> soList = [SELECT Id,SVMXC__Case__c FROM SVMXC__Service_Order__c WHERE Id =:recId];
            proactiveRec.Work_Order__c = soList[0].Id;
            proactiveRec.Case__c = soList[0].SVMXC__Case__c != null ? soList[0].SVMXC__Case__c : null;
        }
        // CMCM-303 - END
        proactiveRec.BS_Run_ID__c = sWrap.runId;
        proactiveRec.Run_ID__c = saveRunWrapper.runName;
        proactiveRec.Proactive_Link__c = stringEmptyCheck(sWrap.proactiveLink);
        proactiveRec.Yield__c = (sWrap.yieldTotalG==NULL)?0:sWrap.yieldTotalG; //number
        proactiveRec.Error_Rate__c = (sWrap.errorRate==NULL)?0:sWrap.errorRate; //number
        proactiveRec.Percent_Passing_Filter__c = decimalNullCheck(sWrap.percentPf); //percent
        proactiveRec.Overall_Q3__c = decimalNullCheck(sWrap.gtq30Percent); //percent
        proactiveRec.Q30_Read_1__c = decimalNullCheck(sWrap.percentGTQ30Read1); //percent
        proactiveRec.Q30_Read_2__c = decimalNullCheck(sWrap.percentGTQ30Read2); //percent
        proactiveRec.Percent_Aligned__c = decimalNullCheck(sWrap.alignedPercent); //percent 
        
        if(!saveRunWrapper.isProactiveUpdate) {
            proactiveRec.Serial_Number__c = saveRunWrapper.serialNumber;
            proactiveRec.Proactive_Id__c = saveRunWrapper.id;
            proactiveRec.Environment__c = saveRunWrapper.env;
            proactiveRec.Product_Category__c = saveRunWrapper.category;
            proactiveRec.Installed_Product__c = saveRunWrapper.ipId;
            proactiveRec.Notes__c = saveRunWrapper.runNotes;
            proactiveRec.Read_Length__c = saveRunWrapper.readLength;
            proactiveRec.Run_Start_Date__c = saveRunWrapper.runStartDate;
            proactiveRec.Run_End_Date__c = saveRunWrapper.runEndDate;
            proactiveRec.Run_Status__c = saveRunWrapper.runStatus;
        }
        
    }
    
    
/***************************************************************************************
* Author: Raviteja
* Description: A utility method to prepare a map using all the partnumbers from proactive. 
* Params : WorkOrder record,ProactiveRunMetricsWrapper
*****************************************************************************************/
    
    public static void productUtility(ProactiveRunMetricsWrapper sWrap) {
        
        addToPartNumSetIfNotNull(sWrap.flowcellEepromTagPartNumber);
        addToPartNumSetIfNotNull(sWrap.reagentKitRfidTagPartNumber);
        addToPartNumSetIfNotNull(sWrap.pr2BottleRfidTagPartNumber);
        addToPartNumSetIfNotNull(sWrap.flowcellRfidTagPartNumber);
        addToPartNumSetIfNotNull(sWrap.flowcellPartNumber);
        addToPartNumSetIfNotNull(sWrap.bufferPartNumber);
        addToPartNumSetIfNotNull(sWrap.sbsPartNumber);
        addToPartNumSetIfNotNull(sWrap.clusterPartNumber);
        addToPartNumSetIfNotNull(sWrap.cartridgePartNumber);
        //CMCM-6601
        addToPartNumSetIfNotNull(sWrap.sampleTubePartNumber);
        addToPartNumSetIfNotNull(sWrap.reagentPartNumber);
        addToPartNumSetIfNotNull(sWrap.lyoPartNumber);
        
        for(product2 pr:new ProductsSelector().fetchProductId(partNumSet)) {
            prodMap.put(pr.ProductCode,pr);
        }
    }
/***************************************************************************************
* Author: Abhishek Yadav
* Description: A Helper method to add part value. 
* Params : ProactiveRunMetricsWrapper.dataWrapp
*****************************************************************************************/    
    private static void addToPartNumSetIfNotNull(ProactiveRunMetricsWrapper.dataWrapp data) {
        if (data != null && data.value != null) {
            partNumSet.add(data.value);
        }
    }

/***************************************************************************************
* Author: Abhishek Yadav
* Description: A utility method to prepare a map using all the partnumbers from proactive. 
* Params : WorkOrder record,ProactiveRunMetricsWrapper
*****************************************************************************************/
public static List<Associated_Product__c> associatedProductUtility(List<ProactiveComponentController.additionalProdWrapper> apSelectedWrap, proactive_run_detail__c proactiveRec) {
    for(ProactiveComponentController.additionalProdWrapper addPrd : apSelectedWrap) {
        if(addPrd.serialNumber != null) {
            associatedProdObj = new Associated_Product__c();
            if(proactiveRec.Case__c != null) {
                associatedProdObj.Case__c = proactiveRec.Case__c;
            }
            if(proactiveRec.Work_Order__c  != null) {
                associatedProdObj.Work_Order__c = proactiveRec.Work_Order__c ;
            } 
            associatedProdObj.Proactive_Run_Detail__c = proactiveRec.Id;
            associatedProdObj.Product_Serial_Number__c = addPrd.serialNumber;
            
            if(prodMap != NULL && prodMap.containsKey(addPrd.partNumber)) {
                associatedProdObj.Product__c = prodMap.get(addPrd.partNumber).Id;
            }
            
            associatedProdObj.Expired_Date__c = (addPrd.expirationDate == NULL) ? NULL : Date.valueOf(addPrd.expirationDate);
            associatedProdObj.Product_Lot_Number__c = addPrd.lotNumber;
            associatedProdObj.Is_Expired__c = (addPrd.expired == NULL) ? FALSE : addPrd.expired;
            apList.add(associatedProdObj);
        }
    }
    return apList;
}

/***************************************************************************************
* Author: Raviteja
* Description: Method to perform empty check for the response attributes
* Params : String
*****************************************************************************************/
    
public static string stringEmptyCheck(string responseAttr){
        
    if(string.isBlank(responseAttr)) {
        return '';
    } else {
        return responseAttr;
    }

}

/***************************************************************************************
* Author: Raviteja
* Description: Method to perform null check for the Decimal type attributes from the response
* Params : Decimal
*****************************************************************************************/
    
public static Decimal decimalNullCheck(Decimal responseAttr){
        
    if(responseAttr == 0) {
        return 0;
    } else {
        return responseAttr;
    }

}

/**
*  @author: Raviteja
*  @description: Method to change the category value as needed to fetch the metadata records 
**/
    
public static string handleCategory(String category) {
        
    String proCategory = '';
    if(category != '' && category != NULL) {
        if(category.contains('NextSeq 500')) {
            proCategory = 'NextSeq500';
        } else if(category.contains('NextSeq 1000')) {
            proCategory = 'NextSeq1000';   
        } else if(category.contains('NovaSeq X Series')) { //CMCM-6601
            proCategory = 'NovaSeq X';   
        } else {
            proCategory = category;
        }
    }
    return proCategory;
}

}