/*
* @Author
* @Date
* @Description  test class of DataApttusAsset class
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Aman Tyagi            7th Oct 2022               Codescan Fixes
---------------------------------------------------------------------------------------------------------------------------------------                                                 
*/
@isTest
public class TestDataApttusAsset {

    /**
     * @author   
     * @description static method to get the new Asset line item based on id
     * @param  Id soldToId, Id ucId, Id productId
     * @return Apttus_Config2__AssetLineItem__c
     **/
    public static Apttus_Config2__AssetLineItem__c getNewAssetLineItem(Id soldToId, Id ucId, Id productId)
    {
        Apttus_Config2__AssetLineItem__c rec = initAssetLineItem(soldToId, ucId, productId);
        insert rec;
        return rec;
    }
    /**
     * @author   
     * @description static method to init the new Asset line item based on id
     * @param  Id soldToId, Id ucId, Id productId
     * @return Apttus_Config2__AssetLineItem__c
     **/
    public static Apttus_Config2__AssetLineItem__c initAssetLineItem(Id soldToId, Id ucId, Id productId)
    {
        Date startDate = Date.today();
        Date endDate = startDate + 365;
        return initAssetLineItem(soldToId, ucId, productId, startDate, endDate);
    }

    /**
     * @author   
     * @description static method to get the new expired asset line item based on id
     * @param  Id soldToId, Id ucId, Id productId
     * @return Apttus_Config2__AssetLineItem__c
     **/
    public static Apttus_Config2__AssetLineItem__c getNewExpiredAssetLineItem(Id soldToId, Id ucId, Id productId)
    {
        Apttus_Config2__AssetLineItem__c rec = initExpiredAssetLineItem(soldToId, ucId, productId);
        insert rec;
        return rec;
    }
    
    /**
     * @author   
     * @description static method to init the expired Asset line item based on id
     * @param  Id soldToId, Id ucId, Id productId
     * @return Apttus_Config2__AssetLineItem__c
     **/
    public static Apttus_Config2__AssetLineItem__c initExpiredAssetLineItem(Id soldToId, Id ucId, Id productId)
    {
        Date pastEndDate = Date.today() - 10;
        Date pastStartDate = pastEndDate - 365;
        return initAssetLineItem(soldToId, ucId, productId, pastStartDate, pastEndDate);
    }

    /**
     * @author   
     * @description static method to get the new Asset line item based on id and date
     * @param  Id soldToId, Id ucId, Id productId , Date startDate, Date endDate
     * @return Apttus_Config2__AssetLineItem__c
     **/
    public static Apttus_Config2__AssetLineItem__c getNewAssetLineItem(Id soldToId, Id ucId, Id productId, Date startDate, Date endDate)
    {
        Apttus_Config2__AssetLineItem__c rec = initAssetLineItem(soldToId, ucId, productId, startDate, endDate);
        insert rec;
        return rec;
    }

    /**
     * @author   
     * @description static method to init the Asset line item based on id and date
     * @param  Id soldToId, Id ucId, Id productId , Date startDate, Date endDate
     * @return Apttus_Config2__AssetLineItem__c
     **/
    public static Apttus_Config2__AssetLineItem__c initAssetLineItem(Id soldToId, Id ucId, Id productId, Date startDate, Date endDate)
    {
        Apttus_Config2__AssetLineItem__c rec = new Apttus_Config2__AssetLineItem__c(
            Apttus_Config2__AccountId__c = soldToId,
            Ultimate_Consignee__c = ucId,
            Apttus_Config2__ProductId__c = productId,
            Serial_Number__c = TestData.getRandomNumeric(),
            Contract_Number__c = TestData.getRandomNumeric(),
            Contract_Type__c = TestData.getRandom(),
            Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated,
            Status__c = System.Label.AssetLineItemStatusActivated,
            Apttus_Config2__EndDate__c = endDate,
            Apttus_Config2__StartDate__c = startDate,
            Apttus_Config2__OriginalStartDate__c = startDate
        );
        return rec;
    }

}