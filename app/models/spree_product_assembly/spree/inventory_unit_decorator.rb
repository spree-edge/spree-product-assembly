module SpreeProductAssembly
  module Spree
    module InventoryUnitDecorator
      def percentage_of_line_item
        product = line_item.product
        if product.assembly?
          total_value = line_item.quantity_by_variant.map { |part, quantity| part.price * quantity }.sum
          variant.price / total_value
        else
          1 / BigDecimal(line_item.quantity)
        end
      end
    end
  end
end

Spree::InventoryUnit.prepend SpreeProductAssembly::Spree::InventoryUnitDecorator
