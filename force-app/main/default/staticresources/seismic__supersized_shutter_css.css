/*

	Supersized - Fullscreen Slideshow jQuery Plugin
	Version : 3.2.7
	Site	: www.buildinternet.com/project/supersized
	
	Theme 	: Shutter 1.2
	Author	: Sam Dunn
	Company : One Mighty Roar (www.onemightyroar.com)
	License : MIT License / GPL License
	
*/

	/* Controls Bar
	----------------------------*/
	#controls-wrapper { margin:0 auto; height:42px; width:100%; bottom:0px; left:0; z-index:4; background:url(../nav-bg.png) repeat-x; position:sta; }
		#controls { overflow:hidden; height:100%; position:relative; text-align:left; z-index:5; }
			#slidecounter { color:#000; font:14px "Helvetica Neue", Helvetica, Arial, sans-serif; margin:0 30px; line-height:30px; height:30px; text-align: left;}
			#slidecaption { overflow:hidden; float:left; color:#FFF; font:400 14px "Helvetica Neue", Helvetica, Arial, sans-serif; text-shadow:#000 1px 1px 2px; margin:0 20px 0 0; line-height:42px; }
			
			#navigation { float:right; margin:0px 20px 0 0; }
				#play-button{ float:left; margin-top:1px;border-right:1px solid #333; background:url('../bg-hover.png') repeat-x 0 44px; }
					#play-button:hover{ background-position:0 1px; cursor:pointer; }
				
				#prevslide, #nextslide{ position:absolute; height:43px; width:43px; top:50%; margin-top:-21px; opacity:0.6; z-index: 1; }
					#prevslide{ left:10px; }
					#nextslide{ right:10px; }
						#prevslide:active, #nextslide:active{ margin-top:-19px; }
						#prevslide:hover, #nextslide:hover{ cursor:pointer; }
				
				ul#slide-list{ padding:15px 0; float:left; position:absolute; left:50%; }
					ul#slide-list li{ list-style:none; width:12px; height:12px; float:left; margin:0 5px 0 0; }
						ul#slide-list li.current-slide a, ul#slide-list li.current-slide a:hover{ background-position:0 0px; }
						ul#slide-list li a{ display:block; width:12px; height:12px; background:url('../nav-dot.png') no-repeat 0 -24px; }
							ul#slide-list li a:hover{ background-position:0 -12px; cursor:pointer; }
				
				#tray-button{ float:right; margin-top:1px; border-left:1px solid #333; background:url('../bg-hover.png') repeat-x 0 44px; }
					#tray-button:hover{ background-position:0 1px; cursor:pointer; }
		
	
	/* Progress Bar
	----------------------------*/					
	#progress-back{ z-index:5; position:fixed; bottom:42px; left:0; height:8px; width:100%;  }
		#progress-bar{ position:relative; height:8px; width:100%; }
	
	/* Thumbnail Navigation
	----------------------------*/	
	#nextthumb,#prevthumb { z-index:2; display:none; position:absolute; bottom:61px; height:75px; width:100px; overflow:hidden; background:#ddd; border:1px solid #fff; -webkit-box-shadow:0 0 5px #000; }
		#nextthumb { right:12px; }
		#prevthumb { left:12px; }
			#nextthumb img, #prevthumb img { width:150px; height:auto;  }
			#nextthumb:active, #prevthumb:active { bottom:59px; }
			#nextthumb:hover, #prevthumb:hover { cursor:pointer; }
	
	
	/* Thumbnail Tray
	----------------------------*/			
	#thumb-tray{ position:absolute; z-index:3; bottom:0; left:0; background:url(../bg-black.png); height:140px; width:100%; overflow:hidden; text-align:left; -moz-box-shadow: 0px 0px 4px #000; -webkit-box-shadow: 0px 0px 4px #000; box-shadow: 0px 0px 4px #000; }
		
		#thumb-back, #thumb-forward{ opacity: 0.8; position:absolute; z-index:5; top:0px; height: 0; width: 0; border-width: 8px;border-color: black;margin: 10px;border-style: solid;margin: 6px 0;padding: 0;border-top-color: transparent;border-bottom-color: transparent;cursor: pointer;}
			#thumb-back{ left: 0; border-left-color: transparent; }
			#thumb-forward{ right: 0; border-right-color: transparent; }
				#thumb-back:hover, #thumb-forward:hover{ opacity: 1; }
		
		
		ul#thumb-list{ display:inline-block; list-style:none; position:relative; left:0px; padding:0 0px;}
			ul#thumb-list li{ background:#fff; list-style:none; display:inline; width:150px; height:108px; overflow:hidden; float:left; margin:0; }
				ul#thumb-list li img { width:150px; height:auto; opacity:0.5; -ms-filter: "progid:DXImageTransform.Microsoft.Alpha(Opacity=60)"; filter:alpha(opacity=60); -webkit-transition: all 100ms ease-in-out; -moz-transition: all 100ms ease-in-out; -o-transition: all 100ms ease-in-out; -ms-transition: all 100ms ease-in-out; transition: all 100ms ease-in-out; }
                ul#thumb-list li img.thumbImage[isloadingimage] { display: block; margin: auto; padding: 30px 0; width: 30px;}
				ul#thumb-list li > span {display: block; color: #888888; width: 100%; height: 18px;background-color: black;text-align: center;line-height: 18px;}
                ul#thumb-list li.current-thumb img, ul#thumb-list li:hover img{ opacity:1; -ms-filter: "progid:DXImageTransform.Microsoft.Alpha(Opacity=100)"; filter:alpha(opacity=100); }
				ul#thumb-list li:hover{ cursor:pointer; }
				