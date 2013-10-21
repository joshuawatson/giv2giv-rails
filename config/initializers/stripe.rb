Stripe.api_key = App.stripe["api_key"]

StripeEvent.setup do
  subscribe 'charge.succeeded' do |event|
    invoice = event.data.object.invoice
    
    if invoice.blank?    
      ret_invoice = nil
    else
      ret_invoice = Stripe::Invoice.retrieve(invoice)
    end

    if ret_invoice.blank?
      # one-time-payment
      stripe_amount = event.data.object.amount / 100
      Donation.add_donation(stripe_amount, event.data.object.id)
    else
      # donor subscriptions
      ret_invoice.lines.data.each do |line_data|
        stripe_amount = line_data.amount / 100
        Donation.add_donation(stripe_amount, line_data.id)
      end # invoice lines data
    end
    
  end # end charge.successed
end