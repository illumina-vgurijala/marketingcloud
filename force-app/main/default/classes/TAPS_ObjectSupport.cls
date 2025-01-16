/**
*    @author Todd N   
*    @date          
*    @description   Accounts domain class
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Akshay Mohan                18-June-2021           DCP-38968 Change sharing logic for Opportunity to Field Support
*             Adyasha Satapathy           03-Dec-2021            DCP-50392 Added Junction Object Objective Opportunity Relationship
*             Koustubh M                  22-May-2022            TASK0748834 Added Channel_Partner_Quota__c
*             Gerardo Garcia              29-Sep-2023            CMCM-2893 Added Competitive_Complementary_Technology__c
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_ObjectSupport {

    // only these objects are supported by the factory method 
    public static List<SObjectType> allSharedObjectTypes = new List<SObjectType> {
        SVMXC__Installed_Product__c.SObjectType,
        Comment__c.SObjectType,
        Apttus__APTS_Agreement__c.SObjectType,
        Apttus_Proposal__Proposal__c.SObjectType,
        Apttus_Config2__ProductConfiguration__c.SObjectType,
        Apttus_Config2__FavoriteConfiguration__c.SObjectType,
        Apttus_Config2__TempObject__c.SObjectType,
        Customer_Readiness_Form__c.SObjectType,
        Apttus_Config2__Order__c.SObjectType,
        Apttus_Config2__AssetLineItem__c.SObjectType,
        Apttus_Config2__AssetLineItemHistory__c.SObjectType,
        Apttus_Approval__Approval_Request__c.SObjectType,
        Apttus_Approval__Approval_Request_History__c.SObjectType,
        Apttus_Config2__TempRenewAssetGroup__c.SObjectType,
        Apttus_Config2__TempRenewAssetLineItem__c.SObjectType,
        SVMXC__Service_Order__c.SObjectType,
        SVMXC__Site__c.SObjectType,
        SVMXC__Product_Stock__c.SObjectType,
        SVMXC__Parts_Request__c.SObjectType,
        SVMXC__RMA_Shipment_Order__c.SObjectType,
        Consortium__c.SObjectType,
        Partner_Request__c.SObjectType,
        Opportunity.SObjectType,  
        //Added for DCP-27435 for Account Plan Sharing
        Account_Plan__c.SObjectType,
        Apttus__DocumentVersion__c.SObjectType,
        // Added for DCP-50392
        Objective_Opportunity_Relationship__c.SObjectType,
        // Added for TASK0718153
        Apttus__APTS_Related_Agreement__c.SObjectType,
        //Added for TASK0748834
        Channel_Partner_Quota__c.SObjectType,
        Competitive_Complementary_Technology__c.SObjectType
    };

    //Added for DCP-27435 for Account To Field Support Sharing
    // only these objects are supported by the factory method. 
    //Add those objects which need to be shared on change of Account to Field Support
    public static List<SObjectType> allATFSSharedObjectTypes = new List<SObjectType> {
        Account_Plan__c.SObjectType,
        Opportunity.SObjectType,//DCP-38968
        Objective_Opportunity_Relationship__c.SObjectType //DCP-50392
    };

    /*
    * Comments are added to fix code scan issues
    */
    public static TAPS_ComposedBase sharingFactory(SObjectType objType)
    {
        if (objType == SVMXC__Installed_Product__c.SObjectType)
            return new TAPS_InstalledProducts();
        if (objType == Comment__c.SObjectType)
            return new TAPS_Comments();
        if (objType == Apttus__APTS_Agreement__c.SObjectType)
            return new TAPS_ApttusAgreements();
        if (objType == Apttus_Proposal__Proposal__c.SObjectType)
            return new TAPS_ApttusProposals();
        if (objType == Apttus_Config2__ProductConfiguration__c.SObjectType)
            return new TAPS_ApttusProductConfiguration();
        if (objType == Apttus_Config2__FavoriteConfiguration__c.SObjectType)
            return new TAPS_ApttusFavoriteConfiguration();
        if (objType == Apttus_Config2__TempObject__c.SObjectType)
            return new TAPS_ApttusTempObject();
        if (objType == Customer_Readiness_Form__c.SObjectType)
            return new TAPS_CustomerReadinessForm();
        if (objType == Apttus_Config2__Order__c.SObjectType)
            return new TAPS_ApttusOrder();
        if (objType == Apttus_Config2__AssetLineItem__c.SObjectType)
            return new TAPS_ApttusAssetLine();
        if (objType == Apttus_Config2__AssetLineItemHistory__c.SObjectType)
            return new TAPS_ApttusAssetLineHistory();
        if (objType == Apttus_Approval__Approval_Request__c.SObjectType)
            return new TAPS_ApttusApprovalRequest();
        if (objType == Apttus_Approval__Approval_Request_History__c.SObjectType)
            return new TAPS_ApttusApprovalRequestHistory();
        if (objType == Apttus_Config2__TempRenewAssetGroup__c.SObjectType)
            return new TAPS_ApttusTempRenewAssetGroup();
        if (objType == Apttus_Config2__TempRenewAssetLineItem__c.SObjectType)
            return new TAPS_ApttusTempRenewAssetLine();
        if (objType == SVMXC__Service_Order__c.SObjectType)
            return new TAPS_SmaxWorkOrder();
        if (objType == SVMXC__Parts_Request__c.SObjectType)
            return new TAPS_SmaxPartsRequest();
        if (objType == SVMXC__RMA_Shipment_Order__c.SObjectType)
            return new TAPS_SmaxPartsOrders();

        // Channel Partner-specific sharing
        if (objType == SVMXC__Site__c.SObjectType)
            return new TAPS_Locations();
        if (objType == SVMXC__Product_Stock__c.SObjectType)
            return new TAPS_ProductStock();
        
        if (objType == Consortium__c.SObjectType)
            return new TAPS_Consortium();

        //Added for DCP-25198 for Partner Request Sharing
        if (objType == Partner_Request__c.SObjectType)
            return new TAPS_PartnerRequest();
        
        //Added for DCP-27435 for Account Plan Sharing
        if (objType == Account_Plan__c.SObjectType)
            return new TAPS_AccountPlans();

        if (objType == Opportunity.SObjectType)
            return new TAPS_Opportunity();

        if (objType == Apttus__DocumentVersion__c.SObjectType)
            return new TAPS_ApttusDocumentVersion();

        if(objType == Objective_Opportunity_Relationship__c.SObjectType) {
            return new TAPS_ObjectiveOpportunityRelationships();
        }
        // Added for TASK0718153
        if(objType == Apttus__APTS_Related_Agreement__c.SObjectType) {
            return new TAPS_ApttusRelatedAgreement();
        }
        
        //Added for TASK0748834
        if(objType == Channel_Partner_Quota__c.SObjectType) {
            return new TAPS_ChannelPartnerQuotas();
        }

        if(objType == Competitive_Complementary_Technology__c.SObjectType) {
            return new TAPS_CompetitiveComplementaryTech();
        }

        throw new ApexSharingObjectSupportException(TAPS_ComposedBase.ETM_SHARING_NOT_SUPPORTED + objType);
    }

    /*
    * Comments are added to fix code scan issues
    */
    public class ApexSharingObjectSupportException extends Exception { }

}