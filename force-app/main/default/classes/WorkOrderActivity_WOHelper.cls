/**
* @author Shivani Jain
* @date 6th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to verify uploaded documents in work order 
*                        and validate work details with work order activity rules
 MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
*  Shivani Jain           05-01-2023           DCP-58614: modified iterateRules method to correct Rules criteria
*  Nancy                  13-Feb-2024          CMCM-5307 Work Order Trigger Query Optimization

*/ 
public with sharing class WorkOrderActivity_WOHelper {
    public static String userProfileName = ''; //CMCM-5307
    /**
     * DCP-43185
     *  @author Raja Siva Krishna
     *  @description - verify uploaded documents in work order
     **/
    public static void workOrderActivityRulesExecution(Map<Id, SObject> oldRecords, List<sObject> records) {
        ilib_LogEvent.push(WorkOrders.LOG_TITLE + '.workOrderActivityRulesExecution()');
        if(!WorkOrders.hasactivityRuleran) {
            //DCP-43185- verify uploaded documents in work order
            verifyWoDocumentation(oldRecords, records);
            //DCP-41619 - validating work details with work order activity rules
           verifyWorkOrderActivityRules(records);
        }
        WorkOrders.hasactivityRuleran=true;
        ilib_LogEvent.pop();
    }

    /**
    * @author Raja Siva Krishna
    * @date   02-Dec-2020
    * @description  DCP-43185 - validating reason for missing documentation & uploaded documents before completing the WO
    **/
    public static void verifyWoDocumentation(Map<Id, SObject> oldRecords, List<sObject> records) {
        Map<Id, SObject> mapReopenWO = new Map<Id, SObject>();
        Map<Id, SObject> mapopenWO = new Map<Id, SObject>();
        if(!UserInfo.getName().containsIgnoreCase(WorkOrders.STRING_SNAP_INTEGRATION_USER)) {
            for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
                SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)); 
                ilib_LogEvent.message('DCP-43185:objWorkOrder.Latest_Completion_Date_Time__c:'+objWorkOrder.Latest_Completion_Date_Time__c);
                ilib_LogEvent.message('DCP-43185:string.datetime:'+objWorkOrder.Latest_Completion_Date_Time__c);
                if(!String.isBlank(String.valueof(objWorkOrder.Latest_Completion_Date_Time__c))) {
                    mapReopenWO.put(objWorkOrder.Id,objOldWorkOrder);
                }
                else{
                    mapopenWO.put(objWorkOrder.Id,objOldWorkOrder);
                }
            }
            if(!mapopenWO.keySet().isEmpty()) {
                verifyWOForMissingDocumentation(mapopenWO,'OpenWO', records);
            }
            if(!mapReopenWO.keySet().isEmpty()) {
                verifyWOForMissingDocumentation(mapReopenWO,'ReopenWO', records);
            }
            ilib_LogEvent.message('DCP-43185:mapopenWO:'+mapopenWO);
            ilib_LogEvent.message('DCP-43185:mapReopenWO:'+mapReopenWO);
        }
    }

    /**
    * @author Raja Siva Krishna
    * @date   25-Nov-2020
    * @description  DCP-43185 - validating reason for missing documentation & uploaded documents before completing the WO
    **/
    public static void verifyWOForMissingDocumentation(Map<Id, SObject> oldRecords, String keyParam, List<sObject> records) {
        set<Id> setWOIds = new set<Id>();
        Map<Id,Id> mapWOIdtoWOProdId = new Map<Id,Id> ();
        Map<id,String> mapProdIdToProdGrp = new Map<id,String>();
        Map<Id,set<String>> mapWOIdtoUploadedDocNames = new Map<Id,set<String>>();
        Map<Id,String> mapWOIdtoRepairProtocol = new Map<Id,String> ();//Pooja :49644
        Map<id,set<String>> mapWOIdToRequiredDocs = new Map<id,set<String>>();

        missingDocumentation(records, oldRecords, setWOIds, mapWOIdtoRepairProtocol, mapWOIdtoWOProdId);

        if(!WorkOrders.lstProducts.isEmpty()) {
            mapProdIdToProdGrp = getProductGroupForProduct(WorkOrders.lstProducts);
        }

        if(!WorkOrders.lstContentDocLinks.isEmpty()) {
            mapWOIdtoUploadedDocNames = getWoIdToUploadedDocumentNames(WorkOrders.lstContentDocLinks);
        }//Req-- No change req
        
        if(!setWOIds.isEmpty()) {
            mapWOIdToRequiredDocs = getWoToRequiredDocumentsToBeUploaded(setWOIds,mapProdIdToProdGrp,mapWOIdtoWOProdId,keyParam, oldRecords,mapWOIdtoRepairProtocol);//Pooja :49644 :mapWOIdtoRepairProtocol
        }

        ilib_LogEvent.message('DCP-43185-mapWOIdtoWOProdId: '+mapWOIdtoWOProdId);
        ilib_LogEvent.message('DCP-43185-mapProdIdToProdGrp: '+mapProdIdToProdGrp);
        ilib_LogEvent.message('DCP-43185-mapWOIdToRequiredDocs: '+mapWOIdToRequiredDocs);
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)); 
            throwError(objOldWorkOrder, mapWOIdtoUploadedDocNames, mapWOIdToRequiredDocs, objWorkOrder );
        }
     
    }

    /**
    * @author Raja Siva Krishna
    * @date   25-Nov-2020
    * @description  DCP-43185 - get product id to product gropup map
    **/
    public static Map<id,String> getProductGroupForProduct(List<Product2> lstProducts) {
        Map<id,String> mapProdIdToProdGroup = new Map<id,String>();
        for(Product2 eachProd : lstProducts) {
                mapProdIdToProdGroup.put(eachProd.Id,eachProd.Product_Group__c);
        }
        return mapProdIdToProdGroup;
    }

    /**
    * @author Raja Siva Krishna
    * @date   25-Nov-2020
    * @description  DCP-43185 - get uploaded documents as a map of work order id and set of document names
    **/
    public static Map<Id,set<String>> getWoIdToUploadedDocumentNames(List<ContentDocumentLink> lstContendDocumentLinks) {
        Map<Id,Id> mapContentDocIdToWoId=new Map<Id,Id> ();
        Map<Id,set<String>> mapWOIdtoUploadedDocumentNames = new Map<Id,set<String>>();
        List<Id> lstContentDocIds = new List<Id>();
        for(ContentDocumentLink eachCDL : lstContendDocumentLinks) {
            lstContentDocIds.add(eachCDL.ContentDocument.Id);
            mapContentDocIdToWoId.put(eachCDL.ContentDocument.Id,eachCDL.LinkedEntityId);
        }
        for(ContentVersion eachCV:WorkOrders.lstContentVersions) {
            if(!string.isempty(eachCV.Document_Type_fileupload__c)) {
                if(mapContentDocIdToWoId.containsKey(eachCV.ContentDocumentId)) {
                    if(mapWOIdtoUploadedDocumentNames.containsKey(mapContentDocIdToWoId.get(eachCV.ContentDocumentId))) {
                        mapWOIdtoUploadedDocumentNames.get(mapContentDocIdToWoId.get(eachCV.ContentDocumentId)).add(eachCV.Document_Type_fileupload__c);
                    }
                    else{
                        set<String> emptySet=new set<String>();
                        emptySet.add(eachCV.Document_Type_fileupload__c);
                        mapWOIdtoUploadedDocumentNames.put(mapContentDocIdToWoId.get(eachCV.ContentDocumentId),emptySet);
                    }
                }
            }
        }
        ilib_LogEvent.message('DCP-43185-mapWOIdtoUploadedDocNames: '+mapWOIdtoUploadedDocumentNames);
        ilib_LogEvent.message('DCP-43185-mapContentDocIdToWoId: '+mapContentDocIdToWoId);
        return mapWOIdtoUploadedDocumentNames;
    }
    /**
    * @author Raja Siva Krishna
    * @date   25-Nov-2020
    * @description  DCP-43185 - get requird documents as a map of work order id and set of document names
    **/
    public static Map<Id,set<String>> getWoToRequiredDocumentsToBeUploaded(set<Id> woIds, Map<id,String> mapProductIdToProductGrp, Map<Id,Id> mapWOIdtoWOProductId,String keyParam,Map<Id, SObject> oldRecords, Map<Id,String> mapWOIdtoRepairProtocol) {//Pooja :49644 : Map<Id,String> mapWOIdtoRepairProtocol
        Map<Id,set<String>> mapWOIdtoWDActivity=new Map<id,set<String>> ();
        set<String> setofWDActivity = new set<String>();
        List<Work_Order_Activity_Rules__c> listWOAcitivityRules = new List<Work_Order_Activity_Rules__c>();
        Map<id,set<String>> mapWOIdToRequiredDocuments = new Map<id,set<String>>();
        
        populateWDActivityCollections(keyParam, oldRecords, mapWOIdtoWDActivity, setofWDActivity);
        
        if(!setofWDActivity.isEmpty() || !mapWOIdtoRepairProtocol.isEmpty()) { // Pooja: 49644: Or condn
            listWOAcitivityRules = WorkOrders.lstWOActivityRules;
        }
       
        for(Id eachWO:woIds) {
            set<String> setofWOWDActivity = new set<String>();
            String workOrderProductId ='';
            String workOrderProductGrp = '';
            String workOrderRepairProtocol = '';//Pooja :DCP-49644
            Set<String> setRepairProtocolWOAR = new Set<String>();//Pooja :DCP-49644
            List<String> repairProtocolsSelLst= new List<String>();//Pooja :DCP-49644
           
            
            set<String> requiredDocsToUpload = new set<String>();
            if(mapWOIdtoWDActivity.containskey(eachWO)) {
                setofWOWDActivity = mapWOIdtoWDActivity.get(eachWO);
            }
            if(mapWOIdtoWOProductId.containsKey(eachWO)) {
                workOrderProductId=mapWOIdtoWOProductId.get(eachWO);
            }
            if(mapProductIdToProductGrp.containsKey(workOrderProductId)) {
                workOrderProductGrp=mapProductIdToProductGrp.get(workOrderProductId);
            }
            
            //Pooja :DCP-49644 Start
            if(mapWOIdtoRepairProtocol.containsKey(eachWO)) {
                workOrderRepairProtocol=mapWOIdtoRepairProtocol.get(eachWO);
                repairProtocolsSelLst=workOrderRepairProtocol.split(';');
            }
            //Pooja :DCP-49644 End
            iterateActivityRules(listWOAcitivityRules, setofWOWDActivity, workOrderProductId, requiredDocsToUpload, setRepairProtocolWOAR, workOrderProductGrp, repairProtocolsSelLst);
            mapWOIdToRequiredDocuments.put(eachWO,requiredDocsToUpload);
        }
        return mapWOIdToRequiredDocuments;
    }

    /**
    * @author Karthik Rayani
    * @date   20-Nov-2020
    * @description  DCP-41619 - validating work details with work order activity rules
    * 
    **/
    public static void verifyWorkOrderActivityRules(List<sObject> records) {
        //Initialization of variables.   
        List<SVMXC__Service_Order__c> lstWordOrder = new List<SVMXC__Service_Order__c>();
        set<Id> setWordOrderIds = new set<Id>();
        set<Id> setProductIds = new set<Id>();
        Map<Id , String> mapProductGroups = new Map<Id , String>();
        Map<Id , List<String>> mapActType = new Map<Id , List<String>>();
        List<String> lstActivityType = new List<String>();
        Id woServiceSupportRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Service Support').getRecordTypeId();
        Id woFieldServiceRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId();
        List<SVMXC__Service_Order__c> lstValidationWorkOrder = new List<SVMXC__Service_Order__c>();

        //Looping over work order and storing product and work order Id's. 
        for(SVMXC__Service_Order__c objWorkOrder:(List<SVMXC__Service_Order__c>)records) {
            //condition for non cancelled work order of Field service and service support record types and having No_Calibrated_Tools_Used__c as false. 
            if(objWorkOrder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED 
                    && objWorkOrder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED 
                    && (String.isBlank(objWorkOrder.Reason_for_not_Debriefing_Tool__c) || !objWorkOrder.No_Calibrated_Tools_Used__c)
                    && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
                    && (objWorkOrder.RecordTypeId == woServiceSupportRecordTypeId || objWorkOrder.RecordTypeId == woFieldServiceRecordTypeId)) {
                lstWordOrder.add(objWorkOrder);
                setWordOrderIds.add(objWorkOrder.Id);
                setProductIds.add(objWorkOrder.SVMXC__Product__c);              
            }
        }
        lstValidationWorkOrder = lstWordOrder.clone();
        //getting product group from product. 
        for(Product2 objProd  : WorkOrders.lstProducts) {
            mapProductGroups.put(objProd.Id,objProd.Product_Group__c);
        }
        //looping over work details and storing activity type. 
        storeActivityType(setWordOrderIds, lstActivityType, mapActType);

        //querying work order activity rules tables having specific product, product group , activity type. 
        for (Work_Order_Activity_Rules__c objWOActivityRule: WorkOrders.lstWOActivityRules) {
            integer index = 0;
            //looping over work order and checking with work order activity rules record for valid match. if found adding the error message. 
            for(SVMXC__Service_Order__c objWorkOrder : lstWordOrder) {
                List<String> lstActType =new List<String>( mapActType.get(objWorkOrder.Id));

                if(objWorkOrder.Number_of_Tools__c == 0 && !UserInfo.getName().containsIgnoreCase(WorkOrders.STRING_SNAP_INTEGRATION_USER) 
                        && (objWorkOrder.SVMXC__Product__c == objWOActivityRule.Product_Code__c || mapProductGroups.get( objWorkOrder.SVMXC__Product__c) == objWOActivityRule.Product_Group__c) 
                        &&  lstActType.contains(objWOActivityRule.Activity_Type__c) && objWOActivityRule.Is_Tool_Debrief_Mandatory__c) {
                    objWorkOrder.addError(Label.ReasonForNotDebriefingTool);
                    if(!lstValidationWorkOrder.isEmpty() && lstValidationWorkOrder.size() > Index)
                        lstValidationWorkOrder.remove(index);
                        
                }
                index = index +1;     
            }
        }

        String profileName = getProfileName();

        // for the delta work order checking with pervious condition. Earlier this was in SFM validation rule "CheckCalibratedToolsUsedWhenUnchecked".  
        throwCalibratedErrorMessage(lstValidationWorkOrder, woServiceSupportRecordTypeId, woFieldServiceRecordTypeId, profileName);
    }

    /**
    * @author Raja Siva Krishna
    * @date   25-Nov-2020
    * @description  DCP-43185 - validating reason for missing documentation & uploaded documents before completing the WO
    **/
    private static void missingDocumentation(List<sObject> records, Map<Id, SObject> oldRecords, Set<Id> setWOIds, Map<Id,String> mapWOIdtoRepairProtocol, Map<Id,Id> mapWOIdtoWOProdId) {
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)); 
            if(objOldWorkOrder!=null && objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c 
                    && objWorkOrder.SVMXC__Order_Status__c==WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED) {
                setWOIds.add(objWorkOrder.Id);
                 //Pooja: DCP:49644 Start
                if(!mapWOIdtoRepairProtocol.containsKey(objWorkOrder.Id) && objWorkOrder.Repair_protocols__c != null 
                        && objWorkOrder.Repair_protocols__c != WorkOrders.STRING_RP_NOT_APPLICABLE) {
                    mapWOIdtoRepairProtocol.put(objWorkOrder.Id,objWorkOrder.Repair_protocols__c);
                }
                ilib_LogEvent.message('Inside verifyWOForMissingDocumentation mapWOIdtoRepairProtocol-->'+mapWOIdtoRepairProtocol);
                //Pooja: DCP:49644 END

                if(!mapWOIdtoWOProdId.containsKey(objWorkOrder.Id)) {
                    mapWOIdtoWOProdId.put(objWorkOrder.Id,objWorkOrder.SVMXC__Product__c);
                }
            }
        }
    }

    /**
    * @author Raja Siva Krishna
    * @date   25-Nov-2020
    * @description  DCP-43185 - validating reason for missing documentation & uploaded documents before completing the WO
    **/
    private static void throwError(SVMXC__Service_Order__c objOldWorkOrder, Map<Id,set<String>> mapWOIdtoUploadedDocNames, Map<id,set<String>> mapWOIdToRequiredDocs, SVMXC__Service_Order__c objWorkOrder) {
        Set<String> lstUploadedDocs = new set<String>();
        Set<String> setDocsNotUploaded = new set<String>();
        set<String> setReqDocs  = new set<String>();
        ilib_LogEvent.message('DCP-43185-objWorkOrder.Record_Type__c:'+objWorkOrder.Record_Type__c);
        ilib_LogEvent.message('DCP-43185-objWorkOrder.SVMXC__Order_Status__c:'+objWorkOrder.SVMXC__Order_Status__c);
        ilib_LogEvent.message('DCP-43185-objOldWorkOrder.SVMXC__Order_Status__c:'+objOldWorkOrder);
        if(objOldWorkOrder!=null && objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c 
                && objWorkOrder.SVMXC__Order_Status__c==WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
                && (objWorkOrder.Record_Type__c==System.Label.WorkOrderRecordTypeFieldService 
                    || objWorkOrder.Record_Type__c==System.Label.WorkOrderRecordTypeServiceSupport)) {
            if(String.isBlank(objWorkOrder.Reason_for_Missing_Documentation__c)) {
                ilib_LogEvent.message('DCP-43185-Inside empty for reason');
                if(mapWOIdtoUploadedDocNames.containsKey(objWorkOrder.Id)) {
                    lstUploadedDocs=mapWOIdtoUploadedDocNames.get(objWorkOrder.Id);
                }
                if(mapWOIdToRequiredDocs.containsKey(objWorkOrder.Id)) {
                    setReqDocs = mapWOIdToRequiredDocs.get(objWorkOrder.Id);
                }
                for(String eachReqDoc:setReqDocs) {
                    if(!lstUploadedDocs.contains(eachReqDoc)) {
                        setDocsNotUploaded.add(eachReqDoc);
                    }
                }
                if(!setDocsNotUploaded.isEmpty()) {
                    objWorkOrder.addError(System.Label.WO_Trigger_Documents_Upload_Error_Message);
                }
            } 
        }
        ilib_LogEvent.message('DCP-43185-setDocsNotUploaded:'+setDocsNotUploaded);
        ilib_LogEvent.message('DCP-43185-lstUploadedDocs:'+lstUploadedDocs);
        ilib_LogEvent.message('DCP-43185-setReqDocs:'+setReqDocs);
    }

    /**
    * @author Raja Siva Krishna
    * @date   25-Nov-2020
    * @description  DCP-43185 - validating reason for missing documentation & uploaded documents before completing the WO
    **/
    private static void populateWDActivityCollections(String keyParam, Map<Id, SObject> oldRecords, Map<Id,set<String>> mapWOIdtoWDActivity, 
                                                    set<String> setofWDActivity) {
        for(SVMXC__Service_Order_Line__c eachWD: WorkOrders.lstworkDetails) {
            if(eachWD.SVMXC__Line_Type__c==WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && eachWD.SVMXC__Line_Status__c!=WorkOrders.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
                SVMXC__Service_Order__c objOldWOrder = (SVMXC__Service_Order__c)(oldRecords.get(eachWD.SVMXC__Service_Order__c)); 
                ilib_LogEvent.message('DCP-43185-eachWD.CreatedDate:'+eachWD.CreatedDate);
                ilib_LogEvent.message('DCP-43185-objOldWOrder.Latest_Completion_Date_Time__c:'+objOldWOrder.Latest_Completion_Date_Time__c);
                if(keyParam=='ReopenWO' && oldRecords.containskey(eachWD.SVMXC__Service_Order__c) && eachWD.CreatedDate>objOldWOrder.Latest_Completion_Date_Time__c) { 
                    if(mapWOIdtoWDActivity.containsKey(eachWD.SVMXC__Service_Order__c)) {
                        mapWOIdtoWDActivity.get(eachWD.SVMXC__Service_Order__c).add(eachWD.SVMXC__Activity_Type__c);
                    } else {
                        set<String> emptySet = new set<String>();
                        emptySet.add(eachWD.SVMXC__Activity_Type__c);
                        mapWOIdtoWDActivity.put(eachWD.SVMXC__Service_Order__c,emptySet);
                    }
                    if(eachWD.SVMXC__Activity_Type__c!=null) {
                        setofWDActivity.add(eachWD.SVMXC__Activity_Type__c);
                    }
                    ilib_LogEvent.message('DCP-43185-Reopen-setofWDActivity:'+setofWDActivity);
                } else if(keyParam==WorkOrders.STRING_OPEN_WO) {
                    if(mapWOIdtoWDActivity.containsKey(eachWD.SVMXC__Service_Order__c)) {
                        mapWOIdtoWDActivity.get(eachWD.SVMXC__Service_Order__c).add(eachWD.SVMXC__Activity_Type__c);
                    } else {
                        set<String> emptySet = new set<String>();
                        emptySet.add(eachWD.SVMXC__Activity_Type__c);
                        mapWOIdtoWDActivity.put(eachWD.SVMXC__Service_Order__c,emptySet);
                    }
                    if(eachWD.SVMXC__Activity_Type__c!=null) {
                        setofWDActivity.add(eachWD.SVMXC__Activity_Type__c);
                    }
                    ilib_LogEvent.message('DCP-43185-open-setofWDActivity:'+setofWDActivity);
                }
            }
        }
    }

    /**
    * @author Raja Siva Krishna
    * @date   25-Nov-2020
    * @description  DCP-43185 - validating reason for missing documentation & uploaded documents before completing the WO
    **/
    private static void iterateActivityRules(List<Work_Order_Activity_Rules__c>  listWOAcitivityRules, set<String> setofWOWDActivity, String workOrderProductId, 
                                                    set<String> requiredDocsToUpload, Set<String> setRepairProtocolWOAR, 
                                                    String workOrderProductGrp, List<String> repairProtocolsSelLst) {
        List<String> lstRepairProtocolWOAR= new List<String>();//Pooja :DCP-49644

        for(Work_Order_Activity_Rules__c eachWOAR : listWOAcitivityRules) {
            if(setofWOWDActivity.contains(eachWOAR.Activity_Type__c) && eachWOAR.Required__c && (workOrderProductId == eachWOAR.Product_Code__c
                                    || workOrderProductGrp==eachWOAR.Product_Group__c) && String.isEmpty(eachWOAR.Repair_Protocol__c)) {  //DCP-58614 [only process non Repair Protocol rules]
                if(eachWOAR.Document_Name__c !=null) {
                    requiredDocsToUpload.add(eachWOAR.Document_Name__c);
                }
            }
            
            //Pooja : DCP-49644 Start
            if(eachWOAR.Repair_Protocol__c!=null && eachWOAR.Required__c && workOrderProductGrp == eachWOAR.Product_Group__c) {  //DCP-58614 [match rules as per product group]
                lstRepairProtocolWOAR = eachWOAR.Repair_Protocol__c.split(';');//split val can only be addded in list
                setRepairProtocolWOAR.addAll(lstRepairProtocolWOAR);
                setRepairProtocolWOAR.retainAll(repairProtocolsSelLst);

                if(!setRepairProtocolWOAR.isEmpty() && eachWOAR.Document_Name__c != null) {
                    requiredDocsToUpload.add(eachWOAR.Document_Name__c);
                }
                setRepairProtocolWOAR.clear();// Clearing thelist value added to the set
            }
            //Pooja : DCP-49644 End
        }
    }

    /**
    * @author Raja Siva Krishna
    * @date   25-Nov-2020
    * @description  Store activity Type
    **/
    private static void storeActivityType(set<Id> setWordOrderIds, List<String> lstActivityType, Map<Id , List<String>> mapActType) {
        for(SVMXC__Service_Order_Line__c objWorkDetail: WorkOrders.lstworkDetails) {       
            if(setWordOrderIds.contains(objWorkDetail.SVMXC__Service_Order__c) && objWorkDetail.SVMXC__Line_Status__c !='Canceled') {
                lstActivityType.add(objWorkDetail.SVMXC__Activity_Type__c);
                List<String> listActType = new  List<String>();
                if(mapActType.containsKey(objWorkDetail.SVMXC__Service_Order__c)) {
                    listActType = mapActType.get(objWorkDetail.SVMXC__Service_Order__c);
                }       
                listActType.add(objWorkDetail.SVMXC__Activity_Type__c);
                mapActType.put(objWorkDetail.SVMXC__Service_Order__c , listActType);

            }
        }
    }

    /*******************************************************************************************************
     * @description Rteurn Profile Name
     * @return String
     */
    private static String getProfileName() {
        if(UserInfo.getName() != WorkOrders.STRING_AUTOMATED_PROCESS) {
            //CMCM-5307 - Add empty check for WO trigger Optimization
            if(!String.isBlank(WorkOrders.loggedInUserProfileName) || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                userProfileName = WorkOrders.loggedInUserProfileName;
            }
        }
        return userProfileName;
    }

    /*******************************************************************************************************
     * @description Throw Error - Please enter a Tool (if used) or indicate "No Calibrated Tools Used" via the checkbox.
     * @return String
     */
    private static void throwCalibratedErrorMessage(List<SVMXC__Service_Order__c> lstValidationWorkOrder, Id woServiceSupportRecordTypeId, 
                                                Id woFieldServiceRecordTypeId, String profileName) {
        for(SVMXC__Service_Order__c objWorkOrderMaster : lstValidationWorkOrder) {
            if(objWorkOrderMaster.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED  && !objWorkOrderMaster.No_Calibrated_Tools_Used__c 
                && (objWorkOrderMaster.RecordTypeId == woServiceSupportRecordTypeId || objWorkOrderMaster.RecordTypeId == woFieldServiceRecordTypeId) 
                && objWorkOrderMaster.Number_of_Tools__c == 0  && !UserInfo.getName().containsIgnoreCase(WorkOrders.STRING_SNAP_INTEGRATION_USER) 
                && !profileName.equalsIgnoreCase(WorkOrders.STRING_SYSTEM_ADMINISTRATOR) && String.isBlank(objWorkOrderMaster.Abandoned_Reason__c)) {
                    objWorkOrderMaster.addError(Label.Check_Calibrated_Tools_Used_When_Unchecked);
            }
        }
    }

}