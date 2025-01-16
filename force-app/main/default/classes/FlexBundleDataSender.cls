/**
 * @author Akash Kumar 
 * @date   2018-07-30
 * @description    DCP-4113: Bundle Creation from SFDC to SAP  
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 Version
*   Akash Kumar              2018-07-30          Class to Send the Product and related Bundle data to SAP    Original
*                                                Added change                                                Modified
*   Akshay Mohan		     2018-08-27       	 DCP-10430 change
*	Joshith K				 2018-11-2			 DCP-13185 change											 Modified
*   Joshith K                2018-11-5           DCP 11324 change                                            Modified
*   Nishan Shetty          22-April-2022         CodeScan Fix-Avoid Literals in If condition 
*   Aman Tyagi               2022-03-30          CodeSan Fixes

*/
public without sharing class FlexBundleDataSender extends ilib_RestSender {

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_STATUS_CODE_200 = 200;
    //End CodeScan Fix
    
    /*
    * @Author: Akash Kumar 
    * @Description : class for callout the data 
    */
    private class CalloutData extends ilib_CalloutData
    {
        Product2 record;
        List<Apttus_Config2__ProductOptionGroup__c> productOptionsGroupList;

        /*
        * @Author: Joshith K
        * @Description : parameterized constructor of class CalloutData and instantiating Product2 , Apttus_Config2__ProductOptionGroup__c
        * @param: Product2 record,List<Apttus_Config2__ProductOptionGroup__c> productOptionsGroupList
        * @return: NA
        */ 
        public CalloutData(Product2 record,List<Apttus_Config2__ProductOptionGroup__c> productOptionsGroupList)
        {
            this.record = record;
            this.productOptionsGroupList = productOptionsGroupList;
        }
    }

    private CalloutData data {
        get { return (CalloutData)idata; }
    }

    /*
    * @Author: Joshith K
    * @Description : thie method has logic for retrieving callout data using selectors
    * @param: null
    * @return: CalloutData
    */
    protected override ilib_CalloutData retrieveCalloutData()
    {
        ProductOptionGroupsSelector prodOptionsGrpSelector = new ProductOptionGroupsSelector();
        Set<Id> setRecord = new Set<Id>{ recordId };

        //Calling the method to get OptionGroups with related Products & Options
        List<Apttus_Config2__ProductOptionGroup__c> productOptionsGroupList = prodOptionsGrpSelector.selectByIdWithOptionGroups(setRecord);
        Product2 objProduct = new ProductsSelector().selectProducts(setRecord)[0];
        System.debug('retrieveCalloutData Interface in FlexBundleDataSender class:::'+productOptionsGroupList);

        CalloutData data = new CalloutData(objProduct,productOptionsGroupList);
        return data;
    }

    /**
     *  @author  Akshay Mohan
     *  @description   this method is the last line of defense to make sure we don't send garbage to
     *      the target system.  Some validation will occur before the interface is called
     *      but we may allow retriggers by admins so we need these sanity checks here
     *      it builds a list of errors which are thrown to the caller
     */
    protected override void validateFields() { }

    /**
     *  @author   Akash Kumar
     *  @Description   US-***: This Method will return String body in JSON format which will be used in HTTP request method.
     */
    protected override String createJSON()
    {
        System.debug('Json Called');

        List<FlexBundleWrapper.BundleProductWrapper> lstPrdOptions = new List<FlexBundleWrapper.BundleProductWrapper>();

        //Adding the primary bundle-Product detail to the Bundle_Products list
        System.debug('data.record: ' + data.record);
        lstPrdOptions.add(new FlexBundleWrapper.BundleProductWrapper( data.record ));

        //populating the details of other Bundle_Products records, for JSON, from the related Options list records(coming from the query)
        for (Apttus_Config2__ProductOptionGroup__c pog : data.productOptionsGroupList)
        {
            for (Apttus_Config2__ProductOptionComponent__c option : pog.Apttus_Config2__Options__r)
            {
                //Add the details of Component Products from the related Options list with sequence numbers
                lstPrdOptions.add( new FlexBundleWrapper.BundleProductWrapper(option.Apttus_Config2__ComponentProductId__r,string.valueOf(option.Apttus_Config2__Sequence__c)) );
            }
        }
        System.debug('the list of Bundle_Products wrapper==> '+lstPrdOptions);

        FlexBundleWrapper.ProductHeader productHeader = new FlexBundleWrapper.ProductHeader(data.record, lstPrdOptions);

        String strJson = JSON.serialize(productHeader);
        System.debug(LoggingLevel.INFO, 'JSON Output:\n' + strJson);
        return strJson;
    }
    
    /*
        create JSON in below sample format:
        {
           "ProductCode":"Bundle_Id__c", 
           "Name":"Bundle_Name__c",
           "Bundle_Products":[  
              {  
				 "Sequence":null,//null for primary bundle product and values for all standalone inside bundle
                 "ProductCode":"Material1#",
                 "Apttus_Config2__ConfigurationType":"bundle" // if bundle then it is Primary Product
              },
              {  
				 "Sequence":"1",
                 "ProductCode":"Material2#",
                 "Apttus_Config2__ConfigurationType":"standalone" 
              },
              {  
				 "Sequence":"2",
                 "ProductCode":"Material3#",
                 "Apttus_Config2__ConfigurationType":"standalone"
              }
           ],
           "Apttus_Config2_EffectiveDate":"2018-07-17T18:25:43.511",
           "Apttus_Config2__ExpirationDate":"2018-12-31T18:25:43.511",
           "Description":"This where bundle decription will be sent",
           "Bundle_Segment":[  
              "Segment1"
           ],
           "Bundle_Channel":"online",
           "isActive":"active"
        }
    */

    public override void handleResult(HTTPResponse res)
    {
        System.debug('Result coming in FlexBundleDataSender ==>: ' +res);
        Product2 objProduct = ((CalloutData)idata).record;
        String strMessage;
        if (res.getStatusCode() == INTEGER_STATUS_CODE_200)
        {
            // mark Product_Send_To_AEM_Status__c to Deactivated if inactive and configuration type is bundle
        	if(objProduct.IsActive==false)
            {
            	objProduct.Product_Send_To_AEM_Status__c =Label.DeactivatedBundle;
            	strMessage = ' Product: '+ objProduct.Name + ' Deactivated Successfully';
        	} else {   //mark Product_Send_To_AEM_Status__c to Sent
                objProduct.Product_Send_To_AEM_Status__c = 'Sent';
                strMessage = 'Sending of Product: '+ objProduct.Name + ' to AEM was successful';
            }

        } else {
            //mark Product_Send_To_AEM_Status__c to Failed
            objProduct.Product_Send_To_AEM_Status__c = 'Failed';
			strMessage = 'Sending of Product: '+ objProduct.Name + ' to AEM got Failed with Status: '
                        + res.getStatus()+'(Code: '+res.getStatusCode()+')';
        }

        //Creating a chatter feed for the User
        FeedItem post = new FeedItem();
        post.ParentId = objProduct.LastModifiedById;
        post.Body = strMessage;
        insert post;

        System.debug('post: '+post);
        System.debug('objProduct: '+objProduct);
        //update the Product sent to AEM with respective StatusCode received
        update objProduct;
    }

    /*
    * @Author: Akshay Mohan
    * @Description : boolean method for handling error
    * @param: null
    * @return: boolean
    */
    protected override Boolean handlesError()
    {
        return true;
    }

}