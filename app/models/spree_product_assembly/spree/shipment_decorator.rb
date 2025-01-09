module SpreeProductAssembly
  module Spree
    module ShipmentDecorator
      # Overriden from Spree core as a product bundle part should not be put
      # together with an individual product purchased (even though they're the
      # very same variant) That is so we can tell the store admin which units
      # were purchased individually and which ones as parts of the bundle
      #
      # Account for situations where we can't track the line_item for a variant.
      # This should avoid exceptions when users upgrade from spree 1.3
      #
      # TODO Can possibly be removed as well. We already override the manifest
      # partial so we can get the product there
      ManifestItem = Struct.new(:part, :product, :line_item, :variant, :quantity, :states)

      def manifest
        inventory_units.group_by(&:variant_id).map do |variant, inventory_units|
          inventory_units.group_by(&:line_item_id).map do |line_item, units|

            line_item = units.first.line_item
            variant = units.first.variant

            if Gem.loaded_specs['spree_core'].version >= Gem::Version.create('3.3.0')
              states = units.group_by(&:state).each_with_object({}) { |(state, iu), acc| acc[state] = iu.sum(&:quantity) }
              quantity = units.sum(&:quantity)
            else
              states = units.group_by(&:state).each_with_object({}) { |(state, iu), acc| acc[state] = iu.count }
              quantity = units.length
            end

            part = line_item.try(:product).try(:assembly?) || false
            ManifestItem.new(part,
                              line_item.try(:product),
                              line_item,
                              variant,
                              quantity,
                              states)
          end
        end.flatten
      end

      # There might be scenarios where we don't want to display every single
      # variant on the shipment. e.g. when ordering a product bundle that includes
      # 5 other parts. Frontend users should only see the product bundle as a
      # single item to ship
      def line_item_manifest
        inventory_units.includes(:line_item, :variant).group_by(&:line_item).map do |line_item, units|
          states = {}
          units.group_by(&:state).each { |state, iu| states[state] = iu.count }
          OpenStruct.new(line_item: line_item, variant: line_item.variant, quantity: units.length, states: states)
        end
      end

      def inventory_units_for_item(line_item, variant)
        inventory_units.where(line_item_id: line_item.id, variant_id: variant.id)
      end
    end
  end
end
Spree::Shipment.prepend SpreeProductAssembly::Spree::ShipmentDecorator
