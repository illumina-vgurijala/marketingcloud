/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger 
*               to Prevent creation of Parts Order Lines Record Matching POL Restrictions 
*/
public class POLRestrictions_POLHelper {

    /*******************************************************************************************************
    * @description populate Eligible POs
    * @param partOrderLine new record
    * @param objOldPartOrderLine old record
    * @return
    */
    public static void populateEligiblePOs(SVMXC__RMA_Shipment_Line__c partOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
        //If Service Product Type is Spare and Parts Order Type is Shipment Check for POL Restriction
        //DCP-31049
        if(partOrderLine.SVMXC__Product__c != null 
                && (partOrderLine.Service_Product_Type__c == PartsOrderLines.STRING_PRODUCT_TYPE 
                    || partOrderLine.Service_Product_Type__c == PartsOrderLines.STRING_SERVICE_PRODUCT_TYPE_NONFRU)
                && partOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_TYPE_SHIPMENT
                && (objOldPartOrderLine == NULL || objOldPartOrderLine.SVMXC__Product__c != partOrderLine.SVMXC__Product__c)) {
            PartsOrderLines.setEligiblePOsForRestrictionCheck.add(partOrderLine.SVMXC__RMA_Shipment_Order__c);
        }
    }

    /*DCP-31049
    *  @AUTHOR:  Soumya Sahu
    *  @DESCRIPTION: To Prevent creation of Parts Order Lines Record Matching POL Restrictions 
    *  @PARAM :  set of Parts Order Ids
    *  @RETURN:  void
    */  
    public static void checkPOLRestriction(set<id> setPartsOrders, List<sObject> records) {
        
        set<string> setProductCodes = new set<string>();
        set<string> setClinincalTypes = new set<string>{PartsOrderLines.STRING_ALL};
        set<string> setCustomerTypes = new set<string>{PartsOrderLines.STRING_ALL};
        set<string> setTerritoryRegion = new set<string>{PartsOrderLines.STRING_ALL};
        
        List<Parts_Ordering_Restrictions__c> lstPORestrictions = new List<Parts_Ordering_Restrictions__c>();
        
        for(SVMXC__RMA_Shipment_Line__c objPOL: (List<SVMXC__RMA_Shipment_Line__c>) records) {
            if(setPartsOrders.contains(objPOL.SVMXC__RMA_Shipment_Order__c)) {
                
                if(objPOL.Product_Code__c != null) {
                    setProductCodes.add(objPOL.Product_Code__c);
                }
                if(PartsOrderLines.partsOrderIdToPartsOrder.get(objPOL.SVMXC__RMA_Shipment_Order__c).SVMXC__Company__r.Clinical_Type__c != null) {
                    setClinincalTypes.add(PartsOrderLines.partsOrderIdToPartsOrder.get(objPOL.SVMXC__RMA_Shipment_Order__c).SVMXC__Company__r.Clinical_Type__c);
                }
                if(PartsOrderLines.partsOrderIdToPartsOrder.get(objPOL.SVMXC__RMA_Shipment_Order__c).SVMXC__Company__r.Customer_Type__c != null) {
                    setCustomerTypes.add(PartsOrderLines.partsOrderIdToPartsOrder.get(objPOL.SVMXC__RMA_Shipment_Order__c).SVMXC__Company__r.Customer_Type__c);
                }
                if(PartsOrderLines.partsOrderIdToPartsOrder.get(objPOL.SVMXC__RMA_Shipment_Order__c).SVMXC__Company__r.Territory_Region__c != null) {
                    setTerritoryRegion.add(PartsOrderLines.partsOrderIdToPartsOrder.get(objPOL.SVMXC__RMA_Shipment_Order__c).SVMXC__Company__r.Territory_Region__c);
                }
            }
        }
       
        lstPORestrictions = populateListPORestrictions(setProductCodes, setClinincalTypes, setCustomerTypes, setTerritoryRegion);
        if(!lstPORestrictions.isEmpty()) {
            for(SVMXC__RMA_Shipment_Line__c objPOL: (List <SVMXC__RMA_Shipment_Line__c>) records) {
                throwError(objPOL, lstPORestrictions);
            }
        }   
    }

    /*******************************************************************************************************
    * @description throw error
    * @param objPOL SVMXC__RMA_Shipment_Line__c
    * @param lstPORestrictions List<Parts_Ordering_Restrictions__c>
    * @return void
    */
    private static void throwError(SVMXC__RMA_Shipment_Line__c objPOL, List<Parts_Ordering_Restrictions__c> lstPORestrictions) {
        String errorMessage = '';
        string strGenericError = 'is not approved to order for';
        string strClinicalStatic = ' Clinical Type(s)';
        string strCustomerStatic = ' Customer Type(s)';
        string strTerritoryStatic = ' Territory Region(s)';
        
        Map<string,boolean> picklistNametoFlag = new Map<string,boolean>{'ClinicalType'=>false,'CustomerType'=>false,
                                            'TerritoryRegion'=>false,'showClinicalType'=>false,'showCustomerType'=>false,'showTerritoryRegion'=>false};

        for(Parts_Ordering_Restrictions__c objPORestriction :lstPORestrictions) {
            //To match the product code of Parts Order and Parts Order Restriction Object
            picklistNametoFlag = getRestrictionsValue(picklistNametoFlag, PartsOrderLines.partsOrderIdToPartsOrder.get(objPOL.SVMXC__RMA_Shipment_Order__c), objPORestriction);
            if(objPORestriction.Product_Code__c==objPOL.Product_Code__c && picklistNametoFlag.get('showClinicalType') 
                    && picklistNametoFlag.get('showCustomerType') && picklistNametoFlag.get('showTerritoryRegion')) {
                errorMessage=errorMessage+objPOL.Product_Code__c+' '+strGenericError;
                integer intErrorMsgInitial = errorMessage.length();
                if(picklistNametoFlag.get('ClinicalType')) {
                    errorMessage= errorMessage+' '+objPORestriction.Clinical_Type__c+ strClinicalStatic;
                }
                //To Append Customer Type Error
                if(picklistNametoFlag.get('CustomerType')) {
                    errorMessage = generateErrorMessage(errorMessage, intErrorMsgInitial, objPORestriction.Customer_Type__c, strCustomerStatic);
                }
                //To Append Territory Region Error
                if(picklistNametoFlag.get('TerritoryRegion')) {
                    errorMessage = generateErrorMessage(errorMessage, intErrorMsgInitial, objPORestriction.Territory_Region__c, strTerritoryStatic);
                }
                errorMessage= errorMessage+'. Please refer to the following comment:'+objPORestriction.Comment__c+'.';
                //Show Error
                objPOL.addError(errorMessage); 
            }     
        }
    }
    
