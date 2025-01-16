/*****************************************************************************************************************
 * Class Name: UpdateProductGroup_WorkdetailHelper
 * 
 * Description: Queueable class to update product group on the work orders.
 * 
 * Author: Prashanth
 * 
 * Date: 07-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  07-12-2021                       Queueable class to update product group on the work orders.
 * 
 ******************************************************************************************************************/
public with sharing class UpdateProductGroup_WorkdetailHelper implements Queueable{
    Set < Id > setWOIdforICEPrdGrp = new Set<Id>();
	public static Boolean catchException = false;
    /**
     * constructor
     */
    public UpdateProductGroup_WorkdetailHelper(Set < Id > setWOIdforICEPrdGrp){
        this.setWOIdforICEPrdGrp = setWOIdforICEPrdGrp;
    }
    /*
     *  @AUTHOR:  Shruti Karn
     *  @DESCRIPTION: Method to for populating Product group on work Order
     *  @modification : CMSI-38 Added Try Catch mechanism Emitting exception to ApexExceptions class with Workstream.
     *  @PARAM :  set<Id>  - set of Work Order Ids 
     *  @RETURN:  void
     */
    public void execute(QueueableContext qc){
        try{
        if(!setWOIdforICEPrdGrp.isEmpty()){
            updateProductGrponWorkOrder(setWOIdforICEPrdGrp);
        }
		if(catchException == true){
				throw new AuraHandledException('Throwing Custom Exception');
			 }
        }catch(Exception e){
            //CMSI-38 Emitting exception to ApexExceptions class with Workstream.
            ApexExceptions.emit('UpdateProductGroup_WorkdetailHelper',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
    }
    /*
     *  @AUTHOR:  Shruti Karn
     *  @DESCRIPTION: Method to for populating Product group on work Order
     *  @PARAM :  set<Id>  - set of Work Order Ids 
     *  @RETURN:  void
     */

    public static void updateProductGrponWorkOrder(set < Id > setWOIdforICEPrdGrp) {
        map < Id, String > mapWOToProdGrp = new map < Id, String > ();
        list < SVMXC__Service_Order__c > lstWOtoUpdate = new list < SVMXC__Service_Order__c > ();
        //if (setWOIdforICEPrdGrp.size() > 0) {
            
            populateWorkdetailsMap(setWOIdforICEPrdGrp, mapWOToProdGrp);
            for (SVMXC__Service_Order__c wo: new WorkOrdersSelector().selectWorkOrdersFromIds(setWOIdforICEPrdGrp)) {
                WO.ICE_WO_Products__c = '';
                if (mapWOToProdGrp.containsKey(WO.Id) && mapWOToProdGrp.get(WO.Id) != null && !String.ISBLANK(mapWOToProdGrp.get(WO.Id))){
                    WO.ICE_WO_Products__c = mapWOToProdGrp.get(WO.Id);
                }
                if ((WO.SVMXC__Component__r.SVMXC__Product__r.Product_Group__c) != null && !String.ISBLANK(WO.SVMXC__Component__r.SVMXC__Product__r.Product_Group__c)){
                    if (WO.ICE_WO_Products__c != ''){
                        WO.ICE_WO_Products__c = WO.SVMXC__Component__r.SVMXC__Product__r.Product_Group__c + ',' + WO.ICE_WO_Products__c;
                    }   
                    else{
                        WO.ICE_WO_Products__c = WO.SVMXC__Component__r.SVMXC__Product__r.Product_Group__c;
                    }
                }
                    
                lstWOtoUpdate.add(WO);
            }
        //}
        if (!lstWOtoUpdate.isEmpty()) {
            try {
                update lstWOtoUpdate;
                WorkOrders.skipWOTrigger = true; // Added during cmcm-12023 analysis to avoid unnecessary soqls
            }
            Catch(Exception e ) { 
                System.debug( e.getMessage());
                throw e;
            }
        }
    }
    /*
     *  @AUTHOR:  Shruti Karn
     *  @DESCRIPTION: Method to for populating Product group on work Order
     *  @PARAM :  set<Id>  - set of Work Order Ids 
     *  @RETURN:  void
     */
    public static void populateWorkdetailsMap(Set<Id> setWOIdforICEPrdGrp,map < Id, String > mapWOToProdGrp){
        for (SVMXC__Service_Order_Line__c objWorkDetail: new WorkDetailsSelector().selectWorkDetailsForWorkOrderId(setWOIdforICEPrdGrp)) {
            if (!mapWOToProdGrp.containsKey(objWorkDetail.SVMXC__Service_Order__c) && objWorkDetail.SVMXC__Product__r.Product_Group__c != null && !String.ISBLANK(objWorkDetail.SVMXC__Product__r.Product_Group__c)){
                mapWOToProdGrp.put(objWorkDetail.SVMXC__Service_Order__c, objWorkDetail.SVMXC__Product__r.Product_Group__c);
            }
            else {
                if (objWorkDetail.SVMXC__Product__r.Product_Group__c != null && !mapWOToProdGrp.get(objWorkDetail.SVMXC__Service_Order__c).contains(objWorkDetail.SVMXC__Product__r.Product_Group__c)) {
                    //String prodGroup = mapWOToProdGrp.get(objWorkDetail.SVMXC__Service_Order__c) + ',' + objWorkDetail.SVMXC__Product__r.Product_Group__c;
                    mapWOToProdGrp.put(objWorkDetail.SVMXC__Service_Order__c, mapWOToProdGrp.get(objWorkDetail.SVMXC__Service_Order__c) + ',' + objWorkDetail.SVMXC__Product__r.Product_Group__c);
                }
            }
        }
    }
}
