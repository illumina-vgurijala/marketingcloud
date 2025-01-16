/**
 *	This JavaScript resource contains utility functions for CPQ System Overview feature displaying bad data.
 *	(Refer JIRA Issue - 1884)
 */
	var j$ = jQuery.noConflict();
	
	j$(function() {
		refreshRuleSection();
		refreshPriceListSection();
		refreshProductFilterSection();
		refreshAssetLineSection();
		refreshCustomSettingsSection();
		refreshCategoryHierarchySection();
		refreshAVMSection();
		refreshProductAttributeSchemaComparisonSection();
		refreshMissingConditionCriteriaFields();

	});
	
	var vfRemoteParams = {buffer: false, escape: true, timeout: 120000};
	            
	/** 
	 *	This function displays the bad data in Category hierarchy section for following aspects:
	 *  1. Verify that category hierarchy object have correct values in required fields. (Checking correctness of parent option group, 
	 *		root option group and level fields of any option group)
	 *	2. Verify that option groups have correct hierarchy references. (Parent Option Group value of Product Option Group should 
	 *	  	match with Ancestor of corresponding Classification Hierarchy and Root Option Group value of Product Option Group should match 
	 *	   	with Hierarchy valud of corresponding Classification Hierarchy)
	 */
	function refreshCategoryHierarchySection(){
		j$('#categoryHierarchyContentDivRefresh').hide();
		j$('#categoryHierarchyContentDivLoading').show();
		
		Visualforce.remoting.Manager
			.invokeAction(
				j$.APTTUS.RemoteController.getCategoryHierarchySectionMap,
					function(result, event) {
						showHTMLContent('categoryHierarchyContentDiv', result);
						j$('#categoryHierarchyContentDivLoading').hide();
						j$('#categoryHierarchyContentDivRefresh').show();
					}
			, vfRemoteParams);
	}
	
	/**
	 *	This function displays the bad data in Custom Settings section. Custom Settings section shows bad data related to
	 *  following custom settings :  
	 *  1. Config System Properties
	 *  2. Config Select Product Settings
	 *  3. Config Select Option Settings
	 *  4. Config LineItem Criteria Fields
	 *  5. Config Constraint Criteria Fields
	 *  6. Installed Product Settings
	 *  7. COnfig Custom Display Columns
	 */
	function refreshCustomSettingsSection(){
		j$('#customSettingsContentDivRefresh').hide();
		j$('#customSettingsContentDivLoading').show();
		
		Visualforce.remoting.Manager
			.invokeAction(
				j$.APTTUS.RemoteController.getCustomSettingsSectionMap,
					function(result, event) {
						showHTMLContent('customSettingsContentDiv', result);
						j$('#customSettingsContentDivLoading').hide();
						j$('#customSettingsContentDivRefresh').show();
					}, vfRemoteParams);
	}
	
	/** 
	 *	This function displays the bad data in Asset line section. Asset Line Section displays bad data for following aspects: 
	 *	1. Asset line items should have appropriate values for business object id, isPrimaryLine flag, 
	 *		line number and bundle Item id for option asset line.
	 */
	function refreshAssetLineSection(){
		j$('#assetLineItemsContentDivRefresh').hide();
		j$('#assetLineItemsContentDivLoading').show();
		Visualforce.remoting.Manager
			.invokeAction(
				j$.APTTUS.RemoteController.getAssetLineSectionMap,
					function(result, event) {
						showHTMLContent('assetLineItemsContentDiv', result);
						j$('#assetLineItemsContentDivLoading').hide();
						j$('#assetLineItemsContentDivRefresh').show();
					}, vfRemoteParams);
	}

	/** 
	 *	This function displays the bad data in Constraint Rule section for following aspects:
	 *	1. Constraint Rule Must have at least one condition and one action.
	 *	2. Constraint action criteria for validation rule is with line item object context and 
	 *		constraint action criteria for inclusion and exclusion action is with product object context.
	 *	3. Verify that field names used in criteria like constraint rule condition criteria and 
	 *		constraint rule action criteria, charge type conditions etc are present in object
 	 */            
    function refreshRuleSection(){
		j$('#ruleContentDivRefresh').hide();
		j$('#ruleContentDivLoading').show();
    	
    	Visualforce.remoting.Manager
			.invokeAction(
				j$.APTTUS.RemoteController.getRuleSectionMap,
					function(result, event) {
				       	showHTMLContent('ruleContentDiv', result);
						j$('#ruleContentDivLoading').hide();
						j$('#ruleContentDivRefresh').show();
			       	}, vfRemoteParams);
    }

    
   /** 
   	*	This function displays the bad data in Price List section for following aspects.
   	*  1. Price List Item must have a charge type.
   	*  2. Price list item with duplicate charge type should be conditional
   	*  3. Verify that Price Dimension field name is API name.
    */ 
   function refreshPriceListSection(){
		j$('#priceListContentDivRefresh').hide();
   		j$('#priceListContentDivLoading').show();
   		
   		Visualforce.remoting.Manager
   			.invokeAction(
			   	j$.APTTUS.RemoteController.getPriceListSectionMap,
				   	function(result, event) {
						showHTMLContent('priceListContentDiv', result);
						j$('#priceListContentDivLoading').hide();
						j$('#priceListContentDivRefresh').show();
				   	}, vfRemoteParams);
   }
    
   /** 
   	*	This function displays the bad data in Price List section for following aspects.
   	*  1. Price List Item must have a charge type.
   	*  2. Price list item with duplicate charge type should be conditional
   	*  3. Verify that Price Dimension field name is API name.
    */ 
   function refreshProductFilterSection(){
		j$('#productFilterContentDivRefresh').hide();
   		j$('#productFilterContentDivLoading').show();
   		
   		Visualforce.remoting.Manager
   			.invokeAction(
			   	j$.APTTUS.RemoteController.getProductFilterSectionMap,
				   	function(result, event) {
						showHTMLContent('productFilterContentDiv', result);
						j$('#productFilterContentDivLoading').hide();
						j$('#productFilterContentDivRefresh').show();
				   	}, vfRemoteParams);
    }

    /**
     * This function displays html text obtained from back-end to corresponding division of a particular section.
     */
    function showHTMLContent(sectionDiv, resultMap) {
		try{
			var isRecordsToDisplayAvailable = false;
			for (key in resultMap) {
				// setting the limit to 10 if there are more than 10 invalid records
				var limit = (resultMap[key].length > 10) ? 10 : resultMap[key].length;
				j$('#' + key + 'Div').show();
				// j$('#' + key).empty();
				if(resultMap[key].length == 0) {
					console.log('No records in ' + key);
					j$('#' + key + 'Div').hide();
				} else {
					// Limiting the number of records to 'limit' to display on front-page using slice() method and 
					// removing commas in the string representation of list using split() and join() method
					var invalidRecords = resultMap[key].slice(0, limit).toString().split(",").join(" ");
					if(resultMap[key].length > 10) {
						invalidRecords += '&lt;li&gt; ... ' + (resultMap[key].length - 10) + ' ' + j$.APTTUS.More + '&lt;/li&gt; ';
					}
					var invalidRecordsHtml = j$.parseHTML(htmlDecode(invalidRecords));
					j$('#' + key).html(invalidRecordsHtml);
					isRecordsToDisplayAvailable = true;
				}
			}
			if(!isRecordsToDisplayAvailable) {
				j$('#' + sectionDiv).html('<p style="margin-left:2%">' + j$.APTTUS.NoRecordsToDisplay +  '</p>');
			} 
		} catch (exception) {
			j$('#' + sectionDiv).html(j$.APTTUS.ErrorRetrievingInvalidRecords);
		}
    }

	/** 
	 *	This function displays the bad data in Attribute Based Configuration section for following aspects:
	 *	1. The Product scope for an attribute value matrix is 'All'
	 *	2. The Product Group scope for an attribute value matrix is 'All'
	 *	3. The Product Family scope for an attribute value matrix is 'All'
	 */
	function refreshAVMSection(){
		j$('#avmContentDivRefresh').hide();
		j$('#avmContentDivLoading').show();
    	
    	Visualforce.remoting.Manager
			.invokeAction(
				j$.APTTUS.RemoteController.getAVMSectionMap,
					function(result, event) {
				       	showHTMLContent('avmContentDiv', result);
						j$('#avmContentDivLoading').hide();
						j$('#avmContentDivRefresh').show();
			       	}, vfRemoteParams);
    }

    /**
	 *	This function displays the bad data in Product Attribute Schema Comparison section. Product Attribute Schema Comparison section shows bad data related to
	 *  1. missing attributes from Apttus_QPConfig__ProposalProductAttributeValue__c
	 *  2. missing attributes from OrderProductAttributeValue__c
	 *  3. missing attributes from AssetAttributeValue__c
	 */
	function refreshProductAttributeSchemaComparisonSection(){
		j$('#attributeComparisonContentDivRefresh').hide();
		j$('#attributeComparisonContentDivLoading').show();
		
		Visualforce.remoting.Manager
			.invokeAction(
				j$.APTTUS.RemoteController.getProductAttributeSchemaComparisonMap,
					function(result, event) {
						showHTMLContent('attributeComparisonContentDiv', result);
						j$('#attributeComparisonContentDivLoading').hide();
						j$('#attributeComparisonContentDivRefresh').show();
					}, vfRemoteParams);
	}

    function refreshMissingConditionCriteriaFields(){
    	j$('#missingConditionCriteriaFieldsDivRefresh').hide();
		j$('#missingConditionCriteriaFieldsDivLoading').show();

		Visualforce.remoting.Manager
			.invokeAction(
				j$.APTTUS.RemoteController.getMissingConditionCriteriaFieldMap,
					function(result, event) {
						showHTMLContent('missingConditionCriteriaFieldsDiv', result);
						j$('#missingConditionCriteriaFieldsDivLoading').hide();
						j$('#missingConditionCriteriaFieldsDivRefresh').show();
					}, vfRemoteParams);
    }
    
    /** 
     *	This function decodes html string obtained from controller functions correctly so that 
   	 *	strings get parsed correctly as html content on the front-end.
     *	Earlier, without using this function, html string '<li> (bad data message) </li>' was 
     *	displayed on front-end as '&lt;li&gt; (bad data message) &lt;/li&gt;'. 
   	 */ 
    function htmlDecode(input){
	  var elem = document.createElement('div');
	  elem.innerHTML = input;
	  return elem.childNodes.length === 0 ? "" : elem.childNodes[0].nodeValue;
	}
      