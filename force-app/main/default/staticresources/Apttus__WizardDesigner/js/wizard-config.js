	$(document).ready(function(){
 		$(document).on("mouseenter", "table td div", function() {
            if (this.offsetWidth < this.scrollWidth){
                $(this).attr('title',$(this).text());
            }
        }).on("mouseleave", "table td div", function() {
            $(this).removeAttr('title',$(this).text());
        });
    })