/**
 * @File Name          : WorkOrderServiceMaxWebservice.cls
 * @Description        : Update a checkbox field on Work Order to trigger integration out to SAP. This class will be called from Parts Order SFM.
 * @Author             : Vaibhav Parashar
 * @Group              : 
 * @Last Modified By   : Rohan Rathod
 * @Last Modified On   : 02-23-2023
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0    6/26/2019,       1:56:23 PM   Vaibhav     Initial Version
 * 1.1    02/21/2023                    Rohan       Modified: DCP-59333 AutoPopulate To Location for Shipment PO SFM
 **/
Global Class WorkOrderServiceMaxWebservice {

    Public static final string PARTS_ORDER_OBJECT_API = 'SVMXC__RMA_Shipment_Order__c';

    //DCP-59333
    private static final string CUSTOMER_LOCATION = 'Customer Location';
    private static final string DESTINATION_LOCATION_FIELD = 'SVMXC__Destination_Location__c';
    private static final string ORDER_TYPE_FIELD = 'SVMXC__Order_Type__c';

    /**
     * @description Process Parts Order SFM fields and make an update on Work Order.
     * @author Vaibhav Parashar | 6/26/2019
     * @param SVMXC.SFM_WrapperDef.SFM_TargetRecord request
     * @return webservice
     */
    webservice static SVMXC.SFM_WrapperDef.SFM_PageData updateWorkOrder(SVMXC.SFM_WrapperDef.SFM_TargetRecord request) {
        system.debug('Request = ' + request);

        //parts order object api to parts order schema sobjectType
        map < String, Schema.SObjectType > allObj = new map < String, Schema.SObjectType > ();

        SVMXC.SFM_WrapperDef.SFM_PageData pagedata;

        //get the sObjectType of parts order.
        SVMXC__RMA_Shipment_Order__c objPartsOrder = new SVMXC__RMA_Shipment_Order__c();
        Schema.sObjectType objPartsOrderType = objPartsOrder.getSObjectType();

        //populate the map to be passed into serviceMax methods.
        allObj.put(PARTS_ORDER_OBJECT_API, objPartsOrderType);

        SVMXC.SFM_ServicesDef def = new SVMXC.SFM_ServicesDef();

        //get the header object from the SFM clicked by the user.
        Sobject headerSobj = def.SFM_Page_GetHeaderRecord(request, allObj);

        //Instantiate a new parts order and update the required field.
        SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c();
        partsOrder = (SVMXC__RMA_Shipment_Order__c) headerSobj;

        //START - DCP-59333 - Autopopulate To Location 
        List<Profile> currentProfile = new ProfilesSelector().getProfilesById(new Set<Id>{UserInfo.getProfileId()});

        if(headerSobj.get(ORDER_TYPE_FIELD) == System.Label.PartOrderTypeShipment && headerSobj.get(DESTINATION_LOCATION_FIELD) == null && !currentProfile.isEmpty() 
                && (currentProfile[0].Name == System.Label.ProfileTechnicalSupport || currentProfile[0].Name == System.Label.Field_Service)) {
            headerSobj.put(DESTINATION_LOCATION_FIELD, CUSTOMER_LOCATION);            
        } 
        //END - DCP-59333

        // The method below returns the detail Sobject records in a map (Key: Tab Id, Value: List of Sobject records)
        map < String, List < Sobject >> detailSobjectMap = new map < String, List < Sobject >> ();

        detailSobjectMap = def.SFM_Page_GetDetailRecords(request, allObj);

        //serviceMax metadata syntax
        if (request.detailRecords != null && !request.detailRecords.isEmpty())
            pagedata = def.SFM_Page_BuildResponse(request, headerSobj, detailSobjectMap);


        try {
            system.debug('partsOrder.SVMXC__Service_Order__c == ' + partsOrder.SVMXC__Service_Order__c);
            //update send to erp on work order to trigger out integration.
            if (String.isNotBlank(partsOrder.SVMXC__Service_Order__c)) {
                SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(Id = partsOrder.SVMXC__Service_Order__c, Send_to_ERP__c = true);
                update workOrder;
            }
        } catch (Exception ex) {
            system.debug('Exxception == ' + ex);
        }


        system.debug('Response = ' + pagedata);
        return pagedata;
    }
}