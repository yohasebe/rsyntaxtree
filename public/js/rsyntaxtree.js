$(function(){                 

  var subdir = $('#top').data('subdir');

  function alert(msg, type){
    $("#alert").html("<div style='padding:2px; margin:0;' class='" + type + 
    "'>" + msg + "</p></div>");
  }

  function make_params(data){
    var params = "data=" + encodeURIComponent(data);
    params = params + "&format=" +  $("select[name=format]").val();
    params = params + "&leafstyle=" +  $("select[name=leafstyle]").val();
    params = params + "&fontstyle=" +  $("select[name=fontstyle]").val();
    params = params + "&fontsize=" +  $("select[name=fontsize]").val();
    params = params + "&color=" +  $("button.active[name=color]").val();
    params = params + "&autosub=" +  $("button.active[name=autosub]").val();
    params = params + "&symmetrize=" +  $("button.active[name=symmetrize]").val();
    return params;
  }
  
  function draw_graph(data){
	$.ajax({
	    url: subdir + '/draw_png',
	    type: 'POST',
	    data: make_params(data),
	    success: function (raw_data) {
	      var png_img = 'data:image/png;base64, ' + raw_data;
        $("#result").html("<img id='tree_image'>");
	      $('#tree_image').attr('src', png_img);
	    }
    });
  }

  function escape_chrs(data){
    data = data.replace(/\&/g, "-AMP-").replace(/\'/g, "-PRIME-").replace(/\;/g, "-SCOLON");
    data = $('<div/>').text(data).html();
    return data;
  }

  function postForm(data, format){
    $('<form/>', {action: subdir + '/download_' + format, method: 'POST'})
      .append($('<input/>', {type: 'hidden', name: 'data', value: data}))
      .append($('<input/>', {type: 'hidden', name: 'format', value: $("select[name=format]").val()}))
      .append($('<input/>', {type: 'hidden', name: 'leafstyle', value: $("select[name=leafstyle]").val()}))
      .append($('<input/>', {type: 'hidden', name: 'fontstyle', value: $("select[name=fontstyle]").val()}))
      .append($('<input/>', {type: 'hidden', name: 'fontsize', value: $("select[name=fontsize]").val()}))
      .append($('<input/>', {type: 'hidden', name: 'color', value: $("button.active[name=color]").val()}))
      .append($('<input/>', {type: 'hidden', name: 'autosub', value: $("button.active[name=autosub]").val()}))
      .append($('<input/>', {type: 'hidden', name: 'symmetrize', value: $("button.active[name=symmetrize]").val()}))
      .appendTo(document.body).submit();
  }


  $("#draw_png").click(function(){
    $("#alert").empty();
    var data = $("#data").val();
    data = escape_chrs(data);
    $.ajax({
       type: "POST",
       url: subdir + "/check",
       data:"data=" + data,
       success: function(msg){
         if(msg != "true"){
           alert("Expression is not valid", "alert-error");
         } else {
           draw_graph(data, "png");
         }  
       }
    });
  });

  $("#download_pdf").click(function(){
    $("#alert").empty();
    var data = $("#data").val();
    data = escape_chrs(data);
    $.ajax({
       type: "POST",
       url: subdir + "/check",
       data:"data=" + data,
       success: function(msg){
         if(msg != "true"){
           alert("Expression is not valid", "alert-error");
         } else {
           postForm(data, "pdf");
         }  
       }
    });
  });
              

  $("#download_svg").click(function(){
    $("#alert").empty();
    var data = $("#data").val();
    data = escape_chrs(data);
    $.ajax({
       type: "POST",
       url: subdir + "/check",
       data:"data=" + data,
       success: function(msg){
         if(msg != "true"){
           alert("Expression is not valid", "alert-error");
         } else {
           postForm(data, "svg");
         }  
       }
    });
  });
    
  
  $("#check").click(function(){    
    $.ajax({
       type: "POST",
       url: subdir + "/check",
       data:"data=" + escape_chrs($("#data").val()),
       success: function(msg){
         if(msg == "true"){
           alert("Expression is valid", "alert-success");
         } else {
           alert("Expression is not valid", "alert-error");
         }
       }
    });    
  });

  $("#clear").click(function(){
    $("#data").html("");
    $("#alert").empty();
  });


});