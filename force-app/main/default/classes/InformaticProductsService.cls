/**
 *    @author Akshay Mohan
 *    @date   01-13-2020
 *    @description   Service class to contain all Informatics Product Identification business logic
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *      Developer                      Date                 Description
 *      Akshay Mohan                   01-13-2020           Initial version
 *      Gopinath Reddy                 01-28-2020           DCP-32166 - Check LIMS/DRAGEN conditons
 *      Iram Malik                     14-Jul-2022          Codescan Fixes
 *      Prem Ranjan                    20-Feb-2023          CodeScan Fixes (APEX) Variable Naming Conventions
 */
public with sharing class InformaticProductsService {

    private static Map<String,Map<String,Map<String,InformaticsProductWrapper>>> mapFamilyToTypeToTier= new Map<String,Map<String,Map<String,InformaticsProductWrapper>>>();
    public static InformaticsProductWrapper iCreditConfig,dragenConfig;
    private static final String ICREDIT = 'Informatics_iCredit_Types';
    private static final String DRAGEN = 'Informatics_Dragen_Family';
    //DCP-32166
    private static final String LIMS ='Informatics_LIMS_Family';  
    private static final String SKUTYPE ='Informatics_LIMS_SKU_Type';
    private static final String ADDON_SKUTYPE ='Informatics_SKU_Type_Add_On';
    private static String strLIMSValue,strSubscription,strADDON;

    //Global constants -DCP-32166
    public static final String DRAGEN_TRIGGER1 ='DragenTrigger1';
    public static final String DRAGEN_TRIGGER2 ='DragenTrigger2';
    public static final String LIMS_TRIGGER1 ='LIMSTrigger1';
    public static final String LIMS_TRIGGER2 ='LIMSTrigger2';

    
    static {
        initialize();
    }
   
   /**
    * @author Gopinath Reddy
    * @date   01-28-2020
    * @description Checking case conditions with return string 
    */

     public static String checkCaseTriggerConditions(Apttus_Config2__OrderLineItem__c oli){
        if(oli.Renewal_Subscription__c) return null;
        if(oli.Apttus_Config2__ProductId__r.Informatics_Family__c == strLIMSValue && oli.Apttus_Config2__ProductId__r.Informatics_SKU_Type__c == strSubscription )//check LIMS Trigger 1
            return LIMS_TRIGGER1;
        else if(oli.Apttus_Config2__ProductId__r.Informatics_Family__c == strLIMSValue && oli.Apttus_Config2__ProductId__r.Informatics_SKU_Type__c == strADDON)//check LIMS Trigger 2
            return LIMS_TRIGGER2;
        else if(oli.Apttus_Config2__ProductId__r.Informatics_Family__c == dragenConfig.strFamily && oli.Custom_License_Flag__c)//check Dragen Trigger 1
            return DRAGEN_TRIGGER1;
        else if(oli.Apttus_Config2__ProductId__r.Informatics_Family__c == dragenConfig.strFamily && oli.Dragen_Connectivity__c == System.Label.Dragen_Connectivity_Offline)//check Dragen Trigger 2
            return DRAGEN_TRIGGER2;
        
        return null;       
    }

    /**
    * @author Akshay Mohan
    * @date   01-13-2020
    * @description prepare mapFamilyToTypeToTier
    */
    private static void initialize(){
        List<Informatics_Product__mdt> lstConfig = new InformaticsProductsSelector().loadAllInformaticsConfigurations();
        System.debug('lstConfig: '+ lstConfig);
        String iCreditValue;
        String dragenValue;
        
        for(Code_Parameter__mdt config : new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{ICREDIT,DRAGEN,LIMS,SKUTYPE,ADDON_SKUTYPE})){
            if(ICREDIT.equals(config.DeveloperName))
                iCreditValue=config.Value__c;
            if(DRAGEN.equals(config.DeveloperName))
                dragenValue=config.Value__c;
            if(LIMS.equals(config.DeveloperName))
                strLIMSValue=config.Value__c;
            if(SKUTYPE.equals(config.DeveloperName))
                strSubscription=config.Value__c;
            if(ADDON_SKUTYPE.equals(config.DeveloperName))
                strADDON=config.Value__c;
        }

        for(Informatics_Product__mdt config: lstConfig){
            Map<String,Map<String,InformaticsProductWrapper>> mapTypeToTier = mapFamilyToTypeToTier.get(config.Product_Family__c.toUpperCase());
            if(mapTypeToTier==null){
                mapTypeToTier = new Map<String,Map<String,InformaticsProductWrapper>>();
                mapFamilyToTypeToTier.put(config.Product_Family__c.toUpperCase(),mapTypeToTier);
            }
                
            Map<String,InformaticsProductWrapper> mapTierToConfig = mapTypeToTier.get(config.Product_Type__c.toUpperCase());
            if(mapTierToConfig==null){
                mapTierToConfig = new Map<String,InformaticsProductWrapper>();
                mapTypeToTier.put(config.Product_Type__c.toUpperCase(),mapTierToConfig);
            }
                
            InformaticsProductWrapper wrapConfig = new InformaticsProductWrapper(config);
            mapTierToConfig.put(config.Subscription_Type__c.toUpperCase(),wrapConfig);
            if(config.Product_Type__c.toUpperCase() == iCreditValue.toUpperCase())
                iCreditConfig = wrapConfig;
            if(config.Product_Family__c.toUpperCase() == dragenValue.toUpperCase())
                dragenConfig = wrapConfig;
        }
        System.debug('mapFamilyToTypeToTier: '+mapFamilyToTypeToTier);
        System.debug('iCreditConfig: '+iCreditConfig);
        System.debug('dragenConfig: '+dragenConfig);
    }

    /**
    * @author Akshay Mohan
    * @date   01-13-2020
    * @description Get records based on proposal line item
    */
    public static InformaticsProductWrapper getConfig(Apttus_Proposal__Proposal_Line_Item__c pli){
        InformaticsProductWrapper wrapVal =  getConfig(pli.Product_Family__c, pli.Product_Type__c, pli.Product_Tier__c);
        if(wrapVal==null && pli.Is_iCredit__c) wrapVal = iCreditConfig;
        if(wrapVal == null && pli.Is_Dragen__c) wrapVal = dragenConfig;
        return wrapVal;
    }


    /**
    * @author Akshay Mohan
    * @date   01-13-2020
    * @description Get records based on product charecteristics
    */
    public static InformaticsProductWrapper getConfig(String strFamily,String strType,String strTier){
        strFamily= strFamily==null? null : strFamily.toUpperCase();
        strType= strType==null? null : strType.toUpperCase();
        strTier= strTier==null? null : strTier.toUpperCase();
        Map<String,Map<String,InformaticsProductWrapper>> mapTypeToTier = mapFamilyToTypeToTier.get(strFamily);
        if(mapTypeToTier == null) return null;
        Map<String,InformaticsProductWrapper> mapTierToConfig = mapTypeToTier.get(strType);
        if(mapTierToConfig == null) return null;

        return mapTierToConfig.get(strTier);
    }

    
    /**
    * @author Akshay Mohan
    * @description wrapper that has attributres for Informatics Product
    */
    
    public class InformaticsProductWrapper {
        public String strFamily,strType,strTier,strFields,strRequiredFields,strReadOnlyFields;
        public Set<String> setRequiredFields,setReadOnlyFields;
        public List<String> lstCartFields, lstQuoteFields;
        /**
        * @author Akshay Mohan
        * @description wrapper that has attributres for Informatics Product
        * @params Informatics_Product__mdt config
        * retun null
        */
        public InformaticsProductWrapper(Informatics_Product__mdt config){
            strFamily = config.Product_Family__c;
            strType = config.Product_Type__c;
            strTier = config.Subscription_Type__c;
            setRequiredFields = new Set<String>(config.Required_Fields__c.split(','));
            strRequiredFields = config.Required_Fields__c;
            lstCartFields = config.Line_Item__c.split(',');
            lstQuoteFields = config.Quote_Line_Item_Fields__c.split(',');
            strFields = config.Quote_Line_Item_Fields__c;
            strReadOnlyFields = config.Read_Only_Fields__c;
            if(String.isNotBlank(strReadOnlyFields))
                setReadOnlyFields = new Set<String>(strReadOnlyFields.split(','));
            else
                setReadOnlyFields = new Set<String>();
        }
    }
}