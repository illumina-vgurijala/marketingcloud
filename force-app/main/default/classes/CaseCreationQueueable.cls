/***************************************************************************************************************************************
* NAME         : CaseCreationQueueable
* DESCRIPTION  : Automatic Case Creation from Order Line Item
* @AUTHOR      : Gopinath Reddy
* @DATE        : 29-Jan-2020
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Gopinath Reddy           29-Jan-2019         Initial Version
* Akshay Mohan             16-Apr-2019         INC0265244 & INC0266068 Changes in case subject and creation restriction
* Avina                    16-Jun-2022         CMSI-68,Added Instrumentation
* Gladis                   17-Jun-2022         DCP-45368 Added IP mapping on Case by adding methods fetchIPFromOrderLineItem,mapInstalledProductToCase
* Sagar Madkaikar          22-Jun-2022         DCP-45368 Created new method createAdditionalProductRecords() and called it from end of execute method
* Avina                    16-Jun-2022         CMSI-69,Added Instrumentation
* Dhairya Shah             17 April 2024       CMCM-6760 - Removed the method 'createAdditionalProductRecords()'
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public without sharing class CaseCreationQueueable implements System.Queueable {
    
    private static final String LOG_TITLE = 'CaseCreationQueueable';//CMSI-69
    private static final String TECH_SUPPORT_QUEUE = 'TS_LIMS';
    private static final String CSGC_CUST_SERVICE_QUEUE = 'CS_GC_Customer_Service';
    // POL-18 AC9 keywords replaced from APJ to AMEA
    private static final String CSAMEA_CUST_SERVICE_QUEUE = 'CS_AMEA_Customer_Service'; 
    // POL-18 AC9 keywords replaced from EMEA to EUR
    private static final String CSEUR_CUST_SERVICE_QUEUE = 'CS_EUR_Customer_Service';
    private static final String CSAMRCUSTSERVICEQUEUE = 'CS_AMR_Customer_Service';	
    private static final Integer SIZE_CHECK = 2; 

    //constants
    private static final String ORDER_NUMBER = 'Order Number: ';
    private static final String ORDER_LINE_NUMBER = 'Order Line Number: ';
    private static final String SOLD_TO = 'Sold To: ';
    private static final String ULTIMATE_CONSIGNEE = 'Ultimate Consignee: ';
    private static final String SPACE = ' ';
    
    
    Map<String,Id> mapRegionToGroupId = new Map<String,Id>();
    Map<String,Apttus_Config2__OrderLineItem__c> mapOLIExtIdtoOLI = new Map<String,Apttus_Config2__OrderLineItem__c>();
    public Set<String> setErpLineNo {get;set;}
    Integer intRetryCount;
    String techSupportQueueId;
    Map<String,String> mapOLIInstalledProduct = new Map<String,String>();//DCP-45368
    Map<String,String> mapOLIERPToProduct = new Map<String,String>();//DCP-45368 : This will hold the ERP Line Number with the Dragon Product ID
   /*
    * Constructor
    */
    public CaseCreationQueueable(Set<String> setErpLineNo,Integer intRetryCount){
        this.setErpLineNo = setErpLineNo;
        this.intRetryCount = intRetryCount;
    }
   
   /*
    * Description - execute method of this queueable class
    */
    public void execute(System.QueueableContext qc){ 
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SERVICE);//CMSI-69
        ilib_LogEvent.push(LOG_TITLE + '.execute()');//CMSI-69
        try{
               // POL-18 AC9 keywords replaced from EMEA to EUR And  APJ WITH AMEA
                List<Group> lstGroups = new GroupsSelector().getQueueIdsbyDevName(new set<String> { TECH_SUPPORT_QUEUE,CSAMRCUSTSERVICEQUEUE,CSGC_CUST_SERVICE_QUEUE,CSAMEA_CUST_SERVICE_QUEUE,CSEUR_CUST_SERVICE_QUEUE});           

            //Populate Map with territory region as key and group id as value.
            for(Group oneGroup: lstGroups ) {
                if(TECH_SUPPORT_QUEUE.equals(oneGroup.DeveloperName))
                    techSupportQueueId = oneGroup.id;
                if(CSAMRCUSTSERVICEQUEUE.equals(oneGroup.DeveloperName))
                    mapRegionToGroupId.put(System.Label.TerritoryRegionAMR,oneGroup.id);
                if(CSGC_CUST_SERVICE_QUEUE.equals(oneGroup.DeveloperName))
                    mapRegionToGroupId.put(System.Label.TerritoryRegionChina,oneGroup.id);
                if(CSAMEA_CUST_SERVICE_QUEUE.equals(oneGroup.DeveloperName))
                    mapRegionToGroupId.put(System.Label.TerritoryRegionAMEA,oneGroup.id); // POL-18 AC9 keywords replaced from APJ to AMEA
                if(CSEUR_CUST_SERVICE_QUEUE.equals(oneGroup.DeveloperName))
                    mapRegionToGroupId.put(System.Label.TerritoryRegionEUR,oneGroup.id); // POL-18 AC9 keywords replaced from EMEA to EUR
            }
            
            ilib_LogEvent.info('mapRegionToGroupId' + mapRegionToGroupId);//CMSI-69
            
            List<Case> lstCase = new List<Case>();
            Map<String,Case> mapOLIExtIdtoCase = new Map<String,Case>();
            ilib_LogEvent.info('setErpLineNo -->' + setErpLineNo);//CMSI-69
            List<Apttus_Config2__OrderLineItem__c> lstOrderLines=new ApttusOrderLineItemsSelector().selectOLIbyERPHeaderContract(setErpLineNo);
            //DCP-45368 starts
            if(!lstOrderLines.isEmpty()) {
                ilib_LogEvent.info('45368-lstOrderLines-->'+lstOrderLines);
                fetchIPFromOrderLineItem(lstOrderLines); 
            }
            //DCP-45368 ends
            ilib_UpsertHelpers.OrderLineItemUnitOfWorkHelper objOLIWork=new ilib_UpsertHelpers.OrderLineItemUnitOfWorkHelper();
            ilib_SObjectUnitOfWork objUnitOfWork=new ilib_SObjectUnitOfWork(new List<Schema.SObjectType> { Apttus_Config2__Order__c.SObjectType, Apttus_Config2__OrderLineItem__c.SObjectType});
            objUnitOfWork.registerWork(objOLIWork);
            
            Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Label.CaseRecordTypeServiceRequest).getRecordTypeId();
            
            Date goLiveDate = Date.newInstance(2020,4,12);
            List<String> lstSplit = Label.Informatics_Go_Live_Date.split('-');
            if(lstSplit.size()==3)
                goLiveDate=Date.newInstance(Integer.valueOf(lstSplit[0]),Integer.valueOf(lstSplit[1]),Integer.valueOf(lstSplit[2]));
                ilib_LogEvent.info('goLiveDate: ' + goLiveDate);//CMSI-69
            for(Apttus_Config2__OrderLineItem__c orderLineItem : lstOrderLines){
                ilib_LogEvent.message('My OLI Renewal Subscription Value -->'+orderLineItem);//CMSI-69
                //function call to set case condition according to orderlineitem.
                String stringCaseCondition = InformaticProductsService.checkCaseTriggerConditions(orderLineItem);
                ilib_LogEvent.message('stringCaseCondition -->' + stringCaseCondition);//CMSI-69
                mapOLIExtIdtoOLI.put(orderLineItem.ERP_Line_Number_Id__c , orderLineItem);

                // INC0266068 check if order line was created post go-live 
                Boolean booCreatedAfterGoLive=goLiveDate.daysBetween(orderLineItem.CreatedDate.Date())>0;
                ilib_LogEvent.message('booCreatedAfterGoLive: ' + booCreatedAfterGoLive);//CMSI-69
                
                //setting up case according to orderlineitem and case condition.
                if(booCreatedAfterGoLive && String.isNotBlank(stringCaseCondition) && String.isBlank(orderLineItem.Case_Id__c)){ 

                    Case oneCase = new Case();
                    oneCase.Status = System.Label.CaseStatusInitiated;
                    oneCase.Sub_Type__c = System.Label.CaseSubTypeSalesSupport;
                    oneCase.RecordTypeId = devRecordTypeId;
                    oneCase.Origin = System.Label.CaseOrigin;
                    oneCase.ContactId = orderLineItem.Registrant_Contact__c;
                    oneCase.AccountId = orderLineItem.Ultimate_Consignee__c;
                    oneCase.SVMXC__Product__c = orderLineItem.Apttus_Config2__ProductId__c;
                    oneCase.Order_Line_External_Id__c = orderLineItem.ERP_Line_Number_Id__c;

                    if(InformaticProductsService.LIMS_TRIGGER1.equals(stringCaseCondition))
                        oneCase = limsTrigger1(oneCase, orderLineItem);
                    else if(InformaticProductsService.LIMS_TRIGGER2.equals(stringCaseCondition)) 
                        oneCase = limsTrigger2(oneCase, orderLineItem);
                    else if( InformaticProductsService.DRAGEN_TRIGGER1.equals(stringCaseCondition))
                        oneCase = dragenTrigger1(oneCase, orderLineItem); 
                    else if( InformaticProductsService.DRAGEN_TRIGGER2.equals(stringCaseCondition))
                        oneCase = dragenTrigger2(oneCase, orderLineItem);
                    lstCase.add(oneCase);
                    mapOLIExtIdtoCase.put(orderLineItem.ERP_Line_Number_Id__c, oneCase);
                }
            }
            ilib_LogEvent.info('mapOLIExtIdtoOLI' +  mapOLIExtIdtoOLI);//CMSI-69	
            ilib_LogEvent.info('mapOLIExtIdtoCase' +  mapOLIExtIdtoCase);//CMSI-69
            ilib_LogEvent.info('My List of Cases Size:'+lstCase.size());//CMSI-69
            if(!lstCase.isEmpty()){
                ilib_LogEvent.info('45368-lstCase-->'+lstCase);
              /*  List<Database.UpsertResult> lstResults = Database.upsert(lstCase, Case.Fields.Order_Line_External_Id__c, false);
                for (Database.UpsertResult res : lstResults)
                    if (!res.isSuccess()) for(Database.Error err : res.getErrors()) ApexExceptions.emit('CaseCreationQueueable', err.getStatusCode() + ': ' + err.getMessage()+'\nFields: '+err.getFields(), ilib_LogEvent.SERVICE );
*/
                    upsert lstCase Case.Fields.Order_Line_External_Id__c;
            }
            if(!mapOLIExtIdtoOLI.isEmpty()){
                for(String oLIExtId: mapOLIExtIdtoOLI.keySet()){
                    if(mapOLIExtIdtoOLI.containsKey(oLIExtId) && mapOLIExtIdtoOLI.get(oLIExtId) != null){
                        Apttus_Config2__OrderLineItem__c objOLI = mapOLIExtIdtoOLI.get(oLIExtId);
                        if(mapOLIExtIdtoCase.get(oLIExtId) != null && mapOLIExtIdtoCase.get(oLIExtId).id != null){
                            objOLI.Case_Id__c = mapOLIExtIdtoCase.get(oLIExtId).id;   
                        }
                        objOLIWork.registerUpsert(objOLI);
                    }
                }
                objUnitOfWork.commitWork();
            }
        }catch(Exception e){
            ApexExceptions.emit('CaseCreationQueueable',e,ilib_LogEvent.SERVICE );
            if(!Test.isRunningTest()){
                ilib_LogEvent.pop();//CMSI-69
                ilib_LogEvent.emit();
                throw e;
            }
            
        }
        ilib_LogEvent.pop();//CMSI-69
        ilib_LogEvent.emit();//CMSI-69
    }
    //function to set case attributes for LIMS.
    private case limsTrigger1(Case oneCase, Apttus_Config2__OrderLineItem__c orderLineItem){
        ilib_LogEvent.message('orderLineItem-->: '+orderLineItem);//CMSI-69
        oneCase.Subject = System.Label.Case_Subject_Clarity_LIMS+ SPACE +addStringValue(orderLineItem.Domain_URL__c);
        oneCase.Description ='Instances to be provisioned: '+addStringValue(orderLineItem.Apttus_Config2__ProductId__r.Number_of_Instances__c) + '\n' +
                                'Instance Region: '+addStringValue(orderLineItem.Instance_Region__c) + '\n' +
                                'CS Install Confirmation Subject: Clarity LIMS Subscriptions Install Completed for Contract '+orderLineItem.ERP_Line_Number_Id__c;
        oneCase.OwnerId = techSupportQueueId;
        oneCase.Next_Steps__c = 'Email CS confirming Install completed to release invoicing hold' +'\n'+ 
                            ORDER_NUMBER+orderLineItem.Contract_Number__c + '\n' +
                            ORDER_LINE_NUMBER+ getSAPLineNumber(orderLineItem.ERP_Line_Number_Id__c)+'('+orderLineItem.Name +')\n' +
                            SOLD_TO+orderLineItem.Apttus_Config2__OrderId__r.Apttus_Config2_SoldToAccountId_ERP_Id__c +'\n'+
                            ULTIMATE_CONSIGNEE+orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee_ERP_Id__c;
        ilib_LogEvent.message('oneCase-->: '+oneCase);//CMSI-69
        return oneCase;
    }
    //function to set case attributes for LIMS.
    private case limsTrigger2(Case oneCase, Apttus_Config2__OrderLineItem__c orderLineItem){

        ilib_LogEvent.message('orderLineItem-->: '+orderLineItem);//CMSI-69
        oneCase.Subject = System.Label.Case_Subject_Clarity_LIMS_Add_On+ SPACE + addStringValue(orderLineItem.Domain_URL__c);
        oneCase.Description ='Add-On Quantity:'+orderLineItem.Apttus_Config2__Quantity__c + '\n' +
                                'Add-On Instances per Item: '+addStringValue(orderLineItem.Apttus_Config2__ProductId__r.Number_of_Instances__c) + '\n' +
                                'Add-On Users per Item:'+addStringValue(orderLineItem.Apttus_Config2__ProductId__r.Number_of_Users__c);
        oneCase.OwnerId = techSupportQueueId;
        oneCase.Next_Steps__c = 'Email CS confirming Install completed to release invoicing hold' +'\n'+ 
                                ORDER_NUMBER+orderLineItem.Contract_Number__c + '\n' +
                                ORDER_LINE_NUMBER+ getSAPLineNumber(orderLineItem.ERP_Line_Number_Id__c)+'('+orderLineItem.Name +')\n' +
                                SOLD_TO+orderLineItem.Apttus_Config2__OrderId__r.Apttus_Config2_SoldToAccountId_ERP_Id__c +'\n'+
                                ULTIMATE_CONSIGNEE+orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee_ERP_Id__c;
        ilib_LogEvent.message('oneCase-->: '+oneCase);//CMSI-69                    
        return oneCase;
    }
    //function to set case attributes for DRAGEN.
    private case dragenTrigger1(Case oneCase, Apttus_Config2__OrderLineItem__c orderLineItem){
        oneCase.Subject =  System.Label.Case_Subject_DRAGEN;
        oneCase.Description = 'DRAGEN Software License Setup' + '\n' + 
                                'Start Date: '+orderLineItem.Apttus_Config2__StartDate__c + '\n' +
                                'End Date:'+orderLineItem.Apttus_Config2__EndDate__c + '\n' +
                                'Dragen Throughput (Gb):'+addStringValue(orderLineItem.Apttus_Config2__ProductId__r.DRAGEN_Throughput_Gb__c);
        ilib_LogEvent.message('map value1 --> ' + mapRegionToGroupId.get(orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee__r.Territory_Region__c));//CMSI-69
        if(mapRegionToGroupId.containsKey(orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee__r.Territory_Region__c))
            oneCase.OwnerId = mapRegionToGroupId.get(orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee__r.Territory_Region__c); 
        oneCase.Next_Steps__c = 'Please review custom software license setup request' +'\n'+ 
                                ORDER_NUMBER+orderLineItem.Contract_Number__c + '\n' +
                                ORDER_LINE_NUMBER+ getSAPLineNumber(orderLineItem.ERP_Line_Number_Id__c)+'('+orderLineItem.Name +')\n' +
                                SOLD_TO+orderLineItem.Apttus_Config2__OrderId__r.Apttus_Config2_SoldToAccountId_ERP_Id__c +'\n'+
                                ULTIMATE_CONSIGNEE+orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee_ERP_Id__c;
        
        //DCP-45368 starts
        oneCase.SVMXC__Component__c = mapInstalledProductToCase(mapOLIInstalledProduct,orderLineItem);
        //DCP-45368 ends 
        ilib_LogEvent.message('oneCase-->: '+oneCase);//CMSI-69    
        return oneCase;
    }
    //function to set case attributes for DRAGEN.
    private Case dragenTrigger2(Case oneCase, Apttus_Config2__OrderLineItem__c orderLineItem ){
        oneCase.Subject = System.Label.Case_Subject_DRAGEN;
        oneCase.Description = 'DRAGEN Software License Setup' + '\n' + 
                                'Start Date: '+orderLineItem.Apttus_Config2__StartDate__c + '\n' +
                                'End Date:'+orderLineItem.Apttus_Config2__EndDate__c + '\n' +
                                'Dragen Throughput (Gb):'+addStringValue(orderLineItem.Apttus_Config2__ProductId__r.DRAGEN_Throughput_Gb__c);
        ilib_LogEvent.message('map value --> ' + mapRegionToGroupId.get(orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee__r.Territory_Region__c));//CMSI-69
        if(mapRegionToGroupId.containsKey(orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee__r.Territory_Region__c))
            oneCase.OwnerId = mapRegionToGroupId.get(orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee__r.Territory_Region__c);
        oneCase.Next_Steps__c = 'Server Connectivity = '+addStringValue(orderLineItem.Dragen_Connectivity__c) +'\n'+
                                'Please review order to determine if license files will need to be sent to the customer.' +'\n'+ 
                                ORDER_NUMBER+orderLineItem.Contract_Number__c + '\n' +
                                ORDER_LINE_NUMBER+ getSAPLineNumber(orderLineItem.ERP_Line_Number_Id__c)+'('+orderLineItem.Name +')\n' +
                                SOLD_TO+orderLineItem.Apttus_Config2__OrderId__r.Apttus_Config2_SoldToAccountId_ERP_Id__c +'\n'+
                                ULTIMATE_CONSIGNEE+orderLineItem.Apttus_Config2__OrderId__r.Ultimate_Consignee_ERP_Id__c;
        
        //DCP-45368 starts
        oneCase.SVMXC__Component__c = mapInstalledProductToCase(mapOLIInstalledProduct,orderLineItem);
        //DCP-45368 ends
        ilib_LogEvent.message('oneCase-->: '+oneCase);//CMSI-69
        return oneCase;
    } 

    private String getSAPLineNumber(String strExternalId){
        ilib_LogEvent.push(LOG_TITLE + '.getSAPLineNumber()');//CMSI-69
        ilib_LogEvent.info('strExternalId-->: '+strExternalId);//CMSI-69
        List<String> lstValues = strExternalId.split('_');
        ilib_LogEvent.info('lstValues-->: '+lstValues);//CMSI-69
        
        
        if(lstValues.size()!=SIZE_CHECK){ 
            ilib_LogEvent.pop();//CMSI-69
            return '';
        }
         else {
            ilib_LogEvent.pop();//CMSI-69
            return lstValues[1];
         }
    }
    
    private String addStringValue(Object objValue){
        ilib_LogEvent.push(LOG_TITLE + '.addStringValue()');//CMSI-69
        ilib_LogEvent.info('objValue-->: '+objValue);//CMSI-69
        String strValue =objValue==null?null:String.valueOf(objValue);
        ilib_LogEvent.pop();//CMSI-69
        return String.isNotBlank(strValue ) ? strValue : 'N/A';
    }

    /**
    *  @AUTHOR - Gladis
    *  @RETURN - Map<String,String>
    *  @DESCRIPTION - DCP-45368 this method will return Installed Product Id.
    **/
    private void fetchIPFromOrderLineItem(List<Apttus_Config2__OrderLineItem__c> lstOrderLines) {
        ilib_LogEvent.push(LOG_TITLE + '.fetchIPFromOrderLineItem()');
        ilib_LogEvent.info('45368-lstOrderLines in fetchIPFromOrderLineItem method-->'+lstOrderLines);
        Set<String> setEquipmentIds = new Set<String>();
        try {
            for(Apttus_Config2__OrderLineItem__c orderLineItem : lstOrderLines) {
                if(String.isnotblank(orderLineItem.Equipment_Id__c)) {
                    setEquipmentIds.add(orderLineItem.Equipment_Id__c);
                }
            }
            List<SVMXC__Installed_Product__c> lstInstalledProduct =  new InstalledProductsSelector().selectInstalledProductsFromEquipmentId(setEquipmentIds);
            ilib_LogEvent.info('45368-lstInstalledProduct-->'+lstInstalledProduct);
            
            for(SVMXC__Installed_Product__c objIP: lstInstalledProduct) {
                if(setEquipmentIds.contains(objIP.ERP_Equipment_ID__c)) { 
                    mapOLIInstalledProduct.put(objIP.ERP_Equipment_ID__c, objIP.Id);
                }
            }
            ilib_LogEvent.info('45368-mapOLIInstalledProduct-->'+mapOLIInstalledProduct);
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /**
    *  @AUTHOR - Gladis
    *  @RETURN - String
    *  @DESCRIPTION - DCP-45368 method to get Installed Product Id from given Order line item and to map to Case's IP.
    **/
    private String mapInstalledProductToCase(Map<String, String> mapOLIInstalledProduct, 
                                                        Apttus_Config2__OrderLineItem__c orderLineItem) {
        ilib_LogEvent.push(LOG_TITLE + '.mapInstalledProductToCase()');
        ilib_LogEvent.info('45368-orderLineItem in mapInstalledProductToCase method-->'+orderLineItem);
        ilib_LogEvent.info('45368-mapOLIInstalledProduct in mapInstalledProductToCase method-->'+mapOLIInstalledProduct);
        String strInstalledProductId = null;
        if(mapOLIInstalledProduct.containsKey(orderLineItem.Equipment_Id__c)) {
            strInstalledProductId = mapOLIInstalledProduct.get(orderLineItem.Equipment_Id__c);
        }
        //Populate Map to hold OLI's ERP Line Number with respective Dragen Product ID.
        mapOLIERPToProduct.put(orderLineItem.ERP_Line_Number_Id__c,orderLineItem.Apttus_Config2__ProductId__c);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        ilib_LogEvent.info('45368-strInstalledProductId in mapInstalledProductToCase method-->'+strInstalledProductId);
        return strInstalledProductId;
    }
}