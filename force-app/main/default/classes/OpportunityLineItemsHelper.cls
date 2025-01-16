/* @ author       : Indra Ganesan 
* @ date         : 03-22-2022
* @ Description  : OpportunityLineItemsHelper for code scan fix
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Indra Ganesan        05-18-2018                  DCP-598             Initial version
* Prem Ranjan          03-22-2022                  DCP - 52276         Method Split to resolve N-Path Complexity
*/
public with sharing class OpportunityLineItemsHelper {
    public static final String INSTALL_WO_CASE_REQUEST = 'Auto Create Install Work Order and Service Request Case'; 
    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public void prepareOpportunitySet(List<OpportunityLineItem> lstOptyLineItems,Set<Id> setCRFNeededOppIds,Set<Id> setInfoOppids,Set<Id> setOpprtyIds) {  
        ilib_LogEvent.push('OpportunityLineItemsHelper.prepareOpportunitySet()');
        if (!lstOptyLineItems.isEmpty()) {
            for(OpportunityLineItem oli : lstOptyLineItems) {
                //DCP-30367 - checking if oli is informatics product
                if(oli.Has_Informatics_Product__c) {
                    setInfoOppids.add(oli.OpportunityId);
                }
                //DCP-28965 - To add the relevant opportunites to set where opportunity line item meet the criteria
                /*if(oli.Product2.Auto_Create_Install_Work_Order__c && ( oli.Product2.Service_Product_Type__c == System.Label.ProductClassInstrument || oli.Product2.Service_Product_Type__c == System.Label.ProductServiceProductTypeCore)  && oli.Product2.IsActive) {
                    setCRFNeededOppIds.add(oli.opportunityId);
                }*/
                //CMCM-1662
                if(oli.Product2.Auto_Create_Installation_Workflow__c == INSTALL_WO_CASE_REQUEST && ( oli.Product2.Service_Product_Type__c == System.Label.ProductClassInstrument || oli.Product2.Service_Product_Type__c == System.Label.ProductServiceProductTypeCore)  && oli.Product2.IsActive) {
                    setCRFNeededOppIds.add(oli.opportunityId);
                }
                //DCP-40052 - To create a set of Opportunities that satisfy certain conditions based on Opportunity Line Items
                /*if(oli.Product2.Material_Class__c == System.Label.ProductMaterialClassInstrument  && ( oli.Product2.Service_Product_Type__c == System.Label.ProductClassInstrument || oli.Product2.Service_Product_Type__c == System.Label.ProductServiceProductTypeCore)  && (oli.Product2.Material_Class_Type__c == System.Label.ProductMaterialClassTypeSystem ||oli.Product2.Auto_Create_Install_Work_Order__c)) {
                    setOpprtyIds.add(oli.opportunityId);
                }*/
                //CMCM-1662
                if(oli.Product2.Material_Class__c == System.Label.ProductMaterialClassInstrument  && ( oli.Product2.Service_Product_Type__c == System.Label.ProductClassInstrument || oli.Product2.Service_Product_Type__c == System.Label.ProductServiceProductTypeCore)  && (oli.Product2.Material_Class_Type__c == System.Label.ProductMaterialClassTypeSystem ||oli.Product2.Auto_Create_Installation_Workflow__c == INSTALL_WO_CASE_REQUEST)) {
                    setOpprtyIds.add(oli.opportunityId);
                }
            }
        ilib_LogEvent.pop();
        }
    }

    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public void opportunityLineToDelete(List<OpportunityLineItem> lstOptyLineItems) {  
        ilib_LogEvent.push('OpportunityLineItemsHelper.opportunityLineToDelete()');
        List<OpportunityLineItem> lstOptyLineItemsToDelete = new List<OpportunityLineItem>();
        if (!lstOptyLineItems.isEmpty()) {
            for(OpportunityLineItem oli : lstOptyLineItems) {
                Boolean boolFixedBundle = oli.Product2.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && oli.Product2.Material_Class_Type__c == Label.FixedBundleMatClassType;
                if(oli.OptionId__c == null && boolFixedBundle) {
                    lstOptyLineItemsToDelete.add(oli);
                }           
            }
        }
        
        //ilib_LogEvent.message('setInfoOppidsafterinsert : ' + setInfoOppids);
        if(!lstOptyLineItemsToDelete.isEmpty()) {
            delete lstOptyLineItemsToDelete;
        }
        //DCP-28663 Ends
        ilib_LogEvent.pop();
    }

    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public void updateParentOpp(Opportunity opp, Map<Id, Opportunity> mapUpdateOpportunity, Map<Id, Set<String>> oppIdToProdGroup) {
        ilib_LogEvent.push('OpportunityLineItemsHelper.updateParentOpp()'); 
        Boolean booCheckGroupChanged = false;
                ilib_LogEvent.message('<--Join-->');
            //String strOldProductGroups = opp.ICE_Opportunity_Product_Lines__c;
            Set<String> setOldProductGroups = new Set<String>();

            if (!String.IsBlank(string.valueOf(opp.ICE_Opportunity_Product_Lines__c))) {
                setOldProductGroups.addAll(string.valueOf(opp.ICE_Opportunity_Product_Lines__c).split(','));
                }

                ilib_LogEvent.message('oppIdToProdGroup.get(opp.Id): ' + oppIdToProdGroup.get(opp.Id));
                ilib_LogEvent.message('setOldProductGroups: ' + setOldProductGroups);
            if (!(oppIdToProdGroup.get(opp.Id).containsAll(setOldProductGroups) && setOldProductGroups.containsAll(oppIdToProdGroup.get(opp.Id)))) {
                booCheckGroupChanged = true;
                opp.ICE_Opportunity_Product_Lines__c = String.join((Iterable<String>) oppIdToProdGroup.get(opp.Id), ',');
            }

            if (booCheckGroupChanged && !mapUpdateOpportunity.containsKey(opp.id)) {
                mapUpdateOpportunity.put(opp.Id, opp);
            }
        ilib_LogEvent.pop();
    }

    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public boolean updateOppFields(Opportunity opp, Map<Id, Set<String>> oppIdToProdType) {
        ilib_LogEvent.push('OpportunityLineItemsHelper.updateOppFields()'); 
        ilib_LogEvent.message('<--Join-->INSIDE updateOppFields');
        boolean isFieldChanged = false;
        //String strOldProductTypes = opp.Product_Type__c;
        Set<String> setOldProductTypes = new Set<String>();

        if (!String.isBlank(string.valueOf(opp.Product_Type__c))) {
            setOldProductTypes.addAll(string.valueOf(opp.Product_Type__c).split(';'));
            }
        if (!oppIdToProdType.isEmpty()) {
            ilib_LogEvent.message('oppIdToProdType.get(opp.Id): ' + oppIdToProdType.get(opp.Id));
            ilib_LogEvent.message('setOldProductTypes: ' + setOldProductTypes);

            if (!(oppIdToProdType.get(opp.Id).containsAll(setOldProductTypes) && setOldProductTypes.containsAll(oppIdToProdType.get(opp.Id)))) {
                isFieldChanged = true;
                opp.Product_Type__c = String.join((Iterable<String>) oppIdToProdType.get(opp.Id), ';');

            }
        }
        if (!opp.Are_Products_Added_by_Channel_Partner__c) {
            opp.Are_Products_Added_by_Channel_Partner__c = true;
            isFieldChanged = true;
        }
        if (!opp.Are_Products_Added__c) {
            opp.Are_Products_Added__c = true;
            isFieldChanged = true;
        }

        ilib_LogEvent.pop();
        return isFieldChanged;
    }

    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public void updateOpportunityForInformaticsProduct(Opportunity opp, Map<Id, Opportunity> mapUpdateOpportunity, Set<Id> setInfoOppids) {
        //DCP-30367 - if opportunity contains informatics product then update Informatics_Opportunity__c
        if(setInfoOppids.contains(opp.Id)) {
            opp.Informatics_Opportunity__c = true;
            ilib_LogEvent.message('updated opp in info : ' + opp.Id);
            if(!mapUpdateOpportunity.containsKey(opp.Id)) {
                mapUpdateOpportunity.put(opp.id , opp);}                   
        }
    }

     /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public void markisCRFRequiredTrue(Opportunity opp, boolean booCheckFieldsChanged, Map<Id, Opportunity> mapUpdateOpportunity, Set<Id> setCRFNeededOppIds) {
        ilib_LogEvent.push('OpportunityLineItemsHelper.markisCRFRequiredTrue()'); 
        ilib_LogEvent.message('<--Join-->INSIDE markisCRFRequiredTrue');
        if (booCheckFieldsChanged && !mapUpdateOpportunity.containsKey(opp.Id)) {
            mapUpdateOpportunity.put(opp.Id, opp);
        }
        //DCP-28965 - To update the Is_Customer_Readiness_Form_Required__c checkbox on opportunity
        if(setCRFNeededOppIds.contains(opp.Id) && !opp.Is_Customer_Readiness_Form_Required__c) {
            opp.Is_Customer_Readiness_Form_Required__c = true;
            if(!mapUpdateOpportunity.containsKey(opp.Id)) {
                mapUpdateOpportunity.put(opp.Id, opp);}
        }
        ilib_LogEvent.pop();
    }

    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public void createMapOppIdToOLI(List<OpportunityLineItem> lstAllOptyLineItems, Map<id, List<OpportunityLineItem>> mapOppidToOpportunitylineitem, Set<Id> setCRFNeededOppIds,Set<Id> setOppRecTypeSwitch) {
        ilib_LogEvent.push('OpportunityLineItemsHelper.createMapOppIdToOLI()');
        //DCP-30367 - Create map opp id to opportunity line item.
        for(OpportunityLineItem oli : lstAllOptyLineItems) {
            if(!mapOppidToOpportunitylineitem.containsKey(oli.OpportunityId) && oli.Has_Informatics_Product__c) {
                mapOppidToOpportunitylineitem.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            if(mapOppidToOpportunitylineitem.containsKey(oli.OpportunityId)) {
                mapOppidToOpportunitylineitem.get(oli.OpportunityId).add(oli);
            }
            /*if(oli.Product2.Auto_Create_Install_Work_Order__c && 
                ( oli.Product2.Service_Product_Type__c == System.Label.ProductClassInstrument || oli.Product2.Service_Product_Type__c == System.Label.ProductServiceProductTypeCore)  && 
                    oli.Product2.IsActive) {
                setCRFNeededOppIds.add(oli.opportunityId);
            }*/
            //CMCM-1662
            if(oli.Product2.Auto_Create_Installation_Workflow__c == INSTALL_WO_CASE_REQUEST && 
                ( oli.Product2.Service_Product_Type__c == System.Label.ProductClassInstrument || oli.Product2.Service_Product_Type__c == System.Label.ProductServiceProductTypeCore)  && 
                    oli.Product2.IsActive) {
                setCRFNeededOppIds.add(oli.opportunityId);
                    }
            //DCP-40052 - To create a set of Opportunities that satisfy certain conditions based on Opportunity Line Items
            if(oli.Product2.Material_Class__c == System.Label.ProductMaterialClassInstrument  && ( oli.Product2.Service_Product_Type__c == System.Label.ProductClassInstrument || oli.Product2.Service_Product_Type__c == System.Label.ProductServiceProductTypeCore)  && (oli.Product2.Material_Class_Type__c == System.Label.ProductMaterialClassTypeSystem ||oli.Product2.Auto_Create_Installation_Workflow__c == INSTALL_WO_CASE_REQUEST)) {
                setOppRecTypeSwitch.add(oli.opportunityId);
            }
        }
        ilib_LogEvent.pop();
    }

    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public void populateICEOpportunityProductLine(Opportunity opp, Map<Id, Set<String>> oppIdToProdGroup, Map<Id, Opportunity> mapUpdateOpportunity, Set<Id> setCRFNeededOppIds, Set<Id> setOppRecTypeSwitch) {
        ilib_LogEvent.push('OpportunityLineItemsHelper.populateICEOpportunityProductLine()');
        Boolean booCheckGroupChanged = false;

        //String strOldProductGroups = opp.ICE_Opportunity_Product_Lines__c;
        Set<String> setOldProductGroups = new Set<String>();

        if (!String.isBlank(string.valueOf(opp.ICE_Opportunity_Product_Lines__c))) {
            setOldProductGroups.addAll(string.valueOf(opp.ICE_Opportunity_Product_Lines__c).split(','));
        }

        if (oppIdToProdGroup.containsKey(opp.Id)) {
            // update parent opportunities with remaining product types
            ilib_LogEvent.message('<--Join-->');
            booCheckGroupChanged = true;
            ilib_LogEvent.message('<--Before Join-->' + opp.ICE_Opportunity_Product_Lines__c);
            opp.ICE_Opportunity_Product_Lines__c = String.join((Iterable<String>) oppIdToProdGroup.get(opp.Id), ',');
        } else {
            // update parent opportunities, all product types deleted
            if (!String.isBlank(opp.ICE_Opportunity_Product_Lines__c)) {
                opp.ICE_Opportunity_Product_Lines__c = null;
                booCheckGroupChanged = true;
            }
        }

        if (booCheckGroupChanged && !mapUpdateOpportunity.containsKey(opp.Id) && opp.Account_Change__c == False) {
            mapUpdateOpportunity.put(opp.Id, opp);
        }
        ilib_LogEvent.pop();
        updateCRFRAndRTSTSOnOppy(opp, mapUpdateOpportunity, setCRFNeededOppIds, setOppRecTypeSwitch);
    }

    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public void updateCRFRAndRTSTSOnOppy(Opportunity opp, Map<Id, Opportunity> mapUpdateOpportunity, Set<Id> setCRFNeededOppIds, Set<Id> setOppRecTypeSwitch) {
        ilib_LogEvent.push('OpportunityLineItemsHelper.updateCRFRAndRTSTSOnOppy()');
        //DCP-28965 - To update the Is_Customer_Readiness_Form_Required__c checkbox to true/false on opportunity
        if((setCRFNeededOppIds.isEmpty() || !setCRFNeededOppIds.contains(opp.Id)) 
            && opp.Is_Customer_Readiness_Form_Required__c) {
                opp.Is_Customer_Readiness_Form_Required__c = false;
            if(!mapUpdateOpportunity.containsKey(opp.Id)) {
                mapUpdateOpportunity.put(opp.Id, opp);
                }
        }
        //DCP-40052 - To set the Flag Is_Record_Type_Switched_To_Standard__c to false on Opportunity if all Opp line items meeting conditions are deleted
        if(setOppRecTypeSwitch.isEmpty() || !setOppRecTypeSwitch.contains(opp.Id)) {
            opp.Is_Record_Type_Switched_To_Standard__c = false;  
            if(!mapUpdateOpportunity.containsKey(opp.Id)) {
                    mapUpdateOpportunity.put(opp.Id, opp);
                    }
        }

        if(!mapUpdateOpportunity.containsKey(opp.Id)) { 
            mapUpdateOpportunity.put(opp.Id, opp);
        }
        ilib_LogEvent.pop();
    }

    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public void setInformaticsOppyToFalse(Opportunity opp,  Map<Id, Opportunity> mapUpdateOpportunity,Map<id, List<OpportunityLineItem>> mapOppidToOpportunitylineitem) {
        ilib_LogEvent.push('OpportunityLineItemsHelper.setInformaticsOppyToFalse()');
              
        //String strOldProductTypes = opp.Product_Type__c;
        Set<String> setOldProductTypes = new Set<String>();

        //DCP-30367 - if opportunity has no informatics oli then set Informatics_Opportunity__c to false.
        if(mapOppidToOpportunitylineitem.containsKey(opp.id)) {
             opp.Informatics_Opportunity__c = true;
        } else {
            opp.Informatics_Opportunity__c = false;
        }
        if(!mapUpdateOpportunity.containsKey(opp.Id)) {
            mapUpdateOpportunity.put(opp.Id, opp); 
        }                
        if (!String.IsBlank(string.valueOf(opp.Product_Type__c))) {
            setOldProductTypes.addAll(string.valueOf(opp.Product_Type__c).split(';'));
        }
        ilib_LogEvent.pop();
    }    

    /*
    * Author : Prem Ranjan
    * User Story : DCP - 52276
    * Functionality : Method Split to resolve N-Path Complexity
    */
    public Boolean updateParentOppFieldsOnOLIDel(Opportunity opp, Map<Id, Set<String>>oppIdToProdType) {
        ilib_LogEvent.push('OpportunityLineItemsHelper.updateParentOppFieldsOnOLIDel()');
        Boolean result = false;
        // NOTE: if this combination of criteria is commonly used
        // functions should be added to Opportunities.cls
        Boolean booStageCreateOrQualify = opp.StageName == Label.OpportunityStageCreate || opp.StageName == Label.OpportunityStageQualify;
        Boolean booStageCreateOrQualifyOrDevelop = opp.StageName == Label.OpportunityStageCreate || opp.StageName == Label.OpportunityStageQualify || opp.StageName == Label.OpportunityStageDevelop;
        Boolean booStageDevelop = opp.StageName == Label.OpportunityStageDevelop;
        Boolean booRtStandard = opp.RecordType.DeveloperName == Label.OpportunityRTDirectStandard;
        Boolean booRtIndirectStandard = opp.RecordType.DeveloperName == Label.OpportunityRTIndirectStandard;
        Boolean booRtDirectFieldServiceOrReorder = opp.RecordType.DeveloperName == Label.FieldServices || opp.RecordType.DeveloperName == Label.OpportunityRTDirectReOrder;
        Boolean booRtIndirectFieldServiceOrReorder = opp.RecordType.DeveloperName == Label.IndirectReOrder || opp.RecordType.DeveloperName == Label.IndirectFieldServices;
       
        if (oppIdToProdType.containsKey(opp.Id)) {
            // update parent opportunities with remaining product types
            ilib_LogEvent.message('<--Join-->');
            result = true;
            ilib_LogEvent.message('<--Before Join-->' + opp.Product_Type__c);
            opp.Product_Type__c = String.join((Iterable<String>) oppIdToProdType.get(opp.Id), ';');
            // update Are Products Added for all record types 
            if (!opp.Are_Products_Added__c && ((booRtStandard && booStageCreateOrQualifyOrDevelop) || (booRtDirectFieldServiceOrReorder && booStageDevelop))) {
                opp.Are_Products_Added__c = true;
                result = true;
            }
            if (((booStageCreateOrQualify && booRtIndirectStandard) || (booStageDevelop && booRtIndirectFieldServiceOrReorder)) && !opp.Are_Products_Added_by_Channel_Partner__c) {
                opp.Are_Products_Added_by_Channel_Partner__c = true;
                result = true;
            }
        } else {
            // update parent opportunities, all product types deleted
            if (!String.isBlank(opp.Product_Type__c)) {
                opp.Product_Type__c = null;
                result = true;
            }
            // update Are Products Added for all record types 
            if (opp.Are_Products_Added__c && ((booRtStandard && booStageCreateOrQualifyOrDevelop) || (booRtDirectFieldServiceOrReorder && booStageDevelop))) {
                opp.Are_Products_Added__c = false;
                result = true;
            }
            if (((booStageCreateOrQualify && booRtIndirectStandard) || (booStageDevelop && booRtIndirectFieldServiceOrReorder)) && opp.Are_Products_Added_by_Channel_Partner__c) {
                opp.Are_Products_Added_by_Channel_Partner__c = false;
                result = true;
            }
        }
        ilib_LogEvent.pop();
        return result;
    }

    /**
     *  @author       : Dushyant Srivastava.
     *  @description  : DCP-51025 updating Dist Mod Sales Price if sales price is updated.
     *  @return       : void
     */
    public static void markCPModifiedPriceTrue(List<OpportunityLineItem> lstTempOpp, Map<Id, SObject> idToOldOpportunityLineItem, boolean isAutomation) {
        for(OpportunityLineItem objOpportunityLineItem : lstTempOpp) {
            OpportunityLineItem oldOpportunityLineItem = (OpportunityLineItem)idToOldOpportunityLineItem.get(objOpportunityLineItem.Id);
            if(!isAutomation && oldOpportunityLineItem.UnitPrice != objOpportunityLineItem.UnitPrice) {
                objOpportunityLineItem.CP_Modified_Price__c = true;
            }
        }
    }

    /**
     *  @author       : Akash Kumar.
     *  @description  : US-7708: Prevent delete of Opportunity Products on Creation of Quote
     *  @return       : void
     */
    public static void addErrorOnOppLineItem(List<OpportunityLineItem> lstTempOpp, Map<Id, Opportunity> idToOpportunity) {
        for (OpportunityLineItem oli : lstTempOpp) {
            if (!oli.By_Pass_Sync_To_Opportunity__c && idToOpportunity.get(oli.OpportunityId).First_Proposal_Id__c != null && idToOpportunity.get(oli.OpportunityId).Account_Change__c == False) {
                oli.addError(System.Label.UI_AddProductErrorOnQuoteCreation);
            }
        }
    }

}