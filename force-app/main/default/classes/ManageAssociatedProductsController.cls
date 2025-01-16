/**
*    @author: Amit Sachan
*    @date:   18-Sep-2023
*    @description:  Main class to manage Associated Products functionality for LWC
*    Modification Log:
*    ------------------------------------------------------------------------------------
*         Developer                         Date                               Description
*    Siddartha Reddy Kalam                  28-Nov-2023                        Initial version - CMCM-3980     
        Developer                           Date                               Desc
        Dhairya Shah		            31-Jan-24	.        CMCM-3591
*    ------------------------------------------------------------------------------------
*/
public with sharing class ManageAssociatedProductsController {

    static final String OBJECT_IP = 'Installed Product';
    private static final String SOURCESYSTEM = 'SFDC';
    private static final String CONTRACTTYPESOFTWAREZWS = 'Software (ZWS)';
    private static final String CONTRACTTYPEZCQ = 'Quantity Contract (ZCQ)';
    private static final String CONTRACTTYPESOFTWAREZWV = 'Software Contract (ZWV)';
    static final String OBJECT_SERVCON = 'Service Contract';
    static final String OBJECT_PROD = 'Products';
    static final String DEFALT = 'default';
    static final String OPTION1 = 'option1';
    static final String OPTION2 = 'option2';
    static final String OPTION3 = 'option3';
    static final String OPTION4 = 'option4';
    static final String LOG_TITLE = 'ManageAssociatedProductsController.';
    static final String BLNK = 'null';
    static final String CASEIDSTARTS = '500'; //CMCM-5309 FR change 7th March 2024 CODE SCAN error Solution
    public static List<Associated_Product__c> sasProduct = new List<Associated_Product__c>(); // added for CMCM - 8090 by Dhairya Shah
    public static List<SVMXC__Installed_Product__c> ipSelectedRows = new List<SVMXC__Installed_Product__c>(); // added for CMCM - 8090 by Dhairya Shah
    public static List<SVMXC__Service_Contract__c> sbcrptsSelectedRows = new List<SVMXC__Service_Contract__c>(); // added for CMCM - 8090 by Dhairya Shah

     /*
     * @author:         Siddartha Reddy Kalam  
     * @description:    Fetch Installed Products, Products, Service Contracts in LWC for creation of AP records.
     * @param:          recordId, searchKey and options.
     * @return:         Main method that get's called through wire adapter and returns Installed Products, Products, Service Contracts in LWC
     */
    @AuraEnabled(cacheable=true)
    public static List<AssociatedProductsWrapper> mainMethod(Id recordId, String searchKey, String options){
        ilib_LogEvent.push(LOG_TITLE + 'mainMethod()');
        try{
            List<AssociatedProductsWrapper> wrapper = new List<AssociatedProductsWrapper>();
            if (options.contains(OPTION4) && String.isNotBlank(recordId)) {
                
                List<SVMXC__Installed_Product__c> insProducts = getInstalledProductsListByAccount(recordId,searchKey);
                for (SVMXC__Installed_Product__c ips:insProducts) {
                    AssociatedProductsWrapper apw = new AssociatedProductsWrapper();
                    
                    apw.id = ips.Id;
                    apw.name = ips.Name;
                    apw.productName = ips.SVMXC__Product_Name__c;
                    apw.productCode = ips.Product_Code__c;
                    apw.productId = ips.SVMXC__Product__c;
                    //apw.type = OBJECT_IP;
                    apw.activeContract = ips.Currently_Active_Service_Contract__r.Name; // added by dhairya shah for CMCM 7944
                    wrapper.add(apw);
                }
                
                List<SVMXC__Service_Contract__c> serviceContracts = getServiceContractsListByAccount(recordId,searchKey);
                for (SVMXC__Service_Contract__c sc:serviceContracts) {
                    AssociatedProductsWrapper apw = new AssociatedProductsWrapper();
                    
                    apw.id = sc.Id;
                    apw.name = sc.Name;
                    apw.productName = sc.Product_Name__c;
                    apw.productCode = sc.ProductCode__c;
                    apw.activeContract = sc.Status__c; // added by dhairya shah for CMCM 8089
                    wrapper.add(apw);
                }
            }
            if (String.isNotBlank(options) && options.contains(OPTION2) && String.isNotBlank(searchKey)){
                List<Product2> productList = getProductsList(searchKey);
                for (Product2 p:productList) {
                    AssociatedProductsWrapper apw = new AssociatedProductsWrapper();
                    apw.id = p.Id;
                    apw.productName = p.Name;
                    apw.productCode = p.ProductCode;
                    apw.type = OBJECT_PROD;
                    wrapper.add(apw);
                }
            }
            if (String.isNotBlank(options) && options.contains(OPTION1) && String.isNotBlank(searchKey)){
                List<SVMXC__Installed_Product__c> installedProductList = getInstalledProductsList(searchKey);
                for (SVMXC__Installed_Product__c p:installedProductList) {
                    AssociatedProductsWrapper apw = new AssociatedProductsWrapper();
                    apw.id = p.Id;
                    apw.name = p.Name;
                    apw.productName = p.SVMXC__Product_Name__c;
                    apw.productCode = p.Product_Code__c;
                    apw.productId = p.SVMXC__Product__c;
                    apw.type = OBJECT_IP;
                    apw.activeContract = p.Currently_Active_Service_Contract__r.Name; // added for CMCM 9250
                    wrapper.add(apw);
                }
            }

            if(String.isNotBlank(options) && options.contains(OPTION3) && String.isNotBlank(searchKey)){
                List<SVMXC__Service_Contract__c> serviceContracts = getServiceContractsList(searchKey);
                for (SVMXC__Service_Contract__c sc:serviceContracts) {
                    AssociatedProductsWrapper apw = new AssociatedProductsWrapper();
                    apw.id = sc.Id;
                    apw.name = sc.Name;
                    apw.productName = sc.Product_Name__c;
                    apw.productCode = sc.ProductCode__c;
                    apw.activeContract = sc.Status__c; // added by dhairya shah for CMCM 8089
                    wrapper.add(apw);
                }
            }
            //CMCM-5334 deduplication logic only for Installed Product records only start
            Map<String,AssociatedProductsWrapper> mapApwForSub = new Map<String,AssociatedProductsWrapper>();//CMCM-5309 FR change 6th March 2024
            Map<String, AssociatedProductsWrapper> uniqueMap = new Map<String, AssociatedProductsWrapper>();
            for (AssociatedProductsWrapper apw : wrapper) {
                if(String.valueOf(apw.id).substring(0, 3).equals('a0N')){
                    uniqueMap.put(apw.name, apw);
                }else{
                    mapApwForSub.put(apw.id,apw);
                }
            }
            List<AssociatedProductsWrapper> deduplicatedWrapper = new List<AssociatedProductsWrapper>(uniqueMap.values());
            deduplicatedWrapper.addAll(mapApwForSub.values());
            ilib_LogEvent.message('wrapper:' + deduplicatedWrapper);
            ilib_LogEvent.pop();
            return deduplicatedWrapper;
            //CMCM-5334 deduplication logic end
            
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /* Method to get AccountId from Case or Work Order record */
    private static Id getAccountId (String recordId){
        ilib_LogEvent.push(LOG_TITLE + 'getAccountId()');
        String escapedRecordId = String.escapeSingleQuotes(recordId);
        Id accountId = null;
        if(recordId != null && recordId.startsWith(CASEIDSTARTS)){
            for(Case cs: new CasesSelector().selectAccountByCaseId(escapedRecordId)){
            AccountId = cs.AccountId;
            }
        }
        else if(recordId != null && recordId.startsWith('a2B')){
            for(SVMXC__Service_Order__c wo: new WorkOrdersSelector().getAccountonWorkOrder(escapedRecordId)){
            accountId = wo.SVMXC__Company__c;
            }
        }
        ilib_LogEvent.message('accountId:'+accountId);
        ilib_LogEvent.pop(); 
        return accountId;
    }

     /*
     * @author:         Siddartha Reddy Kalam  
     * @description:    Method to get list of installed products associated with the account on the case
     * @param:          searchKey
     * @return:         Method to get list of installed products associated with the account on the case in LWC
     */
    @AuraEnabled(cacheable=true)
    public static List<SVMXC__Installed_Product__c> getInstalledProductsList(String searchKey) {
            ilib_LogEvent.push(LOG_TITLE + 'getInstalledProductsList()');
        try{
            String key = '*' + String.escapeSingleQuotes(searchKey) + '*';        
            List<SVMXC__Installed_Product__c> lstip = new List<SVMXC__Installed_Product__c>();
            if(key != null){
                lstip.addAll(new InstalledProductsSelector().selectIPsWithSearchWithSOSL(key)); 
            }
            ilib_LogEvent.message('lstip:'+lstip);
            ilib_LogEvent.pop();
            return lstip;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }    
    }
    /*
     * @author:         Siddartha Reddy Kalam  
     * @description:    Method to get list of installed products associated with the account on the case
     * @param:          recordId and searchKey
     * @return:         Method to get list of installed products associated with the account on the case in LWC
     */
    @AuraEnabled(cacheable=true)
    public static List<SVMXC__Installed_Product__c> getInstalledProductsListByAccount(Id recordId,String searchKey) {
        ilib_LogEvent.push(LOG_TITLE + 'getInstalledProductsListByAccount()');
        try{
            List<SVMXC__Installed_Product__c> lstip = new List<SVMXC__Installed_Product__c>();
            String key='';
            if (searchKey == DEFALT){
                key = '%' + '' + '%';
            }
            else {
                key = '%' + String.escapeSingleQuotes(searchKey) + '%';
            }
            Id accountId = getAccountId(recordId);
            
            lstip.addAll(new InstalledProductsSelector().selectIPsWithAccountIdandSearch(accountId, key));

            ilib_LogEvent.message('lstip:'+lstip);
            ilib_LogEvent.pop();
            return lstip;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*
     * @author:         Siddartha Reddy Kalam  
     * @description:    Method to get list of Service Contracts associated with the account on the case
     * @param:          recordId and searchKey
     * @return:         Method to get list of Service Contracts associated with the account on the case in LWC
     */
    @AuraEnabled(cacheable=true)
    public static List<SVMXC__Service_Contract__c> getServiceContractsListByAccount(Id recordId,String searchKey) {
        ilib_LogEvent.push(LOG_TITLE + 'getServiceContractsListByAccount()');
        try{
            List<SVMXC__Service_Contract__c> lstsub = new List<SVMXC__Service_Contract__c>();
            String key='';
            if (searchKey == DEFALT){
                key = '%' + '' + '%';
            }
            else{
                key = '%' + String.escapeSingleQuotes(searchKey) + '%';
            }
            Id accountId = getAccountId(recordId);
            
            lstsub.addAll(new ServiceContractSelector().selectServContractsWithAccountIdandSearch(accountId,key));
            ilib_LogEvent.message('lstsub:'+lstsub);
            ilib_LogEvent.pop();  
            return lstsub;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*
     * @author:         Siddartha Reddy Kalam  
     * @description:    Method to get list of Service Contracts associated with the account on the case
     * @param:          searchKey
     * @return:         Method to get list of Service Contracts associated with the account on the case in LWC
     */
    @AuraEnabled(cacheable=true)
    public static List<SVMXC__Service_Contract__c> getServiceContractsList(String searchKey) {
        ilib_LogEvent.push(LOG_TITLE + 'getServiceContractsList()');
        try{
            List<SVMXC__Service_Contract__c> templstsub = new List<SVMXC__Service_Contract__c>();
            List<SVMXC__Service_Contract__c> lstsub = new List<SVMXC__Service_Contract__c>();
            String key = '*' + String.escapeSingleQuotes(searchKey) + '*';
            templstsub.addAll(new ServiceContractSelector().selectServContractsWithSearchSOSL(key));
            for(SVMXC__Service_Contract__c sc : templstsub) {
                if(sc.ERP_Contract_Type__c == CONTRACTTYPESOFTWAREZWS || sc.ERP_Contract_Type__c == CONTRACTTYPEZCQ || sc.ERP_Contract_Type__c == CONTRACTTYPESOFTWAREZWV) {
                    lstsub.add(sc);
                }
            }
            ilib_LogEvent.message('lstsub:'+lstsub);
            ilib_LogEvent.pop();  
            return lstsub;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
     * @author:         Siddartha Reddy Kalam  
     * @description:    Method to get list of products associated with the account on the case
     * @param:          searchKey
     * @return:         Method to get list of products associated with the account on the case in LWC
     */
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductsList(String searchKey) {
        ilib_LogEvent.push(LOG_TITLE + 'getProductsList()');
        try{
            List<Product2> templstprod = new List<Product2>();
            List<Product2> lstprod = new List<Product2>();
            String key = '*' + String.escapeSingleQuotes(searchKey) + '*';
            
            templstprod.addAll(new ProductsSelector().selectProductsWithSearchSOSL(key));
            for(Product2 prod : templstprod) {
                if (prod.Source_System__c != SOURCESYSTEM) {
                    lstprod.add(prod);
                }
            }
            ilib_LogEvent.message('lstprod:'+lstprod);
            ilib_LogEvent.pop();  
            return lstprod;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
     * @author:         Siddartha Reddy Kalam  
     * @description:    Method to get list of products associated with the account on the case
     * @param:          recordId
     * @return:         Method to get list of products associated with the account on the case in LWC
     */
    @AuraEnabled(cacheable=true)
    public static List<AssociatedProductsWrapper> getAssociatedProductsList(String recordId) {
        ilib_LogEvent.push(LOG_TITLE + 'getAssociatedProductsList()');
        try{
            List<AssociatedProductsWrapper> wrapper = new List<AssociatedProductsWrapper>();
            List<Associated_Product__c> assocProducts;
            String escapedRecordId = String.escapeSingleQuotes(recordId);
            if( recordId.startsWith(CASEIDSTARTS)){
                assocProducts = new AssociatedProductSelector().selectAssocProdsWithCase(escapedRecordId);
            }
            else{
                assocProducts = new AssociatedProductSelector().selectAssocProdsWithWorkOrder(escapedRecordId);  
            }   
            for (Associated_Product__c p:assocProducts) {
                AssociatedProductsWrapper apw = new AssociatedProductsWrapper();
                apw.id = p.Id;
                apw.Name = p.Name;
                apw.isPrimary = p.Is_Primary__c;
                apw.productId = p.Product__c;
                apw.subscriptionId = p.Subscription__c;
                apw.installedProduct =  p.Installed_Product__c;
                apw.installedProductName = p.Installed_Product__r.Name;
                apw.serialNumber = p.Product_Serial_Number__c; 
                apw.ivdIdentifier = p.IVD_Product_Identifier__c;
                apw.productName = p.Product__r.Name;
                apw.subscription = p.Subscription__r.Name;
                apw.lotNumber = p.Product_Lot_Number__c;
                apw.expiredDate = p.Expired_Date__c;
                apw.isExpired = p.Is_Expired__c;
                apw.version = p.Software_Version__c;
                //apw.location = p.Location__c;
                wrapper.add(apw);
            }  
            ilib_LogEvent.message('wrapper:'+wrapper);
            ilib_LogEvent.pop();
            return wrapper;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*
     * @author:         Siddartha Reddy Kalam  
     * @description:    Method to create list of Ip's, Service Contracts and products associated with the account on the case
     * @param:          wrapperString
     */
    @AuraEnabled
    public static void createAssociatdInstalledProducts(List<Map<String, Object>> wrapperString) {
        ilib_LogEvent.push(LOG_TITLE + 'createAssociatdInstalledProducts()');
        List<Id> idofIPs = new List<Id>();
        List<Id> idofsbcrpts = new List<Id>();
        for(Map<String, Object> getIPandP: wrapperString) {
            if(((String)getIPandP.get('id')).substring(0, 3).equals('a20')){ 
                idofsbcrpts.add((Id)getIPandP.get('id'));
            }
            else if(((String)getIPandP.get('id')).substring(0, 3).equals('a0N')){
                idofIPs.add((Id)getIPandP.get('id'));
            }
        }

        sbcrptsSelectedRows= new ServiceContractSelector().selectServContractsWithid(idofsbcrpts);

        ipSelectedRows= new InstalledProductsSelector().selectIPsWithId(idofIPs);


        List<Associated_Product__c> assocProducts = new List<Associated_Product__c>();
        for(Map<String, Object> obj: wrapperString) {           
            Associated_Product__c apc = new Associated_Product__c();
            if(obj.get('caseId')!= BLNK){
            apc.Case__c = (Id)obj.get('caseId');
            }
            if(obj.get('workOrderId')!= BLNK){
            apc.Work_Order__c = (Id)obj.get('workOrderId');
            }
            if (((String)obj.get('id')).substring(0, 3).equals('01t')){
                apc.Product__c = (Id)obj.get('id');
            }
            else if(((String)obj.get('id')).substring(0, 3).equals('a20')){
                apc.Subscription__c = (Id)obj.get('id');
                for(SVMXC__Service_Contract__c objs: sbcrptsSelectedRows){
                    if(objs.id == apc.Subscription__c){
                        apc.Product__c = objs.Order_Line_Item__r.Apttus_Config2__ProductId__c;
                    }
                }
            }
            else{
                apc.Installed_Product__c = (Id)obj.get('id');
                for(SVMXC__Installed_Product__c  objip: ipSelectedRows){
                    if(objip.id == apc.Installed_Product__c){                        
                        apc.Account__c = objip.SVMXC__Company__c;
                        apc.Product__c = objip.SVMXC__Product__c;
                        apc.Location__c = objip.SVMXC__Site__c;
                    }
                } 
            }
            assocProducts.add(apc);
            ilib_LogEvent.message('assocProducts:'+assocProducts);
        }
        
        if (!assocProducts.isEmpty()) {
            insert assocProducts;
        }
        ilib_LogEvent.pop();
    }   

    /*
     * @author:         Siddartha Reddy Kalam  
     * @description:    Method to get list of associated products associated with the account on the case or WO
     * @param:          recordId
     * @return:         Method to get list of associated products associated with the account on the case or WO in LWC
     */
    @AuraEnabled(cacheable=true)
    public static List<Associated_Product__c> getAssociatedProductsListByCaseId(String recordId) {
        ilib_LogEvent.push(LOG_TITLE + 'getAssociatedProductsListByCaseId()');
        try{
            List<Associated_Product__c> assocProduct;
            String escapedRecordId = String.escapeSingleQuotes(recordId);
                if(recordId != null && recordId.startsWith(CASEIDSTARTS)){
                    assocProduct = new AssociatedProductSelector().selectAssocProdsWithCase(escapedRecordId);

                }
                else if(recordId != null && recordId.startsWith('a2B')){
                    assocProduct = new AssociatedProductSelector().selectAssocProdsWithWorkOrder(escapedRecordId);  
                }
            ilib_LogEvent.message('assocProduct:'+assocProduct);
            ilib_LogEvent.pop();
            return  assocProduct;
            }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }  
    /*
     * @author:         Dhairya Shah
     * @description:    Method to get list of associated products associated with the account on the case or WO with imperative call
     * @param:          recordId
     * @return:         Method to get list of associated products associated with the account on the case or WO in LWC
     * CMCM-5309 FR change 7th March 2024 ==> created Imperative call method to refersh the data
     */
    @AuraEnabled
    public static List<Associated_Product__c> getAssociatedProductsListByCaseIdImp(String recordId) {
        ilib_LogEvent.push(LOG_TITLE + 'getAssociatedProductsListByCaseIdImp()');
        try{
            return  getAssociatedProductsListByCaseId(recordId);
            }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }  
/*
     * @author:         Dhairya Shah 
     * @description:    Fetch Installed Products, Products, Service Contracts in LWC for creation of AP records using imperative call.
     * @param:          recordId, searchKey and options.
     * @return:         Main method that get's called through wire adapter and returns Installed Products, Products, Service Contracts in LWC
     * //CMCM-5309 FR change 7th March 2024 ==> created Imperative call method to refersh the data
     */
    @AuraEnabled
    public static List<AssociatedProductsWrapper> findProductsImp(Id recordId, String searchKey, String options){
        try{
            return mainMethod(recordId, searchKey, options);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
     * @author: Dhairya Shah 
     * @description: Method which is called in lwc component -assocaitedproductcomponent to update Associated Products.
     * CMCM-6367 FR change 29th March 2024 ==> created method updategetAssociatedProductsList to update row data in assocaitedproductcomponent.
     */
    @AuraEnabled
    public static void updategetAssociatedProductsList(String data){
        try {
            List<Associated_Product__c> recordsList = (List<Associated_Product__c>)JSON.deserialize(data, List<Associated_Product__c>.class);
            Update recordsList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
     * @author:         Dhairya Shah  
     * @description:    Method which is called in lwc component -manageProductsContainerComponent to Create new Primary Associated Products.
     * @param:          New Record to create Associate Product and Current Page record Id   
     */
    @AuraEnabled
    public static void createPrimaryAssociatdInstalledProducts(List<Map<String, Object>> wrapperString, String recordId) {
        
        ilib_LogEvent.push(LOG_TITLE + 'createAssociatdInstalledProducts()');
        // Update Is_Primary Primary Associated Product to False
        Set<Id> idofCases = new Set<Id>();
        Set<Id> idofWO = new Set<Id>();
        Set<Associated_Product__c> updateAPFalse = new Set<Associated_Product__c>(); // Holds Is_Primary__c = false
        Set<Associated_Product__c> updateAPTrue = new Set<Associated_Product__c>(); // Holds Is_Primary__c = true
        List<Associated_Product__c> listDMLAP = new List<Associated_Product__c>();

        if (recordId != null && recordId.substring(0, 3) == '500') {
            idofCases.add(recordId); // Add to idofCases set if it starts with '500'
        } else if (recordId != null && recordId.substring(0, 3) == 'a2B') {
            idofWO.add(recordId); // Add to idofWO set if it starts with 'a2B'
        }
        
        // Query for the associate product which is already Primary 
        if(idofCases != null && !idofCases.isEmpty() && sasProduct.isEmpty()){
            sasProduct = new AssociatedProductSelector().selectPrimaryProductwithCase(idofCases);
        }

        if(idofWO != null && !idofWO.isEmpty() && sasProduct.isEmpty()){
            sasProduct= new AssociatedProductSelector().selectPrimaryProductwithWorkOrder(idofWO);
        }

        if(sasProduct != null && !sasProduct.isEmpty()){
            for(Associated_Product__c assProd : sasProduct){
                assProd.Is_Primary__c = false;
                updateAPFalse.add(assProd); // Add to updateAPFalse for Is_Primary__c = false
            }
        }
        
        // Insert new Primary Associated Product
        List<Id> idofIPs = new List<Id>();
        List<Id> idofsbcrpts = new List<Id>();
        if(wrapperString != null && !wrapperString.isEmpty()){
            for(Map<String, Object> getIPandP: wrapperString) {
                if(((String)getIPandP.get('id')).substring(0, 3).equals('a20')){ 
                    idofsbcrpts.add((Id)getIPandP.get('id'));
                }
                else if(((String)getIPandP.get('id')).substring(0, 3).equals('a0N')){
                    idofIPs.add((Id)getIPandP.get('id'));
                }
            }

            if(idofsbcrpts != null && !idofsbcrpts.isEmpty() && sbcrptsSelectedRows.isEmpty()){
                sbcrptsSelectedRows = new ServiceContractSelector().selectServContractsWithid(idofsbcrpts);
            }
            if(idofIPs != null && !idofIPs.isEmpty() && idofIPs.isEmpty()){
                ipSelectedRows = new InstalledProductsSelector().selectIPsWithId(idofIPs);
            }
            
            for(Map<String, Object> obj : wrapperString) {          
                Associated_Product__c apc = new Associated_Product__c();
                if(obj.get('caseId') != BLNK){
                    apc.Case__c = (Id)obj.get('caseId');
                }
                if(obj.get('workOrderId') != BLNK){
                    apc.Work_Order__c = (Id)obj.get('workOrderId');
                }
                if (((String)obj.get('id')).substring(0, 3).equals('01t')){
                    apc.Product__c = (Id)obj.get('id');
                }
                else if(((String)obj.get('id')).substring(0, 3).equals('a20')){
                    apc.Subscription__c = (Id)obj.get('id');
                    for(SVMXC__Service_Contract__c objs : sbcrptsSelectedRows){
                        if(objs.id == apc.Subscription__c){
                            apc.Product__c = objs.Order_Line_Item__r.Apttus_Config2__ProductId__c;
                        }
                    }
                }
                else{
                    apc.Installed_Product__c = (Id)obj.get('id');
                    for(SVMXC__Installed_Product__c objip : ipSelectedRows){
                        if(objip.id == apc.Installed_Product__c){                        
                            apc.Account__c = objip.SVMXC__Company__c;
                            apc.Product__c = objip.SVMXC__Product__c;
                            apc.Location__c = objip.SVMXC__Site__c;
                        }
                    } 
                }
                apc.Is_Primary__c = true;
                updateAPTrue.add(apc); // Add to updateAPTrue for Is_Primary__c = true
                ilib_LogEvent.message('assocProducts:' + updateAPTrue);
            }
        }

        // Upsert records with Is_Primary__c = false first
        if (updateAPFalse != null && !updateAPFalse.isEmpty()) {
            listDMLAP.addAll(updateAPFalse);
            WorkOrders.skipWOTrigger = true; //avoid 101 soql
            UPDATE listDMLAP;
        }

        // Upsert records with Is_Primary__c = true
        listDMLAP.clear(); // Clear the list for the next upsert
        if (updateAPTrue != null && !updateAPTrue.isEmpty()) {
            AssociatedProduct.addPrimaryOnInsert = true;
            listDMLAP.addAll(updateAPTrue);
            INSERT listDMLAP;
        }
        ilib_LogEvent.pop();
    }  
}