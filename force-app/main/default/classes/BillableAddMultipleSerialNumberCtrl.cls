/**
*    @author KD
*    @date   3-May-2021
*    @description : Controllerr class adding multiple serial number on lines
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*                    
*/
public with sharing class BillableAddMultipleSerialNumberCtrl {
    private static final String CONFIGID = 'id';
    private static final String CONFIGREQUESTID = 'configRequestId';
    private static final String FLOW = 'flow';
    private static final String BUSINESSOBJECTID = 'businessObjectId';
    private String strConfigId;
    private string strConfigRequestId;
    private string strFlow;
    private String strBusinessObjectId;
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Line Detail wrapper
    */
    public class LineDetails{
        Set<String> setSerialNumber;
        Id idLineItemid;
        String strLineItemNumber;
        Decimal decQuantity;
        String strProductName;
        /*
        *  @AUTHOR:  KD
        *  @DESCRIPTION: Line details constructor
        */
        public LineDetails(Apttus_Config2__LineItem__c li){
            if(String.isNotBlank(li.Serial_Number__c)){
                this.setSerialNumber = new Set<String>(li.Serial_Number__c.split(','));
            }
            this.idLineItemid = li.id;
            this.strLineItemNumber = li.Name;
            this.decQuantity = li.Apttus_Config2__Quantity__c;
            this.strProductName = li.Apttus_Config2__ProductId__r.Name;
        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: InstalledProduct wrapper
    */
    public class InstalledProduct{
        String strSerialNumber;
        String strProductName;
        String strInstrumentType;
        String strProductCode;
        String strInstalledProductID;
        /*
        *  @AUTHOR:  KD
        *  @DESCRIPTION: InstalledProduct constructor
        */
        public InstalledProduct(SVMXC__Installed_Product__c objIP){
            this.strSerialNumber = objIP.SVMXC__Serial_Lot_Number__c;
            this.strProductName = objIP.SVMXC__Product__r.Name;
            this.strInstrumentType = objIP.Service_Product_Type__c;
            this.strProductCode = objIP.SVMXC__Product__r.ProductCode;
            this.strInstalledProductID = objIP.Id;
        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Constructor
    */
    public BillableAddMultipleSerialNumberCtrl() {
        strConfigId = ApexPages.CurrentPage().getParameters().get(CONFIGID).escapeHtml4();
        strConfigRequestId = ApexPages.currentpage().getparameters().get(CONFIGREQUESTID) == null ? null: ApexPages.currentpage().getparameters().get(CONFIGREQUESTID).escapeHtml4();
        strFlow = ApexPages.currentpage().getparameters().get(FLOW).escapeHtml4();
        strBusinessObjectId = ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID).escapeHtml4();
    }
    /**
    *  @author KD
    *  @description method to redirect user back to cart
    *  @param NA
    *  @return pageReference
    **/
    public PageReference redirectToCart(){
        PageReference cartPage = Page.Apttus_Config2__Cart;
        cartPage.getParameters().put(CONFIGID, strConfigId);
        cartPage.getParameters().put(CONFIGREQUESTID, strConfigRequestId);
        cartPage.getParameters().put(FLOW, strFlow);
        cartPage.getParameters().put(BUSINESSOBJECTID, strBusinessObjectId);
        return cartPage;
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Fetch initial record for page load
    *  @PARAM :  Id Product COnfig Id
    *  @RETURN:  JSON String
    */
    @AuraEnabled
    public static string initRecord(Id recordId){
        List<LineDetails> lstLineDetails = new List<LineDetails>();
        List<Apttus_Config2__ProductConfiguration__c> lstProductConfiguration = new ApttusProductConfigurationsSelector().selectConfigWithLines(new Set<Id>{recordId});
        try{
            for (Apttus_Config2__ProductConfiguration__c conf : lstProductConfiguration){
                for (Apttus_Config2__LineItem__c li : conf.Apttus_Config2__LineItems__r){
                    lstLineDetails.add(new LineDetails(li));
                }
            }
            Id idCurrentUCId = lstProductConfiguration[0].Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Current_Ultimate_Consignee__c;
            Boolean boolIsRelocation = lstProductConfiguration[0].Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c.contains(Label.OpportunityProductInterestRelocation);
            Map<String,String> mapLabels = new Map<String,string>{
                'Button_Back_To_Cart' => Label.Button_Back_To_Cart,
                    'UI_Message_Available_For_Relocation' => Label.UI_Message_Available_For_Relocation,
                    'UI_Message_Select_Line_Item' => Label.UI_Message_Select_Line_Item,
                    'UI_Label_Serial_Number_Selection' => Label.UI_Label_Serial_Number_Selection,
                    'UI_Label_Cart_Line_Selection' => Label.UI_Label_Cart_Line_Selection,
                    'Button_Remove_From_Cart_Line_Item' => Label.Button_Remove_From_Cart_Line_Item,
                    'Button_Add_To_Cart_Line_Item' => Label.Button_Add_To_Cart_Line_Item,
                    'UI_Label_Selected_Installed_Products_Serials' => Label.UI_Label_Selected_Installed_Products_Serials,
                    'UI_Label_Add_Installed_Products_Serials' => Label.UI_Label_Add_Installed_Products_Serials,
                    'UI_Message_SerialNumber_HelpText' => Label.UI_Message_SerialNumber_HelpText
                    };
                        return '{"lstLineDetails": '+JSON.serialize(lstLineDetails)+','
                        +' "idCurrentUCId": "'+idCurrentUCId+'",'
                        +' "boolIsRelocation": '+boolIsRelocation+','
                        +' "mapLabels": '+JSON.serialize(mapLabels)+'}';
        }catch(Exception e){
            ApexExceptions.emit('BillableAddMultipleSerialNumberCtrl',e);
            throw new AuraHandledException(e.getMessage());  
        }
        
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Save updated serial number on Cart line
    *  @PARAM :  String Cart line Id, Serial numbers
    *  @RETURN:  
    */
    @AuraEnabled
    public static string saveLine(Id recordId,String strSerialNumber){
        try{
            ilib_LogEvent.message('Serial number to update--'+recordId);
            ilib_LogEvent.message('Serial number to update--'+strSerialNumber);
            List<String> setSerialNumber = 
                (List<String>)JSON.deserialize(strSerialNumber, List<String>.class);
            String strUpdatedSerialNumber = String.join(setSerialNumber,','); 
            Apttus_Config2__LineItem__c objLineItem = new Apttus_Config2__LineItem__c(id = recordId,Serial_Number__c = strUpdatedSerialNumber);
            update objLineItem;
            return 'SUCCESS';
        }catch(Exception e){
            ApexExceptions.emit('BillableAddMultipleSerialNumberCtrl',e);
            throw new AuraHandledException(e.getMessage());  
        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: fetch IP list
    *  @PARAM :  
    *  @RETURN:  
    */
    @AuraEnabled
    public static string getInstalledProduct(Id idCurrentUC,String strSerialNumber,Boolean boolIncludeOnly){
        try{
            List<InstalledProduct> lstIP = new List<InstalledProduct>();
            List<String> lstSerialNumber = String.isNotBlank(strSerialNumber) ? (List<String>)JSON.deserialize(strSerialNumber, List<String>.class) : new List<String>();
            for(SVMXC__Installed_Product__c objIP : new InstalledProductsSelector().selectInstalledProductByAccountAndSerialNumber(new Set<Id>{idCurrentUC},lstSerialNumber,boolIncludeOnly)){
                lstIP.add(new InstalledProduct(objIP));
            }
            return '{"lstIPDetails": '+JSON.serialize(lstIP)+'}';
        }catch(Exception e){
            ApexExceptions.emit('BillableAddMultipleSerialNumberCtrl',e);
            throw new AuraHandledException(e.getMessage());  
        }
    }
}