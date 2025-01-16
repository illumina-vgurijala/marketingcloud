/**
 *    @author Rohan Chandarana
 *    @date   2018-05-15
 *    @description  DCP-454: Create Quote - Ability to Clone Quote
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *          Rahul Sharma                    23-Oct-2018         Added Is Updated By System Flag to initProposal
 *          Roopal Verma                    30-May-2019         DCP-25322, Manual rebate
 *          Kushagra Desai                  21-June-2019        DCP-26680 : Added new field to custom setting
 *          Roopal Verma                    12-Aug-2019         DCP-28526 : Added new methods initApprovalIncoTermMatrix 
 *          Umesh                           23-Jan-2020         DCP-31142 - Added New Method initAgreementApprovalRequest
 *          prem ranjan                     09-Sep-2022         DCP-56856 : commented update to user in initApprovalRequest method for avoid too many sql
 *          Jitesh Lakhwani                 1-Jan-2023          Code scan fix
 *    ------------------------------------------------------------------------------------
 *
 */
@isTest
public class TestDataProposal
{

    /**
     *  @author Rohan Chandarana
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
     *  @author Rohan Chandarana
     *  @description Initialize Proposal sObject
     *  @param idAcc Account Id
     *  @param idOpp Opportunity Id
     *  @param strName Proposal Name
     *  @param idPriceList Price List Id
     *  @param isPrimary proposal primary or not
     *  @return Proposal sObject
     **/
    public static Apttus_Proposal__Proposal__c getNewProposal(String strName, Boolean isPrimary, String strQuteStage, String strApprovalStatus)
    {
        Apttus_Proposal__Proposal__c rec = initProposal(strName, isPrimary, strQuteStage, strApprovalStatus);
        insert rec;
        return rec;
    }
    /**
     *  @author Rohan Chandarana
     *  @description Initialize Proposal sObject
     *  @param idAcc Account Id
     *  @param idOpp Opportunity Id
     *  @param strName Proposal Name
     *  @param idPriceList Price List Id
     *  @param isPrimary proposal primary or not
     *  @return Proposal sObject
     **/
    public static Apttus_Proposal__Proposal__c initProposal(String strName, Boolean isPrimary, String strQuteStage, String strApprovalStatus)
    {
        Id recTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        Apttus_Proposal__Proposal__c prop = new Apttus_Proposal__Proposal__c(
            Apttus_Proposal__Proposal_Name__c = strName,
            RecordTypeId = recTypeId,
            Apttus_Proposal__Primary__c = isPrimary,
            Apttus_Proposal__Approval_Stage__c = strQuteStage,
            Apttus_QPApprov__Approval_Status__c = strApprovalStatus,
            Is_Updated_By_System__c = true
        );
        return prop;
    }

    /**
     *  @author Rohan Chandarana
     *  @description Initialize Proposal sObject
     *  @param idAcc Account Id
     *  @param idOpp Opportunity Id
     *  @param strName Proposal Name
     *  @param idPriceList Price List Id
     *  @param isPrimary proposal primary or not
     *  @return Proposal sObject
     **/
    public static Apttus_Proposal__Proposal__c getNewProposal(Id idAcc, Id idOpp, String strName, Id idPriceList, Boolean isPrimary, String strQuteStage, String strApprovalStatus)
    {
        Apttus_Proposal__Proposal__c rec = initProposal(idAcc, idOpp, strName, idPriceList, isPrimary, strQuteStage, strApprovalStatus);
        insert rec;
        return rec;
    }
    /**
     *  @author Rohan Chandarana
     *  @description Initialize Proposal sObject
     *  @param idAcc Account Id
     *  @param idOpp Opportunity Id
     *  @param strName Proposal Name
     *  @param idPriceList Price List Id
     *  @param isPrimary proposal primary or not
     *  @return Proposal sObject
     **/
    public static Apttus_Proposal__Proposal__c initProposal(Id idAcc, Id idOpp, String strName, Id idPriceList, Boolean isPrimary, String strQuteStage, String strApprovalStatus)
    {
        Id recTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        Apttus_Proposal__Proposal__c prop = new Apttus_Proposal__Proposal__c(
            Apttus_Proposal__Proposal_Name__c = strName,
            Apttus_Proposal__Opportunity__c  = idOpp,
            Apttus_QPConfig__PriceListId__c = idPriceList,
            RecordTypeId = recTypeId,
            Apttus_Proposal__Primary__c = isPrimary,
            Apttus_Proposal__Account__c = idAcc,
            Apttus_Proposal__Approval_Stage__c = strQuteStage,
            Apttus_QPApprov__Approval_Status__c = strApprovalStatus,
            Is_Updated_By_System__c = true
        );
        return prop;
    }

    /**
     *  @author Divyansh
     *  @description Initialize Restricted Product object record
     *  @param product Account ,Product sObject
     *  @return Restricted_Product__c custom Object record
     **/
    public static Restricted_Product__c initRestrictedProduct(Account objAccount, Product2 objProduct){
        Restricted_Product__c resprod = new Restricted_Product__c(
            Account__c = objAccount.id,
            Product__c = objProduct.id
        );
        return resprod;
    }

