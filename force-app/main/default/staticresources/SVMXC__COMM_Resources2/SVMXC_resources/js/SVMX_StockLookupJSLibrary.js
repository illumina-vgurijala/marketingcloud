/*========   Global variables used by Stock Lookup Routines   ===========*/
var SLKP_ReqQty;
var SLKP_UserId;
var SLKP_geocoder;
var SLKP_map;
var SLKP_unit;
var SLKP_radius = 0;
var SLKP_YouAreHere;
var SLKP_StartingPoint;
var MsgList = new Object();
var markersArray = new Array();
var returnValue;
var objPSIDName = new Object();

/*=====================================================================================*/
function SVMXI_CalculateDistance(lat1, lon1, lat2, lon2) 
{ 
	var R = 6371; // km 
	var dLat = (lat2-lat1) * Math.PI / 180; 
	var dLon = (lon2-lon1) * Math.PI / 180; 
	var a = Math.sin(dLat/2) * Math.sin(dLat/2) + 
	Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
	Math.sin(dLon/2) * Math.sin(dLon/2); 
	var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
	var dkm = R * c;
	var dmiles = dkm * 0.621371192; 
	if (SLKP_unit == "Miles")
	{
		return Math.round(dmiles);
	}
	else {return Math.round(dkm);}
} 

/*==========================================================*/
function SVMXC_SetupStockLookupPage(loc, reqQty, strJSONMessage) 
{
	SLKP_YouAreHere = loc;
	SLKP_ReqQty = reqQty;
	MsgList = JSON.parse(strJSONMessage);

    var mapOptions = {
		zoom: 8,
		mapTypeControl: true,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	}
	SLKP_map = new google.maps.Map(document.getElementById("googlemap"), mapOptions);
	SLKP_geocoder = new google.maps.Geocoder(); 
    if (!SLKP_geocoder)
		alert(SVMXC_GetMessage("MSG008"));
	SVMXC_AddStartingPoint();
}

/*==========================================================*/
function SVMXC_AddStartingPoint()
{
	SLKP_geocoder.geocode( {'address': SLKP_YouAreHere }, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			var point = results[0].geometry.location;		
			if (point)
			{
				SLKP_StartingPoint = point;
				var blueIcon = {
						size: new google.maps.Size(32, 32), 
						anchor: new google.maps.Point(16, 32),
						url: "http://maps.google.com/mapfiles/kml/pal3/icon38.png"
				}
				var markerOptions = { 
					map: SLKP_map,
					icon: blueIcon, 
					position: point, 
					//shadow: {size: new google.maps.Size(56, 32)}	Because marker is not coming with this parameter that why we comented it on 06/Sep/2013. 
				};
				var marker = new google.maps.Marker(markerOptions);
				SLKP_map.setCenter(marker.Position);
				SLKP_map.setZoom(8)
				SLKP_map.panTo(point);				
				var info_window = new google.maps.InfoWindow({content: SVMXC_GetMessage("MSG010")});
				google.maps.event.addListener(marker, "mouseover", function() {info_window.open(SLKP_map, marker);}) ;
				google.maps.event.addListener(marker, "mouseout", function() {info_window.close();}) ;
				markersArray.push(marker);
			}
			else
			{
				alert(SVMXC_GetMessage("MSG009"));
				SVMXC_ShowUnitedStates();
			}
		}
	})
}

/*==========================================================*/
function SVMXC_ShowPointsOnMap(strJSON,radius,unit) 
{	
	var SiteName = '';
    var Street = '';
    var City = '';
    var State = '';
    var Zip = '';
    var Country = '';
    var Phone = '';
	var latitude = 0;
	var longitute = 0;
	var QtyAvlbl = 0;
	var SiteId = '';
	var KeyValue;
	var keyVal = JSON.parse(strJSON);
	SLKP_radius = radius;
	SLKP_unit = unit;
	
	returnValue = new Object();
	SVMXC_deleteOverlays();
	SVMXC_AddStartingPoint();
	
	if(keyVal.length <= 0)
		alert(SVMXC_GetMessage("MSG011"));
		
	for(key in keyVal){
		var val = keyVal[key];
		QtyAvlbl = val['SVMXC__Quantity2__c'];
		SiteId = val['SVMXC__Location__c'];
		KeyValue = val['SVMXC__Location__r'];
		SiteName = KeyValue['Name'];
		Street = KeyValue['SVMXC__Street__c'];
		City = KeyValue['SVMXC__City__c'];
		State = KeyValue['SVMXC__State__c'];
		Zip = KeyValue['SVMXC__Zip__c'];
		Country = KeyValue['SVMXC__Country__c'];
		Phone = KeyValue['SVMXC__Site_Phone__c'];
		latitude = KeyValue['SVMXC__Latitude__c'];
		longitute = KeyValue['SVMXC__Longitude__c'];
		objPSIDName[''+KeyValue['Id']] = (SiteName)?SiteName:SiteId;
		
		var point = new google.maps.LatLng(((latitude)?latitude:" "), ((longitute)?longitute:" "));
		var icon = {
			size: new google.maps.Size(32, 32), 
			anchor: new google.maps.Point(16, 32),
			url: "http://maps.google.com/mapfiles/kml/pal2/icon5.png"
		}
		var StockTag = "<b>" + ((SiteName)?SiteName:" ") + "</b><br>" + 
							  ((Street)?Street:" ") + "<br>" + ((City)?City:" ") + ", " + ((State)?State:" ") + " " + ((Zip)?Zip:" ") + ", " + ((Country)?Country:" ") + "<br>" + 
							  SVMXC_GetMessage("MSG013") + ((Phone)?Phone:" ") + "<br>" + 
							  "<b> "+SVMXC_GetMessage("MSG014") + QtyAvlbl + "</b>" +
							  "<br>"+SVMXC_GetMessage("MSG012");				  
		var Distance = SVMXI_CalculateDistance(SLKP_StartingPoint.lat(),SLKP_StartingPoint.lng(),latitude,longitute);
		if (Distance <= SLKP_radius || SLKP_radius == 0)
		{	
			returnValue[SiteName] = Distance;
			if (parseFloat(QtyAvlbl) >= parseFloat(SLKP_ReqQty)) 
				icon.image = "http://maps.google.com/mapfiles/kml/pal2/icon5.png"; 
			else 
				icon.image = "http://maps.google.com/mapfiles/kml/pal4/icon53.png"; 
			SVMXC_AddPointToMap(icon,point,StockTag,SiteId);
		}
	}
	if(markersArray.length <= 0){
		alert(SVMXC_GetMessage("MSG022"));
	}
	return 	returnValue;
} 