    /*******************************************************************************************************
    * @description generate Error Message
    * @param errorMessage String
    * @param intErrorMsgInitial Integer
    * @param fieldValue String
    * @param staticText String
    * @return String
    */
    private static String generateErrorMessage(String errorMessage, Integer intErrorMsgInitial, String fieldValue, String staticText) {
        String errMsg = errorMessage;
        if(errMsg.length() > intErrorMsgInitial) {
            errMsg = errMsg + ', ';
        }
        errMsg = errMsg + ' ' + fieldValue + staticText;
        return errMsg;
    }

    /*******************************************************************************************************
    * @description populate ListPORestrictions
    * @param partOrderLine Set<String>
    * @param setClinincalTypes Set<String>
    * @param setCustomerTypes Set<String>
    * @param setTerritoryRegion Set<String>
    * @return List<Parts_Ordering_Restrictions__c>
    */
    private static List<Parts_Ordering_Restrictions__c> populateListPORestrictions(Set<String> setProductCodes, Set<String> setClinincalTypes, 
                                                                        Set<String> setCustomerTypes, Set<String> setTerritoryRegion) {
        //To get all the matching values of Parts Ordering Restrictions Object //33876 null check
        List<Parts_Ordering_Restrictions__c> lstPORestrictions = new List<Parts_Ordering_Restrictions__c>();
        if(setProductCodes != null && !setProductCodes.isEmpty() 
                && ((setClinincalTypes != null && !setClinincalTypes.isEmpty()) 
                    || (setCustomerTypes != null && !setCustomerTypes.isEmpty()) 
                    || (setTerritoryRegion != null && !setTerritoryRegion.isEmpty()))) {
            lstPORestrictions = new PartsOrderingRestrictionsSelector().selectPORestrictionsByKey(setProductCodes, setClinincalTypes, 
                                                                                                setCustomerTypes, setTerritoryRegion);
        }
        return lstPORestrictions;
    }

    /* DCP-31049
    *  @AUTHOR:  Soumya Sahu
    *  @DESCRIPTION: To Prevent creation of Parts Order Lines Record Matching POL Restrictions 
    *  @PARAM :  map<string, boolean, Obj PO, Obj POR
    *  @RETURN:  map<string, boolean>
    */  
    public static Map<string,boolean> getRestrictionsValue(Map<string,boolean> picklistNametoFlag,SVMXC__RMA_Shipment_Order__c objPO, Parts_Ordering_Restrictions__c objPOR ) {   
        //show flags are set to true when an error message needs to be shows
        //Field booleans are set to true, when the field value is 'ALL' or Exact Match is found
        
        picklistNametoFlag.put('ClinicalType', objPOR.Clinical_Type__c == PartsOrderLines.STRING_ALL  || (objPOR.Clinical_Type__c != null && objPO.SVMXC__Company__r.Clinical_Type__c==objPOR.Clinical_Type__c) ? true : false);
        picklistNametoFlag.put('showClinicalType', objPOR.Clinical_Type__c == PartsOrderLines.STRING_ALL  || objPOR.Clinical_Type__c == null ||(objPOR.Clinical_Type__c != null && objPO.SVMXC__Company__r.Clinical_Type__c==objPOR.Clinical_Type__c) ? true: false);
        picklistNametoFlag.put('CustomerType', objPOR.Customer_Type__c == PartsOrderLines.STRING_ALL  || (objPOR.Customer_Type__c != null && objPO.SVMXC__Company__r.Customer_Type__c==objPOR.Customer_Type__c) ? true : false);
        picklistNametoFlag.put('showCustomerType', objPOR.Customer_Type__c == PartsOrderLines.STRING_ALL  || objPOR.Customer_Type__c == null || (objPOR.Customer_Type__c!=null && objPO.SVMXC__Company__r.Customer_Type__c==objPOR.Customer_Type__c) ? true : false);
        picklistNametoFlag.put('TerritoryRegion', objPOR.Territory_Region__c == PartsOrderLines.STRING_ALL  || (objPOR.Territory_Region__c != null && objPO.SVMXC__Company__r.Territory_Region__c==objPOR.Territory_Region__c) ? true : false);
        picklistNametoFlag.put('showTerritoryRegion', objPOR.Territory_Region__c == PartsOrderLines.STRING_ALL  || objPOR.Territory_Region__c == null || (objPOR.Territory_Region__c != null && objPO.SVMXC__Company__r.Territory_Region__c==objPOR.Territory_Region__c) ?  true : false);

        return picklistNametoFlag;
    }
    
}
