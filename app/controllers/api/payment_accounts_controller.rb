class Api::PaymentAccountsController < Api::BaseController
  before_filter :current_donor_id, :except => [:index, :create, :one_time_payment]
  skip_before_filter :current_donor_id, :only => [:all_donation_list, :cancel_subscription, :cancel_all_subscription]
  skip_before_filter :require_authentication, :only => :one_time_payment

  def index
    pas = current_donor.payment_accounts

    respond_to do |format|
      format.json { render json: pas }
    end
  end

  def create
    set_token = params[:stripeToken]
    if set_token.blank?
      render json: { :message => "Please provide your stripe token" }.to_json
    else
      if params.has_key?(:payment_account)
        payment = PaymentAccount.new_account(set_token, current_donor.id, {:donor => current_donor}.merge(params[:payment_account]))
        render json: payment.to_json
      else
        render json: { :message => "Wrong parameters" }.to_json
      end
    end
  end

  def update
    set_token = params[:stripeToken]
    if set_token.blank?
      render json: { :message => "Please provide your stripe token"}.to_json
    else
      if params.has_key?(:payment_account)
        payment = PaymentAccount.update_account(set_token, current_donor.id, current_donor_id, {:donor => current_donor}.merge(params[:payment_account]))

        respond_to do |format|
            if current_donor_id && current_donor_id.update_attributes(params[:payment_account])
              format.json { render json: current_donor_id }
            elsif current_donor_id
              format.json { render json: current_donor_id.errors, status: :unprocessable_entity }
            else
              format.json { head :not_found }
            end
        end

      else
        render json: {:message => "Wrong parameters"}.to_json
      end
    end
  end

  def show
    respond_to do |format|
      if current_donor_id
        format.json { render json: current_donor_id }
      else
        format.json { head :not_found }
      end
    end
  end

  def destroy
    respond_to do |format|
      if current_donor_id
        current_donor_id.destroy
        render json: { :message => "Payment account has been delete" }.to_json
      else
        format.json { head :not_found }
      end
    end
  end

  def donate_subscription
    respond_to do |format|
      if current_donor_id && donation = current_donor_id.donate_subscription(params[:amount], params[:charity_group_id], params[:id], current_donor.email)
        format.json { render json: donation }
      else
        format.json { head :not_found }
      end
    end
  end

  def one_time_payment
    respond_to do |format|
      donation = PaymentAccount.one_time_payment(params[:amount].to_i, params[:charity_group_id], params[:email], params[:stripeToken])
      format.json { render json: donation }
    end
  end

  def donation_list
    respond_to do |format|
      if current_donor_id
        format.json { render json: current_donor_id.donations }
      else
        format.json { head :not_found }
      end
    end
  end

  def all_donation_list
    if current_donor
      respond_to do |format|
        if params.has_key?(:start_date) and params.has_key?(:end_date) and params.has_key?(:charity_group_id)
          format.json { render json: Donation.where("charity_group_id = ? AND DATE(created_at) between ? AND ?", params[:charity_group_id], params[:start_date], params[:end_date]) }   
        elsif params.has_key?(:start_date) and params.has_key?(:end_date)   
          format.json { render json: Donation.where("DATE(created_at) between ? AND ?", params[:start_date], params[:end_date]) }
        elsif params.has_key?(:charity_group_id)
          format.json { render json: Donation.where("charity_group_id = ?", params[:charity_group_id]) }
        else
          donor_payment_accounts = current_donor.payment_accounts.all
          donation_data = []
          donor_payment_accounts.each do |payment_account|
            donation_data << payment_account.donations
          end
          format.json { render json: donation_data }
        end
      end
    else
      render :json => { :message => "unauthorized" }.to_json
    end
  end

  def cancel_subscription
    find_donation = Donation.find(params[:id])
    get_donor_id = PaymentAccount.find(find_donation.payment_account_id)
    
    if current_donor.id.to_s.eql?(get_donor_id.donor_id.to_s)
      respond_to do |format|
        cancel_subscription = PaymentAccount.cancel_subscription(get_donor_id.stripe_cust_id, find_donation.gross_amount, params[:id])
        format.json { render json: cancel_subscription }
      end
    else
      render :json => {:message => "unauthorized"}.to_json
    end
  end

  def cancel_all_subscription
    if current_donor
      respond_to do |format|
        cancel_all_subscription = PaymentAccount.cancel_all_subscription(current_donor)
        format.json { render json: cancel_all_subscription }
      end
    else
      render :json => {:message => "unauthorized"}.to_json
    end
  end

  protected

  def current_donor_id
    current_donor.payment_accounts.find(params[:id])
  end

end
