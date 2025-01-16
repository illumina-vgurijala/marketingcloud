/*
 *  This is a work in progress.
 */
/*
 *    @author         :
 *    @date           :
 *    @description    :
 *    Test class for 90% coverage:
 *    Test class for 75% coverage:
 *	  Modification Log:
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date                Description
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ilib_UpsertHelpers {

    //DCP-47694
    public static final String STRING_PART_ORDER_LINE_STATUS_PARTIALLY_SHIPPED = 'Partially Shipped';

    /*
    *  Class Pricelist unit of work helper
    */
    public class PriceListUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Apttus_Config2__PriceList__c> plrecords;

        /*
        *  constructor for decalaring a list of pricelist
        */
        public PriceListUnitOfWorkHelper()
        {
            plrecords = new List<Apttus_Config2__PriceList__c>();
        }

        /*
        *  Method to add Apttus_Config2__PriceList__c
        */
        public void registerUpsert(Apttus_Config2__PriceList__c plRecord)
        {
            plrecords.add(plRecord);
        }

        /*
        *  Method to update database
        */
        public void doWork()
        {
            results = Database.upsert(plrecords, Apttus_Config2__PriceList__c.Fields.External_Id__c, true);
        }
    }

    /*
    *  Class Price Book Entry unit of work helper
    */
    public class PriceBookEntryUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<PricebookEntry> priceBookEntriesRecords;

        /*
        *  constructor for decalaring a list of pricelist
        */
        public PriceBookEntryUnitOfWorkHelper()
        {
            priceBookEntriesRecords = new List<PricebookEntry>();
        }

        /*
        *  Method to add PricebookEntry
        */
        public void registerUpsert(PricebookEntry priceBookEntry)
        {
            priceBookEntriesRecords.add(priceBookEntry);
        }

        /*
        *  Method to update database
        */
        public void doWork()
        {
            results = Database.upsert(priceBookEntriesRecords, false);
        }
    }

    /*
    *  Class for PliUnit of Work helper
    */
    public class PliUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Apttus_Config2__PriceListItem__c> plirecords;

        /*
        *  TConstructor for PliUnitofWorkHelper
        */
        public PliUnitOfWorkHelper()
        {
            plirecords = new List<Apttus_Config2__PriceListItem__c>();
        }

        /*
        *  Method for registerupsert.
        */
        public void registerUpsert(Apttus_Config2__PriceListItem__c pliRecords)
        {
           this.plirecords.add(pliRecords);
        }
        /*
        *  Method for doWork
        */
        public void doWork()
        {
            results = Database.upsert(plirecords, Apttus_Config2__PriceListItem__c.Fields.External_Id__c, true);
        }
    }
    /*
    *  Class for  InsPrdUnitofWorkHelper
    */
   public class InsPrdUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Installed_Product__c> iprecords;

        /*
         *  Method for  InsPrdUnitofWorkHelper
         */
        public InsPrdUnitofWorkHelper()
        {
            iprecords = new List<SVMXC__Installed_Product__c>();
        }

        /*
        *  Method for  adding SVMXC__Installed_Product__c
        */
        public void registerUpsert(SVMXC__Installed_Product__c ipRecord)
        {
            iprecords.add(ipRecord);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(iprecords, SVMXC__Installed_Product__c.Fields.ERP_Equipment_Id__c, true);
        }
    }

    /*
    *  Class for ServContrUnitofWorkHelper
    */
 public class ServContrUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Service_Contract__c> serConrecords;

        /*
        *  Method for  ServContrUnitofWorkHelper
        */
        public ServContrUnitofWorkHelper()
        {
            serConrecords = new List<SVMXC__Service_Contract__c>();
        }

        /*
        *  Method for  adding SVMXC__Service_Contract__c
        */
        public void registerUpsert(SVMXC__Service_Contract__c serConRecord)
        {
            serConrecords.add(serConRecord);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(serConrecords, SVMXC__Service_Contract__c.Fields.SVMX_PS_External_ID__c, true);
        }
    }

    /*
    *  Class for CoveredPrdUnitOfWorkHelper
    */
  public class CoveredPrdUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Service_Contract_Products__c> lirecords;

        /*
        *  Method for  CoveredPrdUnitOfWorkHelper
        */
        public CoveredPrdUnitOfWorkHelper()
        {
            lirecords = new List<SVMXC__Service_Contract_Products__c>();
        }

        /*
        *  Method for adding SVMXC__Service_Contract_Products__c
        */
        public void registerUpsert(SVMXC__Service_Contract_Products__c liRecords)
        {
           this.lirecords.add(liRecords);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(lirecords, SVMXC__Service_Contract_Products__c.Fields.External_Id__c, true);
        }
    }

    /*
    *  Class for CoveredLocationUnitOfWorkHelper
    */
	public class CoveredLocationUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Service_Contract_Sites__c> coveredLocationrecords;

        /*
        *  Method for  CoveredLocationUnitOfWorkHelper
        */
        public CoveredLocationUnitOfWorkHelper()
        {
            coveredLocationrecords = new List<SVMXC__Service_Contract_Sites__c>();
        }

        /*
        *  Method for  adding SVMXC__Service_Contract_Sites__c
        */
        public void registerUpsert(SVMXC__Service_Contract_Sites__c coveredLocation)
        {
           coveredLocationrecords.add(coveredLocation);
        }
        /*
        *  Method for inserting into database
        */
        public void doWork()
        {
            results = Database.upsert(coveredLocationrecords, SVMXC__Service_Contract_Sites__c.Fields.SVMX_PS_External_ID__c, true);
        }
    }
	/*
    * @Author:Kushagra Desai
    * @Description : For Opportunity Object Unit of Work
   */
    public class OpportunityUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Opportunity> opportunityrecords;

        /*
        *  Method for  OpportunityUnitOfWorkHelper
        */
        public OpportunityUnitOfWorkHelper()
        {
           opportunityrecords  = new List<Opportunity>();
        }

        /*
        *  Method for  adding Opportunity
        */
        public void registerUpsert(Opportunity oppsRecord)
        {
            opportunityrecords.add(oppsRecord);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(opportunityrecords, Opportunity.Fields.id, true);
        }
    }
    /*
    * @Author:Kushagra Desai
    * @Description : For Quotation Object Unit of Work
   */
    public class QuoteUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Apttus_Proposal__Proposal__c> quoterecords;

        /*
        *  Method for Quote unit of workhelper
        */
        public QuoteUnitOfWorkHelper()
        {
            quoterecords = new List<Apttus_Proposal__Proposal__c>();
        }

        /*
        *  Method for  adding Apttus_Proposal__Proposal__c
        */
        public void registerUpsert(Apttus_Proposal__Proposal__c quoterecord)
        {
            quoterecords.add(QuoteRecord);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(quoterecords, Apttus_Proposal__Proposal__c.Fields.SAP_Quote__c, true);
        }
    }
    /*
     * @Author: Kushagra Desai
     * @Description: Proposal lineitem Unit of Work
    */
    public class QuotationLineItemUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Apttus_Proposal__Proposal_Line_Item__c> quoteLinerecords;
        private List<Apttus_Proposal__Proposal_Line_Item__c> quoteLineDelrecords;

        /*
        *  Method for  Quotattion LineItem UnitOfWorkHelper
        */
        public QuotationLineItemUnitOfWorkHelper()
        {
            quoteLinerecords = new List<Apttus_Proposal__Proposal_Line_Item__c>();
            quoteLineDelrecords = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        }

        /*
        *  Method for  adding Apttus_Proposal__Proposal_Line_Item__c
        */
        public void registerUpsert(Apttus_Proposal__Proposal_Line_Item__c quoteLineRecord)
        {
            quoteLinerecords.add(quoteLineRecord);
        }
        /*
        *  Method for Deletion of records
        */
        public void registerDelete(List<Apttus_Proposal__Proposal_Line_Item__c> quoteLineRecord)
        {
            quoteLineDelrecords.addall(quoteLineRecord);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
          results = Database.upsert(quoteLinerecords, Apttus_Proposal__Proposal_Line_Item__c.Fields.ERP_Line_Number__c, true);
          Database.delete(quoteLineDelrecords,true);
        }
	}
	/*
    * @Author:Sravan Panchangam
    * @Description : For Product2 Object Unit of Work
   */
    public class ProductUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Product2> plrecords;

        /*
        *  Method for  Production UnitOfWorkHelper
        */
        public ProductUnitOfWorkHelper()
        {
            plrecords = new List<Product2>();
        }

        /*
        *  Method for  Adding Product2
        */
        public void registerUpsert(Product2 plRecord)
        {
            plrecords.add(plRecord);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(plrecords, Product2.Fields.Material_Number__c, true);
        }
    }

    /*
     * @Author: Sravan Panchangam
     * @Description: Product_Sales_Area__c Unit of Work
    */
    public class ProductSalesAreaUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Product_Sales_Area__c> plrecords;

        /*
        *  Method for Product Sales Area UnitOfWorkHelper
        */
        public ProductSalesAreaUnitOfWorkHelper()
        {
            plrecords = new List<Product_Sales_Area__c>();
        }

        /*
        *  Method for  adding Product_Sales_Area__c
        */
        public void registerUpsert(Product_Sales_Area__c plRecord)
        {
            plrecords.add(plRecord);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(plrecords, Product_Sales_Area__c.Fields.ERP_Product_Sales_Area_ID__c, true);
        }
    }

    /*
     * @Author: Todd
     * @Description: Product_Localization__c Unit of Work
    */
    public class ProductLocalizationUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Product_Localization__c> plrecords;

    /*
     * @Description : This method is used to declare a variable of type list
     */
        public ProductLocalizationUnitOfWorkHelper()
        {
            plrecords = new List<Product_Localization__c>();
        }

    /*
     * @Description : This method is used to add a Product_Localization__c records in list
     */
        public void registerUpsert(Product_Localization__c plRecord)
        {
            plrecords.add(plRecord);
        }

    /*
     * @Description : This method is used to upsert the records and add to the list
     */
        public void doWork()
        {
            results = Database.upsert(plrecords, Product_Localization__c.Fields.Product_Localization_ID__c, true);
        }
    }

	/*
     * @Author:Sravan Panchangam
     * @Description : For Apttus_Config2__Order__c Object Unit of Work
    */
    public class ApttusOrderUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Apttus_Config2__Order__c> aorecords;

        /*
        *  Method for  Apttus Order UnitOfWorkHelper
        */
        public ApttusOrderUnitOfWorkHelper()
        {
            aorecords = new List<Apttus_Config2__Order__c>();
        }

        /*
        *  Method for adding Apttus_Config2_Order__c
        */
        public void registerUpsert(Apttus_Config2__Order__c aoRecord)
        {
            aorecords.add(aoRecord);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(aorecords, Apttus_Config2__Order__c.Fields.Sales_Order_Number_Unique__c, true);
        }
    }

    /*
     * @Author: Sravan Panchangam
     * @Description: Apttus_Config2__OrderLineItem__c Unit of Work
     */
    public class OrderLineItemUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Apttus_Config2__OrderLineItem__c> olirecords;

        /*
        *  Method for  Declaring list of OrderLineItem
        */
        public OrderLineItemUnitOfWorkHelper()
        {
            olirecords = new List<Apttus_Config2__OrderLineItem__c>();
        }

        /*
        *  Method for adding Apttus_Config2_OrderLineItem__c
        */
        public void registerUpsert(Apttus_Config2__OrderLineItem__c oliRecord)
        {
            olirecords.add(oliRecord);
        }
        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(olirecords, Apttus_Config2__OrderLineItem__c.Fields.ERP_Line_Number_Id__c, true);
        }
    }

	  /*
    * @Author: Kushagra Desai
    * @Description : For Case Object Unit of Work
   */
    public class CaseUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Case> plrecords;

        /*
        *  Method for declaring a list of case
        */
        public CaseUnitOfWorkHelper()
        {
            plrecords = new List<Case>();
        }

        /*
        *  Method for addign a case
        */
        public void registerUpsert(Case plRecord)
        {
            plrecords.add(plRecord);
        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(plrecords, Case.id, true);
        }
    }

    /*
    *  Class for WorkOrdersUnitofWorkHelper
    */
	public class WorkOrdersUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Service_Order__c> workOrderrecords;

        /*
        *  Method for declaring a list of SVMXC_Service_Order__c
        */
        public WorkOrdersUnitofWorkHelper()
        {
            workOrderrecords = new List<SVMXC__Service_Order__c>();
        }

        /*
        *  Method for inserting a record
        */
        public void registerUpsert(SVMXC__Service_Order__c workOrderRecord)
        {
            workOrderrecords.add(workOrderRecord);
        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(workOrderrecords, SVMXC__Service_Order__c.Fields.Id, true);
        }
    }

    /*
    *  Class for WorkDetailsUnitOfWorkHelper
    */
  public class WorkDetailsUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Service_Order_Line__c> workDetailrecords;

        /*
        *  Method for declaring a list
        */
        public WorkDetailsUnitOfWorkHelper()
        {
            workDetailrecords = new List<SVMXC__Service_Order_Line__c>();
        }

        /*
        *  Method for inserting a record
        */
        public void registerUpsert(SVMXC__Service_Order_Line__c workDetailRecords)
        {
           this.workDetailrecords.add(workDetailRecords);
        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(workDetailrecords, SVMXC__Service_Order_Line__c.Fields.Id, true);
        }
    }

    /*
    *  Class for ServiceBOMUnitofWorkHelper
    */
	 public class ServiceBOMUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Service_Bill_Of_Materials__c> serviceBOMrecords;

        /*
        *  Method for declaring a list
        */
        public ServiceBOMUnitofWorkHelper()
        {
            serviceBOMrecords = new List<Service_Bill_Of_Materials__c>();
        }

        /*
        *  Method for adding a record
        */
        public void registerUpsert(Service_Bill_Of_Materials__c serviceBOMRecord)
        {
            serviceBOMrecords.add(serviceBOMRecord);
        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(serviceBOMrecords, Service_Bill_Of_Materials__c.Fields.ERP_Service_BoM_Number__c, true);
        }
    }

    /*
    *  Class for FruListUnitOfWorkHelper
    */
  public class FruListUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<FRU_List__c> fruListrecords;
		private List<FRU_List__c> fruListDelrecords;
        private List<FRU_List__c> finalFruListDelrecords;

        /*
        *  Method for declaring Lists
        */
        public FruListUnitOfWorkHelper()
        {
            fruListrecords = new List<FRU_List__c>();
			fruListDelrecords = new List<FRU_List__c>();
            finalFruListDelrecords = new List<FRU_List__c>();
        }

        /*
        *  Method for adding a record
        */
        public void registerUpsert(FRU_List__c fruListRecords)
        {
           this.fruListrecords.add(fruListRecords);
        }

        /*
        *  Method for deleting records
        */
		public void registerDelete(List<FRU_List__c> fruListRecord)
        {
            fruListDelrecords = fruListRecord;

        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
             //check if the upsert was successfull.
            Boolean isSuccess = false;

            //store fruList records with its upsert/insert status
            Map<String,Boolean> fruListRecordsToIsUpserted = new  Map<String,Boolean>();

            //make an upsert call
            results = Database.upsert(fruListrecords, FRU_List__c.Fields.SVMX_PS_External_ID__c, true);
            system.debug('results  '  +results);

            //Iterate to check all the fruList records processed.
            for(Integer index = 0, size = results.size(); index < size; index++) {
            if(results[index].isSuccess() && results[index].getErrors().isEmpty()) {
            fruListRecordsToIsUpserted.put(results[index].getId(),results[index].isCreated());
            isSuccess = true;
            } else {
            isSuccess = false;
            break;
            }
            }

            //Delete only the records which are not updated.
            for(FRU_List__c fruListIds : fruListDelrecords){
            if(!fruListRecordsToIsUpserted.containsKey(fruListIds.Id)){
            finalFruListDelrecords.add(fruListIds);
            }
            }

            if(isSuccess && finalFruListDelrecords != null && !finalFruListDelrecords.isEmpty())
            Database.delete(finalFruListDelrecords,true);
        }
    }

    /*
    *  Class for PartsOrderUnitofWorkHelper
    */
	public class PartsOrderUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__RMA_Shipment_Order__c> partsOrderrecords;

        /*
        *  COnstructor for PartsOrderUnitofWorkHelper
        */
        public PartsOrderUnitofWorkHelper()
        {
            partsOrderrecords = new List<SVMXC__RMA_Shipment_Order__c>();
        }

        /*
        *  Method for adding PartsOrder record
        */
        public void registerUpsert(SVMXC__RMA_Shipment_Order__c partsOrderRecord)
        {
            partsOrderrecords.add(partsOrderRecord);
        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(partsOrderrecords, SVMXC__RMA_Shipment_Order__c.Fields.ERP_Sales_Order_Number__c, true);
        }
    }

    /*
    *  Class for PartsOrderLineUnitOfWorkHelper
    */
   public class PartsOrderLineUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__RMA_Shipment_Line__c> partsOrderLinerecords;
        private List<SVMXC__RMA_Shipment_Line__c> partsOrderLineDelrecords;
        private List<SVMXC__RMA_Shipment_Line__c> finalPartsOrderLineDelrecords;
        private List<SVMXC__RMA_Shipment_Line__c> partsOrderLineOriginalrecords;


        /*
        *  Method for declaring Lists
        */
        public PartsOrderLineUnitOfWorkHelper()
        {
            partsOrderLinerecords = new List<SVMXC__RMA_Shipment_Line__c>();
            partsOrderLineDelrecords = new List<SVMXC__RMA_Shipment_Line__c>();
            finalPartsOrderLineDelrecords = new List<SVMXC__RMA_Shipment_Line__c>();
            partsOrderLineOriginalrecords = new List<SVMXC__RMA_Shipment_Line__c>();
        }

        /*
        *  Method for adding Partsorder Linerecords
        */
        public void registerUpsert(SVMXC__RMA_Shipment_Line__c partsOrderLineRecords)
        {
           this.partsOrderLinerecords.add(partsOrderLineRecords);
        }

        /*
        *  Method for registerDelete
        */
        public void registerDelete(List<SVMXC__RMA_Shipment_Line__c> partsOrderLineRecord)
        {
            partsOrderLineDelrecords = partsOrderLineRecord;

        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            Boolean isSuccess = false;
            Map<String,Boolean> partsOrderLineToIsUpserted = new  Map<String,Boolean>();
            //make an upsert call
            system.debug('partsOrderLinerecords  '  +partsOrderLinerecords);
            results = Database.upsert(partsOrderLinerecords, SVMXC__RMA_Shipment_Line__c.Fields.External_ID__c, true);

            system.debug('results  '  +results);
            for(Integer index = 0, size = results.size(); index < size; index++) {
            if(results[index].isSuccess() && results[index].getErrors().isEmpty()) {
            partsOrderLineToIsUpserted.put(results[index].getId(),results[index].isCreated());
            isSuccess = true;
            } else {
            isSuccess = false;
            break;
            }
            }

            //Delete only the records which are not updated.

            for(SVMXC__RMA_Shipment_Line__c partsOrderLineIds : partsOrderLineDelrecords){

            //do not delete the original line item - because the external Id is blank, that means it is an original line item.
            if(!partsOrderLineToIsUpserted.containsKey(partsOrderLineIds.Id) && partsOrderLineIds.External_ID__c != null){
            finalPartsOrderLineDelrecords.add(partsOrderLineIds);
            }

            if(partsOrderLineIds.External_ID__c == null && partsOrderLineIds.SVMXC__Line_Status__c != 'Canceled'){
            //mark the status of original line item to status as canceled.
                if(Feature.isOn(PartsOrderLines.PARTIAL_SHIPMENT)){
                    partsOrderLineOriginalrecords.add(new SVMXC__RMA_Shipment_Line__c(Id = partsOrderLineIds.Id, SVMXC__Line_Status__c = partsOrderLineIds.SVMXC__Line_Status__c == STRING_PART_ORDER_LINE_STATUS_PARTIALLY_SHIPPED ? STRING_PART_ORDER_LINE_STATUS_PARTIALLY_SHIPPED : 'Canceled' ));
                }else{
                    partsOrderLineOriginalrecords.add(new SVMXC__RMA_Shipment_Line__c(Id = partsOrderLineIds.Id, SVMXC__Line_Status__c = 'Canceled'));
                }

            }

            }

             system.debug('partsOrderLineOriginalrecords ' +partsOrderLineOriginalrecords);
            if(isSuccess && partsOrderLineOriginalrecords != null && !partsOrderLineOriginalrecords.isEmpty())
            update partsOrderLineOriginalrecords;

            system.debug('finalPartsOrderLineDelrecords ' +finalPartsOrderLineDelrecords);
            if(isSuccess && finalPartsOrderLineDelrecords != null && !finalPartsOrderLineDelrecords.isEmpty())
            Database.delete(finalPartsOrderLineDelrecords,true);



        }
    }

    /*
    *  Class for LocationUnitofWorkHelper
    */
	 public class LocationUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Site__c> locationrecords;

        /*
        *  Method for declaring new List
        */
        public LocationUnitofWorkHelper()
        {
            locationrecords = new List<SVMXC__Site__c>();
        }

        /*
        *  Method for adding Location record
        */
        public void registerUpsert(SVMXC__Site__c locationRecord)
        {
            locationrecords.add(locationRecord);
        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(locationrecords, SVMXC__Site__c.Fields.SVMX_PS_External_ID__c, true);
        }
    }

    /*
    *  Class for ProductStockUnitOfWorkHelper
    */
