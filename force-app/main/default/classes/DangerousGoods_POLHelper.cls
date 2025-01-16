/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to populate Dangerous Goods 
*/ 
public class DangerousGoods_POLHelper {

    /*******************************************************************************************************
    * @description DCP-42724 - Populate Dangerous goods in POL.
    * @param objPartOrderLine new record
    * @param objOldPartOrderLine old record
    * @return
    */
    public static void populateDangerousGoods(SVMXC__RMA_Shipment_Line__c objPartOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
		if(objPartOrderLine.SVMXC__Product__c != NULL 
			&& (objOldPartOrderLine == NULL || (objPartOrderLine.SVMXC__Product__c != objOldPartOrderLine.SVMXC__Product__c))) {
			objPartOrderLine.Dangerous_Goods__c = PartsOrderLines.mapProduct.get(objPartOrderLine.SVMXC__Product__c).Dangerous_Goods__c ;
		} else{
			objPartOrderLine.Dangerous_Goods__c = false;
		}
	}
}