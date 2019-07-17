function autoreload_subscribe() {
  WebChannels.sendMessageTo("autoreload", "subscribe");
  console.log("Autoreloading ready");
}

setTimeout(autoreload_subscribe, 2000);

WebChannels.messageHandlers.push(function(event) {
  console.log(event.data);

  if ( event.data == "autoreload:full" ) {
    location.reload(true);
  }
  if ( event.data == "autoreload:dom" ) {
    console.log("dom autoreload");

    $.ajax({
      url: window.location
    }).done(function(data) {
      $('html').html();
    });
  }
});