/*=====================================================================================*/
function SVMXC_AddPointToMap(icon,point,StockTag,SiteId)
{	
	icon.size = new google.maps.Size(32, 32);
	icon.anchor = new google.maps.Point(16, 32);
	var markerOptions = { 
		map: SLKP_map,
		icon: icon, 
		position: point, 
		//shadow: { size: new google.maps.Size(56, 32)}	Because marker is not coming with this parameter that why we comented it on 06/Sep/2013. 
	};
	var marker = new google.maps.Marker(markerOptions);
	var info_window = new google.maps.InfoWindow({content: StockTag});
	google.maps.event.addListener(marker, "mouseover", function() {info_window.open(SLKP_map, marker);}) ;
	google.maps.event.addListener(marker, "mouseout", function() {info_window.close();}) ;
	//google.maps.event.addListener(marker, "click", function() { SVMXC_ShowDirections(SLKP_StartingPoint, point); });
	google.maps.event.addListener(marker, "dblclick", function() { SVMXC_RequestStock(SiteId); }); 
	markersArray.push(marker);
}

/*=====================================================================================*/
function SVMXC_ShowDirections(FromAddress, ToAddress)
{	
	var directionsService = new google.maps.DirectionsService();
	var	directionsDisplay =	new google.maps.DirectionsRenderer();
	var request = {
        origin:FromAddress,
        destination:ToAddress,
		travelMode: google.maps.TravelMode.DRIVING
    };
	directionsService.route(request, function(response, status) {
			if (status == google.maps.DirectionsStatus.OK) {
				directionsDisplay.setMap(SLKP_map);	
				directionsDisplay.setDirections(response);
			}
    });
}

/*=====================================================================================*/
function SVMXC_deleteOverlays() {
  if (markersArray) {
    for (i in markersArray) {
      markersArray[i].setMap(null);
    }
    markersArray.length = 0;
  }
}


/*=============================================================================*/
// Get the message for the given message number from the global hash table.
// Return "setup-issue" if the message is not found
function SVMXC_GetMessage(MsgNum)
{
    if (!MsgList[''+MsgNum])
		return "Message definition for " + MsgNum + " not found. This is a setup issue.\nPlease contact your ServiceMax administrator to resolve this.";
    return MsgList[''+MsgNum];
}
/*=============================================================================*/

function SVMXC_GetLocationName(id)
{	
	if (!objPSIDName[''+id])
		return " ";
	return objPSIDName[''+id];
}

/*=====================================================================================*/
function SVMXC_ShowUnitedStates()
{	
	SLKP_StartingPoint = new google.maps.LatLng(0,0); 
	SLKP_geocoder.geocode( {'address': "United States" }, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			var point = results[0].geometry.location;		
			if (point)
			{
				SLKP_StartingPoint = point;
				var blueIcon = {
						size: new google.maps.Size(32, 32), 
						anchor: new google.maps.Point(16, 32),
						url: "http://maps.google.com/mapfiles/kml/pal3/icon38.png"
				}
				markerOptions = { 
					map: SLKP_map,
					icon: blueIcon, 
					position: point, 
					//shadow: {size: new google.maps.Size(56, 32)}	Because marker is not coming with this parameter that why we comented it on 06/Sep/2013. 
				};
				var marker = new google.maps.Marker(markerOptions);
				SLKP_map.setCenter(marker.Position);
				SLKP_map.setZoom(8)
				SLKP_map.panTo(point);				
				var info_window = new google.maps.InfoWindow({content: SVMXC_GetMessage("MSG010")});
				google.maps.event.addListener(marker, "mouseover", function() {info_window.open(SLKP_map, marker);}) ;
				google.maps.event.addListener(marker, "mouseout", function() {info_window.close();}) ;
				markersArray.push(marker);
			}
		}
	})
}
/*=====================================================================================*/ 