public class ProductStockUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Product_Stock__c> productStockrecords;

        /*
        *  Method for new List
        */
        public ProductStockUnitOfWorkHelper()
        {
            productStockrecords = new List<SVMXC__Product_Stock__c>();
        }

        /*
        *  Method for adding ProductStock Record
        */
        public void registerUpsert(SVMXC__Product_Stock__c productStockRecord)
        {
            productStockrecords.add(productStockRecord);
        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(productStockrecords, SVMXC__Product_Stock__c.Fields.SVMX_PS_External_ID__c, true);
        }
    }

    /*
    *  Class for StockedSerialUnitOfWorkHelper
    */
public class StockedSerialUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Product_Serial__c> stockedSerialrecords;

        /*
        *  Method for creating new List
        */
        public StockedSerialUnitOfWorkHelper()
        {
            stockedSerialrecords = new List<SVMXC__Product_Serial__c>();
        }

        /*
        *  Method for adding Stockedserial record
        */
        public void registerUpsert(SVMXC__Product_Serial__c stockedSerialRecord)
        {
            stockedSerialrecords.add(stockedSerialRecord);
        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(stockedSerialrecords, SVMXC__Product_Serial__c.Fields.SVMX_PS_External_ID__c, true);
        }
    }

    /*
    *  Class for AccountUnitofWorkHelper
    */
