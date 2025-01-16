/***************************************************************************************************************************************
* NAME   : ContentDocumentLinks
* DESCRIPTION  : Domain class for ContentDocumentLink.
*                Added logic for DCP-804  
* @AUTHOR : Debalina
* @DATE   : 08-Jun-2018  
*  
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
*   Soumya              05-Jun-2018             Added logic for DCP-1116 to prevent adding files when work order status is closed.
*   Debalina            08-Jun-2018             Initial Version.
*   Soumya              14-Jun-2018             Changes done as per GIS review comments
*   Debalina            19-June-2018            804 Code review comment by GIS
*   Prem Ranjan         15-Nov-2021             DCP-50569 Territory Planning: Reporting ability T/F "Is file attached?"
*   Shivani Jain        04-Apr-2022             DCP-49914 Optimize WeChat case and follower management in SFDC
*   Nidhi               04-March-2024           [CMCM-3329] [CP] - Enable Access to Attachments on FAN's
****************************************************************************************************************************************/ 

public class ContentDocumentLinks extends ilib_SObjectDomain{
    public static final String WORK_ORDER_STATUS_CLOSED = 'Closed'; 
    public static final String POL_ID_PREFIX = 'a10'; 	
    public static final String ACCOUNT_PLAN = 'Account_Plan__c'; 
    public static final String PLAN = 'Plan__c'; 
    public static final String COMMENT = 'Comment__c'; //DCP-49914 
    public static final String ALLUSERS = 'AllUsers';//DCP-49914
    public static final String DESIRED_OBJECT_NAME = 'Field_Action_Notification__c';
    /*
     * Constructor 
     */
    public ContentDocumentLinks(List<ContentDocumentLink> sObjectList)
    {
        super(sObjectList);
    }
    
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
         * Constructor
         */             
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ContentDocumentLinks(sObjectList);
        }
    }
    
    /* METHOD NAME    : onBeforeInsert
    * DEVELOPER      : Soumya
    * DESCRIPTION    : Opertaions before record insert
    * RETURN TYPE    : NA
    * PARAMETER      : NA
    */
    public override void onBeforeInsert(){
        preventFileInsertOnClosedWO();
        provideVisibilitytoFAN(records);
    }
    
    /* METHOD NAME    : onAfterInsert
    * DEVELOPER      : Debalina
    * DESCRIPTION    : Opertaions after record insert
    * RETURN TYPE    : NA
    * PARAMETER      : NA
    */
    public override void onAfterInsert()
    {
        //Map of ContentDocumentLink record and  Work Order Id
        Map<ContentDocumentLink, Id> mapContentDocLinkToWOId = new Map<ContentDocumentLink, Id>();
		//Content Document Id to POL Id
		Map<Id, SVMXC__RMA_Shipment_Line__c> mapCDIdToPOL = new Map<Id, SVMXC__RMA_Shipment_Line__c>();
		 
        //Set of Work Order Ids
        Set<Id> setWorkOrderId = new Set<Id>();
		//Set of POL Id
		Set<Id> setPOLId = new Set<Id>();
        Map<Id, Id> mapContentIdtoComment = new Map<Id, Id>();  //DCP-49914
		
        //Setting that contains Linked Entity Object's API name
        Service_Document_Setting__c objSetting = Service_Document_Setting__c.getInstance();
        for(ContentDocumentLink objCDL : (List<ContentDocumentLink>)records) {
		    String myIdPrefix = String.valueOf(objCDL.LinkedEntityId).substring(0,3); 
            String objectName = ServiceUtilityCollection.getAPIName(objCDL.LinkedEntityId); //DCP-49914
            if(myIdPrefix == POL_ID_PREFIX){
		    setPOLId.add(objCDL.LinkedEntityId);
            }
            if(String.isNotBlank(objSetting.LinkedEntitySObjectName__c) 
                && objSetting.LinkedEntitySObjectName__c.equals(objectName)) //DCP-49914
            {
                mapContentDocLinkToWOId.put(objCDL,objCDL.LinkedEntityId);
                setWorkOrderId.add(objCDL.LinkedEntityId);
            }
            //START - DCP-49914
            if(objectName == COMMENT) {
                mapContentIdtoComment.put(objCDL.ContentDocumentId, objCDL.LinkedEntityId);
            }
            //END - DCP-49914
        }
		//Added setPOLId Empty check so that the query runs only if the  content is linked to POL. This query is currently being triggered for all types of content insertion
		if(Schema.sObjectType.SVMXC__RMA_Shipment_Line__c.isAccessible() && !setPOLId.isEmpty()){
		map<id, SVMXC__RMA_Shipment_Line__c> mapIDtoPOL = new map<id, SVMXC__RMA_Shipment_Line__c>(new PartsOrderLineSelector().selectPartsOrderLineById(setPOLId));
        for(ContentDocumentLink objCDL : (List<ContentDocumentLink>)records){
            mapCDIdToPOL.put(objCDL.ContentDocumentId, mapIDtoPOL.get(objCDL.LinkedEntityId));
        }
        
		if(!setPOLId.isEmpty()){
           insertFromPOLToIP(mapCDIdToPOL,setPOLId);
        }
		
		}
        // Rule 1 link Content uploaded to WO to Account and Installed Product
        if(!setWorkOrderId.isEmpty()){
            insertFromWOToParent(mapContentDocLinkToWOId,setWorkOrderId);
        }
        Map<Id,ContentDocumentLink> contentDocMap = new Map<Id,ContentDocumentLink>((List<ContentDocumentLink>)records);//DCP-50569
        PlanAndAccPlanAttachmentHandler.populateFieldsOnPlan(contentDocMap);//DCP-50569

        //START - DCP-49914
        if(!mapContentIdtoComment.isEmpty()) {
            insertFromCommentToCase(mapContentIdtoComment); 
        }
        //END - DCP-49914
    }
 
    /* METHOD NAME   : provideVisibilitytoFAN
    * DEVELOPER      : Nidhi
    * DESCRIPTION    : Provide Visibility to AllUsers
    * RETURN TYPE    : NA
    * PARAMETER      : List<sObject> ContentDocumentLinks
    */
    public static void provideVisibilitytoFAN(List<sObject> contentDocumentLinks) {
    for(ContentDocumentLink objCDL : (List<ContentDocumentLink>)contentDocumentLinks) {
            String objectName = ServiceUtilityCollection.getAPIName(objCDL.LinkedEntityId);
            if (DESIRED_OBJECT_NAME.equals(objectName)) {
                objCDL.Visibility = ALLUSERS;
            }
        }
    }

    
    /* METHOD NAME   : insertFromWOToParent
    * DEVELOPER      : Debalina
    * DESCRIPTION    : Inserts ContentDocumentLink to parent Account and Installed Product
                       when the ContentDocumentLink uploaded from Work Order
    * RETURN TYPE    : NA
    * PARAMETER      : Map<ContentDocumentLink, Id> , Map<Id, SVMXC__Service_Order__c>
    */
    public static void insertFromWOToParent(Map<ContentDocumentLink, Id> mapContentDocLinkToWOId, Set<Id> setWorkOrderId){
        List<SVMXC__Service_Order__c> lstWorkOrders = new WorkOrdersSelector().selectWorkOrders(setWorkOrderId);
        Map<Id, SVMXC__Service_Order__c> mapWOIdToWorkOrder = ServiceUtilityCollection.getWorkOrderMap(lstWorkOrders);
        
        List<ContentDocumentLink> lstContentToInsert = new List<ContentDocumentLink>();
        for(ContentDocumentLink objCDL : mapContentDocLinkToWOId.keySet()){
            if(String.isNotBlank(mapWOIdToWorkOrder.get(mapContentDocLinkToWOId.get(objCDL)).SVMXC__Company__c)){
                ContentDocumentLink objCDForAccount = 
                new ContentDocumentLink(LinkedEntityId = mapWOIdToWorkOrder.get(mapContentDocLinkToWOId.get(objCDL)).SVMXC__Company__c,
                                        ContentDocumentId = objCDL.ContentDocumentId);
                objCDForAccount.ShareType = 'V';
                objCDForAccount.Visibility = ALLUSERS;
                lstContentToInsert.add(objCDForAccount);
            }
            //check if Installed Product exists
            if(String.isNotBlank(mapWOIdToWorkOrder.get(mapContentDocLinkToWOId.get(objCDL)).SVMXC__Component__c)){
                ContentDocumentLink objCDForInstalledProd = 
                new ContentDocumentLink(LinkedEntityId = mapWOIdToWorkOrder.get(mapContentDocLinkToWOId.get(objCDL)).SVMXC__Component__c,
                                        ContentDocumentId = objCDL.ContentDocumentId);
                objCDForInstalledProd.ShareType = 'V';
                objCDForInstalledProd.Visibility = ALLUSERS;
                lstContentToInsert.add(objCDForInstalledProd);
            }
        }
        try{
            System.debug('lstContentToInsert-->'+lstContentToInsert);
            if(!lstContentToInsert.isEmpty())
                insert lstContentToInsert;
        }
        catch(Exception ex){
            System.debug('Exception on Class : ContentDocumentManager - insertFromWOToParent, Error : ' +
                         ex.getMessage() +
                         ' Line Number : ' +
                         ex.getLineNumber() +
                         ' Cause : ' +
                         ex.getCause() +
                         ' Type : ' +
                         ex.getTypeName());
        }
    }
	
	/*DCP-41581
     * copy the CreatedDate and Documents in File related list in POL to Latest Loaner Agreement Signature Date field and File related list on IP. 
    */
     public static void insertFromPOLToIP(Map<Id, SVMXC__RMA_Shipment_Line__c > mapCDIdToPOL, Set<Id> setPartOrderLineId){
	  if(!setPartOrderLineId.isEmpty()){
        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine = new PartsOrderLineSelector().selectPartsOrderLineById(setPartOrderLineId);
        set<Id>setInstalledProductId = new set<Id>();
        List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>();
        List<SVMXC__Installed_Product__c> lstIP = new List<SVMXC__Installed_Product__c>();
        Set<SVMXC__Installed_Product__c> setIP = new Set<SVMXC__Installed_Product__c>();
         for(SVMXC__RMA_Shipment_Line__c objPOL : lstPartsOrderLine){
             setInstalledProductId.add(objPOL.SVMXC__Serial_Number__c);
         }
         map<id, SVMXC__Installed_Product__c> mapIPIDtoIPobj = new map<id, SVMXC__Installed_Product__c>(new InstalledProductsSelector().selectRelatedInstalledProducts(setInstalledProductId));
         set<Id> cDId = new set<Id>();
         cDId = mapCDIdToPOL.keySet();
         List<Id> lstCDId=new List<Id>(cDId);
         set<Id> setPOLID = new set<Id>();
		 List<SVMXC__RMA_Shipment_Line__c> lstPOL = new PartsOrderLineSelector().selectPartsOrderLineById(setPartOrderLineId);
		 for(SVMXC__RMA_Shipment_Line__c objlstPOL : lstPOL){
              setPOLID.add(objlstPOL.id);
          }
		  map<id,ContentDocumentLink> mapPOLtoCDL = new map<id,ContentDocumentLink>();
          if(!setPOLID.isEmpty()){
          for(ContentDocumentLink objCDL : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN: setPOLID]){
              if(!mapPOLtoCDL.containsKey(objCDL.LinkedEntityId))
                  mapPOLtoCDL.put(objCDL.LinkedEntityId,objCDL);
              
           }
          }
         for(SVMXC__RMA_Shipment_Line__c objPOL : lstPOL){
            ContentDocumentLink cdl = mapPOLtoCDL.get(objPOL.Id);
            if(objPOL.SVMXC__Line_Status__c == 'Shipped' && String.isNotBlank(objPOL.SVMXC__Serial_Number__c) && objPOL.Service_Product_Type__c == 'Instrument' && objPOL.SVMXC__Product__r.Condition_Type__c == 'LOANER' ){
            ContentDocumentLink objCDForInstalledProd = 
                new ContentDocumentLink(LinkedEntityId = objPOL.SVMXC__Serial_Number__c,
                                        ContentDocumentId = cdl.ContentDocumentId);
                objCDForInstalledProd.ShareType = 'V';
                objCDForInstalledProd.Visibility = ALLUSERS;
                lstCDL.add(objCDForInstalledProd);
				setInstalledProductId.add(objPOL.SVMXC__Serial_Number__c);
                mapCDIdToPOL.put(cdl.ContentDocumentId,objPOL);
           }
       }
         Map<Integer,String> monthNameMap=new Map<Integer, String>{1 =>'Jan', 2=>'Feb', 3=>'March', 4=>'Apr', 5=>'May',6=>'Jun', 7=>'Jul', 8=>'Aug', 9=>'Sept',10=>'Oct',11=>'Nov', 12=>'Dec'};
         List<ContentDocument> contentDoc = [Select Id, CreatedDate From ContentDocument WHERE Id IN : lstCDId];
		 for(SVMXC__RMA_Shipment_Line__c objPOL1 : lstPOL){
		   if(!contentDoc.isEmpty() && objPOL1.SVMXC__Line_Status__c == 'Shipped' && String.isNotBlank(objPOL1.SVMXC__Serial_Number__c) && objPOL1.Service_Product_Type__c == 'Instrument' && objPOL1.SVMXC__Product__r.Condition_Type__c == 'LOANER'){
		    for(ContentDocument cdObj : contentDoc){
                Date dt = date.newinstance(cdObj.CreatedDate.year(), cdObj.CreatedDate.month(), cdObj.CreatedDate.day()); 
                mapIPIDtoIPobj.get(mapCDIdToPOL.get(cdObj.Id).SVMXC__Serial_Number__c).Latest_Loaner_Agreement_Signature_Date__c = dt.day() + '-' +  monthNameMap.get(dt.month())  + '-' + dt.year();
                //to avoid duplicates in the list
                if(setIP.add(mapIPIDtoIPobj.get(mapCDIdToPOL.get(cdObj.Id).SVMXC__Serial_Number__c))){
                    lstIP.add(mapIPIDtoIPobj.get(mapCDIdToPOL.get(cdObj.Id).SVMXC__Serial_Number__c));
                }
                
             }
		   }
		 }
		 if(!lstCDL.isEmpty()){
		   insert lstCDL;
		 }
         if(!lstIP.isEmpty()){
             update lstIP;
         }
	  }
   }
	  
    /* METHOD NAME   : onAfterDelete
    * DEVELOPER      : Debalina
    * DESCRIPTION    : Opertaions after record delete
    * RETURN TYPE    : NA
    * PARAMETER      : NA
    */
    public override void onAfterDelete(){    
        //Map of ContentDocumentLink record and  Work Order Id
        Map<ContentDocumentLink, Id> mapContentDocLinkToWOId = new Map<ContentDocumentLink, Id>();
        //Set of Work Order Ids
        Set<Id> setWorkOrderId = new Set<Id>();
        Service_Document_Setting__c objSetting = Service_Document_Setting__c.getInstance();
        for(ContentDocumentLink objCDL : (List<ContentDocumentLink>) records) {
            
            if(String.isNotBlank(objSetting.LinkedEntitySObjectName__c)
                && objSetting.LinkedEntitySObjectName__c.equals(ServiceUtilityCollection.getAPIName(objCDL.LinkedEntityId)))
            {
                mapContentDocLinkToWOId.put(objCDL,objCDL.LinkedEntityId);
                setWorkOrderId.add(objCDL.LinkedEntityId);
            }
        }
        
        // Rule 1 unlink Content uploaded to WO to Account and Installed Product
        if(!setWorkOrderId.isEmpty()){
            deleteLinkFromParent(mapContentDocLinkToWOId,setWorkOrderId);
        }
        Map<Id,ContentDocumentLink> oldMap = (Map<Id,ContentDocumentLink>)trigger.oldMap;//DCP-50569
        PlanAndAccPlanAttachmentHandler.populateFieldsOnPlan(oldMap);//DCP-50569
    }

    /* METHOD NAME    : deleteLinkFromParent
    * DEVELOPER      : Debalina
    * DESCRIPTION    : Deletes ContentDocumentLink from parent Account and Installed Product
    when the ContentDocumentLink is deleted from Work Order
    * RETURN TYPE    : NA
    * PARAMETER      : Set<Id> setContentDocId, Set<Id> setLinkedEntityId
    */
    public static void deleteLinkFromParent(Map<ContentDocumentLink, Id> mapContentDocLinkToWOId, Set<Id> setWorkOrderId){
        
        List<SVMXC__Service_Order__c> lstWorkOrders = new WorkOrdersSelector().selectWorkOrders(setWorkOrderId);
        Map<Id, SVMXC__Service_Order__c> mapWOIdToWorkOrder = ServiceUtilityCollection.getWorkOrderMap(lstWorkOrders);
        
        Set<Id> setContentDocId = new Set<Id>();
        Set<Id> setLinkedEntityId = new Set<Id>();

        for(ContentDocumentLink objCDL : mapContentDocLinkToWOId.keySet()){
            setContentDocId.add(objCDL.ContentDocumentId);
            if(String.isNotBlank(mapWOIdToWorkOrder.get(mapContentDocLinkToWOId.get(objCDL)).SVMXC__Company__c)){
                setLinkedEntityId.add(mapWOIdToWorkOrder.get(mapContentDocLinkToWOId.get(objCDL)).SVMXC__Company__c);
            }
            //check if Installed Product exists
            if(String.isNotBlank(mapWOIdToWorkOrder.get(mapContentDocLinkToWOId.get(objCDL)).SVMXC__Component__c)){
                setLinkedEntityId.add(mapWOIdToWorkOrder.get(mapContentDocLinkToWOId.get(objCDL)).SVMXC__Component__c); 
            }
        }

        if(setContentDocId.size() > 0 && setLinkedEntityId.size() > 0){
            List<ContentDocumentLink> lstCDL = [SELECT Id, 
                                                ContentDocumentId,
                                                LinkedEntityId 
                                                FROM ContentDocumentLink 
                                                WHERE LinkedEntityId IN : setLinkedEntityId
                                                AND ContentDocumentId IN : setContentDocId];
            try{
                //System.debug('lstCDL To Delete-->'+lstCDL);
                if(!lstCDL.isEmpty())
                    delete lstCDL;
            }
            catch(Exception ex){
                System.debug('Exception on Class : ContentDocumentManager - deleteLinkFromParent, Error : ' +
                             ex.getMessage() +
                             ' Line Number : ' +
                             ex.getLineNumber() +
                             ' Cause : ' +
                             ex.getCause() +
                             ' Type : ' +
                             ex.getTypeName());
            }    
        }
    }
    
    /* METHOD NAME   : preventFileInsertOnClosedWO
    * DEVELOPER      : Soumya
    * DESCRIPTION    : Prevents insert of File when work order status is closed
    * RETURN TYPE    : NA
    * PARAMETER      : NA
    */
    Public void preventFileInsertOnClosedWO(){
        Map<Id,ContentDocumentLink> workOrderIdToContentDoc = new Map<Id,ContentDocumentLink>();
        for(ContentDocumentLink objContentDocument : (List<ContentDocumentLink>)records){
            String strObjName = objContentDocument.LinkedEntityId.getSObjectType().getDescribe().getName();
            //To check if uploaded from work order related list
            if(String.isNotBlank(strObjName) && strObjName.equals('SVMXC__Service_Order__c'))
            {
                workOrderIdToContentDoc.put(objContentDocument.LinkedEntityId, objContentDocument);
            }
        }
        
        if(workOrderIdToContentDoc.size() > 0){
            for(SVMXC__Service_Order__c objWorkOrder : [Select id 
                                                        FROM SVMXC__Service_Order__c 
                                                        WHERE Id IN : workOrderIdToContentDoc.keySet() 
                                                        AND SVMXC__Order_Status__c =: WORK_ORDER_STATUS_CLOSED])
            {
                if(workOrderIdToContentDoc.containsKey(objWorkOrder.Id)){
                    workOrderIdToContentDoc.get(objWorkOrder.Id).addError(system.label.WO_trigger_file_error_message);
                }
                
            }
        }
    }

    /*******************************************************************************************************
    * @description DCP-49914 Create Content Document Link record for Case
    * @param contentId Content Document Id
    * @param caseId Case id
    * @return ContentDocumentLink
    */
    private static ContentDocumentLink createCDLForCase(Id contentId, Id caseId) {
        ContentDocumentLink objCDForCase =  new ContentDocumentLink(LinkedEntityId = caseId, 
                ContentDocumentId = contentId, ShareType = 'V',
                Visibility = ALLUSERS);
        return objCDForCase;
    }

    /*******************************************************************************************************
    * @description DCP-49914 insert Content Document Link records (from comment to Case)
    * @param mapContentIdtoCommentId Map<Id, Id>
    * @return void
    */
    private static void insertFromCommentToCase(Map<Id, Id> mapContentIdtoCommentId) {
        Map<Id, Id> commentIdToCaseId = new Map<Id, Id>();
        List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
        List<Comment__c> listComments = new CommentsSelector().selectWeChatCommentsSpecificIds(new Set<Id>(mapContentIdtoCommentId.values()));
        
        if(!listComments.isEmpty()) {
            for(Comment__c commentRec : listComments) {
                commentIdToCaseId.put(commentRec.Id, commentRec.Case__c);
            }

            for(Id contentDocId : mapContentIdtoCommentId.keyset()) {
                if(commentIdToCaseId.get(mapContentIdtoCommentId.get(contentDocId)) != NULL) {
                    cdlToInsert.add(createCDLForCase(contentDocId, commentIdToCaseId.get(mapContentIdtoCommentId.get(contentDocId))));
                }
            }

            if(!cdlToInsert.isEmpty()) {
                insert cdlToInsert;
            }
        }
    }
}