    /**
     *  @author Rohan Chandarana
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
     *  @author Rohan Chandarana
     *  @description Initialize Proposal Line Item sObject
     *  @param proposal Proposal sObject
     *  @param product Product sObject
     *  @return Proposal Line Item sObject
     **/
    public static Apttus_Proposal__Proposal_Line_Item__c initProposalLineItem(Apttus_Proposal__Proposal__c proposal, Product2 product) {
        Apttus_Proposal__Proposal_Line_Item__c propLine = new Apttus_Proposal__Proposal_Line_Item__c(
            Apttus_Proposal__Proposal__c = proposal.id,
            Apttus_Proposal__Product__c = product.id,
            Apttus_Proposal__Service_Date__c = system.Today(),
            Apttus_Proposal__Quantity__c = 1,
            Apttus_QPConfig__ExtendedPrice__c = 50000,
            Apttus_QPConfig__AdjustedPrice__c = 30000,
            Apttus_QPConfig__NetPrice__c = 30000,
            Apttus_QPConfig__NetAdjustmentPercent__c = -20,
            Apttus_QPConfig__LineStatus__c = 'New',
            Apttus_QPConfig__LineType__c = 'Product/Service',
            Apttus_QPConfig__ClassificationHierarchy__c = 'Level_0|Level_1|Level_2|Level_3|Level_4',
            Apttus_QPConfig__IsPrimaryLine__c = true
        );
        return propLine;
    }

    /**
     *  @author Rohan Chandarana
     *  @description Initialize Proposal Adjustment Line Item sObject
     *  @param proposalLineItem Proposal Line Item sObject
     *  @return Proposal Adjustment Line Item sObject
     **/
    public static Apttus_QPConfig__ProposalAdjustmentLineItem__c initProposalAdjustmentLineItem(Apttus_Proposal__Proposal_Line_Item__c pli) {
        Apttus_QPConfig__ProposalAdjustmentLineItem__c propAdjLine = new Apttus_QPConfig__ProposalAdjustmentLineItem__c(
            Apttus_QPConfig__Type__c = 'Promotion',
            Apttus_QPConfig__LineItemId__c = pli.id,
            Apttus_QPConfig__LineType__c = 'Auto',
            Apttus_QPConfig__LineNumber__c = 1,
            Apttus_QPConfig__IncentiveCode__c = 'BOGO'
        );
        return propAdjLine;
    }

    /**
     *  @author Govind Dubey
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
     *  @author Govind Dubey
     *  @description Initialize Backup Approver data
     *  @param NA
     *  @return Backup Approver Object
     **/
    public static Apttus_Approval__Backup_Approver__c initBackupApprover(User objBackupUser,User objCurrentUser){
        Apttus_Approval__Backup_Approver__c objBackupApprover = new Apttus_Approval__Backup_Approver__c(
            Apttus_Approval__IsActive__c = true,
            Apttus_Approval__Effective_Date__c = system.today()+1,
            Apttus_Approval__Expiration_Date__c = system.today()+3,
            Apttus_Approval__Current_User__c =objCurrentUser.Id,
            Apttus_Approval__Backup_User__c = objBackupUser.Id,
            Apttus_Approval__Transfer_in_flight__c = true,
            Apttus_Approval__DelegateUserIds__c = objBackupUser.Id
        );
        return objBackupApprover;
    }

    /**
     *  @author Rohan Chandarana
     *  @description Initialize Custom Approval Matrix sObject
     *  @param recordTypeName Record Type for which matrix created (e.g. Product, Product Group etc)
     *  @param obj sObject (e.g. Product, Classification Hierarchy etc)
     *  @return Custom Approval Matrix sObject
     **/
    public static Custom_Approval_Matrix__c initApprovalMatrix(String recordTypeName, sObject obj , Decimal disPercentage , Decimal disAmount, String newregion, String appLevel, String newcurrency  ,Approval_Hierarchy__c objApprovalHeirarchy  ) {
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Custom_Approval_Matrix__c matrix = new Custom_Approval_Matrix__c(
            Name = recordTypeName + ' Approval Matrix',
            RecordTypeId = recTypeId,
            region__c=newregion,
            Currency__c = newcurrency,
            Distribution_Channel__c = 'Direct',
            Discount_Level_1__c = 5,
            Discount_Amount_Level_1__c=5000,
            Discount_Level_2__c=10,
            Discount_Amount_Level_2__c=10000,
            Discount_Level_3__c=15,
            Discount_Amount_Level_3__c=15000,
            Discount_Level_4__c=20,
            Discount_Amount_Level_4__c=20000,
            Discount_Level_5__c=25,
            Discount_Amount_Level_5__c=25000,
            Discount_Level_6__c=30,
            Discount_Amount_Level_6__c=30000,
            Discount_Level_7__c=55,
            Discount_Amount_Level_7__c=50000,
            Discount_Level_8__c=65,
            Discount_Amount_Level_8__c=75000,
            Approval_Hierarchy__c = objApprovalHeirarchy.Id,
            Approval_Hierarchy_Type__c = 'Record Owner;Custom'
        );
        return matrix;
    }

    /**
     *  @author Rohan Chandarana
     *  @description Initialize Custom Approval Matrix sObject
     *  @param recordTypeName Record Type for which matrix created (e.g. Discount)
     *  @param decAmount Discount amount
     *  @param decPercent Discount percent
     *  @param strLevel Approval level
     *  @return Custom Approval Matrix sObject
     **/
    public static Custom_Approval_Matrix__c initApprovalMatrixForDiscount(String recordTypeName, Decimal decAmount, Decimal decPercent, String strLevel) {
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Custom_Approval_Matrix__c matrix = new Custom_Approval_Matrix__c(
            Name = recordTypeName + ' Approval Matrix',
            RecordTypeId = recTypeId,
            Distribution_Channel__c = 'Direct',
            Currency__c = 'USD',
            region__c = 'AMR',
            Min_Discount__c = 4,
            Min_Discount_Amount__c = 400,
            Discount_Level_1__c = 5,
            Discount_Amount_Level_1__c=500,
            Discount_Level_2__c=10,
            Discount_Amount_Level_2__c=1000,
            Discount_Level_3__c=15,
            Discount_Amount_Level_3__c=1500,
            Discount_Level_4__c=20,
            Discount_Amount_Level_4__c=2000,
            Discount_Level_5__c=25,
            Discount_Amount_Level_5__c=2500,
            Discount_Level_6__c=30,
            Discount_Amount_Level_6__c=3000
        );
        return matrix;
    }