public class AccountUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Account> accrecords=new List<Account>() ;
        private List<Account> listAccountWithId=new List<Account>() ;
        private List<Account> listAccountWithoutId= new List<Account>();

        /*
        *  Method for creating new List
        */
        public AccountUnitofWorkHelper()
        {
            accrecords = new List<Account>();
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(List<Account> records)
        {
            System.debug('accrecords==1'+accrecords);
            accrecords.addAll(records);
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(Account record)
        {
            System.debug('accrecords==1'+accrecords);
            if(record.Id!=Null)
            {
            listAccountWithId.add(record);
            }
            else{
            listAccountWithoutId.add(record);
            }

        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            System.debug('accrecords==='+accrecords);
            if(listAccountWithId!=null){
                results = Database.upsert(listAccountWithId,true);

             System.debug('results666=='+results);
            }
            if(listAccountWithoutId!=null){
                results = Database.upsert(listAccountWithoutId,Account.ERP_Customer_Id__c,true);

            }
            System.debug('results=='+results);

        }
    }

    /*
    *  Class for SalesAreaUnitofWorkHelper
    */
    public class SalesAreaUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Account_Sales_Area__c> erpsalesrecords;

        /*
        *  Method for adding new list
        */
        public SalesAreaUnitofWorkHelper()
        {
            erpsalesrecords = new List<Account_Sales_Area__c>();
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(Account_Sales_Area__c record)
        {
            erpsalesrecords.add(record);
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(List<Account_Sales_Area__c> records)
        {
            erpsalesrecords.addAll(records);
        }

        /*
        *  Method for updating Database
        */
        public void doWork()
        {
            results = Database.upsert(erpsalesrecords, Account_Sales_Area__c.ERP_Account_Sales_Area_Id__c,true);

        }
    }

    /*
    *  Class for AccountRelationshipUnitofWorkHelper
    */
    public class AccountRelationshipUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<Account_Relationship__c> erpsalesrecords;

        /*
        *  Method for adding new List
        */
        public AccountRelationshipUnitofWorkHelper()
        {
            erpsalesrecords = new List<Account_Relationship__c>();
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(Account_Relationship__c record)
        {
            erpsalesrecords.add(record);
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(List<Account_Relationship__c> records)
        {
            erpsalesrecords.addAll(records);
        }

        /*
        *  Method for updating database
        */
        public void doWork()
        {
            results = Database.upsert(erpsalesrecords, Account_Relationship__c.ERP_Account_Relationship_Id__c, true);
        }
    }

    /*
    *  Class for CustMasterUnitofWorkHelper
    */
    public class CustMasterUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }
        private List<Customer_Master_Data__c> erpcustrecords;

        /*
        *  Method for adding new List
        */
        public CustMasterUnitofWorkHelper() {
            erpcustrecords = new List<Customer_Master_Data__c>();
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(Customer_Master_Data__c record) {
            erpcustrecords.add(record);
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(List<Customer_Master_Data__c> records) {
            erpcustrecords.addAll(records);
        }

        /*
        *  Method for updating Database
        */
        public void doWork() {
            results = Database.upsert(erpcustrecords, Customer_Master_Data__c.ERP_Customer_Id__c, true);
        }
    }



/*
public class ErpPartnerUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork{
     public List<Database.UpsertResult> results { get; private set; }

         private List<ERP_Partner_Function__c> erpPartner_records;

         public accUnitofWorkHelper()
        {
            erpPartner_records = new List<Account>();
        }

         public void registerUpsert(List<ERP_Partner_Function__c> records)
         {
             erpPartner_records.addAll(records);
         }

        public void doWork()
        {
            results = Database.upsert(erpPartner_records, ERP_Partner_Function__c.Fields.ExternalId__c, false);
        }
}

    */



    // public class OpportunityUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    // {
    //     public List<Database.UpsertResult> results { get; private set; }
    //
    //     private List<Opportunity> m_records;
    //
    //     public OpportunityUnitOfWorkHelper()
    //     {
    //         m_records = new List<Opportunity>();
    //     }
    //
    //     public void registerUpsert(Opportunity record)
    //     {
    //         m_records.add(record);
    //     }
    //
    //     public void doWork()
    //     {
    //         results = Database.upsert(m_records, Opportunity.Fields.Opportunity_ERP_Id__c, false);
    //     }
    // }
    //
    // public class OliUnitOfWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    // {
    //     public List<Database.UpsertResult> results { get; private set; }
    //
    //     private List<OpportunityLineItem> m_records;
    //
    //     public OliUnitOfWorkHelper()
    //     {
    //         m_records = new List<OpportunityLineItem>();
    //     }
    //
    //     public void registerUpsert(List<OpportunityLineItem> records)
    //     {
    //         m_records.addAll(records);
    //     }
    //
    //     public void doWork()
    //     {
    //         results = Database.upsert(m_records, OpportunityLineItem.Fields.OLI_ERP_Id__c, false);
    //     }
    // }
    /*
    * @Author:Karthik
    * @Description : For Promotions__c Object Unit of Work
   */
    public class PromotionsUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }
        private List<Promotions__c> lstErpPromo;

        /*
        *  Method for adding new List
        */
        public PromotionsUnitofWorkHelper() {
            lstErpPromo = new List<Promotions__c>();
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(List<Promotions__c> records) {
            lstErpPromo.addAll(records);
        }

        /*
        *  Method for Updating Database
        */
        public void doWork() {
            results = Database.upsert(lstErpPromo, Promotions__c.Promotion_Code__c, true);
        }
    }

     /*
    * @Author:Vaibhav
    * @Description : DCP-42718 LMS-DCP Course Completion Data Sync
   */
    public class ProductServicedUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork
    {
        public List<Database.UpsertResult> results { get; private set; }

        private List<SVMXC__Service_Group_Product__c> productServicedRecords;

        /*
        *  Method for adding new List
        */
        public ProductServicedUnitofWorkHelper()
        {
            productServicedRecords = new List<SVMXC__Service_Group_Product__c>();
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(SVMXC__Service_Group_Product__c record)
        {
            productServicedRecords.add(record);
        }

        /*
        *  Method for adding new record
        */
        public void registerUpsert(List<SVMXC__Service_Group_Product__c> records)
        {
            productServicedRecords.addAll(records);
        }

        /*
        *  Method for updating Database
        */
        public void doWork()
        {
            results = Database.upsert(productServicedRecords, SVMXC__Service_Group_Product__c.Id,true);

        }
    }

    /*
    * @Author:Parthasarathy D
    * @Description : DCP-55534-Helper class for the object Account Discount Tier.
   */
    public class DisountTierUnitofWorkHelper implements ilib_SObjectUnitOfWork.IDoWork {

        public List<Database.UpsertResult> results { get; private set; }

        private List<Account_Discount_Tier__c> erpdiscounttierRecords;

        /*
        * @Description : DCP-55534-Default Constructor for the class.
        */
        public DisountTierUnitofWorkHelper() {
            erpdiscounttierRecords = new List<Account_Discount_Tier__c>();
        }

        /*
        * @Description : DCP-55534-Method to register for the upsert of individual Account Discount tier record.
        */
        public void registerUpsert(Account_Discount_Tier__c record) {
            erpdiscounttierRecords.add(record);
        }

        /*
        * @Description : DCP-55534-Method to register for the upsert of list of Account Discount tier record.
        */
        public void registerUpsert(List<Account_Discount_Tier__c> records) {
            erpdiscounttierRecords.addAll(records);
        }

        /*
        * @Description : DCP-55534- Method to perform the upsert operation on the Account Discount Tier records based on the externalID.
        */
        public void doWork() {
            results = Database.upsert(erpdiscounttierRecords, Account_Discount_Tier__c.External_Id__c,true);

        }
    }

}
