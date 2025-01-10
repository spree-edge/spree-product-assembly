module SpreeProductAssembly
  module Spree
    module Stock
      module InventoryUnitBuilderDecorator
        def units
          @order.line_items.flat_map do |line_item|
            line_item.quantity_by_variant.flat_map do |variant, quantity|
              if Gem.loaded_specs['spree_core'].version >= Gem::Version.create('3.3.0')
                build_inventory_unit(variant, line_item, quantity)
              else
                quantity.times.map { build_inventory_unit(variant, line_item) }
              end
            end
          end
        end

        def build_inventory_unit(variant, line_item, quantity=nil)
          @order.inventory_units.includes(
            variant: {
              product: {
                shipping_category: {
                  shipping_methods: [:calculator, { zones: :zone_members }]
                }
              }
            }
          ).build(
            pending: true,
            variant: variant,
            line_item: line_item,
            order: @order
          ).tap do |iu|
            iu.quantity = quantity if quantity
          end
        end
      end
    end
  end
end

Spree::Stock::InventoryUnitBuilder.prepend SpreeProductAssembly::Spree::Stock::InventoryUnitBuilderDecorator