    /**
     *  @author Rohan Chandarana
     *  @description Initialize Custom Approval Matrix sObject
     *  @param recordTypeName Record Type for which matrix created (e.g. Material Class)
     *  @param strMaterialClass Product Material Class
     *  @return Custom Approval Matrix sObject
     **/
    public static Custom_Approval_Matrix__c initApprovalMatrixForMaterialClass(String recordTypeName, String strMaterialClass,Approval_Hierarchy__c objApprovalHeirarchy) {
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Custom_Approval_Matrix__c matrix = new Custom_Approval_Matrix__c(
            Name = recordTypeName + ' Approval Matrix',
            RecordTypeId = recTypeId,
            Material_Class__c = strMaterialClass,
            Distribution_Channel__c = 'Direct',
            Currency__c = 'USD',
            region__c = 'AMR',
            Min_Discount__c = 4,
            Min_Discount_Amount__c = 400,
            Discount_Level_1__c = 5,
            Discount_Amount_Level_1__c=500,
            Discount_Level_2__c=10,
            Discount_Amount_Level_2__c=1000,
            Discount_Level_3__c=15,
            Discount_Amount_Level_3__c=1500,
            Discount_Level_4__c=20,
            Discount_Amount_Level_4__c=2000,
            Discount_Level_5__c=25,
            Discount_Amount_Level_5__c=2500,
            Discount_Level_6__c=30,
            Discount_Amount_Level_6__c=3000,
            Approval_Hierarchy__c = objApprovalHeirarchy.Id
        );
        return matrix;
    }

    /**
     *  @author Rohan Chandarana
     *  @description Initialize Custom Approval Matrix sObject
     *  @param recordTypeName Record Type for which matrix created (e.g. PostPricingMatrix)
     *  @param initApprovalPostPricingMatrix
     *  @return Custom Approval Matrix sObject
     **/
    public static Custom_Approval_Matrix__c initApprovalPostPricingMatrix(String recordTypeName, String emailQueue) {
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Custom_Approval_Matrix__c matrix = new Custom_Approval_Matrix__c(
            Name = recordTypeName + ' Approval Matrix',
            RecordTypeId = recTypeId,
            Email_Queue__c = emailQueue,
            Approver__c = UserInfo.getUserId(),
            Distribution_Channel__c = 'Direct',
            Currency__c = 'USD',
            region__c = 'AMR',
            Post_Pricing_Message__c = 'Non-Standard Post Pricing Message'
        );
        return matrix;
    }

    /**
     *  @author Govind Dubey
     *  @description Initialize Custom Approval Matrix sObject of Payment Term type
     *  @param recordTypeName Record Type for which matrix created
     *  @param queue name
     *  @return Custom Approval Matrix sObject
     **/
    public static Custom_Approval_Matrix__c initApprovalPaymentTermMatrix(String recordTypeName, String emailQueue) {
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Custom_Approval_Matrix__c matrix = new Custom_Approval_Matrix__c(
            Name = recordTypeName + ' Approval Matrix',
            RecordTypeId = recTypeId,
            Email_Queue__c = emailQueue,
            region__c = 'AMR'
        );
        return matrix;
    }

    /** 
     *  @author Roopal 
     *  @description Initialize Custom Approval Matrix sObject of Inco Term type 
     *  @param recordTypeName Record Type for which matrix created 
     *  @param queue name 
     *  @param region name 
     *  @return Custom Approval Matrix sObject 
     **/ 
    public static Custom_Approval_Matrix__c initApprovalIncoTermMatrix(String recordTypeName, String emailQueue,String region) {  
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId(); 
        Custom_Approval_Matrix__c matrix = new Custom_Approval_Matrix__c( 
            Name = recordTypeName + ' Approval Matrix', 
            RecordTypeId = recTypeId, 
            Email_Queue__c = emailQueue, 
            Region__c = region 
        ); 
        return matrix; 
    } 


    /**
     *  @author Rohan Chandarana
     *  @description Initialize Custom Approval Matrix sObject
     *  @param recordTypeName Record Type for which matrix created (e.g. Discount)
     *  @param decAmount Discount amount
     *  @param decPercent Discount percent
     *  @param strLevel Approval level
     *  @return Custom Approval Matrix sObject
     **/
    public static Custom_Approval_Matrix__c initApprovalMatrixForPromotion(String recordTypeName, String strPromoCode, String strLevel,Approval_Hierarchy__c objApprovalHeirarchy) {
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Custom_Approval_Matrix__c matrix = new Custom_Approval_Matrix__c(
            Name = recordTypeName + ' Approval Matrix',
            RecordTypeId = recTypeId,
            //Promotion_Code__c = strPromoCode,
            Region__c ='AMR',
            Discount_Level_1__c = 5,
            Discount_Amount_Level_1__c=5000,
            Discount_Level_2__c=10,
            Discount_Amount_Level_2__c=10000,
            Discount_Level_3__c=15,
            Discount_Amount_Level_3__c=15000,
            Discount_Level_4__c=20,
            Discount_Amount_Level_4__c=20000,
            Discount_Level_5__c=25,
            Discount_Amount_Level_5__c=25000,
            Discount_Level_6__c=30,
            Discount_Amount_Level_6__c=30000,
            Approval_Hierarchy__c = objApprovalHeirarchy.Id
        );
        return matrix;
    }

