var j$ = jQuery.noConflict();

function advancedSearchFunctionality(j$, 
	searchHeaderSelector, 
	searchResultSelector, 
	leaveEnabledIfAllUnchecked){

		// advanced search results check functionality
		j$(searchHeaderSelector).next().find(':checkbox').on("change", function() {
			// if checkbox checked then activate select button
			toggleSelectButton(j$(this).closest(searchResultSelector).parent());
		});


	this._checkAll = function($checkboxes, check) {
			$checkboxes.each(function( index ) {
				var $this = j$( this );

				// if check already matching select all status don't trigger click
				if($this.is(':checked') !== check) {
					$this[0].click();
				}
				
			});
		};

		j$('#checkAll').change(function() {
			$resultSet = j$(this).closest(searchHeaderSelector).next();
            var checkboxes = $resultSet.find(':checkbox');
		    if(j$(this).is(':checked')) {
		    	_checkAll(checkboxes, true);

		        // all checked, so activate select button
		        setSelectButtonStatus($resultSet, true);
		    } else { // deselect all check buttong
		    	_checkAll(checkboxes, false);

		        setSelectButtonStatus($resultSet, false);
		    }
        });

       	// window resize event
       	j$( window ).on("resize", function() {		  
		  j$(searchHeaderSelector).width(j$(searchResultSelector).width())
		});

		// trigger initial resize on load
		j$(window).resize();

		function toggleSelectButton($closestResultSet) {
			// if all unchecked then disable button
	    	if($closestResultSet.find(':checkbox:checked').length === 0) {
	    		// deactivate select button
	    		setSelectButtonStatus($closestResultSet, false);
	    	} else {
	    		// activate select button
	    		setSelectButtonStatus($closestResultSet, true);
	    	}
		}

	this.setSelectButtonStatus = function($closestResultSet, isActive) {
		if(!leaveEnabledIfAllUnchecked) return;
		
			if(!isActive) {
	    		// deactivate select button
	    		var $selectBtn = $closestResultSet.next().find(".btn.select-active");
	    		$selectBtn.attr("class", "btn disabled");
	    		$selectBtn.attr("disabled", "disabled");
	    		$selectBtn.on("click", function() { return false; });
	    	} else {
	    		// activate select button
	    		var $selectBtn = $closestResultSet.next().find(".btn.disabled");
	    		$selectBtn.attr("class", "btn select-active");
	    		$selectBtn.removeAttr("disabled");
	    		$selectBtn.off("click");
	    	}
		}

	return this;
	}

(function() {
	j$(document).ready(function() {
        searchControl(j$, ".advanced-search .search");
	});
	
	function searchControl(j$, searchController) {
		var jqSearchController = j$(searchController);
		jqSearchController.each(function() {
			
			$currentControl = j$(this).find('input');
			
			// search textbox focus event
			$currentControl.on("keyup", function() {
				$this = j$(this);
				if($this.val() !== "") {
					$this.closest('.search').find('i.fa-search').hide();
					$this.closest('.search').find('label > div').show();
				} else {
					j$(this).closest('.search').find('label > div').hide();
					j$(this).closest('.search').find('i.fa-search').show();
				}
			});

			$currentControl.on("blur", function() {
				if(j$(this).closest('.search').find('input').val() === "") {
					j$(this).closest('.search').find('label > div').hide();
					j$(this).closest('.search').find('i.fa-search').show();
				}
			});

			// cancel icon click event
			j$(this).find('label div').on("click", function() {
				j$(this).closest('.search').find('input').val("");
				j$(this).closest('.search').find('label > div').hide();
				j$(this).closest('.search').find('i.fa-search').show();
			});
		});
	}
}());