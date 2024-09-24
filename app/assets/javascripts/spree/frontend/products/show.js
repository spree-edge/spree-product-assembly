Spree.ready(function(){
  if ($('.assemblies_variant').length) {
    $('.assemblies_variant').first().show();

    $('[name="variant_id"]').on('click', function(){
      $('.assemblies_variant').hide();
      $('.assemblies_for_variant_' + $(this).val()).show();
    });
  }
});