    /**
     *  @author Rohan Chandarana 
     *  @description Initialize Category sObject
     *  @param name Name of the category
     *  @return Category sObject
     **/
    public static Apttus_Config2__ClassificationName__c initCategory(String name) {
        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c(
            Apttus_Config2__HierarchyLabel__c = name,
            Apttus_Config2__Active__c = true,
            Apttus_Config2__Type__c = 'Offering'
        );
        return category;
    }

    /**
     *  @author Rohan Chandarana
     *  @description Initialize Category Hierarchy sObject
     *  @param category Category sObject
     *  @param name Name of the Hierarchy
     *  @param primordial
     *  @param anestor
     *  @param level Hierarchy Level
     *  @return Category Hierarchy sObject
     **/
    public static Apttus_Config2__ClassificationHierarchy__c initHierarchy(Apttus_Config2__ClassificationName__c category, String name, Apttus_Config2__ClassificationHierarchy__c primordial, Apttus_Config2__ClassificationHierarchy__c anestor, double level){
        Apttus_Config2__ClassificationHierarchy__c hierarchy = new Apttus_Config2__ClassificationHierarchy__c(
            Apttus_Config2__HierarchyId__c = category.id,
            Apttus_Config2__PrimordialId__c = (primordial == null) ? null : primordial.id,
            Apttus_Config2__AncestorId__c = (anestor == null) ? null : anestor.id,
            Apttus_Config2__Level__c = level,
            Apttus_Config2__Label__c = name,
            Name = name
        );
        return hierarchy;
    }

    /**
    *  @author Tushar Arora
    *  @description Initialize Category Hierarchy sObject
    *  @param category Category sObject
    *  @param name Name of the Hierarchy
    *  @return Category Hierarchy sObject
    **/
    public static Apttus_Config2__ClassificationHierarchy__c initClassification(Apttus_Config2__ClassificationName__c category, String name, double level){
        Apttus_Config2__ClassificationHierarchy__c hierarchy = new Apttus_Config2__ClassificationHierarchy__c(
            Apttus_Config2__HierarchyId__c = category.id,
            Apttus_Config2__Level__c = level,
            Apttus_Config2__Label__c = name,
            Name = name
        );
        return hierarchy;
    }

    /**
     *  @author Rohan Chandarana
     *  @description Initialize Product Classification sObject
     *  @param category Category Hierarchy sObject
     *  @param product Product2 sObject
     *  @return Product Classification sObject
     **/
    public static Apttus_Config2__ProductClassification__c initProductClassification(Apttus_Config2__ClassificationHierarchy__c category, Product2 product)
    {
        Apttus_Config2__ProductClassification__c classification = new Apttus_Config2__ProductClassification__c(
            Apttus_Config2__ClassificationId__c = category.id,
            Apttus_Config2__ProductId__c = product.id
        );
        return classification;
    }

    /**
     *  @author Satya Swain
     *  @description Get Product Configuration sObject
     *  @param proposal Apttus_Proposal__Proposal__csObject
     *  @return Product Configuration sObject
     **/
    public static Apttus_Config2__ProductConfiguration__c getNewCart(Apttus_Proposal__Proposal__c proposal)
    {
        Apttus_Config2__ProductConfiguration__c cart = initCart(proposal);
        insert cart;
        return cart;
    }

    /**
     *  @author Satya Swain
     *  @description Initialize Product Configuration sObject
     *  @param proposal Apttus_Proposal__Proposal__csObject
     *  @return Product Configuration sObject
     **/
    public static Apttus_Config2__ProductConfiguration__c initCart(Apttus_Proposal__Proposal__c proposal)
    {
        Apttus_Config2__ProductConfiguration__c cart = new Apttus_Config2__ProductConfiguration__c(
            Name = 'Product Config - test',
            Apttus_QPConfig__Proposald__c = proposal.Id
        );
        return cart;
    }
    /**
     *  @description Get NewFavorite from object Apttus_Config2__FavoriteConfiguration__c
     *  @param  configurationId,priceListId
     *  @return Apttus_Config2__FavoriteConfiguration__c customObject
     **/

    public static Apttus_Config2__FavoriteConfiguration__c getNewFavorite(Id configurationId, Id priceListId)
    {
        Apttus_Config2__FavoriteConfiguration__c rec = initFavorite(configurationId, priceListId);
        insert rec;
        return rec;
    }
    /**
     *  @description Initialise NewFavorite from object Apttus_Config2__FavoriteConfiguration__c
     *  @param  configurationId,priceListId
     *  @return Apttus_Config2__FavoriteConfiguration__c customObject
     **/
    public static Apttus_Config2__FavoriteConfiguration__c initFavorite(Id configurationId, Id priceListId)
    {
        Apttus_Config2__FavoriteConfiguration__c rec = new Apttus_Config2__FavoriteConfiguration__c(
            Name = TestData.getRandom(),
            Apttus_Config2__PriceListId__c = priceListId,
            Apttus_Config2__ConfigurationId__c = configurationId
        );
        return rec;
    }
    /**
     *  @description Get Temp from object Apttus_Config2__TempObject__c
     *  @param  configurationId
     *  @return Apttus_Config2__TempObject__c customObject
     **/

