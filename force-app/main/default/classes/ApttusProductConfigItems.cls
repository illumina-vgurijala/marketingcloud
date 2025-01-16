/*@ author       : Satya Swain
* @ date         : 05 April 2019
* @ Description  : DCP-24589 Indirect: Direct Sale to UC Logic
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Satya Swain           05 April 2019                   DCP-24589 
* Bharath Varma         03 Dec   2020                   DCP-43354 - Added logic to auto populate Program Type field
* KD                    8-May-2021                      DCP-45742 : Update server serial number
* Prem Ranjan			3-May-2021						DCP-46926 AC2  Automate and Simplify Shipping Close Quantity
* Bharath Varma         3-Sep-2021                      INC0342101: Made shipping in close quarters to 0 if the value is null
* Sai Pasumarthy        11-Dec-2024                     CMCM-11053: TI- Line Item : Update Manual List Price
*/
public with sharing class ApttusProductConfigItems extends ilib_SObjectDomain {

    public static final String PREMIUM = '% Premium'; //DGP-24
    public static final String AMOUNT = 'Amount'; //DGP-24
    private static final List<String> CONSORTIUM_REC_TYPE_NAMES = new List<String> {System.Label.OpportunityTypeConsortium,  System.Label.OpportunityTypeReorderConsortiumConsumable}; //CMCM-11053        
    
    /**
     * Public contructor 
     **/
    public ApttusProductConfigItems(List<Apttus_Config2__LineItem__c> sObjectList)
    {
        super(sObjectList);
    }
    
    /**
     * Boilerplate which is required for base class instantiation logic
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
         * Public contructor
         **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusProductConfigItems(sObjectList);
        }
    }

    /**
     * Method to run before Insert
     **/
    public override void onBeforeInsert()
    {
        // DGP-11, DGP-42, DGP-354, DGP-358 : To populate Discount Guidance values on Line Items.
        DiscountGuidancePopulatorForCPQ populator = new DiscountGuidancePopulatorForCPQ();
        populator.deriveFieldValuesForDiscountGuidance((List<Apttus_Config2__LineItem__c>) records);

        // retrieve parent record details
        Set<Id> configIds = UtilsCollection.getSetOfIds(records, 'Apttus_Config2__ConfigurationId__c');
        Map<Id, Apttus_Config2__ProductConfiguration__c> idToConfiguration = new Map<Id, Apttus_Config2__ProductConfiguration__c>(
            new ApttusProductConfigurationsSelector().selectById(configIds)
        );
        
        resetGTCheckForCopyProducts(idToConfiguration);
        // DCP-45742
        populateLineItem(records);

        //TI-11056
        updateERPNumber(records);       
        updateManualListPrice((List<Apttus_Config2__LineItem__c>) records); //CMCM-11053
        defaultBeadchipPartNumber((List<Apttus_Config2__LineItem__c>) records,idToConfiguration);//CMCM-11053

    }
    
    /** 
* @description  : DCP-45742 :before update override
**/
    public override void onBeforeUpdate(Map<Id, sObject> idToOldRecords){
        // retrieve parent record details
        Set<Id> configIds = UtilsCollection.getSetOfIds(records, 'Apttus_Config2__ConfigurationId__c');
        Map<Id, Apttus_Config2__ProductConfiguration__c> idToConfiguration = new Map<Id, Apttus_Config2__ProductConfiguration__c>(
            new ApttusProductConfigurationsSelector().selectById(configIds)
        );

        populateLineItem(records);
        populateShipingCloseQuarter(trigger.newMap,trigger.oldMap); //DCP-46926 AC2
        populateCustomerPremiumAmount(trigger.newMap,trigger.oldMap); //DGP-24
        updateManualListPrice((List<Apttus_Config2__LineItem__c>) records); //CMCM-11053
        defaultBeadchipPartNumber((List<Apttus_Config2__LineItem__c>) records,idToConfiguration);//CMCM-11053
    }
    
    
    /*
     * Method to check for Copy Products
     */
    private void resetGTCheckForCopyProducts(Map<Id, Apttus_Config2__ProductConfiguration__c> idToConfiguration)
    {        
        Set<Id> setQuoteId = new Set<Id>();
        for (Apttus_Config2__ProductConfiguration__c productConfig : idToConfiguration.values()) {
            if(productConfig.Apttus_QPConfig__Proposald__c != null) {
                setQuoteId.add(productConfig.Apttus_QPConfig__Proposald__c);
            }
        }
        List<Apttus_Proposal__Proposal__c> quotations = new ApttusProposalsSelector().selectById(setQuoteId);
        Map<Id, String> idToQuotationSubType = new Map<Id, String>();
        for(Apttus_Proposal__Proposal__c quote : quotations) {
            idToQuotationSubType.put(quote.Id, quote.Quote_Sub_Type__c);
        }

        List<Apttus_Config2__ProductConfiguration__c> updatedParentRecords = updateLineItems(idToConfiguration, idToQuotationSubType);

        // persist parent rec updates
        if (!updatedParentRecords.isEmpty()) {
             update updatedParentRecords;
        }
    }

    /*
     * Method to update line items
     */
    public List<Apttus_Config2__ProductConfiguration__c> updateLineItems(Map<Id, Apttus_Config2__ProductConfiguration__c> idToConfiguration, Map<Id, String> idToQuotationSubType) {
        List<Apttus_Config2__ProductConfiguration__c> updatedParentRecords = new List<Apttus_Config2__ProductConfiguration__c>();

        for (Apttus_Config2__LineItem__c lineItem : (List<Apttus_Config2__LineItem__c>)records)
        {
            // update parent records
            if (idToConfiguration.containsKey(lineItem.Apttus_Config2__ConfigurationId__c))
            {
                Apttus_Config2__ProductConfiguration__c parentRec = idToConfiguration.get(lineItem.Apttus_Config2__ConfigurationId__c);
                if (parentRec.Is_SAP_Pricing_Completed__c)
                {
                    parentRec.Is_SAP_Pricing_Completed__c = false;
                    updatedParentRecords.add(parentRec);
                }

                 //  Added for Direct Sales to UC logic as part of DCP-24589
                if(parentRec.Apttus_Config2__VersionNumber__c == 1 && parentRec.Apttus_QPConfig__Proposald__r.Cloned_From__c <> null){
                    lineItem.Line_Item_Old_Values__c = null;
                    lineItem.Global_Trade_Block__c = false;
                }
                if(idToQuotationSubType.containsKey(parentRec.Apttus_QPConfig__Proposald__c) && idToQuotationSubType.get(parentRec.Apttus_QPConfig__Proposald__c) == Label.OpportunityTypeRentalReagent) {
                    lineItem.Program_Type__c = Label.OpportunityTypeRentalReagent;
                }
            }

            // update child records
            if (lineItem.Apttus_Config2__CopySourceNumber__c != null && lineItem.Global_Trade_Block__c)
            {
                lineItem.Apttus_Config2__CopySourceNumber__c = null;
                lineItem.Global_Trade_Block__c = false;
                // Added for Direct Sales to UC logic as part of DCP-24589
                lineItem.Line_Item_Old_Values__c = null;
            }
            if (lineItem.Global_Trade_Block__c)
            {
                lineItem.Global_Trade_Block__c = false;
            }
            
        }
        return updatedParentRecords;
    }

    /** 
     * @description  : DGP-24 : Update Customer Premium Amount Per Unit
     **/
    public static void populateCustomerPremiumAmount(Map<Id,SObject> newMapSObject , Map<Id,SObject> oldMapSObject)
    {
        Map<Id,Apttus_Config2__LineItem__c> newMap = (Map<Id,Apttus_Config2__LineItem__c>)trigger.newMap;
        Map<Id,Apttus_Config2__LineItem__c> oldMap = (Map<Id,Apttus_Config2__LineItem__c>)trigger.oldMap; 
        for(Apttus_Config2__LineItem__c item : newMap.values())
        {
            if(item.Customer_Premium_Per_Unit__c != null && item.Customer_Premium_Type__c != null && oldMap.get(item.Id).Customer_Premium_Per_Unit__c != newMap.get(item.Id).Customer_Premium_Per_Unit__c )
            {
                if(item.Customer_Premium_Type__c == AMOUNT){
                    item.Customer_Premium_Amount_Per_Unit__c=item.Customer_Premium_Per_Unit__c;
                }
                else if(item.Customer_Premium_Type__c == PREMIUM){
                    Double temp=item.Customer_Premium_Per_Unit__c*item.List_Price__c/100;
                    item.Customer_Premium_Amount_Per_Unit__c= temp;
                }
            }
        }
    }

    /** 
     * @description  : DCP-45742 : Update Server Serial number
     **/
    public static void populateLineItem(List<Sobject> records){
        for(Apttus_Config2__LineItem__c objLineItem : (List<Apttus_Config2__LineItem__c>) records){
            objLineItem.Server_Serial_Number__c = String.isNotBlank(objLineItem.Serial_Number__c) ? objLineItem.Serial_Number__c.split(',')[0] : '';
        }
    }

    /** 
     * @description  : DCP-46926 AC2 : Populate shiping close quarter
     **/
    public static void populateShipingCloseQuarter(Map<Id,SObject> newMapSObject , Map<Id,SObject> oldMapSObject){
        Map<Id,Apttus_Config2__LineItem__c> newMap = (Map<Id,Apttus_Config2__LineItem__c>)trigger.newMap;
        Map<Id,Apttus_Config2__LineItem__c> oldMap = (Map<Id,Apttus_Config2__LineItem__c>)trigger.oldMap;       
        for(Apttus_Config2__LineItem__c item : newMap.values())
        {
            if(item.Apttus_Config2__Quantity__c != oldMap.get(item.Id).Apttus_Config2__Quantity__c
               && (item.Shipping_In_1Q_After_Close_Quarter__c == 0 || item.Shipping_In_1Q_After_Close_Quarter__c == null) 
               && (item.Shipping_In_2Q_After_Close_Quarter__c == 0 || item.Shipping_In_2Q_After_Close_Quarter__c == null)
               && item.Shipping_In_Close_Quarter__c == oldMap.get(item.Id).Shipping_In_Close_Quarter__c
               && item.Shipping_In_Close_Quarter__c == oldMap.get(item.Id).Apttus_Config2__Quantity__c)
            {
                item.Shipping_In_Close_Quarter__c = item.Apttus_Config2__Quantity__c;
            }
            else{
                if((item.Shipping_In_Close_Quarter__c == 0 || item.Shipping_In_Close_Quarter__c == null) && 
                (item.Shipping_In_1Q_After_Close_Quarter__c == 0 || item.Shipping_In_1Q_After_Close_Quarter__c == null) &&
                (item.Shipping_In_2Q_After_Close_Quarter__c == 0 || item.Shipping_In_2Q_After_Close_Quarter__c == null))
                    {
                        item.Shipping_In_Close_Quarter__c = item.Apttus_Config2__Quantity__c;
                    }
                    // Incident INC0342101
                    item.Shipping_In_Close_Quarter__c = item.Shipping_In_Close_Quarter__c == null ? 0 : item.Shipping_In_Close_Quarter__c;
                    item.Shipping_In_1Q_After_Close_Quarter__c = item.Shipping_In_1Q_After_Close_Quarter__c == null ? 0 : item.Shipping_In_1Q_After_Close_Quarter__c;
                    item.Shipping_In_2Q_After_Close_Quarter__c = item.Shipping_In_2Q_After_Close_Quarter__c == null ? 0 : item.Shipping_In_2Q_After_Close_Quarter__c;
                }
        }
    }
    /*
    @Author : Vijay Masne
    @Story : TI-11056
    @Description : TI- Line Item:Update Erp Number
    @Paramters : List of Line Item
    */
    @testVisible
    private static void updateERPNumber(List<SObject> records) {
        if (Feature.isOn('WF_FF_APTS_Set_ERPNo')) {
            for (Apttus_Config2__LineItem__c objLineItem : (List<Apttus_Config2__LineItem__c>) records) {
                
                if (String.isBlank(objLineItem.Id) || objLineItem.isClone()) {
                    objLineItem.ERP_Line_Number__c = '';
                }
    
            }
        }
    }
    
    /*
@Author : Sai Pasumarthy
@Story : CMCM-11053
@Description : TI- Line Item : Update Manual List Price
@Paramters : List of Line Item
*/
    @testVisible
    private static void updateManualListPrice(List<Apttus_Config2__LineItem__c> records) {
        
        if (Feature.isOn('WF_FF_Update_Manual_List_Price')) {
            for (Apttus_Config2__LineItem__c objLineItem : records) {                      
                if ( objLineItem.List_Price__c == null ) {
                    objLineItem.List_Price__c = objLineItem.Apttus_Config2__ListPrice__c;
                }
            }
        }
    } 

    @testVisible
    private static void defaultBeadchipPartNumber(List<Apttus_Config2__LineItem__c> records, Map<Id, Apttus_Config2__ProductConfiguration__c> idToConfiguration){
        if (Feature.isOn('WF_FF_Update_Manual_List_Price')) {
            for (Apttus_Config2__LineItem__c objLineItem : records) {
                Boolean isConsortiumType = CONSORTIUM_REC_TYPE_NAMES.contains(idToConfiguration.get(objLineItem.Apttus_Config2__ConfigurationId__c).Apttus_QPConfig__Proposald__r?.Quote_Sub_Type__c);
                if( isConsortiumType ){				    
                    objLineItem.Beadchip_Part_Number__c = idToConfiguration.get(objLineItem.Apttus_Config2__ConfigurationId__c).Apttus_QPConfig__Proposald__r?.Apttus_Proposal__Opportunity__r?.Consortium__r?.Beadchip_Part_Number__c;
                }
            }
        }
    }
}