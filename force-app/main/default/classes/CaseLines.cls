/***************************************************************************************************************************************
* NAME   : CaseLines
* DESCRIPTION  : Domain class for Case Line.
*                    
* @AUTHOR : Shashank Singhal
* @DATE   : 16-Aug-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shashank               16-Aug-2018          Initial Version. 
* Preetha                29-Mar-2022          QACM-18 Added if WO status closed in updateAdditionalProductInformation createRelatedProductWithWO method
* Preetha                6-Apr-2022           QACM-18 Added checkShowOnCase method to update show on case
****************************************************************************************************************************************/ 

global with sharing class CaseLines extends ilib_SObjectDomain{
    
    //QACM-18
    public static final String LOG_TITLE = 'CaseLines';
    public static Boolean showOnCaseRecord = false;
    public static Map<Id, SVMXC__Case_Line__c> mapShowOnCaseLineIdToCases;
    
   /*
    * Constructor
    */
    public CaseLines(List<SVMXC__Case_Line__c> sObjectList)
    {
        super(sObjectList);
        ilib_LogEvent.rootTitle = LOG_TITLE;//QACM-18
    }

    /**
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	     /*Param - sobjectList */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new CaseLines(sObjectList);
        }
    }
    
    global static final string STRING_WORK_DETAIL_RECORDTYPE_NAME = 'Related Products';
    global static Boolean boolWorkDetailsCreated = false;
	
   /*
    * DESCRIPTION - InputInvocableParameters
    */
    global class InputInvocableParameters{
        @InvocableVariable
        global List<Id> lstCaseLineIds;
        
        @InvocableVariable
        global boolean boolShowOnCase;
    }
    
    
    /*
    *  @AUTHOR:  Shashank Singhal 
    *  @DESCRIPTION: Invocable method to be called from process builder. It checks if the related product Work Detail record with 
    *               Show on Case as checked is present then update the Additional product information else insert a work detail.
    *  @PARAM :  List<Id> lstCaseIds
    *  @RETURN:  void
    */ 
    @InvocableMethod(label='Upsert Additional Product Information') 
    global static void updateAdditionalProductInformation(List<InputInvocableParameters> lstInputParams){
        set<Id> setCaseLineIds = new set<Id>();
        set<Id> setCaseIds = new set<Id>();
        set<Id> setWOIds = new set<Id>();
        List<SVMXC__Service_Order_Line__c> lstWordDetailsToUpsert = new List<SVMXC__Service_Order_Line__c>();
        
        setCaseLineIds.addAll(lstInputParams[0].lstCaseLineIds);
        //Query the current Case Line
        List<SVMXC__Case_Line__c> lstCaseLines = new CaseLinesSelector().selectCaseLinesFromId(setCaseLineIds);
        if(!lstCaseLines.isEmpty()){
            setCaseIds.add(lstCaseLines[0].SVMXC__Case__c);
        }
        //Query Work orders related to case
        for(SVMXC__Service_Order__c objWO: new WorkOrdersSelector().selectWorkOrderIdOnCase(setCaseIds)){
            if(objWO.SVMXC__Order_Status__c!='Closed' && objWO.SVMXC__Order_Status__c!='Completed' && objWO.SVMXC__Order_Status__c!='Closed-Duplicate'){
                setWOIds.add(objWO.Id);
            }
        }
        if(!setWOIds.isEmpty()){
            //Query the work detail record where record type is related product and show on case is true
            List<SVMXC__Service_Order_Line__c> lstWorkDetailsWithShowOnCase = new WorkDetailsSelector().selectWorkDetailsByWorkOrderIdWithRecordTypeAndShowOnCase(setWOIds, STRING_WORK_DETAIL_RECORDTYPE_NAME, true);
            
            Map<Id, List<SVMXC__Service_Order_Line__c>> mapWOIdtoLstWorkDetailsWithShowOnCase = UtilsCollection.getMapOfIdToSObjects(lstWorkDetailsWithShowOnCase, 'SVMXC__Service_Order__c');
            
            Map<string, SVMXC__Service_Order_Line__c> mapStrToWorkDetailWithoutShowOnCase = new Map<string, SVMXC__Service_Order_Line__c>();
            for(SVMXC__Service_Order_Line__c objWorkDetail:new WorkDetailsSelector().selectWorkDetailsByWorkOrderIdWithRecordTypeAndShowOnCase(setWOIds, STRING_WORK_DETAIL_RECORDTYPE_NAME, false)){
                mapStrToWorkDetailWithoutShowOnCase.put(objWorkDetail.SVMXC__Service_Order__c+'#'+objWorkDetail.SVMXC__Serial_Number__c+'#'+objWorkDetail.SVMXC__Product__c, objWorkDetail);
            }
            for(Id strWOId:setWOIds){
                SVMXC__Service_Order_Line__c objWorkDetailToUpsert;
                if(!lstInputParams[0].boolShowOnCase){
                    if(mapWOIdtoLstWorkDetailsWithShowOnCase.containsKey(strWOId)){
                        objWorkDetailToUpsert = new SVMXC__Service_Order_Line__c(id=mapWOIdtoLstWorkDetailsWithShowOnCase.get(strWOId)[0].Id);
                        objWorkDetailToUpsert.Show_On_Case__c = false;
                    }
                }else{
                    if(mapWOIdtoLstWorkDetailsWithShowOnCase.containsKey(strWOId)){
                        objWorkDetailToUpsert = new SVMXC__Service_Order_Line__c(id=mapWOIdtoLstWorkDetailsWithShowOnCase.get(strWOId)[0].Id);
                    }else if(mapStrToWorkDetailWithoutShowOnCase.containskey(strWOId+'#'+lstCaseLines[0].SVMXC__Installed_Product__c+'#'+lstCaseLines[0].SVMXC__Product__c)){
                        objWorkDetailToUpsert = new SVMXC__Service_Order_Line__c(id=mapStrToWorkDetailWithoutShowOnCase.get(strWOId+'#'+lstCaseLines[0].SVMXC__Installed_Product__c+'#'+lstCaseLines[0].SVMXC__Product__c).Id);
                    }else{
                        objWorkDetailToUpsert = new SVMXC__Service_Order_Line__c();
                        objWorkDetailToUpsert.SVMXC__Service_Order__c = strWOId;
                    }
                    objWorkDetailToUpsert.SVMXC__Serial_Number__c = lstCaseLines[0].SVMXC__Installed_Product__c;
                    objWorkDetailToUpsert.SVMXC__Product__c = lstCaseLines[0].SVMXC__Product__c;
                    objWorkDetailToUpsert.Lot_Number__c = lstCaseLines[0].Product_Lot_Number__c;
                    objWorkDetailToUpsert.Show_On_Case__c = true;
                    objWorkDetailToUpsert.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('SVMXC__Service_Order_Line__c', STRING_WORK_DETAIL_RECORDTYPE_NAME);
                }
                if(objWorkDetailToUpsert != null)
                    lstWordDetailsToUpsert.add(objWorkDetailToUpsert);
            }
            if(!lstWordDetailsToUpsert.isEmpty()){
                 WorkDetails.boolIsCaseLineCreated = true;
                upsert lstWordDetailsToUpsert;
            }
        }
    }
    
    /**
    *  @author Nitin Sood
    *  @description - To be executed, when the Case Line is inserted. 
    *                 1. Checks if Work Detail is created, updates Is-Billable flag for Parts and Labor lines
    **/ 

    public static final Id ID_WORKDETAILS_REL_PROD_RECORDTYPE_ID = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(STRING_WORK_DETAIL_RECORDTYPE_NAME).getRecordTypeId();   
    
    /**
    *  @author Nitin Sood
    *  @description - To be executed, when the Case Line is inserted. 
    *                 1. Checks if Work Detail is created, updates Is-Billable flag for Parts and Labor lines
    **/    
    public override void onAfterInsert(){

        createRelatedProductWithWO((List<SVMXC__Case_Line__c>)records);
        updateIVDIdentifierOnCase((List<SVMXC__Case_Line__c>)records);
    }
    
   /* 
    *  @description - onBeforeInsert method
    */
    public override void onBeforeInsert(){
        checkShowOnCase(records);//QACM-18
        
        Map<Id, SVMXC__Installed_Product__c> iPtoProduct = getProductFromInstallProduct((List<SVMXC__Case_Line__c>)records); 

        if(iPtoProduct != null && !iPtoProduct.isEmpty()){
            for(SVMXC__Case_Line__c objCaseLines: (List<SVMXC__Case_Line__c>)records){
                if(iPtoProduct.containsKey(objCaseLines.SVMXC__Installed_Product__c) && iPtoProduct.get(objCaseLines.SVMXC__Installed_Product__c)!=null){
                    objCaseLines.SVMXC__Product__c = iPtoProduct.get(objCaseLines.SVMXC__Installed_Product__c).SVMXC__Product__c;
					//DCP-31083
                    objCaseLines.Installed_Product_Upgrade_Type__c = iPtoProduct.get(objCaseLines.SVMXC__Installed_Product__c).Installed_Product_Upgrade_Type__c;
                }
            }
        }
    }
    
	/*
    *  @description - onBeforeUpdate method
    */
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords)
    { 
        List<SVMXC__Case_Line__c> lstUpdateCaseLines = new List<SVMXC__Case_Line__c>();
        
        for(SVMXC__Case_Line__c objCaseLine : (List<SVMXC__Case_Line__c>)records){
            SVMXC__Case_Line__c oldObjCaseLine = (SVMXC__Case_Line__c)(oldRecords.get(objCaseLine.Id));
            
            if(oldObjCaseLine.SVMXC__Installed_Product__c != objCaseLine.SVMXC__Installed_Product__c && objCaseLine.SVMXC__Installed_Product__c != null){
                lstUpdateCaseLines.add(objCaseLine);
            }
            /*if(objCaseLine.SVMXC__Installed_Product__c == null){
                objCaseLine.SVMXC__Product__c = null;
            }*/             
        }

        Map<Id, SVMXC__Installed_Product__c> iPtoProduct;    
        if(lstUpdateCaseLines.size() > 0){
            iPtoProduct = getProductFromInstallProduct(lstUpdateCaseLines); 
        }   

        if(iPtoProduct != null && !iPtoProduct.isEmpty()){
            for(SVMXC__Case_Line__c objCaseLine : (List<SVMXC__Case_Line__c>)records){
                if(iPtoProduct.containsKey(objCaseLine.SVMXC__Installed_Product__c) && iPtoProduct.get(objCaseLine.SVMXC__Installed_Product__c)!=null ){
                    objCaseLine.SVMXC__Product__c = iPtoProduct.get(objCaseLine.SVMXC__Installed_Product__c).SVMXC__Product__c;
					//DCP-31083
                    objCaseLine.Installed_Product_Upgrade_Type__c = iPtoProduct.get(objCaseLine.SVMXC__Installed_Product__c).Installed_Product_Upgrade_Type__c;
                }
            }
        }
    }
    
	/*
    *  @description - onAfterUpdate method
    */
    public override void onAfterUpdate(Map<Id, SObject> mapOld)
    {
        List<SVMXC__Case_Line__c> lstCaseLineUpdateWithIVDTrue = new List<SVMXC__Case_Line__c> ();
        List<Id> lstCaseLineUpdateWithIVDFalse = new List<Id> ();
        
        for(Id idCaseLine : mapOld.keySet()){
            
            SVMXC__Case_Line__c objNewCaseLine = (SVMXC__Case_Line__c)Trigger.newMap.get(idCaseLine);
            SVMXC__Case_Line__c objOldCaseLine = (SVMXC__Case_Line__c)mapOld.get(idCaseLine);
            
            if(objNewCaseLine.IVD_Product_Identifier__c == true && (objOldCaseLine.SVMXC__Product__c != objNewCaseLine.SVMXC__Product__c )){
                
                lstCaseLineUpdateWithIVDTrue.add(objNewCaseLine);
            }
            else if(objNewCaseLine.IVD_Product_Identifier__c == false && (objOldCaseLine.SVMXC__Product__c != objNewCaseLine.SVMXC__Product__c )){
                lstCaseLineUpdateWithIVDFalse.add(objNewCaseLine.SVMXC__Case__c);
            }
        }

        if(lstCaseLineUpdateWithIVDTrue.size() > 0){
            updateIVDIdentifierOnCase(lstCaseLineUpdateWithIVDTrue);
        }

        if(lstCaseLineUpdateWithIVDFalse.size() > 0){
            updateCaseWithAdditionalIVDFalse(lstCaseLineUpdateWithIVDFalse);
        }
    }
    
	 
	/*
    *  @description - onAfterDelete method
    */
    public override void onAfterDelete(){
        List<Id> lstCaseLineUpdateWithIVDFalse = new List<Id> ();       
        for(SVMXC__Case_Line__c objCaseLine:(List<SVMXC__Case_Line__c>)records){
            
            if(objCaseLine.IVD_Product_Identifier__c == true ){
                lstCaseLineUpdateWithIVDFalse.add(objCaseLine.SVMXC__Case__c);
            }
        }
        
        if(lstCaseLineUpdateWithIVDFalse.size() > 0){
            updateCaseWithAdditionalIVDFalse(lstCaseLineUpdateWithIVDFalse);
        }
    }
	
   /*
    *  @description - updateCaseWithAdditionalIVDFalse method
    * return - void
    */
    Public void updateCaseWithAdditionalIVDFalse(List<Id> caseIdsWithUpdatesIVDFalse){
        
        List<Case> lstCaseToBeUpdatedAddIVDFalse = new List<Case>();
        Set<Id> setCaseIdsWithAdditionalIVD = new Set<Id>();
        for(SVMXC__Case_Line__c objCaseLine :  [SELECT Id, SVMXC__Case__c, SVMXC__Case__r.IVD_Product_Identifier_Additional_Prod__c, IVD_Product_Identifier__c FROM  SVMXC__Case_Line__c WHERE SVMXC__Case__c IN: caseIdsWithUpdatesIVDFalse ]){

            if(objCaseLine.IVD_Product_Identifier__c == true ){
                
                setCaseIdsWithAdditionalIVD.add(objCaseLine.SVMXC__Case__c);
            }           
        }

        for(Id caseId : caseIdsWithUpdatesIVDFalse ){
            if(!setCaseIdsWithAdditionalIVD.contains(caseId)){
                Case objCase = new Case(IVD_Product_Identifier_Additional_Prod__c = false, Id =caseId ); 
                lstCaseToBeUpdatedAddIVDFalse.add(objCase);
            }
        }
        
        if(lstCaseToBeUpdatedAddIVDFalse.size() > 0){
            update lstCaseToBeUpdatedAddIVDFalse;
        }
    }
    
   /*
    *  @description - getProductFromInstallProduct method
	* return - SVMXC__Installed_Product__c id
	* parameter - list of SVMXC__Case_Line__c
    */
    public Map<Id, SVMXC__Installed_Product__c>  getProductFromInstallProduct(List<SVMXC__Case_Line__c> lstCaseLines){
        
        Set<Id> setInstaledProductIds = new Set<Id>();
        Map<Id, SVMXC__Installed_Product__c> installedProdcutIdToProductId = new Map<Id, SVMXC__Installed_Product__c>();
        for(SVMXC__Case_Line__c objCaseLine :lstCaseLines ){
            if(objCaseLine.SVMXC__Installed_Product__c != null){
                setInstaledProductIds.add(objCaseLine.SVMXC__Installed_Product__c);
            }
        }
    
        if(setInstaledProductIds.size() > 0){
            for(SVMXC__Installed_Product__c objInstalledProduct : [SELECT Id,Installed_Product_Upgrade_Type__c, SVMXC__Product__c FROM SVMXC__Installed_Product__c WHERE ID IN: setInstaledProductIds ]){
                installedProdcutIdToProductId.put(objInstalledProduct.Id, objInstalledProduct);
            }
        }
        
        return installedProdcutIdToProductId;
    }
    
   /*
    *  @description - updateIVDIdentifierOnCase method
	* return - void
	* parameter - list of SVMXC__Case_Line__c
    */
    public static void updateIVDIdentifierOnCase(List<SVMXC__Case_Line__c> lstCaseLines){
        Set<Id> setCaseIds = new Set<Id>();
        List<Case> lstCasesToBeUpdated =  new List<Case>();
        for(SVMXC__Case_Line__c objCaseLine : lstCaseLines){
            if(objCaseLine.IVD_Product_Identifier__c == true){
                setCaseIds.add(objCaseLine.SVMXC__Case__c);
            }
        }
        
        if(setCaseIds != null && setCaseIds.size() >0){
            for(Case objCase : [SELECT Id, IVD_Product_Identifier_Additional_Prod__c FROM Case WHERE Id IN: setCaseIds ]){
                if(objCase.IVD_Product_Identifier_Additional_Prod__c != true){
                    objCase.IVD_Product_Identifier_Additional_Prod__c = true;
                    lstCasesToBeUpdated.add(objCase);
                }
            }
        }
        
        if(lstCasesToBeUpdated.size() >0){
            update lstCasesToBeUpdated;
        }
    }
	
    /*
    *  @description - createRelatedProductWithWO method
	* return - void
	* parameter - list of SVMXC__Case_Line__c
    */
    public static void createRelatedProductWithWO( List<SVMXC__Case_Line__c> lstCaseLines){
        
        /*Map<Id, Id> workOrderIdToCase = new Map<Id, Id>();
        Map<Id, Set<Id>> CaseIdToCaseLinesIPAndProduct = new Map<Id, Set<Id>>();
        List<SVMXC__Service_Order_Line__c> lstWorkDetailsToBeInserted = new List<SVMXC__Service_Order_Line__c>(); 
        
        for(SVMXC__Case_Line__c objCaseLine : lstCaseLines){          
            if(CaseIdToCaseLinesIPAndProduct.containsKey(objCaseLine.SVMXC__Case__c)){
                CaseIdToCaseLinesIPAndProduct.get(objCaseLine.SVMXC__Case__c).add(objCaseLine.SVMXC__Installed_Product__c); 
            }
            else{
                CaseIdToCaseLinesIPAndProduct.put(objCaseLine.SVMXC__Case__c , new Set<Id>{objCaseLine.SVMXC__Installed_Product__c});           
            }
        }
        
        if(!CaseIdToCaseLinesIPAndProduct.isEmpty()  ){          
            for(SVMXC__Service_Order__c objWorkOrder : [SELECT Id, SVMXC__Case__c,(SELECT Id, RecordTypeId, SVMXC__Serial_Number__c, SVMXC__Product__c FROM SVMXC__Service_Order_Line__r WHERE recordTypeId =:ID_WORKDETAILS_REL_PROD_RECORDTYPE_ID) FROM SVMXC__Service_Order__c WHERE SVMXC__Case__c IN: CaseIdToCaseLinesIPAndProduct.keySet()]){
                
                Set<Id> existingadditionalProds = new Set<Id>();
                
                for(SVMXC__Service_Order_Line__c objRelatedProdWorkDetail :  objWorkOrder.SVMXC__Service_Order_Line__r){
                    
                    if(CaseIdToCaseLinesIPAndProduct.get(objWorkOrder.SVMXC__Case__c).contains(objRelatedProdWorkDetail.SVMXC__Serial_Number__c)){
                        existingadditionalProds.add(objRelatedProdWorkDetail.SVMXC__Serial_Number__c);               
                    }  
                }
           
                for(Id s: CaseIdToCaseLinesIPAndProduct.get(objWorkOrder.SVMXC__Case__c)){

                    if(!existingadditionalProds.contains(s)){

                        SVMXC__Service_Order_Line__c objWorkDetail = new SVMXC__Service_Order_Line__c();
                        objWorkDetail.RecordTypeId = ID_WORKDETAILS_REL_PROD_RECORDTYPE_ID;
                        objWorkDetail.SVMXC__Service_Order__c = objWorkOrder.Id;
                        if(s != null ){
                            objWorkDetail.SVMXC__Serial_Number__c = s;
                        }
                        lstWorkDetailsToBeInserted.add(objWorkDetail);                                         
                    }
                }               
            }
        }
        
        if(lstWorkDetailsToBeInserted.size() > 0){
            insert lstWorkDetailsToBeInserted;
        }   */
        if(!CaseLines.boolWorkDetailsCreated){
            Map<Id,List<SVMXC__Case_Line__c>> caseIdToLstCaseLines = new Map<Id,List<SVMXC__Case_Line__c>>();
            //Map<Id, Id> workOrderIdToCase = new Map<Id, Id>();
            List<SVMXC__Service_Order_Line__c> lstWorkDetailsToBeInserted = new List<SVMXC__Service_Order_Line__c>(); 
            
            for(SVMXC__Case_Line__c objCaseLine : lstCaseLines){
                if(!caseIdToLstCaseLines.containskey(objCaseLine.SVMXC__Case__c)){
                    caseIdToLstCaseLines.put(objCaseLine.SVMXC__Case__c, new List<SVMXC__Case_Line__c>());
                }
                caseIdToLstCaseLines.get(objCaseLine.SVMXC__Case__c).add(objCaseLine);
            }
            
            for(SVMXC__Service_Order__c objWorkOrder : [SELECT Id, SVMXC__Case__c,SVMXC__Order_Status__c
                                                        FROM SVMXC__Service_Order__c 
                                                        WHERE SVMXC__Case__c IN: caseIdToLstCaseLines.keySet()]){
                if(objWorkOrder.SVMXC__Order_Status__c!='Closed' && objWorkOrder.SVMXC__Order_Status__c!='Completed' && objWorkOrder.SVMXC__Order_Status__c!='Closed-Duplicate'){
                    for(SVMXC__Case_Line__c objCaseLine : caseIdToLstCaseLines.get(objWorkOrder.SVMXC__Case__c)){
                        SVMXC__Service_Order_Line__c objWorkDetail = new SVMXC__Service_Order_Line__c();
                        objWorkDetail.RecordTypeId = ID_WORKDETAILS_REL_PROD_RECORDTYPE_ID;
                        objWorkDetail.SVMXC__Service_Order__c = objWorkOrder.Id;
                        objWorkDetail.SVMXC__Serial_Number__c = objCaseLine.SVMXC__Installed_Product__c;
                        objWorkDetail.SVMXC__Product__c = objCaseLine.SVMXC__Product__c;
                        objWorkDetail.Show_On_Case__c = objCaseLine.Show_On_Case__c;
                        objWorkDetail.Lot_Number__c = objCaseLine.Product_Lot_Number__c;
                        lstWorkDetailsToBeInserted.add(objWorkDetail);   
                   }   
                }
            }            
            if(lstWorkDetailsToBeInserted.size() > 0){
                WorkDetails.boolIsCaseLineCreated = true;
                insert lstWorkDetailsToBeInserted;
            } 
        }    
    }
      /*
    *  @AUTHOR:  Preetha[QACM-18]
    *  @DESCRIPTION: To Update Show on Case when Case Line is created 
    *  @PARAM :  trigger.new
    *  @RETURN:  void
    */ 
    public static void checkShowOnCase(List<SVMXC__Case_Line__c> records){
      ilib_LogEvent.push(LOG_TITLE + '.checkShowOnCase()');
       set<Id> setCaseIds = new set<Id>(); 
       Map<Id, List<SVMXC__Case_Line__c>> mapCaseIdCaseLines = new  Map<Id, List<SVMXC__Case_Line__c>>();  
       try{
           //Getting case id for the Case line which is getting inserted
           for(SVMXC__Case_Line__c objCL : (List<SVMXC__Case_Line__c>)records){
               if(String.isNotBlank(objCL.SVMXC__Case__c)){
                   setCaseIds.add(objCL.SVMXC__Case__c);
               }
           }
           //Checking the AP's based on the case
           if(!setCaseIds.isEmpty()){ 
               if(new CaseLinesSelector().selectShowOnCaseLines(setCaseIds).size() >0){  
                   mapShowOnCaseLineIdToCases = new Map<Id,SVMXC__Case_Line__c>(new CaseLinesSelector().selectShowOnCaseLines(setCaseIds));  
               }
               //Getting AP details
               if(MapShowOnCaseLineIdToCases != null && !MapShowOnCaseLineIdToCases.isEmpty()){
                   for(SVMXC__Case_Line__c objCL: MapShowOnCaseLineIdToCases.values()){
                       if(!mapCaseIdCaseLines.containsKey(objCL.SVMXC__Case__c)){
                           mapCaseIdCaseLines.put(objCL.SVMXC__Case__c, new List<SVMXC__Case_Line__c>());
                       }
                       mapCaseIdCaseLines.get(objCL.SVMXC__Case__c).add(objCL);
                   }
               }//Checking Show on case AP for a case
               for(SVMXC__Case_Line__c objCL : (List<SVMXC__Case_Line__c>)records){
                   if(!mapCaseIdCaseLines.isEmpty() && mapCaseIdCaseLines.containsKey(objCL.SVMXC__Case__c) && !mapCaseIdCaseLines.get(objCL.SVMXC__Case__c).isEmpty()){
                       for(SVMXC__Case_Line__c objShowOnCL : mapCaseIdCaseLines.get(objCL.SVMXC__Case__c)){
                           if(objShowOnCL.Show_On_Case__c == TRUE){
                                showOnCaseRecord = TRUE;
                           }   
                       }
                   } //Update inserting AP with Show on case
                   if(showOnCaseRecord == false && (!mapCaseIdCaseLines.isEmpty() || mapCaseIdCaseLines.isEmpty())){
                       objCL.Show_On_Case__c = true;
                       showOnCaseRecord = TRUE;
                   }
               }
           }
           ilib_LogEvent.pop();
       }Catch(Exception e){
           ApexExceptions.emit('CaseLines.checkShowOnCase',e);
       }
   }
}