    public static Apttus_Config2__TempObject__c getNewTemp(Id configurationId)
    {
        Apttus_Config2__TempObject__c rec = initTemp(configurationId);
        insert rec;
        return rec;
    }
    /**
     *  @description Initialise Temp from object Apttus_Config2__TempObject__c
     *  @param  configurationId
     *  @return Apttus_Config2__TempObject__c customObject
     **/
    public static Apttus_Config2__TempObject__c initTemp(Id configurationId)
    {
        Apttus_Config2__TempObject__c rec = new Apttus_Config2__TempObject__c(
            Apttus_Config2__ConfigurationId__c = configurationId
        );
        return rec;
    }

    /**
     *  @author Satya Swain
     *  @description Get Line Item sObject
     *  @param cartId Id field
     *  @param productId Id field
     *  @param quantity Integer field
     *  @return Line Item sObject
     **/
    public static Apttus_Config2__LineItem__c getNewLineItem(Id cartId, Id productId, Integer quantity)
    {
        Apttus_Config2__LineItem__c lineItem = initLineItem(cartId,productId,quantity);
        return lineItem;
    }

    /**
     *  @author Satya Swain
     *  @description Initialize Line Item sObject
     *  @param cartId Id field
     *  @param productId Id field
     *  @param quantity Integer field
     *  @return Line Item sObject
     **/
    public static Apttus_Config2__LineItem__c initLineItem(Id cartId, Id productId, Integer quantity)
    {
        Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c(
            Apttus_Config2__LineNumber__c = 1,
            Apttus_Config2__ItemSequence__c = 1,
            Apttus_Config2__ConfigurationId__c = cartId,
            Apttus_Config2__ProductId__c = productId,
            Apttus_Config2__Quantity__c = quantity,
            Apttus_Config2__PriceType__c = 'Recurring'
        );
        return lineItem;
    }

    /**
     *  @author Satya Swain
     *  @description Get Line Item sObject
     *  @param cartId Id field
     *  @param productId Id field
     *  @param quantity Integer field
     *  @param shippingInCloseQuarter Integer field
     *  @return Line Item sObject
     **/
    public static Apttus_Config2__LineItem__c getNewLineItem(Id cartId, Id productId, Integer quantity, Integer shippingInCloseQuarter)
    {
        Apttus_Config2__LineItem__c lineItem = initLineItem(cartId, productId, quantity, shippingInCloseQuarter);
        return lineItem;
    }

    /**
     *  @author Satya Swain
     *  @description Initialize Line Item sObject
     *  @param cartId Id field
     *  @param productId Id field
     *  @param quantity Integer field
     *  @param shippingInCloseQuarter Integer field
     *  @return Line Item sObject
     **/
    public static Apttus_Config2__LineItem__c initLineItem(Id cartId, Id productId,Integer quantity,Integer shippingInCloseQuarter)
    {
        Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c(
            Apttus_Config2__LineNumber__c = 1,
            Apttus_Config2__ItemSequence__c = 1,
            Apttus_Config2__ConfigurationId__c = cartId,
            Apttus_Config2__ProductId__c = productId,
            Apttus_Config2__Quantity__c = quantity,
            Shipping_In_Close_Quarter__c = shippingInCloseQuarter
        );
        return lineItem;
    }

    /**
     *  @author Satya Swain
     *  @description Get Config Custom Class ApexClass
     *  @return Config Custom Class
     **/
    public static Apttus_Config2__ConfigCustomClasses__c getNewConfigCustomClass(){
        Apttus_Config2__ConfigCustomClasses__c configCustomClass = initConfigCustomClass();
        insert configCustomClass;
        return configCustomClass;
    }

    /**
     *  @author Satya Swain
     *  @description Initialize Config Custom Class ApexClass
     *  @return Config Custom Class
     **/
    public static Apttus_Config2__ConfigCustomClasses__c initConfigCustomClass(){
        Apttus_Config2__ConfigCustomClasses__c configCustomClass = new Apttus_Config2__ConfigCustomClasses__c();
        configCustomClass.Name = 'System Properties';
        configCustomClass.Apttus_Config2__ValidationCallbackClass__c = 'ApttusValidationCallback';
        configCustomClass.Apttus_Config2__PricingCallbackClass__c = 'ApttusPricingCallback';
        configCustomClass.Apttus_Config2__ProductFilterCallbackClass__c = 'ApttusProductSearchFilterCallback';
        return configCustomClass;
    }

    /**
     *  @author Satya Swain
     *  @description Get Config LineItem Custom Field ApexClass
     *  @return Config LineItem Custom Field
     **/
    public static Apttus_Config2__ConfigLineItemCustomFields__c getNewConfigLineItemCustomField()
    {
        Apttus_Config2__ConfigLineItemCustomFields__c configLineItemCustomField = initConfigLineItemCustomField();
        insert configLineItemCustomField;
        return configLineItemCustomField;
    }
    /**
     *  @author Satya Swain
     *  @description Get Config LineItem Custom Field ApexClass
     *  @return Config LineItem Custom Field
     **/
    public static Apttus_Config2__ConfigLineItemCustomFields__c getNewConfigLineItemCustomField1()
    {
        Apttus_Config2__ConfigLineItemCustomFields__c configLineItemCustomField = initConfigLineItemCustomField1();
        insert configLineItemCustomField;
        return configLineItemCustomField;
    }

