//= require ./translations

(function() {
  document.addEventListener("turbo:load", function() {
    var makePostRequest, partsTable, searchForParts, searchResults, showErrorMessages;
    Spree.routes.available_admin_product_parts = function(productSlug) {
      return Spree.pathFor("admin/products/" + productSlug + "/parts/available");
    };
    showErrorMessages = function(xhr) {
      var response;
      response = JSON.parse(xhr.responseText);
      return show_flash("error", response);
    };
    partsTable = $("#product_parts");
    searchResults = $("#search_hits");
    searchForParts = function() {
      var productSlug, searchUrl;
      productSlug = partsTable.data("product-slug");
      searchUrl = Spree.routes.available_admin_product_parts(productSlug);
      return $.ajax({
        data: {
          q: $("#searchtext").val(),
          authenticity_token: AUTH_TOKEN
        },
        dataType: 'html',
        success: function(request) {
          searchResults.html(request);
          searchResults.show();
          return $('select.select2').select2();
        },
        type: 'POST',
        url: searchUrl
      });
    };
    $("#searchtext").keypress(function(e) {
      if ((e.which && e.which === 13) || (e.keyCode && e.keyCode === 13)) {
        searchForParts();
        return false;
      } else {
        return true;
      }
    });
    $("#search_parts_button").click(function(e) {
      e.preventDefault();
      return searchForParts();
    });
    makePostRequest = function(link, post_params) {
      var request, spinner;
      if (post_params == null) {
        post_params = {};
      }
      post_params['authenticity_token'] = AUTH_TOKEN
      spinner = $("img.spinner", link.parent());
      spinner.show();
      request = $.ajax({
        type: "POST",
        url: link.attr("href"),
        data: post_params,
        dateType: "script"
      });
      request.fail(showErrorMessages);
      request.always(function() {
        return spinner.hide();
      });
      return false;
    };
    searchResults.on("click", "a.add_product_part_link", function(event) {
      var link, loadingIndicator, part, quantityField, row, selectedVariantOption;
      event.preventDefault();
      part = {};
      link = $(this);
      row = $("#" + link.data("target"));
      loadingIndicator = $("img.spinner", link.parent());
      quantityField = $('input:last', row);
      part.count = quantityField.val();
      if (row.hasClass("with-variants")) {
        selectedVariantOption = $('select.part_selector option:selected', row);
        part.part_id = selectedVariantOption.val();
        if (selectedVariantOption.text() === Spree.translations.user_selectable) {
          part.variant_selection_deferred = "t";
          part.part_id = link.data("master-variant-id");
        }
      } else {
        part.part_id = $('input[name="part[id]"]', row).val();
      }
      part.assembly_id = $('[name="part[assembly_id]"]', row).val();
      return makePostRequest(link, {
        assemblies_part: part
      });
    });
    partsTable.on("click", "a.set_count_admin_product_part_link", function() {
      var params;
      params = {
        count: $("input#count", $(this).parent().parent()).val(),
        change_part_id: $("select", $(this).parent().parent()).val()
      };
      return makePostRequest($(this), params);
    });
    return partsTable.on("click", "a.remove_admin_product_part_link", function() {
      return makePostRequest($(this));
    });
  });

}).call(this);
