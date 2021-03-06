class StripeCallbacks

  def charge_succeeded(event)

    invoice = event.data.object.invoice

    if invoice.blank?
      #subscription = DonorSubscription.where('unique_subscription_id = ?', event.data.object.id) # stripe charge.id
      subscription = DonorSubscription.find_by unique_subscription_id: event.data.object.id

    else
      invoice = Stripe::Invoice.retrieve(event.data.object.invoice)
      subscription = DonorSubscription.find_by unique_subscription_id: invoice.lines.data.first.id

      #subscription = DonorSubscription.where('unique_subscription_id = ?', invoice.lines.data.first.id) # stripe subscription.id
    end

    transaction = Stripe::BalanceTransaction.retrieve(event.data.object.balance_transaction)

    charge_amount = BigDecimal(transaction.amount.to_s) / 100
    transaction_fee = BigDecimal(transaction.fee.to_s) / 100
    donation_amount = BigDecimal(transaction.net.to_s) / 100
    transaction_id = transaction.id.to_s

    donation = Donation.add_donation(subscription.id, charge_amount, transaction_id, transaction_fee, donation_amount)
    
    #passthru_grant = Grant.add_passthru_grant(subscription, donation_amount) #no pass-thrus yet

    donor = Donor.find(subscription.donor_id)
    endowment = Endowment.find(subscription.endowment_id)
    DonorMailer.charge_success(donor, endowment, charge_amount).deliver

  end

  def transfer_created(event)
    transfer = event.data.object

    TransitFund.create(
      transaction_id: transfer.id,
      source: "stripe",
      destination: "etrade",
      amount: (BigDecimal("#{transfer.amount}")/100).floor(2), #stripe records cents, we record BigDecimal
      cleared: false
    )
    
  end
  
  def transfer_paid(event)
    stripe_transfer = event.data.object
    our_transfer = TransitFund.where("transaction_id=?", transfer.id)
    our_transfer.cleared=true
    our_transfer.save
  end
  
end