    /**
     *  @author Satya Swain
     *  @description Initialize Config LineItem Custom Field ApexClass
     *  @return Config LineItem Custom Field
     **/
    public static Apttus_Config2__ConfigLineItemCustomFields__c initConfigLineItemCustomField()
    {
        return new Apttus_Config2__ConfigLineItemCustomFields__c(
            Name = 'System Properties',
            Apttus_Config2__CustomFieldNames__c = 'Is_New__c,Shipping_In_1Q_After_Close_Quarter__c,Shipping_In_2Q_After_Close_Quarter__c,Quote_Sub_Type__c,End_Of_Sale_Date__c,End_Of_Service_Date__c,Quote_Created_Date__c,Billing_Type__c',
            Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__HasIncentives__c,Shipping_In_Close_Quarter__c,Cost_Center__c,Applied_Discount_Details__c,Apttus_Config2__AssetLineItemId__c,Line_Description__c,Project_Id__c,Beadchip_Part_Number__c',
            Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__ExpectedStartDate__c,Product_Material_Class__c,Sales_Discretionary_Type__c,SAP_Cross_Plant_Status__c,Apttus_Config2__OptionId__r.Number_Of_BeadChips_Per_Sample__c',
            Apttus_Config2__CustomFieldNames4__c = 'Sales_Discretionary_Discount__c,Applied_Discount_Percentage__c,Software_Type__c,AssetLineItem_End_Date__c,SFDC_Block__c,Cross_Distribution_Chain_Status__c,Sold_To_Sales_Organization__c,Sold_To_Distribution_Channel__c',
            Apttus_Config2__CustomFieldNames5__c = 'Apttus_Config2__OptionId__r.Number_Of_Samples__c,Apttus_Config2__ProductId__r.Number_Of_Samples__c,Price_per_sample__c,Max_Samples_Allowed_Per_kit__c,Reason_For_Price_Override__c,Price_Override__c'
        );
    }

    /**
     *  @author Satya Swain
     *  @description Initialize Config LineItem Custom Field ApexClass
     *  @return Config LineItem Custom Field
     **/
    public static Apttus_Config2__ConfigLineItemCustomFields__c initConfigLineItemCustomField1()
    {
        return new Apttus_Config2__ConfigLineItemCustomFields__c(
            Name = 'System Properties 1',
            Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ProductId__r.Number_Of_BeadChips_Per_Sample__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c,Customer_Net_Price__c',
            Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ProductId__r.End_Of_Sale_Date__c,Apttus_Config2__ProductId__r.End_Of_Service_Date__c,Apttus_Config2__ProductId__r.Material_Number__c,List_Price__c,Customer_Premium_Amount_Per_Unit__c',
            Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__OptionId__r.Material_Number__c,Apttus_Config2__OptionId__r.End_Of_Sale_Date__c,Apttus_Config2__OptionId__r.End_Of_Service_Date__c,Line_Item_Old_Values__c,Manual_Rebate__c,Line_Item_Validate_Old__c,Manual_Rebate_Per_Unit__c',
            //DCP-26680
            Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__ConfigurationId__r.Quote_Sub_Type__c,Apttus_Config2__ProductId__r.Informatics_SKU_Type__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Primary_Contact__c',
            Apttus_Config2__CustomFieldNames5__c = 'Apttus_Config2__ProductId__r.Informatics_Family__c,Registrant_Contact__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__IsQuantityReadOnly__c,Apttus_Config2__AddedBy__c'
            );
             // DCP-25322
    }

