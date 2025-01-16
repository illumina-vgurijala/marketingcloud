
//this will fix the jittering on sf1
$(function() {
    $('html').css('width', document.body.clientWidth + "px");
});

/************************************************************************************************
* Initialize the Angularjs app and controller for this page
*
*************************************************************************************************/
var app = angular.module("inlineDocViewer", ['ui.bootstrap', 'ngTouch', 'SeismicConnector']);

app.controller("docViewerController", function($scope, seismic, seismicInit) {

	seismic.pageInfo = window.pageInfo;
    seismic.carouselInited = false;
    seismic.setupCarousel = function(isFromCache) {
    	if (window.console) {
        	console.log('Setting up carousel');
    	}
        
        if (seismic.documents && seismic.documents[0]) {
            $scope.formState = 'document-carousel';
            $scope.$digest();
            
            var isSalesforce1App = isInSFOneApp();
            
			if (seismic.carouselInited == false) {
				if (isSalesforce1App) {
		            var style = '<style type="text/css">';
	                style += "\n    html, body, #angular-scope, #document-carousel { height: 100% !important; overflow: hidden; }";
	                style += "\n    body.container { width: 99%; padding-left: 6px; padding-right: 0; }";
	                style += "\n    #document-carousel .carousel-slide { width: 240px; height: 180px; display: inline-block;  margin-top: 10px; vertical-align: top; }";
	                style += "\n    .slick-carousel { overflow: auto; -webkit-overflow-scrolling: touch; }";
	                style += '\n</style>';
	                window.document.head.innerHTML += style;
                }
                seismic.carouselInited = true;
            } else {
            	if (!isSalesforce1App) {
            		$('.slick-carousel').slick("unslick");
            	}
            	
            	var documentHtml = '';
                for (var i = 0, count = seismic.documents.length; i < count; i++){
                    var document = seismic.documents[i];
                    documentHtml += '\n<div class="carousel-slide height-restricted">';
                    documentHtml += '\n    <div style="height: 100%; position: relative; overflow: hidden;">';
                    documentHtml += '\n        <div class="image-border">';
                    documentHtml += '\n            <a href="' + $scope.GetDocUrl(document) + '" target="' + $scope.GetDocTarget(document) + '" class="image-responsive center-block click-open-doc">';
                    documentHtml += '\n                <img src="' + $scope.GetImageUrl(document) + '" style="display: inline-block; cursor: pointer; max-width: 100%;" />';
                    documentHtml += '\n            </a>';
                    documentHtml += '\n        </div>';
                    documentHtml += '\n        <div class="text-overlay" title="' + document.Name + '">';
                    documentHtml += '\n            <h4>' + document.Name + '</h4>';
                    documentHtml += '\n        </div>';
                    documentHtml += '\n    </div>';
                    documentHtml += '\n</div>';
                }
                $('.slick-carousel').html(documentHtml);
            }
            
	        if (isSalesforce1App) {
                if (window.innerHeight <= 210){
                    $('#document-carousel').css({ 'background-color': 'transparent' });
                    $('body').css({ 'background': 'transparent url(' + SeismicResources.Salesforce1InlineViewerBackground + ') right top no-repeat', 'padding-top': '0px' });
                } else {
                    $('#document-carousel').css({ 'background-color': null });
                    $('body').css({ 'background': null, 'padding-top': '10px' });
                }
            } else {
		        $('.slick-carousel').on('init', function(event, slick) {
		            slick.refresh = slick.unfilterSlides;
		        }).slick({
		            speed: 300,
		            slidesToShow: 5,
		            slidesToScroll: 1,
		            variableWidth: false,
		            infinite: false,
		            arrows: true,
		            prevArrow: '<i class="glyphicon glyphicon-chevron-left slick-prev" style="color: black"></i>',
		            nextArrow: '<i class="glyphicon glyphicon-chevron-right slick-next" style="color: black"></i>',
		
		            responsive: [
		                { breakpoint: 1280, settings: { slidesToShow: 4 } },
		                { breakpoint: 1024, settings: { slidesToShow: 3 } },
		                { breakpoint: 600, settings: { slidesToShow: 2 } },
		                { breakpoint: 480, settings: 'unslick' }
		            ]  
		        });
            }
			
	        $('.slick-carousel').css('visibility', 'visible');
        } else {
            if (!isFromCache) {
            	$scope.formState = 'message';
            	$scope.message = { title: 'No Content', content: 'Cannot find related content from Seismic.' };
            }
        }
    }
    
    //pull the modules into the scope
    $scope.seismic = seismic;
    $scope.formState = 'loading';
    $scope.message = { title: null, content: null };
    $scope.errorMessage = null;
    $scope.user = {};

	$scope.GetDocUrl = function(doc) {
        if (doc.Format == DocumentFormats.URL && doc.UrlMode == "1") {
        	return doc.Url;
        } else {
			var url = pageInfo.docViewerUrl;
            url	+= "?live=" + (doc.IsDynamic ? "1" : "0");
			url	+= "&stype=" + seismic.pageInfo.objectType;
            url	+= "&sid=" + seismic.pageInfo.objectId;
            url	+= "&pid=" + seismic.profileInfo.ProfileId;
            url	+= "&pvid=" + seismic.profileInfo.ProfileVersionId;
            url	+= "&fpid=" + encodeURIComponent(doc.DocCenterFullPath);
            url	+= "&fpname=" + encodeURIComponent(doc.FullPath);
            url	+= "&cvid=" + doc.VersionId;
	        
            if (window.location.search && window.location.search.length > 1) {
                var queryString = window.location.search.substring(1);
                var querySections = queryString.split('&');
                for (var index in querySections) {
                    var querySection = querySections[index];
                    if (querySection && angular.isString(querySection)) {
                        var equalIndex = querySection.indexOf('=');
                        if (equalIndex > 0) {
                            var name = querySection.substr(0, equalIndex);
                            var value = querySection.substring(equalIndex + 1);
                            switch (name.toLowerCase()) {
                                case "isdtp":
                                    url	+= "&isdtp=" + value;
                                    break;
                                case "sfdcIFrameOrigin".toLowerCase():
                                    url	+= "&sfdcIFrameOrigin=" + value;
                                    break;
                                case "sfdcIFrameHost".toLowerCase():
                                    url	+= "&sfdcIFrameHost=" + value;
                                    break;
                            }
                        }
                    }
                }
            }
            
            /*
            url	+= "#";
            url += "/" + (doc.IsDynamic ? "LiveDoc" : "Static");
            url	+= "/" + seismic.pageInfo.objectType;
            url	+= "/" + seismic.pageInfo.objectId; 
            url	+= "/" + seismic.profileInfo.ProfileId; 
            url	+= "/" + seismic.profileInfo.ProfileVersionId; 
            url	+= "/" + doc.VersionId;
            */
            
	        return url;
        }
	};
	
	$scope.GetDocTarget = function(doc) {
		if (doc.Format == DocumentFormats.URL && doc.UrlMode == "1") {
			return "_blank";
		}
		return "_top";
	};

    $scope.GetImageUrl = function(doc) {
    	var thumbnailImageId = $scope.GetThumbnailImageId(doc.ThumbnailBlobId);
        var url = 'https://' + seismic.Tenant + '.seismic.com/Resource/Image.ashx' +
                  '?tenant=' + seismic.Tenant + 
                  '&user=' + seismic.UserName +
                  '&client=' + encodeURIComponent(seismic.pageInfo.PackageFullName) + 
                  '&imageid=' + encodeURIComponent(thumbnailImageId);
        return url;
    };
    
    $scope.GetThumbnailImageId = function(thumbnailBlobId) {
    	if (thumbnailBlobId) {
    		return thumbnailBlobId.indexOf('t') == 0 ? thumbnailBlobId : 't' + thumbnailBlobId;
    	}
    	return '';
    };
	
    $scope.OpenDoc = function(doc) {
		var url = $scope.GetDocUrl(doc);
        window.top.location.href = url;
    };
    
    
    
    var loadFromCacheSuccessful = false;
    var hasGetProfileMapping = false;
    
    function _loadProfile() {
        seismic.getProfileMapping(
            function (profileVersionMappings) {
                if (profileVersionMappings && profileVersionMappings[0]) {
                    seismic.cacheSObject();
                    seismic.profileInfo = profileVersionMappings[0];
                    seismic.GetRecursiveDocumentsWithFilter();
                } else {
                    seismic.profileInfo = null;
                	$scope.formState = 'error';
                	$scope.errorMessage = "Seismic cannot find the specified profile, please contact your administrator.";
                }
            });
    }
    
    function _loadPredictiveDocuments() {
        seismic.GetPredictiveDocuments(
            function (serviceResult) {
                if (serviceResult && serviceResult.Profile) {
                    seismic.profileInfo = serviceResult.Profile;
                    
                    if (serviceResult.Documents) {
                        var allDocuments = serviceResult.Documents;
                        var documents = allDocuments[allDocuments.length - 1].Documents;
                        seismic.pushDocuments(documents);
                    }
                } else {
                    seismic.profileInfo = null;
                	$scope.formState = 'error';
                	$scope.errorMessage = "Seismic cannot find the specified profile, please contact your administrator.";
                }
            });
    }
    
    seismicInit.init({ skipOrganization: true }).then(
        function () {
            // Load user information successfully from service call
            _loadPredictiveDocuments();
        }, 
        function (error) {
            // Initialization Error
            if (pageInfo.seismicIsLogined) {
	            $scope.formState = 'error';
	        	if (error && error.Message) {
	                $scope.errorMessage = error.Message;
	            } else {
	                $scope.errorMessage = 'Cannot retrieve your account information from Seismic.'
	            }
            } else {
            	// Let Apex program handle authentication logic
            }
        },
        function (isFromCache) {
            // For most cases, this method will be called twice, first is from cache, second is from service result.
            // If this has been called only once, it must be service result.
            
            if (isFromCache) {
                var cachedSObject = seismic.getCachedSObject();
                if (cachedSObject && cachedSObject.SystemModstamp && cachedSObject.SystemModstamp != pageInfo.objectSystemModstamp) {
                    // The SOjbect has been updated, force to call service to load documents.
                    return;
                } else {
                    var cachedProfileMapping = seismic.getCachedProfileMapping();
                    if (cachedProfileMapping && cachedProfileMapping[0]) {
                        seismic.profileInfo = cachedProfileMapping[0];
                        var cachedDocs = seismic.GetCachedRecursiveDocumentsWithFilter()
                        if (cachedDocs) {
                            setTimeout(function(){
                                seismic.pushDocuments(cachedDocs, true);
                            }, 0);
                            
                            loadFromCacheSuccessful = true;
                        }
                    }
                    
                    if (loadFromCacheSuccessful) {
                       // keep loading from service call 
                    }
                }
            } else {
                _loadProfile();
            }
        });
});