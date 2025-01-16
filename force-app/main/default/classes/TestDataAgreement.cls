/**
 *    @author Kushagra Desai
 *    @date   12-Dec-2019
 *    @description  Test data creation
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *      Roopal                        1 sep 2020                  modified initApprovalMatrixForAgreement to add Approval hierarchy type  
 *      Aman Tyagi                    7th Oct 2022                codescan Fixes
 *      Saddam                           08-Dec-2022             Codescan Fix , Varaible naming convention. 
 *    ------------------------------------------------------------------------------------
 *
 */
@isTest
public class TestDataAgreement {

    /**
    * @author Kushagra Desai
    * @description static method addHierarchyPermission()
    * @return NA
    **/
    public static void addHierarchyPermission()
    {
		addHierarchyPermission(UserInfo.getProfileId());
    }

    /**
    * @author  Kushagra Desai 
    * @description static method addHierarchyPermission
    * @param Id userId
    * @return NA
    **/
    public static void addHierarchyPermission(Id userId)
    {
		insert new CLM_ProfileValidation__c(
            SetupOwnerId = userId,
            Channel_Partner_Agreement__c = true,
            Master_Customer_Agreement__c = true,
            Master_Service_Agreement__c = true,
            Negotiated_Terms_and_Conditions__c = true,
            Standing_Quote__c = true,
            Open_Offer_Agreement__c = true,
            Tender__c = true);
    }
    /**
    * @author  Kushagra Desai 
    * @description static method initAgreements
    * @param String agreementName, Id accountId
    * @return Apttus__APTS_Agreement__c
    **/
    public static Apttus__APTS_Agreement__c initAgreements(String agreementName, Id accountId)
    {
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standing Quote').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c(
            Name = agreementName,
            Apttus__Account__c  = accountId,
            Apttus__Contract_Start_Date__c = system.today(),
            RecordTypeId = recTypeId
            
        );
        return oAgreement;
    }

    /**
    * @author  Kushagra Desai 
    * @description static method initAgreementsLineItem
    * @param Id agreementId
    * @return Apttus__AgreementLineItem__c
    **/
     public static Apttus__AgreementLineItem__c initAgreementsLineItem(Id agreementId)
    {
       
        Apttus__AgreementLineItem__c oAgreementLineItem = new Apttus__AgreementLineItem__c(
            Apttus__AgreementId__c = agreementId
        );
        return oAgreementLineItem;
    }

     /**
     *  @author Saswati
     *  @description Initialize Price List sObject
     *  @param strName Price List Name
     *  @return Price List sObject
     **/
    public static Apttus_Config2__PriceList__c initPriceList(String strName)
    {
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c(
            Name = strName,
            Apttus_Config2__Active__c = true
        );
        return priceList;
    }

     /**
     *  @author Saswati 
     *  @description Initialize Price List Item sObject
     *  @param product Product sObject
     *  @param priceList Price List sObject
     *  @return Price List Item sObject
     **/
    public static Apttus_Config2__PriceListItem__c initPriceListItem(Product2 product, Apttus_Config2__PriceList__c priceList) {
        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c(
            Apttus_Config2__ProductId__c = product.id,
            Apttus_Config2__PriceListId__c = priceList.id,
            Apttus_Config2__ChargeType__c = 'Standard Fee',
            Apttus_Config2__PriceType__c = 'Recurring',
            Apttus_Config2__ListPrice__c = 100,
            Apttus_Config2__PriceMethod__c = 'Per Unit',
            Apttus_Config2__PriceUom__c = 'Each',
            Apttus_Config2__BillingRule__c = 'Bill in Advanced',
            Apttus_Config2__Frequency__c = 'Monthly',
            Apttus_Config2__Active__c = true,
            Apttus_Config2__EffectiveDate__c=system.today(),
            Apttus_Config2__ExpirationDate__c=system.today()+5
        );
        return pli;
    }

     /**
     *  @author Saswati Prusty
     *  @description Initialize Custom Approval Matrix sObject
     *  @param obj Type of Approval Hierarchy
     *  @return Approval Hierarchy sObject
     **/
    public static Approval_Hierarchy__c initApprovalHierarchy(String strType){
        Approval_Hierarchy__c objApprovalHeirarchy = new Approval_Hierarchy__c(
            Name = 'Test Hierarchy',
            Approver_Level_1__c = UserInfo.getUserId(),
            Approver_Level_2__c = UserInfo.getUserId(),
            Approver_Level_3__c = UserInfo.getUserId(),
            Approver_Level_4__c = UserInfo.getUserId(),
            Approver_Level_5__c = UserInfo.getUserId(),
            Approver_Level_6__c = UserInfo.getUserId(),
            Approval_Hierarchy_Type__c = strType
        );
        return objApprovalHeirarchy;
    }

     /**
     *  @author Saswati Prusty - 31789
     *  @description Initialize Custom Approval Matrix sObject
     *  @param recordTypeName Record Type for which matrix created (e.g. Discount)
     *  @param decPercent Discount percent
     *  @param strLevel Approval level
     *  @return Custom Approval Matrix sObject
     **/
    public static Custom_Approval_Matrix__c initApprovalMatrixForAgreement(String recordTypeName, Decimal decPercent, String strMaterialGroup, Id materialNumber, Id approvalHierarchy) {
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
         Custom_Approval_Matrix__c matrix = new Custom_Approval_Matrix__c(
            Name = recordTypeName + ' Approval Matrix',
            RecordTypeId = recTypeId,
            Distribution_Channel__c = 'Direct',
            Currency__c = 'USD',
            region__c = 'AMR',  
            Sales_Organization__c = 'HK01',
            Discount_Level_1__c = 5,
            Discount_Level_2__c=10,         
            Discount_Level_3__c=15,         
            Discount_Level_4__c=20,      
            Discount_Level_5__c=25,          
            Discount_Level_6__c=30,
            Material_Group_1__c = strMaterialGroup,
            Material_Number__c = materialNumber,
            Approval_Hierarchy__c = approvalHierarchy,
            Approval_Hierarchy_Type__c = 'Record Owner;Custom'  // 40115
        );
        return matrix;
    }  
    /**
    *  @author      : Umesh Mor - 31177
    *  @description : Initialize Agreement Approval Data.
    **/
    public static Apttus_Approval__Approval_Request__c initAgreementApprovalRequest(Id agreementId)
    {
        User user = TestDataUser.findUserInProfile('System Administrator');
        user.Title = 'test title';
        update user;
        Apttus_Approval__Approval_Request__c objApprovalRequest = new Apttus_Approval__Approval_Request__c();
        objApprovalRequest.Apttus_Approval__Sequence__c = '1';
        objApprovalRequest.Apttus_Approval__Assigned_To_Id__c = user.id;
        objApprovalRequest.Apttus_Approval__Step_Name__c = 'test';
        objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = user.Name;
        objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Not Submitted';
        objApprovalRequest.Apttus_Approval__Assigned_To_Type__c = 'User';
        objApprovalRequest.Apttus_Approval__Related_Agreement__c = agreementId;
        objApprovalRequest.Apttus_Approval__StepSequence__c = 1.1;
        return objApprovalRequest;
    }

    /**
     *  @author Saswati Prusty - DCP-32563
     *  @description Initialize Custom Approval Matrix sObject
     *  @param obj Type of Approval Hierarchy
     *  @return Approval Hierarchy sObject
     **/
    public static Approval_Hierarchy__c initApprovalHierarchyStandingDiscount(String strType, Id strOwnerId){
        Approval_Hierarchy__c objApprovalHeirarchy = new Approval_Hierarchy__c(
            Name = 'Test Hierarchy',
            Approver_Level_1__c = strOwnerId,
            Approver_Level_2__c = UserInfo.getUserId(),
            Approver_Level_3__c = UserInfo.getUserId(),
            Approver_Level_4__c = UserInfo.getUserId(),
            Approver_Level_5__c = UserInfo.getUserId(),
            Approver_Level_6__c = UserInfo.getUserId(),
            Approval_Hierarchy_Type__c = strType
        );
        return objApprovalHeirarchy;
    }

    /**
     *  @author Saswati Prusty - 32046
     *  @description Initialize Custom Approval Matrix sObject
     *  @param recordTypeName Record Type for which matrix created (e.g. Discount)
     *  @param decPercent Discount percent
     *  @param strLevel Approval level
     *  @return Custom Approval Matrix sObject
     **/
    public static Custom_Approval_Matrix__c initClauseApprovalMatrix(String recordTypeName, String strEmailQueue, String strAgreementRecordType)
    {
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Custom_Approval_Matrix__c matrix = new Custom_Approval_Matrix__c(
            Name = recordTypeName + ' Approval Matrix',
            RecordTypeId = recTypeId,
            Action__c = 'Inserted',
            Clause_Name__c = 'SQ - AMR-Standard Tax-English',
            Region__c = 'AMR',  
            Active__c = true,
            Email_Queue__c = strEmailQueue,
            Agreement_Record_Type__c = strAgreementRecordType
        );
        return matrix;
    }

    /*
    Added by Saswati 
    */
    public static Apttus__Agreement_Clause__c initAgreementClauses( Id agreementId, String strClause)
    {
        Apttus__Agreement_Clause__c oAgreementClause = new Apttus__Agreement_Clause__c(
            Apttus__Active__c = true,
            Apttus__Agreement__c  = agreementId,
            Apttus__Action__c = 'Inserted',
            Apttus__Clause__c = strClause,
            CurrencyIsoCode = 'USD'
            
        );
        return oAgreementClause;
    }
    /**
    * @author  
    * @description static method initRelationship
    * @param Id accountId, Id agreementId
    * @return Agreement_Account_Relationship__c
    **/
    public static Agreement_Account_Relationship__c initRelationship(Id accountId, Id agreementId)
    {
        Agreement_Account_Relationship__c rec = new Agreement_Account_Relationship__c(
            Account__c = accountId,
            Agreement__c = agreementId
        );
        return rec;
    }

    /**
    * @author  
    * @description static method to get the new Agreement Account relationship
    * @param Id accountId, Id agreementId
    * @return Agreement_Account_Relationship__c
    **/
    public static Agreement_Account_Relationship__c getNewRelationship(Id accountId, Id agreementId)
    {
        Agreement_Account_Relationship__c rec = initRelationship(accountId, agreementId);
        insert rec;
        return rec;
    }

}