    /**
     *  @author Satya Swain
     *  @description Initialize Hierarchical Custom Setting for Product_Level_Indicator__c
     *  @return List of Product_Level_Indicator__c custom setting
     **/
    public static List<Product_Level_Indicator__c> initProductLevelIndicator()
    {
        List<Product_Level_Indicator__c> lstProductLevelIndicator = new List<Product_Level_Indicator__c>();
        Id idSalesUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP).ProfileId;
        Id idCommercialOpsQuotingUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_COMMERCIAL_OPS_QUOTING_USER).ProfileId;
        Id idCommercialandRevenueOperations = TestDataUser.findUserInProfile(TestDataUser.PROFILE_COMMERCIAL_REVENUE_OPERATIONS).ProfileId;
        Product_Level_Indicator__c objPLI1 = new Product_Level_Indicator__c(SetupOwnerId=idSalesUser,Values__c='\'COM_PROD\'');
        Product_Level_Indicator__c objPLI2 = new Product_Level_Indicator__c(SetupOwnerId=idCommercialOpsQuotingUser,Values__c='\'COM_PROD\',\'COM_CNTL\',\'COM_COMP\',\'COM_CNTL_COMP\',\'\'');
        Product_Level_Indicator__c objPLI13 = new Product_Level_Indicator__c(SetupOwnerId=idCommercialandRevenueOperations,Values__c='\'COM_PROD\'');

        lstProductLevelIndicator.add(objPLI1);
        lstProductLevelIndicator.add(objPLI2);
        lstProductLevelIndicator.add(objPLI13);

        insert lstProductLevelIndicator;
        return lstProductLevelIndicator;
    }
    

    /**
     *  @author Govind Dubey
     *  @description Initialize Approval Request
     *  @param Proposal id
     *  @return Approval Request object
     **/
    public static Apttus_Approval__Approval_Request__c getNewApprovalRequest(Id idProposal)
    {
        Apttus_Approval__Approval_Request__c rec = initApprovalRequest(idProposal);
        insert rec;
        return rec;
    }
    /**
     *  @author Govind Dubey
     *  @description Initialize Approval Request
     *  @param Proposal id
     *  @return Approval Request object
     **/
    public static Apttus_Approval__Approval_Request__c initApprovalRequest(Id idProposal)
    {
        User user = TestDataUser.findUserInProfile('System Administrator');
        //user.Title = 'test title';
        //update user; //DCP-56856
        Apttus_Approval__Approval_Request__c objApprovalRequest = new Apttus_Approval__Approval_Request__c();
        objApprovalRequest.Apttus_Approval__Sequence__c = '1';
        objApprovalRequest.Apttus_Approval__Assigned_To_Id__c = user.id;
        objApprovalRequest.Apttus_Approval__Step_Name__c = 'test';
        objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = user.Name;
        objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Not Submitted';
        objApprovalRequest.Apttus_Approval__Assigned_To_Type__c = 'User';
        objApprovalRequest.Apttus_QPApprov__ProposalId__c = idProposal;
        objApprovalRequest.Apttus_Approval__StepSequence__c = 1.1;
        return objApprovalRequest;
    }

    /**
     *  @author Enrique Reyes
     *  @description Initialize Approval Request
     *  @param Proposal id
     *  @return Approval Request object
     **/
    public static Apttus_Approval__Approval_Request__c initApprovalRequest(Id proposalId, Id assignedToId)
    {
        Apttus_Approval__Approval_Request__c objApprovalRequest = new Apttus_Approval__Approval_Request__c();
        objApprovalRequest.Apttus_Approval__Sequence__c = '1';
        objApprovalRequest.Apttus_Approval__Assigned_To_Id__c = assignedToId;
        objApprovalRequest.Apttus_Approval__Step_Name__c = 'test';
        objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Not Submitted';
        objApprovalRequest.Apttus_Approval__Assigned_To_Type__c = 'User';
        objApprovalRequest.Apttus_Approval__ObjectRefId__c = proposalId;
        objApprovalRequest.Apttus_Approval__Object_Type__c = 'Apttus_Proposal__Proposal__c';
        objApprovalRequest.Apttus_Approval__StepSequence__c = 1.1;
        return objApprovalRequest;
    }

    /**
     *  @description Get Approval History
     *  @param Apttus_Approval__Approval_Request__c 
     *  @return Approval Request History
     **/

    public static Apttus_Approval__Approval_Request_History__c getNewApprovalHistory(Apttus_Approval__Approval_Request__c objRequest)
    {
        Apttus_Approval__Approval_Request_History__c rec = initApprovalHistory(objRequest);
        insert rec;
        return rec;
    }
    /**
     *  @description Initialize Approval History
     *  @param Apttus_Approval__Approval_Request__c 
     *  @return Approval Request History
     **/
    public static Apttus_Approval__Approval_Request_History__c initApprovalHistory(Apttus_Approval__Approval_Request__c objRequest)
    {
        Apttus_Approval__Approval_Request_History__c rec = new Apttus_Approval__Approval_Request_History__c(
            Apttus_Approval__Sequence__c = '1',
            Apttus_Approval__Assigned_To_Id__c = objRequest.Apttus_Approval__Assigned_To_Id__c,
            Apttus_Approval__Step_Name__c = 'test',
            Apttus_Approval__Assigned_To_Name__c = objRequest.Apttus_Approval__Assigned_To_Name__c,
            Apttus_Approval__Approval_Status__c = 'Not Submitted',
            Apttus_Approval__Assigned_To_Type__c = 'User',
            Apttus_Approval__ParentRequestId__c = objRequest.Id,
            Apttus_Approval__StepSequence__c = 1.1
        );

        return rec;
    }

    /**
     *  @author Govind Dubey
     *  @description Initialize Content Version
     *  @param NA
     *  @return ContentVersion object
     **/
    public static ContentVersion initContentVersion(){
        Contentversion objContentVersion = new ContentVersion();
        objContentVersion.title='ABC';
        objContentVersion.PathOnClient ='test';
        objContentVersion.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        return objContentVersion;
    }
    /**
     *  @author Govind Dubey
     *  @description Initialize Content Document Link
     *  @param Proposal id
     *  @return ContentDocumentLink object
     **/
    public static ContentDocumentLink initContentDocumentLink(Id idProposal,Id idContentDocumentId){
        ContentDocumentLink objContentDocumentLink = new ContentDocumentLink();
        objContentDocumentLink.LinkedEntityId = idProposal;
        objContentDocumentLink.ShareType = 'V';
        objContentDocumentLink.contentdocumentid = idContentDocumentId;
        return objContentDocumentLink;
    }
    /**
     *  @author Gopinath Reddy
     *  @description Initialize Asset Line Item
     *  @param Id
     *  @return Apttus_Config2__AssetLineItem__c
     **/
    public static Apttus_Config2__AssetLineItem__c getNewAssetLineItem(Id accountId, Id productId)
    {
        Apttus_Config2__AssetLineItem__c rec = initAssetLineItem(accountId, productId);
        insert rec;
        return rec;
    }
    /**
     *  @author Gopinath Reddy
     *  @description Initialize Asset Line Item
     *  @param Id
     *  @return Apttus_Config2__AssetLineItem__c object
     **/

    public static Apttus_Config2__AssetLineItem__c initAssetLineItem(Id accountId, Id productId)
    {
        Apttus_Config2__AssetLineItem__c rec = new Apttus_Config2__AssetLineItem__c(
            Name = TestData.getRandom(),
            Apttus_Config2__AccountId__c = accountId,
            Ultimate_Consignee__c = accountId,
            Apttus_Config2__ProductId__c = productId,
            Apttus_Config2__PriceType__c = 'Recurring',
            Serial_Number__c = TestData.getRandomNumeric(),
            Contract_Number__c = TestData.getRandomNumeric(),
            Contract_Type__c = TestData.getRandom(),
            Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated,
            Status__c = System.Label.AssetLineItemStatusActivated,
            Apttus_Config2__EndDate__c = Date.today() + 10,
            Apttus_Config2__StartDate__c = Date.today() - 20,
            Apttus_Config2__OriginalStartDate__c = Date.today() - 20
        );
        return rec;
    }
    /**
     
     *  @description Initialize Asset Line Item
     *  @param Id
     *  @return Apttus_Config2__AssetLineItem__c object
     **/
    public static Apttus_Config2__AssetLineItem__c getNewAssetLineItem(Id accountId, Id productId, Id quoteId)
    {
        Apttus_Config2__AssetLineItem__c rec = initAssetLineItem(accountId, productId, quoteId);
        insert rec;
        return rec;
    }
    /**
     
     *  @description Initialize Asset Line Item
     *  @param Id
     *  @return Apttus_Config2__AssetLineItem__c object
     **/
    public static Apttus_Config2__AssetLineItem__c initAssetLineItem(Id accountId, Id productId, Id quoteId)
    {
        Apttus_Config2__AssetLineItem__c rec = new Apttus_Config2__AssetLineItem__c(
            Name = TestData.getRandom(),
            Apttus_Config2__AccountId__c = accountId,
            Ultimate_Consignee__c = accountId,
            Apttus_Config2__ProductId__c = productId,
            Apttus_Config2__PriceType__c = 'Recurring',
            Serial_Number__c = TestData.getRandomNumeric(),
            Contract_Number__c = TestData.getRandomNumeric(),
            Contract_Type__c = TestData.getRandom(),
            Apttus_QPConfig__ProposalId__c = quoteId,
            Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated,
            Status__c = System.Label.AssetLineItemStatusActivated,
            Apttus_Config2__EndDate__c = Date.today() + 10,
            Apttus_Config2__StartDate__c = Date.today() - 20,
            Apttus_Config2__OriginalStartDate__c = Date.today() - 20
        );
        return rec;
    }
    /** 
     *  @description Initialize Asset Line Item
     *  @param AssetlineItem id
     *  @return Apttus_Config2__AssetLineItemHistory__c object
     **/
    public static Apttus_Config2__AssetLineItemHistory__c getNewAssetLineItemHistory(Id assetLineItemId)
    {
        Apttus_Config2__AssetLineItemHistory__c rec = initAssetLineItemHistory(assetLineItemId);
        insert rec;
        return rec;
    }
    /**
     *  @description Initialize Asset Line Item
     *  @param AssetlineItem id
     *  @return Apttus_Config2__AssetLineItemHistory__c object
     **/
    public static Apttus_Config2__AssetLineItemHistory__c initAssetLineItemHistory(Id assetLineItemId)
    {
        Apttus_Config2__AssetLineItemHistory__c rec = new Apttus_Config2__AssetLineItemHistory__c(
            Apttus_Config2__AssetStatus__c = 'New',
            Apttus_Config2__AssetLineItemId__c = assetLineItemId
        );
        return rec;
    }
    /**
     *  @description Initialize  Apttus_Config2__TempRenewAssetGroup__c
     *  @param  Id
     *  @return Apttus_Config2__TempRenewAssetGroup__c object
     **/

    public static Apttus_Config2__TempRenewAssetGroup__c getNewRenewAssetGroup(Id configId)
    {
        Apttus_Config2__TempRenewAssetGroup__c rec = initRenewAssetGroup(configId);
        insert rec;
        return rec;
    }
    /**
     *  @description Initialize  Apttus_Config2__TempRenewAssetGroup__c
     *  @param  Id
     *  @return Apttus_Config2__TempRenewAssetGroup__c object
     **/
    public static Apttus_Config2__TempRenewAssetGroup__c initRenewAssetGroup(Id configId)
    {
        Apttus_Config2__TempRenewAssetGroup__c rec = new Apttus_Config2__TempRenewAssetGroup__c(
            Apttus_Config2__ConfigurationId__c = configId
        );
        return rec;
    }
    /**
     *  @description Initialize  Apttus_Config2__TempRenewAssetLineItem__c
     *  @param  Id
     *  @return Apttus_Config2__TempRenewAssetLineItem__c object
     **/

    public static Apttus_Config2__TempRenewAssetLineItem__c getNewRenewAssetLine(Id assetGroupId)
    {
        Apttus_Config2__TempRenewAssetLineItem__c rec = initRenewAssetLine(assetGroupId);
        insert rec;
        return rec;
    }
    
    /**
     *  @description Initialize  Apttus_Config2__TempRenewAssetLineItem__c
     *  @param  Id
     *  @return Apttus_Config2__TempRenewAssetLineItem__c object
     **/
    public static Apttus_Config2__TempRenewAssetLineItem__c initRenewAssetLine(Id assetGroupId)
    {
        Apttus_Config2__TempRenewAssetLineItem__c rec = new Apttus_Config2__TempRenewAssetLineItem__c(
            Apttus_Config2__RenewAssetGroupId__c = assetGroupId
        );
        return rec;
    }

    /**
     *  @author Saswati
     *  @description Promotions - Incentives
     *  @param String, String
     *  @return Apttus_Config2__Incentive__c object
     **/
     public static Apttus_Config2__Incentive__c initIncentives(String incentiveName, String incentiveCode)
    {
        Apttus_Config2__Incentive__c incentive = new Apttus_Config2__Incentive__c();
        incentive.Name = incentiveName;
        incentive.Apttus_Config2__Sequence__c =1;
        incentive.Apttus_Config2__IncentiveCode__c = incentiveCode;
        insert incentive;
        return incentive;
    }
    /**
     *  @author Umesh
     *  @description Agreement Approval Requests
     *  @param Id
     *  @return Apttus_Approval__Approval_Request__c object
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

}