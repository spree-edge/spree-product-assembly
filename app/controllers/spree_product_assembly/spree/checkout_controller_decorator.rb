module SpreeProductAssembly
  module Spree
    module CheckoutControllerDecorator
      # Override because we don't want to remove unshippable items from the order
      # A bundle itself is an unshippable item

      private

      def before_payment
        if @order.checkout_steps.include? 'delivery'
          packages = @order.shipments.map(&:to_package)
          @differentiator = ::Spree::Stock::Differentiator.new(@order, packages)
          @differentiator.missing.reject { |variant| variant.try(:parts).try(:any?) }.each do |variant, quantity|
            ::Spree::Dependencies.cart_remove_item_service.constantize.call(order: @order, variant: variant, quantity: quantity)
          end
        end

        @payment_sources = try_spree_current_user.payment_sources if try_spree_current_user&.respond_to?(:payment_sources)
      end
    end
  end
end

Spree::CheckoutController.prepend SpreeProductAssembly::Spree::CheckoutControllerDecorator
