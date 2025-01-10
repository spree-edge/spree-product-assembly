module Spree::Cart::AddItemDecorator
  private

  def add_to_line_item(order:, variant:, quantity: nil, public_metadata: {}, private_metadata: {}, options: {})
    options ||= {}
    quantity ||= 1
    line_item = Spree::Dependencies.line_item_by_variant_finder.constantize.new.execute(order: order, variant: variant, options: options)
    line_item_created = line_item.nil?

    if line_item_created
      opts = ::Spree::PermittedAttributes.line_item_attributes.flatten.each_with_object({}) do |attribute, result|
        result[attribute] = options[attribute]
      end.merge(currency: order.currency).merge(whitelist(options)).delete_if { |_key, value| value.nil? }

      line_item = order.line_items.new(quantity: quantity,
                                      variant: variant,
                                      options: opts)
    else
      line_item.quantity += quantity.to_i
    end

    line_item.target_shipment = options[:shipment] if options.key? :shipment
    line_item.public_metadata = public_metadata.to_h if public_metadata
    line_item.private_metadata = private_metadata.to_h if private_metadata
    return failure(line_item) unless line_item.save

    line_item.reload.update_price

    ::Spree::TaxRate.adjust(order, [line_item]) if line_item_created
    populate_part_line_items(line_item: line_item, options: options) if options[:populate]
    success(order: order, line_item: line_item, line_item_created: line_item_created, options: options)
  end

  def populate_part_line_items(line_item:, options:)
    parts = line_item.variant.parts_variants
    parts.each do |part|
      part_line_item = line_item.part_line_items.find_or_initialize_by(
        line_item: line_item,
        variant_id: variant_id_for(part, options)
      )

      part_line_item.update!(quantity: part.count)
    end
  end

  def part_variant_ids(line_item)
    line_item.part_line_items.map(&:variant_id)
  end

  def variant_id_for(part, options)
    if part.variant_selection_deferred?
      options[:selected_variants]['selected_variants'][part.part.id.to_s]
    else
      part.part.id
    end
  end

  def whitelist(params)
    if params.is_a? ActionController::Parameters
      params.permit(Spree::PermittedAttributes.line_item_attributes)
    else
      params.slice(*Spree::PermittedAttributes.line_item_attributes)
    end
  end
end

Spree::Cart::AddItem.prepend Spree::Cart::AddItemDecorator if Spree.version.to_f >= 3.7
