$(function() {
  $("#logout, #login")
    .bind("ajax:beforeSend", function() {
      $(".float-left .btn").addClass("disabled");
      $(this).addClass("no-hover");
      $("a[data-toggle]").tooltip("hide");
      $("#loading").show();
      $("#subscription").empty();
    })
    .bind("ajax:complete", function() {
      $(this).removeClass("no-hover");
      $("#loading").hide();
      $(".float-left .btn").removeClass("disabled");
    })
    .bind("ajax:error", function() {
      console.log('error');
    });
});
