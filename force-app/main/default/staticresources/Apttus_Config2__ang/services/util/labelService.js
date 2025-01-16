;(function() {
	angular.module('ngCPQ')
		.service('ngCPQLabels', CPQLabels);
	
	CPQLabels.$inject = ['ngCPQLabelsData'];
			
	function CPQLabels(ngCPQLabelsData) {
		//this.ngCPQLabelsData = ngCPQLabelsData;
		// this.labels = staticDatalabels.CustomLabel;
		this.labels = ngCPQLabelsData.CustomLabel;
		this.getLabelByKey = function(key) {
			return this.ngCPQlabelsData[key];
		
		};
		return this;
	
	}

})();